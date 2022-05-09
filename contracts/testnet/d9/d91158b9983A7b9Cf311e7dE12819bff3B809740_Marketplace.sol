pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title NFT Marketplace with ERC-2981 support
 * @notice Defines a marketplace to bid on and sell NFTs.
 *         Sends royalties to rightsholder on each sale if applicable.
 */
contract Marketplace is Ownable {

    struct SellOffer {
        address seller;
        uint256 minPrice;
    }

    struct BuyOffer {
        address buyer;
        uint256 price;
        uint256 createTime;
    }

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // Store the address of the contract of the NFT to trade. Can be changed in
    // constructor or with a call to setTokenContractAddress.
    //address public _tokenContractAddresses = address(0);
    mapping(address => bool) public tokenContractAddresses;
    // Store all active sell offers  and maps them to their respective token ids
    mapping( IERC721 => mapping(uint256 => SellOffer)) public activeSellOffers;
    // Store all active buy offers and maps them to their respective token ids
    mapping( IERC721 => mapping(uint256 => BuyOffer)) public activeBuyOffers;
    // Token contract
    //Token token;
    //IERC721 token;
    // Escrow for buy offers
    mapping(IERC721 => mapping(address => mapping(uint256 => uint256))) public buyOffersEscrow;
    // Allow buy offers
    bool public allowBuyOffers = false;

    // Events
    event NewSellOffer(IERC721 token, uint256 tokenId, address seller, uint256 value);
    event NewBuyOffer(IERC721 token, uint256 tokenId, address buyer, uint256 value);
    event SellOfferWithdrawn(IERC721 token, uint256 tokenId, address seller);
    event BuyOfferWithdrawn(IERC721 token, uint256 tokenId, address buyer);
    event RoyaltiesPaid(IERC721 token, uint256 tokenId, uint value);
    event Sale(IERC721 token, uint256 tokenId, address seller, address buyer, uint256 value);

    constructor(address[] memory _tokenContractAddresses) {
        addTokens(_tokenContractAddresses);
    }

    // can only add tokens to marketplace, not delete them
    function addTokens(address[] memory _tokenContractAddresses) public onlyOwner {
        for(uint i=0; i<_tokenContractAddresses.length; i++){
            require(_checkRoyalties(_tokenContractAddresses[i]), 'contract is not IERC2981');
            tokenContractAddresses[_tokenContractAddresses[i]] = true;
        }
    }

    // /// @notice Checks if NFT contract implements the ERC-2981 interface
    // /// @param _contract - the address of the NFT contract to query
    // /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal returns (bool) {
        return IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
    }

    /// @notice Puts a token on sale at a given price
    /// @param tokenId - id of the token to sell
    /// @param minPrice - minimum price at which the token can be sold
    function makeSellOffer(IERC721 token, uint256 tokenId, uint256 minPrice)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) tokenOwnerOnly(token, tokenId)
    {
        // Create sell offer
        activeSellOffers[token][tokenId] = SellOffer({seller : msg.sender,
                                               minPrice : minPrice});
        // Broadcast sell offer
        emit NewSellOffer(token, tokenId, msg.sender, minPrice);
    }

    /// @notice Withdraw a sell offer
    /// @param tokenId - id of the token whose sell order needs to be cancelled
    function withdrawSellOffer(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) isMarketable(token, tokenId)
    {
        require(activeSellOffers[token][tokenId].seller != address(0),
            "No sale offer");
        require(activeSellOffers[token][tokenId].seller == msg.sender || owner() == msg.sender,
            "Not seller nor owner");
        if(owner() == msg.sender && activeSellOffers[token][tokenId].seller != msg.sender){
            require(token.getApproved(tokenId) != address(this), "token is still approved");
        }
        // Removes the current sell offer
        delete (activeSellOffers[token][tokenId]);
        // Broadcast offer withdrawal
        emit SellOfferWithdrawn(token, tokenId, msg.sender);
    }

    // /// @notice Transfers royalties to the rightsowner if applicable
    // /// @param tokenId - the NFT assed queried for royalties
    // /// @param grossSaleValue - the price at which the asset will be sold
    // /// @return netSaleAmount - the value that will go to the seller after
    // ///         deducting royalties
    function _deduceRoyalties(IERC721 token, uint256 tokenId, uint256 grossSaleValue)
    internal returns (uint256 netSaleAmount) {
        // Get amount of royalties to pays and recipient
        (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(address(token))
        .royaltyInfo(tokenId, grossSaleValue);
        // Deduce royalties from sale value
        uint256 netSaleValue = grossSaleValue - royaltiesAmount;
        // Transfer royalties to rightholder if not zero
        if (royaltiesAmount > 0) {
            royaltiesReceiver.call{value: royaltiesAmount}('');
        }
        // Broadcast royalties payment
        emit RoyaltiesPaid(token, tokenId, royaltiesAmount);
        return netSaleValue;
    }

    /// @notice Purchases a token and transfers royalties if applicable
    /// @param tokenId - id of the token to sell
    function purchase(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) tokenOwnerForbidden(token, tokenId) payable {
        address seller = activeSellOffers[token][tokenId].seller;

        require(seller != address(0),
            "No active sell offer");

        // If, for some reason, the token is not approved anymore (transfer or
        // sale on another market place for instance), we remove the sell order
        // and throw
        // if (token.getApproved(tokenId) != address(this)) {
        //     delete (activeSellOffers[token][tokenId]);
        //     // Broadcast offer withdrawal
        //     emit SellOfferWithdrawn(token, tokenId, seller);
        //     // Revert
        //     revert("Invalid sell offer");
        // }

        require(msg.value == activeSellOffers[token][tokenId].minPrice,
            "Invalid value");
        uint256 saleValue = msg.value;
        // Pay royalties if applicable
        saleValue = _deduceRoyalties(token, tokenId, saleValue);
        // Transfer funds to the seller
        activeSellOffers[token][tokenId].seller.call{value: saleValue}('');
        // And token to the buyer
        token.safeTransferFrom(
            seller,
            msg.sender,
            tokenId
        );
        // Remove all sell and buy offers
        delete (activeSellOffers[token][tokenId]);
        delete (activeBuyOffers[token][tokenId]);
        // Broadcast the sale
        emit Sale(token, tokenId, seller, msg.sender, msg.value);
 } 
    /// @notice Makes a buy offer for a token. The token does not need to have
    ///         been put up for sale. A buy offer can not be withdrawn or
    ///         replaced for 24 hours. Amount of the offer is put in escrow
    ///         until the offer is withdrawn or superceded
    /// @param tokenId - id of the token to buy
    function makeBuyOffer(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) tokenOwnerForbidden(token, tokenId) buyOffersAllowed
    payable {
        // Reject the offer if item is already available for purchase at a
        // lower or identical price
        if (activeSellOffers[token][tokenId].minPrice != 0) {
        require((msg.value < activeSellOffers[token][tokenId].minPrice),
            "Sell order at this price or lower exists");
        }
        // Only process the offer if it is higher than the previous one or the
        // previous one has expired
        require(activeBuyOffers[token][tokenId].createTime <
                (block.timestamp - 180 days) || msg.value >
                activeBuyOffers[token][tokenId].price,
                "Previous buy offer higher or not expired");
        address previousBuyOfferOwner = activeBuyOffers[token][tokenId].buyer;
        uint256 refundBuyOfferAmount = buyOffersEscrow[token][previousBuyOfferOwner]
        [tokenId];
        // Refund the owner of the previous buy offer
        buyOffersEscrow[token][previousBuyOfferOwner][tokenId] = 0;
        if (refundBuyOfferAmount > 0) {
            payable(previousBuyOfferOwner).call{value: refundBuyOfferAmount}('');
        }
        // Create a new buy offer
        activeBuyOffers[token][tokenId] = BuyOffer({buyer : msg.sender,
                                             price : msg.value,
                                             createTime : block.timestamp});
        // Create record of funds deposited for this offer
        buyOffersEscrow[token][msg.sender][tokenId] = msg.value;
        // Broadcast the buy offer
        emit NewBuyOffer(token, tokenId, msg.sender, msg.value);
    }

    /// @notice Withdraws a buy offer. 
    /// @param tokenId - id of the token whose buy order to remove
    function withdrawBuyOffer(IERC721 token, uint256 tokenId)
    external {
        address buyer = activeBuyOffers[token][tokenId].buyer;
        require(buyer == msg.sender || owner() == msg.sender , "Not buyer or owner");
        uint256 refundBuyOfferAmount = buyOffersEscrow[token][buyer][tokenId];
        // Set the buyer balance to 0 before refund
        buyOffersEscrow[token][buyer][tokenId] = 0;
        // Remove the current buy offer
        delete(activeBuyOffers[token][tokenId]);
        // Refund the current buy offer if it is non-zero
        if (refundBuyOfferAmount > 0) {
            buyer.call{value: refundBuyOfferAmount}('');
        }
        // Broadcast offer withdrawal
        emit BuyOfferWithdrawn(token, tokenId, msg.sender);
    }

    /// @notice Lets a token owner accept the current buy offer
    ///         (even without a sell offer)
    /// @param tokenId - id of the token whose buy order to accept
    function acceptBuyOffer(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) tokenOwnerOnly(token, tokenId) {
        address currentBuyer = activeBuyOffers[token][tokenId].buyer;
        require(currentBuyer != address(0),
            "No buy offer");
        uint256 saleValue = activeBuyOffers[token][tokenId].price;
        uint256 netSaleValue = saleValue;
        // Pay royalties if applicable
        netSaleValue = _deduceRoyalties(token, tokenId, saleValue);
        // Delete the current sell offer whether it exists or not
        delete (activeSellOffers[token][tokenId]);
        // Delete the buy offer that was accepted
        delete (activeBuyOffers[token][tokenId]);
        // Withdraw buyer's balance
        buyOffersEscrow[token][currentBuyer][tokenId] = 0;
        // Transfer funds to the seller
        msg.sender.call{value: netSaleValue}('');
        // And token to the buyer
        token.safeTransferFrom(
            msg.sender,
            currentBuyer,
            tokenId
        );
        // Broadcast the sale
        emit Sale(token, tokenId, msg.sender, currentBuyer,saleValue);
    }

    modifier tokenOnMarketplace(IERC721 token){
        require(tokenContractAddresses[address(token)],
            "Token is not on marketplace");
        _;
    }

    modifier isMarketable(IERC721 token, uint256 tokenId) {
        require(token.getApproved(tokenId) == address(this),
            "Not approved");
        _;
    }
    modifier tokenOwnerForbidden(IERC721 token, uint256 tokenId) {
        require(token.ownerOf(tokenId) != msg.sender,
            "Token owner not allowed");
        _;
    }

    modifier tokenOwnerOnly(IERC721 token, uint256 tokenId) {
        require(token.ownerOf(tokenId) == msg.sender,
            "Not token owner");
        _;
    }

    modifier buyOffersAllowed() {
        require(allowBuyOffers,"making new buy offer is not allowed");
        _;
    }    

    // allow or disallow to make new buy offers, old buy offers will not be impacted
    function setAllowBuyOffers(bool newValue) external onlyOwner{
        allowBuyOffers = newValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}