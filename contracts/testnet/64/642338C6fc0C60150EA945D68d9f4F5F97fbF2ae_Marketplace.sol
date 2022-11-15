// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./FeeManager.sol";
import "../interfaces/IMarketplace.sol";

contract Marketplace is ReentrancyGuard, Ownable, Pausable, FeeManager, IMarketplace, ERC721Holder, ERC1155Holder {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    IERC20 public thorToken;

    Counters.Counter private _orderIds;
    Counters.Counter private _itemsSold;
    Counters.Counter private _itemsCanceled;

    mapping(uint256 => Order) private idToOrder;

    // From ERC721 registry tokenId to Order (to avoid asset collision)
    mapping(address => mapping(uint256 => Order)) public orderBytokenId;

    // From ERC721 registry tokenId to Bid (to avoid asset collision)
    mapping(address => mapping(uint256 => Bid)) public bidByOrderId;

    /**
     * @dev Initialize this contract. Acts as a constructor
     * @param _thorToken - currency for payments
     */
    constructor(address _thorToken) {
        require(_thorToken.isContract(), "The accepted token address must be a deployed contract");
        thorToken = IERC20(_thorToken);
    }

    bytes4 public constant IID_IERC1155 = type(IERC1155).interfaceId;
    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;

    function _isERC1155(address nftAddress) internal view returns (bool) {
        return IERC1155(nftAddress).supportsInterface(IID_IERC1155);
    }

    function _isERC721(address nftAddress) internal view returns (bool) {
        return IERC721(nftAddress).supportsInterface(IID_IERC721);
    }

    /**
     * @dev Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    function createOrder(
        uint8 _saleType,
        uint8 _paymentType,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) public override nonReentrant whenNotPaused {
        _createOrder(_saleType, _paymentType, _nftAddress, _tokenId, _amountOfErc1155, _priceInWei, _expiresAt);
    }

    function cancelOrder(address _nftAddress, uint256 _tokenId) public override nonReentrant whenNotPaused {
        Order memory order = orderBytokenId[_nftAddress][_tokenId];

        require(order.seller == msg.sender || msg.sender == owner(), "Marketplace: unauthorized sender");

        // Remove pending bid if any
        Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

        if (bid.id != 0) {
            _cancelBid(bid.id, order.paymentType, _nftAddress, _tokenId, bid.bidder, bid.price);
        }

        // Cancel order.
        _cancelOrder(order.id, _nftAddress, _tokenId, order.amountOfErc1155, msg.sender);
    }

    function updateOrder(
        uint8 _saleType,
        uint8 _paymentType,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) public override nonReentrant whenNotPaused {
        Order memory order = orderBytokenId[_nftAddress][_tokenId];

        // Check valid order to update
        require(order.id != 0, "Marketplace: asset not published");
        require(order.seller == msg.sender, "Marketplace: sender not allowed");
        require(order.expiresAt >= block.timestamp, "Marketplace: order expired");

        // check order updated params
        require(_priceInWei > 0, "Marketplace: Price should be bigger than 0");
        require(_expiresAt > 30 minutes, "Marketplace: Expire time should be 30+ minutes in the future");
        _expiresAt = block.timestamp + _expiresAt;
        order.saleType = _saleType;
        order.paymentType = _paymentType;
        order.amountOfErc1155 = _amountOfErc1155;
        order.price = _priceInWei;
        order.expiresAt = _expiresAt;

        emit OrderUpdated(order.id, _paymentType, _amountOfErc1155, _priceInWei, _expiresAt);
    }

    function safeExecuteOrder(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei
    ) public payable override nonReentrant whenNotPaused {
        // Get the current valid order for the asset or fail
        Order memory order = _getValidOrder(_nftAddress, _tokenId);

        // price will be msg.value internally if paymentType is AVAX
        if (order.paymentType == 0) {
            _priceInWei = msg.value;
        }

        /// Check the execution price matches the order price
        require(order.price == _priceInWei, "Marketplace: invalid price");
        require(order.seller != msg.sender, "Marketplace: unauthorized sender");

        // market fee to cut
        uint256 saleShareAmount = 0;

        // Send market fees to owner
        if (FeeManager.cutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = _priceInWei.mul(FeeManager.cutPerMillion).div(1e6);

            // Transfer share amount for marketplace Owner
            if (order.paymentType == 0) {
                Address.sendValue(payable(owner()), saleShareAmount);
            }
            if (order.paymentType == 1) {
                thorToken.safeTransferFrom(
                    msg.sender, //buyer
                    owner(),
                    saleShareAmount
                );
            }
        }

        // Transfer accepted token amount minus market fee to seller
        if (order.paymentType == 0) {
            Address.sendValue(order.seller, _priceInWei.sub(saleShareAmount));
        }
        if (order.paymentType == 1) {
            thorToken.safeTransferFrom(
                msg.sender, // buyer
                order.seller, // seller
                _priceInWei.sub(saleShareAmount)
            );
        }

        // Remove pending bid if any
        Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

        if (bid.id != 0) {
            _cancelBid(bid.id, order.paymentType, _nftAddress, _tokenId, bid.bidder, bid.price);
        }

        _executeOrder(
            order.id,
            msg.sender, // buyer
            _nftAddress,
            _tokenId,
            order.amountOfErc1155,
            _priceInWei
        );
    }

    function safePlaceBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) public payable override nonReentrant whenNotPaused {
        _createBid(_nftAddress, _tokenId, _priceInWei, _expiresAt);
    }

    function cancelBid(address _nftAddress, uint256 _tokenId) public override nonReentrant whenNotPaused {
        Bid memory bid = bidByOrderId[_nftAddress][_tokenId];
        Order memory order = _getValidOrder(_nftAddress, _tokenId);

        require(bid.bidder == msg.sender || msg.sender == owner(), "Marketplace: Unauthorized sender");

        _cancelBid(bid.id, order.paymentType, _nftAddress, _tokenId, bid.bidder, bid.price);
    }

    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei
    ) public payable override nonReentrant whenNotPaused {
        // check order validity
        Order memory order = _getValidOrder(_nftAddress, _tokenId);

        // price will be msg.value internally if paymentType is AVAX
        if (order.paymentType == 0) {
            _priceInWei = msg.value;
        }

        // item seller is the only allowed to accept a bid
        require(order.seller == msg.sender, "Marketplace: unauthorized sender");

        Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

        require(bid.price == _priceInWei, "Marketplace: invalid bid price");
        require(bid.expiresAt >= block.timestamp, "Marketplace: the bid expired");

        // remove bid
        delete bidByOrderId[_nftAddress][_tokenId];

        emit BidAccepted(bid.id);

        // calc market fees
        uint256 saleShareAmount = bid.price.mul(FeeManager.cutPerMillion).div(1e6);

        // transfer escrowed bid amount minus market fee to seller
        if (order.paymentType == 0) {
            Address.sendValue(payable(bid.bidder), bid.price.sub(saleShareAmount));
        } else if (order.paymentType == 1) {
            thorToken.safeTransfer(bid.bidder, bid.price.sub(saleShareAmount));
        }

        _executeOrder(order.id, bid.bidder, _nftAddress, _tokenId, order.amountOfErc1155, _priceInWei);
    }

    /**
     * @dev Internal function gets Order by nftRegistry and tokenId. Checks for the order validity
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     */
    function _getValidOrder(address _nftAddress, uint256 _tokenId) internal view returns (Order memory order) {
        order = orderBytokenId[_nftAddress][_tokenId];

        require(order.id != 0, "Marketplace: asset not published");
        require(order.expiresAt >= block.timestamp, "Marketplace: order expired");
    }

    /**
     * @dev Executes the sale for a published NFT
     * @param _orderId - Order Id to execute
     * @param _buyer - address
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - NFT id
     * @param _priceInWei - Order price
     */
    function _executeOrder(
        uint256 _orderId,
        address _buyer,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        uint256 _priceInWei
    ) internal {
        // remove order
        delete orderBytokenId[_nftAddress][_tokenId];

        // Transfer NFT asset
        if (_isERC721(_nftAddress)) {
            IERC721(_nftAddress).safeTransferFrom(address(this), _buyer, _tokenId);
        } else if (_isERC1155(_nftAddress)) {
            IERC1155(_nftAddress).safeTransferFrom(address(this), _buyer, _tokenId, _amountOfErc1155, "");
        }

        // Notify ..
        emit OrderSuccessful(_orderId, _buyer, _priceInWei);
    }

    function _createOrder(
        uint8 _saleType,
        uint8 _paymentType,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) internal {
        // Check nft registry
        address assetOwner;
        bytes32 nftType = "721";
        if (_isERC721(_nftAddress)) {
            nftType = "721";
            assetOwner = IERC721(_nftAddress).ownerOf(_tokenId);
            // Check order creator is the asset owner
            require(assetOwner == msg.sender, "Marketplace: Only the asset owner can create orders");
        } else if (_isERC1155(_nftAddress)) {
            nftType = "1155";
            require(_amountOfErc1155 <= IERC1155(_nftAddress).balanceOf(msg.sender, _tokenId), "balance is not enough");
        }

        Order memory _order = orderBytokenId[_nftAddress][_tokenId];
        require(_order.id == 0, "Marketplace: asset published already");

        require(_priceInWei > 0, "Marketplace: Price should be bigger than 0");

        require(_expiresAt > 30 minutes, "Marketplace: Order should be 30+ minutes in the future");
        _expiresAt = block.timestamp + _expiresAt;

        // get NFT asset from seller
        if (nftType == "721") {
            IERC721(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId);
        } else if (nftType == "1155") {
            IERC1155(_nftAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _amountOfErc1155, "");
        }

        _orderIds.increment();
        uint256 orderId = _orderIds.current();

        // save order
        Order memory order = Order({
            id: orderId,
            saleType: _saleType,
            paymentType: _paymentType,
            seller: payable(msg.sender),
            owner: payable(address(0)),
            nftAddress: _nftAddress,
            amountOfErc1155: _amountOfErc1155,
            price: _priceInWei,
            expiresAt: _expiresAt,
            sold: false,
            cancelled: false
        });

        orderBytokenId[_nftAddress][_tokenId] = order;

        idToOrder[orderId] = order;

        emit OrderCreated(orderId, msg.sender, _nftAddress, _tokenId, _amountOfErc1155, _priceInWei, _expiresAt);
    }

    /**
     * @dev Creates a new bid on a existing order
     * @param _nftAddress - Non fungible registry address
     * @param _tokenId - ID of the published NFT
     * @param _priceInWei - Price in Wei for the supported coin
     * @param _expiresAt - expires time
     */
    function _createBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) internal {
        // Checks order validity
        Order memory order = _getValidOrder(_nftAddress, _tokenId);
        require(order.saleType == 1, "Order is not auction");

        // price will be msg.value internally if paymentType is AVAX
        if (order.paymentType == 0) {
            _priceInWei = msg.value;
        }
        // check on expire time
        _expiresAt = block.timestamp + _expiresAt;
        if (_expiresAt > order.expiresAt) {
            _expiresAt = order.expiresAt;
        }

        // Check price if theres previous a bid
        Bid memory bid = bidByOrderId[_nftAddress][_tokenId];

        // if theres no previous bid, just check price > 0
        if (bid.id != 0) {
            if (bid.expiresAt >= block.timestamp) {
                require(_priceInWei > bid.price, "Marketplace: bid price should be higher than last bid");
            } else {
                require(_priceInWei > 0, "Marketplace: bid should be > 0");
            }

            _cancelBid(bid.id, order.paymentType, _nftAddress, _tokenId, bid.bidder, bid.price);
        } else {
            require(_priceInWei > 0, "Marketplace: bid should be > 0");
        }

        // Transfer sale amount from bidder to escrow
        if (order.paymentType == 0) {
            // it will work internal
        } else if (order.paymentType == 1) {
            thorToken.safeTransferFrom(
                msg.sender, // bidder
                address(this),
                _priceInWei
            );
        }

        // Create bid
        bytes32 bidId = keccak256(abi.encodePacked(block.timestamp, msg.sender, order.id, _priceInWei, _expiresAt));

        // Save Bid for this order
        bidByOrderId[_nftAddress][_tokenId] = Bid({
            id: bidId,
            bidder: msg.sender,
            price: _priceInWei,
            expiresAt: _expiresAt
        });

        emit BidCreated(
            bidId,
            _nftAddress,
            _tokenId,
            msg.sender, // bidder
            _priceInWei,
            _expiresAt
        );
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param _orderId - Bid identifier
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     * @param _amountOfErc1155 - Amount in case of Erc1155
     * @param _seller - Address
     */
    function _cancelOrder(
        uint256 _orderId,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        address _seller
    ) internal {
        delete orderBytokenId[_nftAddress][_tokenId];

        /// send asset back to seller
        if (_isERC721(_nftAddress)) {
            IERC721(_nftAddress).safeTransferFrom(address(this), _seller, _tokenId);
        } else if (_isERC1155(_nftAddress)) {
            IERC1155(_nftAddress).safeTransferFrom(address(this), _seller, _tokenId, _amountOfErc1155, "");
        }

        emit OrderCancelled(_orderId);
    }

    /**
     * @dev Cancel bid from an already published order
     *  can only be canceled by seller or the contract owner
     * @param _bidId - Bid identifier
     * @param paymentType - paymentType(0: AVAX, 1: Thor)
     * @param _nftAddress - registry address
     * @param _tokenId - ID of the published NFT
     * @param _bidder - Address
     * @param _escrowAmount - in AVAX or thorToken currency
     */
    function _cancelBid(
        bytes32 _bidId,
        uint8 paymentType,
        address _nftAddress,
        uint256 _tokenId,
        address _bidder,
        uint256 _escrowAmount
    ) internal {
        delete bidByOrderId[_nftAddress][_tokenId];

        // return escrow to canceled bidder
        if (paymentType == 0) {
            Address.sendValue(payable(_bidder), _escrowAmount);
        } else if (paymentType == 1) {
            thorToken.safeTransfer(_bidder, _escrowAmount);
        }

        emit BidCancelled(_bidId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeManager is Ownable {
    event ChangedFeePerMillion(uint256 cutPerMillion);

    // Market fee on sales
    uint256 public cutPerMillion;
    uint256 public constant maxCutPerMillion = 100000; // 10% cut

    constructor() {}

    /**
     * @dev Sets the share cut for the owner of the contract that's
     *  charged to the seller on a successful sale
     * @param _cutPerMillion - Share amount, from 0 to 99,999
     */
    function setOwnerCutPerMillion(uint256 _cutPerMillion) external onlyOwner {
        require(_cutPerMillion < maxCutPerMillion, "The owner cut should be between 0 and maxCutPerMillion");

        cutPerMillion = _cutPerMillion;
        emit ChangedFeePerMillion(cutPerMillion);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.9;

interface IMarketplace {
    struct Order {
        // Order ID
        uint256 id;
        // Sale Type(fixed:0, auction:1)
        uint8 saleType;
        // Payment Type(AVAX:0, THOR:1)
        uint8 paymentType;
        // Seller of the NFT
        address payable seller;
        // Owner of the NFT
        address owner;
        // NFT registry address
        address nftAddress;
        // order amount in case of erc1155
        uint256 amountOfErc1155;
        // Price (in wei) for the published item
        uint256 price;
        // Time when this sale ends
        uint256 expiresAt;
        // sold
        bool sold;
        // cancelled;
        bool cancelled;
    }

    // in case of Order.saleType = 1(auction)
    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address
        address bidder;
        // Price for the bid in wei
        uint256 price;
        // Time when this bid ends
        uint256 expiresAt;
    }

    // ORDER EVENTS
    event OrderCreated(
        uint256 id,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 amountOfErc1155,
        uint256 priceInWei,
        uint256 expiresAt
    );

    event OrderUpdated(uint256 id, uint8 paymentType, uint256 amountOfErc1155, uint256 priceInWei, uint256 expiresAt);

    event OrderSuccessful(uint256 id, address indexed buyer, uint256 priceInWei);

    event OrderCancelled(uint256 id);

    // BID EVENTS
    event BidCreated(
        bytes32 id,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 priceInWei,
        uint256 expiresAt
    );

    event BidAccepted(bytes32 id);
    event BidCancelled(bytes32 id);

    /**
     * @dev Creates a new order
     * @param _saleType - Sale type(0: fixed, 1: auction)
     * @param _paymentType - Sale type(0: AVAX, 1: THOR)
     * @param _nftAddress - Non fungible registry address
     * @param _tokenId - ID of the published NFT
     * @param _amountOfErc1155 - Amount in case of Erc1155
     * @param _priceInWei - Price in Wei for the supported coin
     * @param _expiresAt - Duration of the order (in hours)
     */
    function createOrder(
        uint8 _saleType,
        uint8 _paymentType,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) external;

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     */
    function cancelOrder(address _nftAddress, uint256 _tokenId) external;

    /**
     * @dev Update an already published order
     *  can only be updated by seller
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     */
    function updateOrder(
        uint8 _saleType,
        uint8 _paymentType,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amountOfErc1155,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) external;

    /**
     * @dev Executes the sale for a published NFT and checks for the asset fingerprint
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     * @param _priceInWei - Order Thor price if paymentType = 1(Thor)
     */
    function safeExecuteOrder(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei
    ) external payable;

    /**
     * @dev Places a bid for a published NFT and checks for the asset fingerprint
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     * @param _priceInWei - Bid price in thorToken currency(if paymentType = 1, Thor)
     * @param _expiresAt - Bid expiration time
     */
    function safePlaceBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei,
        uint256 _expiresAt
    ) external payable;

    /**
     * @dev Executes the sale for a published NFT by accepting a current bid
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     * @param _priceInWei - Bid price in wei in thorTokens currency(if paymentType = 1, Thor)
     */
    function acceptBid(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _priceInWei
    ) external payable;

    /**
     * @dev Cancel an already published bid
     *  can only be canceled by seller or the contract owner
     * @param _nftAddress - Address of the NFT registry
     * @param _tokenId - ID of the published NFT
     */
    function cancelBid(address _nftAddress, uint256 _tokenId) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}