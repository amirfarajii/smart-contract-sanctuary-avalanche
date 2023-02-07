// SPDX-License-Identifier: Apache 2

pragma solidity >=0.8.9;

import "../interfaces/IBridgeSenderAdapter.sol";
import "../MessageStruct.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWormhole {
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function messageFee() external view returns (uint256);
}

interface IRelayProvider {}

interface ICoreRelayer {
    /**
     * @dev This is the basic function for requesting delivery
     */
    function requestDelivery(
        DeliveryRequest memory request,
        uint32 nonce,
        IRelayProvider provider
    ) external payable returns (uint64 sequence);

    function getDefaultRelayProvider() external returns (IRelayProvider);

    function getDefaultRelayParams() external pure returns (bytes memory relayParams);

    function quoteGasDeliveryFee(
        uint16 targetChain,
        uint32 gasLimit,
        IRelayProvider relayProvider
    ) external pure returns (uint256 deliveryQuote);

    function quoteApplicationBudgetFee(
        uint16 targetChain,
        uint256 targetAmount,
        IRelayProvider provider
    ) external pure returns (uint256 nativeQuote);

    struct DeliveryRequest {
        uint16 targetChain;
        bytes32 targetAddress;
        bytes32 refundAddress;
        uint256 computeBudget;
        uint256 applicationBudget;
        bytes relayParameters; //Optional
    }
}

contract WormholeSenderAdapter is IBridgeSenderAdapter, Ownable {
    string public name = "wormhole";
    address public multiBridgeSender;
    mapping(uint64 => uint16) idMap;
    // dstChainId => receiverAdapter address
    mapping(uint16 => address) public receiverAdapters;

    uint8 consistencyLevel = 1;

    event MessageSent(bytes payload, address indexed messageReceiver);

    IWormhole private immutable wormhole;
    ICoreRelayer private immutable relayer;
    IRelayProvider private relayProvider;

    constructor(address _bridgeAddress, address _relayer) {
        wormhole = IWormhole(_bridgeAddress);
        relayer = ICoreRelayer(_relayer);
        relayProvider = relayer.getDefaultRelayProvider();
    }

    modifier onlyMultiBridgeSender() {
        require(msg.sender == multiBridgeSender, "not multi-bridge msg sender");
        _;
    }

    function getMessageFee(MessageStruct.Message memory _message) external view override returns (uint256) {
        uint256 fee = wormhole.messageFee();
        uint256 deliveryCost = relayer.quoteGasDeliveryFee(idMap[_message.dstChainId], 500000, relayProvider);
        uint256 applicationBudget = relayer.quoteApplicationBudgetFee(idMap[_message.dstChainId], 100, relayProvider);
        return fee + deliveryCost + applicationBudget;
    }

    function sendMessage(MessageStruct.Message memory _message) external payable override onlyMultiBridgeSender {
        address receiverAdapter = receiverAdapters[idMap[_message.dstChainId]];
        bytes memory payload = abi.encode(_message, receiverAdapter);
        uint256 msgFee = wormhole.messageFee();
        wormhole.publishMessage{value: msgFee}(_message.nonce, payload, consistencyLevel);

        uint256 relayFee = msg.value - msgFee;
        ICoreRelayer.DeliveryRequest memory request = ICoreRelayer.DeliveryRequest(
            idMap[_message.dstChainId], //targetChain
            bytes32(uint256(uint160(receiverAdapter))), //targetAddress
            bytes32(uint256(uint160(address(this)))), //refundAddress
            relayFee, //computeBudget
            0, //applicationBudget
            relayer.getDefaultRelayParams() //relayerParams
        );
        relayer.requestDelivery{value: relayFee}(request, _message.nonce, relayProvider);

        emit MessageSent(payload, receiverAdapter);
    }

    function setChainIdMap(uint64[] calldata _origIds, uint16[] calldata _whIds) external onlyOwner {
        require(_origIds.length == _whIds.length, "mismatch length");
        for (uint256 i = 0; i < _origIds.length; i++) {
            idMap[_origIds[i]] = _whIds[i];
        }
    }

    function updateReceiverAdapter(uint64[] calldata _dstChainIds, address[] calldata _receiverAdapters)
        external
        override
        onlyOwner
    {
        require(_dstChainIds.length == _receiverAdapters.length, "mismatch length");
        for (uint256 i = 0; i < _dstChainIds.length; i++) {
            uint16 wormholeId = idMap[_dstChainIds[i]];
            require(wormholeId != 0, "unrecognized dstChainId");
            receiverAdapters[wormholeId] = _receiverAdapters[i];
        }
    }

    function setMultiBridgeSender(address _multiBridgeSender) external override onlyOwner {
        multiBridgeSender = _multiBridgeSender;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "../MessageStruct.sol";

/**
 * @dev Adapter that connects MultiBridgeSender and each message bridge.
 * Message bridge can implement their favourite encode&decode way for MessageStruct.Message.
 */
interface IBridgeSenderAdapter {
    /**
     * @dev Return native token amount in wei required by this message bridge for sending a MessageStruct.Message.
     */
    function getMessageFee(MessageStruct.Message memory _message) external view returns (uint256);

    /**
     * @dev Send a MessageStruct.Message through this message bridge.
     */
    function sendMessage(MessageStruct.Message memory _message) external payable;

    /**
     * @dev Owner update receiver adapter address on dst chain.
     */
    function updateReceiverAdapter(uint64[] calldata _dstChainIds, address[] calldata _receiverAdapters) external;

    /**
     * @dev Owner setup MultiBridgeSender.
     */
    function setMultiBridgeSender(address _multiBridgeSender) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

library MessageStruct {
    /**
     * @dev Message indicates a remote call to target contract on destination chain.
     *
     * @param srcChainId is the id of chain where this message is sent from.
     * @param dstChainId is the id of chain where this message is sent to.
     * @param nonce is an incrementing number held by MultiBridgeSender to ensure msgId uniqueness
     * @param target is the contract to be called on dst chain.
     * @param callData is the data to be sent to target by low-level call(eg. address(target).call(callData)).
     * @param bridgeName is the message bridge name used for sending this message.
     */
    struct Message {
        uint64 srcChainId;
        uint64 dstChainId;
        uint32 nonce;
        address target;
        bytes callData;
        string bridgeName;
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