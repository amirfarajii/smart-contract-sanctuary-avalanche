// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../MintingChain.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SampleMintingChain is OnMintingChain {
  address public owner;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 MaxTokenId_,
    address genericHandler_
  ) OnMintingChain(name_, symbol_, MaxTokenId_, genericHandler_) {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  /// @notice Function to set the linker address
  /// @dev Only owner can call this function
  /// @param _linker Address of the linker
  function setLinker(address _linker) external onlyOwner {
    setLink(_linker);
  }

  /// @notice Function to set the fee token address
  /// @dev Only owner can call this function
  /// @param _feeToken Address of the fee token
  function setFeesToken(address _feeToken) external onlyOwner {
    setFeeToken(_feeToken);
  }

  /// @notice Function to approve the generic handler to cut fees from this contract
  /// @dev Only owner can call this function
  /// @param _feeToken Address of the fee token
  /// @param _amount Amount of approval
  function _approveFees(address _feeToken, uint256 _amount) external onlyOwner {
    approveFees(_feeToken, _amount);
  }

  /// @notice Function to set the cross-chain gas limit
  /// @dev Only owner can call this function
  /// @param _gasLimit amount of gas limit to be set
  function setCrossChainGasLimit(uint256 _gasLimit) external onlyOwner {
    _setCrossChainGasLimit(_gasLimit);
  }

  /// @notice Function to set the fee token for minting NFT
  /// @dev Only owner can call this function
  /// @param _feeToken address  of the fee token
  function setFeeTokenForNFT(address _feeToken) external onlyOwner {
    _setFeeTokenForNFT(_feeToken);
  }

  /// @notice Function to set the amount of fee token for minting one NFT
  /// @dev Only owner can call this function
  /// @param _price price of NFT in fee tokens
  function setFeeInTokenForNFT(uint256 _price) external onlyOwner {
    _setFeeInTokenForNFT(_price);
  }

  /// @notice function to mint the NFT on the same chain
  /// @dev This function deducts fees and mints NFTs but reverts in case NFTs are not available
  /// @param recipient address of recipient of NFT
  function mintSameChain(address recipient) external {
    mint(recipient);
  }

  /// @notice function to create a cross-chain request to transfer NFT cross-chain
  /// @dev The contract burns the NFT into the contract and creates a cross-chain request
  /// to mint (on fee chains) /unlock (on minting chain) the NFT on the destination chain
  /// @param destChainId chainId of the destination chain(router specs - https://dev.routerprotocol.com/important-parameters/supported-chains)
  /// @param recipient address of the recipient on the destination chain
  /// @param tokenId of the token user is willing to transfer cross-chain
  /// @param crossChainGasPrice gas price that you are willing to pay to execute the
  /// transaction on the minting chain
  /// @dev If the crossChainGasPrice is less than required, the transaction can get stuck
  /// on the bridge and you may need to replay the transaction.
  function transferCrossChain(
    uint8 destChainId,
    address recipient,
    uint256 tokenId,
    uint256 crossChainGasPrice
  ) external returns (bytes32) {
    (bool sent, bytes32 hash) = _transferCrossChain(
      destChainId,
      recipient,
      tokenId,
      crossChainGasPrice
    );

    require(sent == true, "Unsuccessful");
    return hash;
  }

  /// @notice function to replay a transaction stuck on the bridge due to insufficient
  /// cross-chain gas limit or gas price passed in _mintCrossChain function
  /// @dev gasLimit and gasPrice passed in this function should be greater than what was passed earlier
  /// @param hash hash returned from RouterSend function should be used to replay a tx
  /// @param gasLimit gas limit to be passed for executing the tx on destination chain
  /// @param gasPrice gas price to be passed for executing the tx on destination chain
  function relpayTransaction(
    bytes32 hash,
    uint256 gasLimit,
    uint256 gasPrice
  ) external onlyOwner {
    replayTx(hash, gasLimit, gasPrice);
  }

  /// @notice function to withdraw fee tokens received as payment for NFT
  function withdrawFeeTokenForNFT() external override onlyOwner {
    address feeToken = this.fetchFeeTokenForNFT();
    uint256 amount = IERC20(feeToken).balanceOf(address(this));
    IERC20(feeToken).transfer(owner, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@routerprotocol/router-crosstalk/contracts/RouterCrossTalk.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title Cross-Chain NFT Minting Chain Contract.
/// @author Router Protocol.
/// @notice This contract is used for minting of cross-chain NFTs.
/// @dev This contract has to be inherited by the developer in his contract only
/// on the chain where NFTs are to be minted.
abstract contract OnMintingChain is ERC721, IERC721Receiver, RouterCrossTalk {
  using SafeERC20 for IERC20;

  /// fee token to be used for paying for the NFT
  address private feeTokenForNFT;

  /// fee amount in fee token for NFT to be paid per NFT
  uint256 private feeInTokenForNFT;

  /// max number of NFTs that can be minted
  uint256 public immutable MaxTokenId;

  /// counter for number of NFTs already minted
  uint256 public CurrentTokenId;

  /// gas limit to be used for execution of the cross-chain request on the other chain
  uint256 private crossChainGasLimit;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 MaxTokenId_,
    address genericHandler_
  ) ERC721(name_, symbol_) RouterCrossTalk(genericHandler_) {
    MaxTokenId = MaxTokenId_;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /// @notice function to to set feeToken for minting NFT
  /// @param _feeToken Address of the token to be set as fee
  function _setFeeTokenForNFT(address _feeToken) internal {
    feeTokenForNFT = _feeToken;
  }

  /// @notice function to fetch the fee token
  /// @return feeTokenForNFT address
  function fetchFeeTokenForNFT() external view returns (address) {
    return feeTokenForNFT;
  }

  /// @notice function to set fees to be paid for NFT
  /// @param _price Amount of feeToken to be taken as price per NFT
  function _setFeeInTokenForNFT(uint256 _price) internal {
    feeInTokenForNFT = _price;
  }

  /// @notice function to fetch fee amount for NFT
  /// @return Returns fee in Token
  function fetchFeeInTokenForNFT() external view returns (uint256) {
    return feeInTokenForNFT;
  }

  /// @notice function to set CrossChainGasLimit
  /// @param _gasLimit Amount of gasLimit that is to be set
  function _setCrossChainGasLimit(uint256 _gasLimit) internal {
    crossChainGasLimit = _gasLimit;
  }

  /// @notice function to fetch CrossChainGasLimit
  /// @return crossChainGasLimit
  function fetchCrossChainGasLimit() external view returns (uint256) {
    return crossChainGasLimit;
  }

  /// @notice function to create a cross-chain request to transfer NFT cross-chain
  /// @dev The contract locks the NFT into the contract and creates a cross-chain
  /// request to mint the NFT on the destination chain
  /// @param destChainId chainId of the destination chain(router specs - https://dev.routerprotocol.com/important-parameters/supported-chains)
  /// @param recipient address of the recipient on the destination chain
  /// @param tokenId of the token user is willing to transfer cross-chain
  /// @param crossChainGasPrice gas price that you are willing to pay to execute the
  /// transaction on the minting chain
  /// @dev If the crossChainGasPrice is less than required, the transaction can get stuck
  /// on the bridge and you may need to replay the transaction.
  function _transferCrossChain(
    uint8 destChainId,
    address recipient,
    uint256 tokenId,
    uint256 crossChainGasPrice
  ) internal returns (bool, bytes32) {
    require(_exists(tokenId) && ownerOf(tokenId) == msg.sender, "not your NFT");
    require(recipient != address(0), "recipient != address(0)");
    safeTransferFrom(msg.sender, address(this), tokenId);

    bytes4 selector = bytes4(keccak256("receiveCrossChain(address,uint256)"));
    bytes memory data = abi.encode(recipient, tokenId);
    (bool success, bytes32 hash) = routerSend(
      destChainId,
      selector,
      data,
      crossChainGasLimit,
      crossChainGasPrice
    );

    return (success, hash);
  }

  /// @notice _routerSyncHandler This is an internal function to control the handling
  /// of various cross-chain requests received from the bridge
  /// @dev all the cross-chain requests should be handled here
  /// @param _selector Selector to interface to be called
  /// @param _data Data to be handled
  function _routerSyncHandler(bytes4 _selector, bytes memory _data)
    internal
    override
    returns (bool, bytes memory)
  {
    if (_selector == bytes4(keccak256("receiveCrossChain(address,uint256)"))) {
      (address recipient, uint256 tokenId) = abi.decode(
        _data,
        (address, uint256)
      );

      (bool success, bytes memory returnData) = address(this).call(
        abi.encodeWithSelector(_selector, recipient, tokenId)
      );
      return (success, returnData);
    } else if (
      _selector == bytes4(keccak256("mintCrossChain(address,address)"))
    ) {
      (address recipient, address refundAddress) = abi.decode(
        _data,
        (address, address)
      );
      (bool success, bytes memory returnData) = address(this).call(
        abi.encodeWithSelector(_selector, recipient, refundAddress)
      );
      return (success, returnData);
    }

    return (false, "");
  }

  /// @notice function to replay a transaction stuck on the bridge due to insufficient
  /// cross-chain gas limit or gas price passed in _mintCrossChain function
  /// @dev gasLimit and gasPrice passed in this function should be greater than what was passed earlier
  /// @param hash hash returned from RouterSend function should be used to replay a tx
  /// @param gasLimit gas limit to be passed for executing the tx on destination chain
  /// @param gasPrice gas price to be passed for executing the tx on destination chain
  function replayTx(
    bytes32 hash,
    uint256 gasLimit,
    uint256 gasPrice
  ) internal {
    routerReplay(hash, gasLimit, gasPrice);
  }

  /// @notice function to handle cross-chain minting of NFT for which fees was paid on another chain
  /// @dev isSelf modifier is placed as a security feature so that requests only from
  /// the bridge is able to trigger this function
  /// @param recipient address of recipient of NFT received from the fee chain
  /// @param refundAddress address of wallet to process refund in case NFT
  /// is unavailable (received from fee chain)
  function mintCrossChain(address recipient, address refundAddress)
    external
    isSelf
  {
    require(recipient != address(0), "recipient != address(0)");
    require(refundAddress != address(0), "refundAddress != address(0)");

    CurrentTokenId = CurrentTokenId + 1;
    if (CurrentTokenId > MaxTokenId || _exists(CurrentTokenId)) {
      IERC20(feeTokenForNFT).safeTransfer(refundAddress, feeInTokenForNFT);
      return;
    }

    _safeMint(recipient, CurrentTokenId);
  }

  /// @notice function to handle cross-chain transfer of NFT for which request was made on another chain
  /// @dev isSelf modifier is placed as a security feature so that requests only from
  /// the bridge is able to trigger this function
  /// @param recipient address of recipient of NFT received from the fee chain
  /// @param tokenId tokenId of NFT to be unlocked to the recipient
  function receiveCrossChain(address recipient, uint256 tokenId)
    external
    isSelf
  {
    require(
      _exists(tokenId) && ownerOf(tokenId) == address(this),
      "invalid request"
    );
    require(recipient != address(0), "recipient != address(0)");

    _safeTransfer(address(this), recipient, tokenId, "");
  }

  /// @notice function to mint the NFT on the same chain
  /// @dev This function deducts fees and mints NFTs but reverts in case NFTs are not available
  /// @param recipient address of recipient of NFT
  function mint(address recipient) internal {
    require(recipient != address(0), "MintingChain: Recipient cannot be 0");

    CurrentTokenId = CurrentTokenId + 1;
    require(CurrentTokenId <= MaxTokenId, "ERC721: MaxTokenId reached");

    IERC20(feeTokenForNFT).safeTransferFrom(
      msg.sender,
      address(this),
      feeInTokenForNFT
    );

    _mint(recipient, CurrentTokenId);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  /// @notice function to withdraw fee tokens received as payment for NFT
  /// @dev This needs to be implemented by the developers to get the fees paid by minters
  function withdrawFeeTokenForNFT() external virtual;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/iGenericHandler.sol";
import "./interfaces/iRouterCrossTalk.sol";

/// @title RouterCrossTalk contract
/// @author Router Protocol
abstract contract RouterCrossTalk is Context, iRouterCrossTalk, ERC165 {
    using SafeERC20 for IERC20;
    iGenericHandler private handler;

    address private linkSetter;

    address private feeToken;

    mapping(uint8 => address) private Chain2Addr; // CHain ID to Address

    mapping(bytes32 => ExecutesStruct) private executes;

    modifier isHandler() {
        require(
            _msgSender() == address(handler),
            "RouterCrossTalk : Only GenericHandler can call this function"
        );
        _;
    }

    modifier isLinkUnSet(uint8 _chainID) {
        require(
            Chain2Addr[_chainID] == address(0),
            "RouterCrossTalk : Cross Chain Contract to Chain ID already set"
        );
        _;
    }

    modifier isLinkSet(uint8 _chainID) {
        require(
            Chain2Addr[_chainID] != address(0),
            "RouterCrossTalk : Cross Chain Contract to Chain ID not set"
        );
        _;
    }

    modifier isLinkSync(uint8 _srcChainID, address _srcAddress) {
        require(
            Chain2Addr[_srcChainID] == _srcAddress,
            "RouterCrossTalk : Source Address Not linked"
        );
        _;
    }

    modifier isSelf() {
        require(
            _msgSender() == address(this),
            "RouterCrossTalk : Can only be called by Current Contract"
        );
        _;
    }

    constructor(address _handler) {
        handler = iGenericHandler(_handler);
    }

    /// @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
    /// @param _addr Address of linker.
    function setLink(address _addr) internal {
        linkSetter = _addr;
    }

    /// @notice Used to set fee Token address, this function is internal and can only be set by contract owner or admins
    /// @param _addr Address of linker.
    function setFeeToken(address _addr) internal {
        feeToken = _addr;
    }

    function fetchHandler() external view override returns (address) {
        return address(handler);
    }

    function fetchLinkSetter() external view override returns (address) {
        return linkSetter;
    }

    function fetchLink(uint8 _chainID)
        external
        view
        override
        returns (address)
    {
        return Chain2Addr[_chainID];
    }

    function fetchFeeToken() external view override returns (address) {
        return feeToken;
    }

    function fetchExecutes(bytes32 hash)
        external
        view
        override
        returns (ExecutesStruct memory)
    {
        return executes[hash];
    }

    /// @notice routerSend This is internal function to generate a cross chain communication request.
    /// @param destChainId Destination ChainID.
    /// @param _selector Selector to interface on destination side.
    /// @param _data Data to be sent on Destination side.
    /// @param _gasLimit Gas limit provided for cross chain send.
    /// @param _gasPrice Gas price provided for cross chain send.
    function routerSend(
        uint8 destChainId,
        bytes4 _selector,
        bytes memory _data,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) internal isLinkSet(destChainId) returns (bool, bytes32) {
        bytes memory data = abi.encode(_selector, _data);
        uint64 nonce = handler.genericDeposit(
            destChainId,
            data,
            _gasLimit,
            _gasPrice,
            feeToken
        );

        bytes32 hash = _hash(destChainId, nonce);

        executes[hash] = ExecutesStruct(destChainId, nonce);
        emitCrossTalkSendEvent(destChainId, _selector, _data, hash);

        return (true, hash);
    }

    function emitCrossTalkSendEvent(
        uint8 destChainId,
        bytes4 selector,
        bytes memory data,
        bytes32 hash
    ) private {
        emit CrossTalkSend(
            handler.fetch_chainID(),
            destChainId,
            address(this),
            Chain2Addr[destChainId],
            selector,
            data,
            hash
        );
    }

    function routerSync(
        uint8 srcChainID,
        address srcAddress,
        bytes memory data
    )
        external
        override
        isLinkSync(srcChainID, srcAddress)
        isHandler
        returns (bool, bytes memory)
    {
        uint8 cid = handler.fetch_chainID();
        (bytes4 _selector, bytes memory _data) = abi.decode(
            data,
            (bytes4, bytes)
        );

        (bool success, bytes memory _returnData) = _routerSyncHandler(
            _selector,
            _data
        );
        emit CrossTalkReceive(srcChainID, cid, srcAddress);
        return (success, _returnData);
    }

    function routerReplay(
        bytes32 hash,
        uint256 _gasLimit,
        uint256 _gasPrice
    ) internal {
        handler.replayGenericDeposit(
            executes[hash].chainID,
            executes[hash].nonce,
            _gasLimit,
            _gasPrice
        );
    }

    /// @notice _hash This is internal function to generate the hash of all data sent or received by the contract.
    /// @param _destChainId Source ChainID.
    /// @param _nonce Nonce.
    function _hash(uint8 _destChainId, uint64 _nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_destChainId, _nonce));
    }

    function Link(uint8 _chainID, address _linkedContract)
        external
        override
        isHandler
        isLinkUnSet(_chainID)
    {
        Chain2Addr[_chainID] = _linkedContract;
        emit Linkevent(_chainID, _linkedContract);
    }

    function Unlink(uint8 _chainID)
        external
        override
        isHandler
        isLinkSet(_chainID)
    {
        emit Unlinkevent(_chainID, Chain2Addr[_chainID]);
        Chain2Addr[_chainID] = address(0);
    }

    function approveFees(address _feeToken, uint256 _value) internal {
        IERC20 token = IERC20(_feeToken);
        token.approve(address(handler), _value);
    }

    /// @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
    /// @param _selector Selector to interface.
    /// @param _data Data to be handled.
    function _routerSyncHandler(bytes4 _selector, bytes memory _data)
        internal
        virtual
        returns (bool, bytes memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
pragma solidity ^0.8.0;

/// @title GenericHandler contract interface for router Crosstalk
/// @author Router Protocol
interface iGenericHandler {
  struct RouterLinker {
    address _rSyncContract;
    uint8 _chainID;
    address _linkedContract;
  }

  /// @notice MapContract Maps the contract from the RouterCrossTalk Contract
  /// @dev This function is used to map contract from router-crosstalk contract
  /// @param linker The Data object consisting of target Contract , CHainid , Contract to be Mapped and linker type.
  function MapContract(RouterLinker calldata linker) external;

  /// @notice UnMapContract Unmaps the contract from the RouterCrossTalk Contract
  /// @dev This function is used to unmap contract from router-crosstalk contract
  /// @param linker The Data object consisting of target Contract , CHainid , Contract to be unMapped and linker type.
  function UnMapContract(RouterLinker calldata linker) external;

  /// @notice generic deposit on generic handler contract
  /// @dev This function is called by router crosstalk contract while initiating crosschain transaction
  /// @param _destChainID Chain id to be transacted
  /// @param _data Data to be transferred: contains abi encoded selector and data
  /// @param _gasLimit Gas limit specified for the contract function
  /// @param _gasPrice Gas price specified for the contract function
  /// @param _feeToken Fee Token Specified for the contract function
  function genericDeposit(
    uint8 _destChainID,
    bytes calldata _data,
    uint256 _gasLimit,
    uint256 _gasPrice,
    address _feeToken
  ) external returns (uint64);

  /// @notice Fetches ChainID for the native chain
  function fetch_chainID() external view returns (uint8);

  /// @notice Function to replay a transaction which was stuck due to underpricing of gas
  /// @param  _destChainID Destination ChainID
  /// @param  _depositNonce Nonce for the transaction.
  /// @param  _gasLimit Gas limit allowed for the transaction.
  /// @param  _gasPrice Gas Price for the transaction.
  function replayGenericDeposit(
    uint8 _destChainID,
    uint64 _depositNonce,
    uint256 _gasLimit,
    uint256 _gasPrice
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title iRouterCrossTalk contract interface for router Crosstalk
/// @author Router Protocol
interface iRouterCrossTalk is IERC165 {
  struct ExecutesStruct {
    uint8 chainID;
    uint64 nonce;
  }

  /// @notice Link event is emitted when a new link is created.
  /// @param ChainID Chain id the contract is linked to.
  /// @param linkedContract Contract address linked to.
  event Linkevent(uint8 indexed ChainID, address indexed linkedContract);

  /// @notice UnLink event is emitted when a link is removed.
  /// @param ChainID Chain id the contract is unlinked to.
  /// @param linkedContract Contract address unlinked to.
  event Unlinkevent(uint8 indexed ChainID, address indexed linkedContract);

  /// @notice CrossTalkSend Event is emited when a request is generated in soruce side when cross chain request is generated.
  /// @param sourceChain Source ChainID.
  /// @param destChain Destination ChainID.
  /// @param sourceAddress Source Address.
  /// @param destinationAddress Destination Address.
  /// @param _selector Selector to interface on destination side.
  /// @param _data Data to interface on Destination side.
  /// @param _hash Hash of the data sent.
  event CrossTalkSend(
    uint8 indexed sourceChain,
    uint8 indexed destChain,
    address sourceAddress,
    address destinationAddress,
    bytes4 indexed _selector,
    bytes _data,
    bytes32 _hash
  );

  /// @notice CrossTalkReceive Event is emited when a request is recived in destination side when cross chain request accepted by contract.
  /// @param sourceChain Source ChainID.
  /// @param destChain Destination ChainID.
  /// @param sourceAddress Address of source contract.
  event CrossTalkReceive(
    uint8 indexed sourceChain,
    uint8 indexed destChain,
    address sourceAddress
  );

  /// @notice routerSync This is a public function and can only be called by Generic Handler of router infrastructure
  /// @param srcChainID Source ChainID.
  /// @param srcAddress Destination ChainID.
  /// @param data Data to interface on Destination side.
  // /// @param hash Hash of the data sent.
  function routerSync(
    uint8 srcChainID,
    address srcAddress,
    bytes calldata data
  )
    external
    returns (
      // bytes32 hash
      bool,
      bytes memory
    );

  /// @notice Link This is a public function and can only be called by Generic Handler of router infrastructure
  /// @notice This function links contract on other chain ID's.
  /// @notice This is an administrative function and can only be initiated by linkSetter address.
  /// @param _chainID network Chain ID linked Contract linked to.
  /// @param _linkedContract Linked Contract address.
  function Link(uint8 _chainID, address _linkedContract) external;

  /// @notice UnLink This is a public function and can only be called by Generic Handler of router infrastructure
  /// @notice This function unLinks contract on other chain ID's.
  /// @notice This is an administrative function and can only be initiated by linkSetter address.
  /// @param _chainID network Chain ID linked Contract linked to.
  function Unlink(uint8 _chainID) external;

  /// @notice fetchLinkSetter This is a public function and fetches the linksetter address.
  function fetchLinkSetter() external view returns (address);

  /// @notice fetchLinkSetter This is a public function and fetches the address the contract is linked to.
  /// @param _chainID Chain ID information.
  function fetchLink(uint8 _chainID) external view returns (address);

  /// @notice fetchLinkSetter This is a public function and fetches the generic handler address.
  function fetchHandler() external view returns (address);

  /// @notice fetchFeeToken This is a public function and fetches the fee token set by admin.
  function fetchFeeToken() external view returns (address);

  /// @notice fetchExecutes This is a public function and fetches the executes struct.
  function fetchExecutes(bytes32 _hash)
    external
    view
    returns (ExecutesStruct memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}