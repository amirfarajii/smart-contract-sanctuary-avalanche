// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/interfaces/IBlacklistableUpgradeable.sol";

interface IAuthority is
    IBlacklistableUpgradeable,
    IAccessControlEnumerableUpgradeable
{
    event ProxyAccessGranted(address indexed proxy);

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool isPaused);

    function requestAccess(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/interfaces/IWithdrawableUpgradeable.sol";

interface ITreasury {
    error Treasury__Expired();
    error Treasury__LengthMismatch();
    error Treasury__InvalidSignature();

    event PaymentsUpdated(address[] indexed tokens);
    event PricesUpdated(address[] indexed tokens, uint256[] indexed prices);
    event PriceUpdated(
        IERC20Upgradeable indexed token,
        uint256 indexed from,
        uint256 indexed to
    );
    event PaymentRemoved(address indexed token);
    event PaymentsRemoved();

    function supportedPayment(address token_) external view returns (bool);

    function priceOf(address token_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "oz-custom/contracts/oz-upgradeable/utils/ContextUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IAuthority.sol";

import "../libraries/Roles.sol";

error Base__Paused();
error Base__Unpaused();
error Base__AlreadySet();
error Base__Unauthorized();
error Base__AuthorizeFailed();
error Base__UserIsBlacklisted();

abstract contract BaseUpgradeable is ContextUpgradeable, UUPSUpgradeable {
    bytes32 private _authority;

    event AuthorityUpdated(IAuthority indexed from, IAuthority indexed to);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    modifier onlyWhitelisted() {
        _checkBlacklist(_msgSender());
        _;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function updateAuthority(
        IAuthority authority_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        IAuthority old = authority();
        if (old == authority_) revert Base__AlreadySet();
        __updateAuthority(authority_);
        emit AuthorityUpdated(old, authority_);
    }

    function updateTreasury(ITreasury treasury_) external virtual;

    function authority() public view returns (IAuthority authority_) {
        assembly {
            authority_ := sload(_authority.slot)
        }
    }

    function __Base_init(
        IAuthority authority_,
        bytes32 role_
    ) internal onlyInitializing {
        __Base_init_unchained(authority_, role_);
    }

    function __Base_init_unchained(
        IAuthority authority_,
        bytes32 role_
    ) internal onlyInitializing {
        authority_.requestAccess(role_);
        __updateAuthority(authority_);
    }

    function _checkBlacklist(address account_) internal view {
        if (authority().isBlacklisted(account_))
            revert Base__UserIsBlacklisted();
    }

    function _checkRole(bytes32 role_, address account_) internal view {
        if (!authority().hasRole(role_, account_)) revert Base__Unauthorized();
    }

    function __updateAuthority(IAuthority authority_) private {
        assembly {
            sstore(_authority.slot, authority_)
        }
    }

    function _requirePaused() internal view {
        if (!authority().paused()) revert Base__Unpaused();
    }

    function _requireNotPaused() internal view {
        if (authority().paused()) revert Base__Paused();
    }

    function _authorizeUpgrade(
        address implement_
    ) internal virtual override onlyRole(Roles.UPGRADER_ROLE) {}

    function _hasRole(
        bytes32 role_,
        address account_
    ) internal view returns (bool) {
        return authority().hasRole(role_, account_);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Roles {
    bytes32 public constant PROXY_ROLE =
        0x77d72916e966418e6dc58a19999ae9934bef3f749f1547cde0a86e809f19c89b;
    bytes32 public constant SIGNER_ROLE =
        0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70;
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    bytes32 public constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    bytes32 public constant TREASURER_ROLE =
        0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07;
    bytes32 public constant FACTORY_ROLE =
        0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "oz-custom/contracts/internal-upgradeable/SignableUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/ProxyCheckerUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/WithdrawableUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./internal-upgradeable/BaseUpgradeable.sol";

import "oz-custom/contracts/libraries/EnumerableSetV2.sol";
import "oz-custom/contracts/libraries/FixedPointMathLib.sol";

import "./interfaces/ITreasury.sol";
import {
    IERC721Upgradeable,
    ERC721TokenReceiverUpgradeable
} from "oz-custom/contracts/oz-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "oz-custom/contracts/oz-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

contract Treasury is
    ITreasury,
    BaseUpgradeable,
    SignableUpgradeable,
    ProxyCheckerUpgradeable,
    WithdrawableUpgradeable,
    ERC721TokenReceiverUpgradeable
{
    using Bytes32Address for address;
    using FixedPointMathLib for uint256;
    using ERC165CheckerUpgradeable for address;
    using EnumerableSetV2 for EnumerableSetV2.AddressSet;

    ///@dev value is equal to keccak256("Treasury_v1")
    bytes32 public constant VERSION =
        0xea88ed743f2d0583b98ad2b145c450d84d46c8e4d6425d9e0c7cd0e4930fce2f;

    ///@dev value is equal to keccak256("Permit(address token,address to,uint256 value,uint256 deadline,uint256 nonce)")
    bytes32 private constant __PERMIT_TYPE_HASH =
        0x2ebfdfe4a977046f076938a5a375e2aed52779362e4769bb2efb0dd45b7fdb54;
    AggregatorV3Interface public priceFeed;

    mapping(bytes32 => uint256) private __priceOf;
    EnumerableSetV2.AddressSet private __payments;

    function init(
        IAuthority authority_,
        AggregatorV3Interface priceFeed_
    ) external initializer {
        priceFeed = priceFeed_;

        __Base_init_unchained(authority_, 0);
        __Signable_init(type(Treasury).name, "1");
    }

    function updateTreasury(ITreasury treasury_) external override {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function withdraw(
        address token_,
        address to_,
        uint256 value_
    ) external override onlyRole(Roles.TREASURER_ROLE) {
        __withdraw(token_, to_, value_);
    }

    function withdraw(
        address token_,
        address to_,
        uint256 value_,
        uint256 deadline_,
        bytes calldata signature_
    ) external whenNotPaused {
        _checkBlacklist(to_);
        _onlyEOA(_msgSender());

        if (block.timestamp > deadline_) revert Treasury__Expired();
        if (
            !_hasRole(
                Roles.SIGNER_ROLE,
                _recoverSigner(
                    keccak256(
                        abi.encode(
                            __PERMIT_TYPE_HASH,
                            token_,
                            to_,
                            value_,
                            deadline_,
                            _useNonce(to_)
                        )
                    ),
                    signature_
                )
            )
        ) revert Treasury__InvalidSignature();

        __withdraw(token_, to_, value_);
    }

    function priceOf(address token_) external view returns (uint256) {
        if (token_ == address(0)) {
            AggregatorV3Interface _priceFeed = priceFeed;
            (, int256 usdUnit, , , ) = _priceFeed.latestRoundData();
            return
                uint256(usdUnit).mulDivDown(
                    1 ether,
                    10 ** _priceFeed.decimals()
                );
        }
        return __priceOf[token_.fillLast12Bytes()];
    }

    function updatePrices(
        address[] calldata tokens_,
        uint256[] calldata prices_
    ) external onlyRole(Roles.TREASURER_ROLE) {
        uint256 length = tokens_.length;
        if (length != prices_.length) revert Treasury__LengthMismatch();

        bytes32[] memory tokens;
        {
            address[] memory _tokens = tokens_;
            assembly {
                tokens := _tokens
            }
        }
        for (uint256 i; i < length; ) {
            __priceOf[tokens[i]] = prices_[i];
            unchecked {
                ++i;
            }
        }
        emit PricesUpdated(tokens_, prices_);
    }

    function updatePayments(
        address[] calldata tokens_
    ) external onlyRole(Roles.TREASURER_ROLE) {
        __payments.add(tokens_);
        emit PaymentsUpdated(tokens_);
    }

    function resetPayments() external onlyRole(Roles.TREASURER_ROLE) {
        __payments.remove();
        emit PaymentsRemoved();
    }

    function removePayment(
        address token_
    ) external onlyRole(Roles.TREASURER_ROLE) {
        if (__payments.remove(token_)) emit PaymentRemoved(token_);
    }

    function payments() external view returns (address[] memory) {
        return __payments.values();
    }

    function supportedPayment(address token_) public view returns (bool) {
        return __payments.contains(token_);
    }

    function __withdraw(address token_, address to_, uint256 value_) private {
        if (supportedPayment(token_)) {
            if (token_.supportsInterface(type(IERC721Upgradeable).interfaceId))
                IERC721Upgradeable(token_).safeTransferFrom(
                    address(this),
                    to_,
                    value_
                );
            else _safeTransfer(IERC20Upgradeable(token_), to_, value_);
            emit Withdrawn(token_, to_, value_);
        }
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBlacklistableUpgradeable {
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);

    function setUserStatus(address account_, bool status) external;

    function isBlacklisted(address account_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISignableUpgradeable {
    error Signable__InvalidSignature();

    function nonces(address sender_) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWithdrawableUpgradeable {
    event Withdrawn(
        address indexed token,
        address indexed to,
        uint256 indexed value
    );
    event Received(address indexed sender, uint256 indexed value);

    function withdraw(
        address from_,
        address to_,
        uint256 amount_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/proxy/utils/Initializable.sol";

error ProxyChecker__EOAUnallowed();
error ProxyChecker__ProxyUnallowed();

abstract contract ProxyCheckerUpgradeable is Initializable {
    modifier onlyEOA() {
        _onlyEOA(msg.sender);
        _;
    }

    function __ProxyChecker_init() internal onlyInitializing {}

    function __ProxyChecker_init_unchained() internal onlyInitializing {}

    function _onlyEOA(address sender_) internal view {
        _onlyEOA(sender_, _txOrigin());
    }

    function _onlyEOA(address msgSender_, address txOrigin_) internal view {
        if (_isProxyCall(msgSender_, txOrigin_) || _isProxy(msgSender_))
            revert ProxyChecker__ProxyUnallowed();
    }

    function _onlyProxy(address sender_) internal view {
        if (!_isProxyCall(sender_, _txOrigin()) && !_isProxy(sender_))
            revert ProxyChecker__EOAUnallowed();
    }

    function _onlyProxy(address msgSender_, address txOrigin_) internal view {
        if (!_isProxyCall(msgSender_, txOrigin_) && !_isProxy(msgSender_))
            revert ProxyChecker__EOAUnallowed();
    }

    function _isProxyCall(address msgSender_, address txOrigin_)
        internal
        pure
        returns (bool)
    {
        return msgSender_ != txOrigin_;
    }

    function _isProxy(address caller_) internal view returns (bool) {
        return caller_.code.length != 0;
    }

    function _txOrigin() internal view returns (address) {
        return tx.origin;
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "./interfaces/ISignableUpgradeable.sol";

import "../libraries/Bytes32Address.sol";

abstract contract SignableUpgradeable is
    EIP712Upgradeable,
    ISignableUpgradeable
{
    using Bytes32Address for address;
    using ECDSAUpgradeable for bytes32;

    mapping(bytes32 => uint256) internal _nonces;

    function __Signable_init(string memory name_, string memory version_)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name_, version_);
    }

    function __Signable_init_unchained() internal onlyInitializing {}

    function nonces(address sender_) external view virtual returns (uint256) {
        return _nonce(sender_);
    }

    function _verify(
        address verifier_,
        bytes32 structHash_,
        bytes calldata signature_
    ) internal view virtual {
        if (_recoverSigner(structHash_, signature_) != verifier_)
            revert Signable__InvalidSignature();
    }

    function _verify(
        address verifier_,
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view virtual {
        if (_recoverSigner(structHash_, v, r, s) != verifier_)
            revert Signable__InvalidSignature();
    }

    function _recoverSigner(bytes32 structHash_, bytes calldata signature_)
        internal
        view
        returns (address)
    {
        return _hashTypedDataV4(structHash_).recover(signature_);
    }

    function _recoverSigner(
        bytes32 structHash_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        return _hashTypedDataV4(structHash_).recover(v, r, s);
    }

    function _useNonce(address sender_)
        internal
        virtual
        returns (uint256 nonce)
    {
        assembly {
            mstore(0x00, sender_)
            mstore(0x20, _nonces.slot)
            let key := keccak256(0x00, 0x40)
            nonce := sload(key)
            sstore(key, add(nonce, 1))
        }
    }

    function _nonce(address sender_)
        internal
        view
        virtual
        returns (uint256 nonce)
    {
        assembly {
            mstore(0x00, sender_)
            mstore(0x20, _nonces.slot)
            nonce := sload(keccak256(0x00, 0x40))
        }
    }

    function _mergeSignature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory signature) {
        signature = new bytes(65);
        assembly {
            mstore8(add(signature, 32), r)
            mstore(add(signature, 33), s)
            mstore(add(signature, 65), v)
        }
    }

    function _splitSignature(bytes calldata signature_)
        internal
        pure
        virtual
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            r := calldataload(signature_.offset)
            s := calldataload(add(signature_.offset, 0x20))
            v := byte(0, calldataload(add(signature_.offset, 0x40)))
        }
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/proxy/utils/Initializable.sol";
import "../oz-upgradeable/token/ERC20/IERC20Upgradeable.sol";

error Transferable__TransferFailed();
error Transferable__InvalidArguments();

abstract contract TransferableUpgradeable is Initializable {
    function __Transferable_init() internal onlyInitializing {}

    function __Transferable_init_unchained() internal onlyInitializing {}

    function _safeTransferFrom(
        IERC20Upgradeable token_,
        address from_,
        address to_,
        uint256 value_
    ) internal virtual {
        __checkValidTransfer(to_, value_);
        bool success;
        if (address(token_) == address(0))
            success = __nativeTransfer(to_, value_);
        else success = __ERC20TransferFrom(token_, from_, to_, value_);

        if (!success) revert Transferable__TransferFailed();
    }

    function _safeTransfer(
        IERC20Upgradeable token_,
        address to_,
        uint256 value_
    ) internal virtual {
        __checkValidTransfer(to_, value_);
        bool success;
        if (address(token_) == address(0))
            success = __nativeTransfer(to_, value_);
        else success = __ERC20Transfer(token_, to_, value_);

        if (!success) revert Transferable__TransferFailed();
    }

    function _safeNativeTransfer(address to_, uint256 amount_)
        internal
        virtual
    {
        __checkValidTransfer(to_, amount_);
        if (!__nativeTransfer(to_, amount_))
            revert Transferable__TransferFailed();
    }

    function _safeERC20Transfer(
        IERC20Upgradeable token_,
        address to_,
        uint256 amount_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);
        if (!__ERC20Transfer(token_, to_, amount_))
            revert Transferable__TransferFailed();
    }

    function _safeERC20TransferFrom(
        IERC20Upgradeable token_,
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        __checkValidTransfer(to_, amount_);

        if (!__ERC20TransferFrom(token_, from_, to_, amount_))
            revert Transferable__TransferFailed();
    }

    function __nativeTransfer(address to_, uint256 amount_)
        private
        returns (bool success)
    {
        assembly {
            success := call(gas(), to_, amount_, 0, 0, 0, 0)
        }
    }

    function __ERC20Transfer(
        IERC20Upgradeable token_,
        address to_,
        uint256 value_
    ) internal virtual returns (bool success) {
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to_) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), value_) // Append the "amount" argument.

            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token_, 0, freeMemoryPointer, 68, 0, 32)
            )
        }
    }

    function __ERC20TransferFrom(
        IERC20Upgradeable token_,
        address from_,
        address to_,
        uint256 value_
    ) internal virtual returns (bool success) {
        assembly {
            let freeMemoryPointer := mload(0x40)

            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from_)
            mstore(add(freeMemoryPointer, 36), to_)
            mstore(add(freeMemoryPointer, 68), value_)

            success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                call(gas(), token_, 0, freeMemoryPointer, 100, 0, 32)
            )
        }
    }

    function __checkValidTransfer(address to_, uint256 value_) private pure {
        if (value_ == 0 || to_ == address(0))
            revert Transferable__InvalidArguments();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";

import "./TransferableUpgradeable.sol";

import "./interfaces/IWithdrawableUpgradeable.sol";

abstract contract WithdrawableUpgradeable is
    ContextUpgradeable,
    TransferableUpgradeable,
    IWithdrawableUpgradeable
{
    receive() external payable virtual {
        emit Received(_msgSender(), msg.value);
    }

    function __Withdrawable_init() internal onlyInitializing {}

    function __Withdrawable_init_unchained() internal onlyInitializing {}

    function withdraw(
        address token_,
        address to_,
        uint256 amount_
    ) external virtual;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BitMap256.sol";

library Array {
    using BitMap256 for uint256;

    // 100 record ~= 60k gas
    function buildSet(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 length = arr_.length;
        {
            uint256 val;
            uint256 bitmap;
            for (uint256 i; i < length; ) {
                unchecked {
                    val = arr_[i];
                    while (length > i && bitmap.get(val)) val = arr_[--length];
                    bitmap = bitmap.set(arr_[i] = val);
                    ++i;
                }
            }
        }
        assembly {
            mstore(arr_, length)
        }
        return arr_;
    }

    function trimZero(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory res)
    {
        res = arr_;
        uint256 length = res.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
        assembly {
            mstore(res, counter)
        }
    }

    function trimZero(uint256[256] memory arr_, uint256 size_)
        internal
        pure
        returns (uint256[] memory res)
    {
        res = new uint256[](size_);
        uint256 length = arr_.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///@dev can store up to 256 slots
library BitMap256 {
    struct BitMap {
        uint256 data;
    }

    function index(uint256 value_) internal pure returns (uint256) {
        return value_ & 0xff;
    }

    function indexHash(uint256 value) internal pure returns (uint256 idx) {
        assembly {
            mstore(0x00, value)
            idx := keccak256(0x00, 32)
        }
    }

    function unsafeGet(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            isSet := and(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
        }
    }

    function unsafeGet(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (bool isSet)
    {
        assembly {
            isSet := and(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function get(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, value_)
            isSet := and(
                sload(bitmap_.slot),
                shl(and(keccak256(0x00, 32), 0xff), 1)
            )
        }
    }

    function get(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, value_)
            isSet := and(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
        }
    }

    function setData(BitMap storage bitmap_, uint256 value) internal {
        assembly {
            sstore(bitmap_.slot, value)
        }
    }

    function setTo(
        BitMap storage bitmap_,
        uint256 value_,
        bool status_
    ) internal {
        if (status_) set(bitmap_, value_);
        else unset(bitmap_, value_);
    }

    function unsafeSet(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
            )
        }
    }

    function unsafeSet(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            bitmap := or(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function set(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(keccak256(0x00, 32), 0xff), 1))
            )
        }
    }

    function set(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            mstore(0x00, value_)
            bitmap := or(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
        }
    }

    function unsafeUnset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            sstore(
                bitmap_.slot,
                and(sload(bitmap_.slot), not(shl(and(value_, 0xff), 1)))
            )
        }
    }

    function unsafeUnset(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            bitmap := and(bitmap_, not(shl(and(value_, 0xff), 1)))
        }
    }

    function unset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            sstore(
                bitmap_.slot,
                and(
                    sload(bitmap_.slot),
                    not(shl(and(keccak256(0x00, 32), 0xff), 1))
                )
            )
        }
    }

    function unset(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            mstore(0x00, value_)
            bitmap := and(bitmap_, not(shl(and(keccak256(0x00, 32), 0xff), 1)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Array.sol";
import "./SSTORE2.sol";
import "../oz/utils/structs/BitMaps.sol";

library EnumerableSetV2 {
    using Array for uint256[];
    using SSTORE2 for bytes;
    using SSTORE2 for address;
    using BitMaps for BitMaps.BitMap;

    struct Set {
        uint96 length;
        address ptr;
        BitMaps.BitMap indexes;
    }

    function _add(Set storage set_, uint256[] memory values_) private {
        set_.ptr = abi.encode(values_).writeToAddr();
        uint256 length_ = values_.length;
        for (uint256 i; i < length_; ) {
            set_.indexes.set(values_[i]);
            unchecked {
                ++i;
            }
        }
        set_.length = uint96(length_);
    }

    function _remove(Set storage set_) private {
        delete set_.ptr;
        delete set_.indexes;
        delete set_.length;
    }

    function _remove(Set storage set_, uint256 value_) private returns (bool) {
        if (_contains(set_, value_)) {
            set_.indexes.unset(value_);
            unchecked {
                --set_.length;
            }
            return true;
        }
        return false;
    }

    function _contains(Set storage set, uint256 value)
        private
        view
        returns (bool)
    {
        return set.indexes.get(value);
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (uint256)
    {
        return _values(set)[index];
    }

    function _length(Set storage set) private view returns (uint256) {
        return _values(set).length;
    }

    function _values(Set storage set) private view returns (uint256[] memory) {
        return abi.decode(set.ptr.read(), (uint256[]));
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address[] memory value) internal {
        uint256[] memory store;
        assembly {
            store := value
        }
        _add(set._inner, store);
    }

    function remove(AddressSet storage set) internal {
        _remove(set._inner);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool removed)
    {
        uint256 val;
        assembly {
            val := value
        }
        removed = _remove(set._inner, val);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _contains(set._inner, store);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address addr)
    {
        uint256 value = _at(set._inner, index);
        assembly {
            addr := value
        }
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory res)
    {
        uint256[] memory val = _values(set._inner);
        uint256 length_ = val.length;
        uint256[] memory tmp = new uint256[](length_);
        BitMaps.BitMap storage bitmap = set._inner.indexes;
        uint256 counter;
        for (uint256 i; i < length_; ) {
            unchecked {
                if (bitmap.get(val[i])) tmp[counter++] = val[i];
                ++i;
            }
        }
        assembly {
            mstore(tmp, counter)
            res := tmp
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = (1 << 256) - 1;
    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(
                mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))
            ) {
                revert(0, 0)
            }

            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(
                mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))
            ) {
                revert(0, 0)
            }

            // Add 1 to the result if x * y mod denominator != 0.
            z := add(
                gt(mod(mul(x, y), denominator), 0),
                div(mul(x, y), denominator)
            )
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    error SSTORE2__DeploymentFailed();
    error SSTORE2__ReadOutOfBounds();

    // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (bytes32 ptr) {
        // Note: The assembly block below does not expand the memory.
        address pointer;
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, 1)

            /**
             * ------------------------------------------------------------------------------------+
             *   Opcode  | Opcode + Arguments  | Description       | Stack View                    |
             * ------------------------------------------------------------------------------------|
             *   0x61    | 0x61XXXX            | PUSH2 codeSize    | codeSize                      |
             *   0x80    | 0x80                | DUP1              | codeSize codeSize             |
             *   0x60    | 0x600A              | PUSH1 10          | 10 codeSize codeSize          |
             *   0x3D    | 0x3D                | RETURNDATASIZE    | 0 10 codeSize codeSize        |
             *   0x39    | 0x39                | CODECOPY          | codeSize                      |
             *   0x3D    | 0x3D                | RETURNDATASZIE    | 0 codeSize                    |
             *   0xF3    | 0xF3                | RETURN            |                               |
             *   0x00    | 0x00                | STOP              |                               |
             * ------------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called. Also PUSH2 is
             * used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    shl(64, dataSize) // shift `dataSize` so that it lines up with the 0000 after PUSH2
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 21), add(dataSize, 10))

            // Restore original length of the variable size `data`
            mstore(data, originalDataLength)
        }

        if (pointer == address(0)) revert SSTORE2__DeploymentFailed();

        assembly {
            ptr := pointer
        }
    }

    function writeToAddr(bytes memory data) internal returns (address pointer) {
        // Note: The assembly block below does not expand the memory.
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, 1)

            /**
             * ------------------------------------------------------------------------------------+
             *   Opcode  | Opcode + Arguments  | Description       | Stack View                    |
             * ------------------------------------------------------------------------------------|
             *   0x61    | 0x61XXXX            | PUSH2 codeSize    | codeSize                      |
             *   0x80    | 0x80                | DUP1              | codeSize codeSize             |
             *   0x60    | 0x600A              | PUSH1 10          | 10 codeSize codeSize          |
             *   0x3D    | 0x3D                | RETURNDATASIZE    | 0 10 codeSize codeSize        |
             *   0x39    | 0x39                | CODECOPY          | codeSize                      |
             *   0x3D    | 0x3D                | RETURNDATASZIE    | 0 codeSize                    |
             *   0xF3    | 0xF3                | RETURN            |                               |
             *   0x00    | 0x00                | STOP              |                               |
             * ------------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called. Also PUSH2 is
             * used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    shl(64, dataSize) // shift `dataSize` so that it lines up with the 0000 after PUSH2
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 21), add(dataSize, 10))

            // Restore original length of the variable size `data`
            mstore(data, originalDataLength)
        }

        if (pointer == address(0)) revert SSTORE2__DeploymentFailed();
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address ptr) internal view returns (bytes memory) {
        address pointer;
        assembly {
            pointer := ptr
        }
        return
            readBytecode(
                pointer,
                DATA_OFFSET,
                pointer.code.length - DATA_OFFSET
            );
    }

    function read(bytes32 ptr) internal view returns (bytes memory) {
        address pointer;
        assembly {
            pointer := ptr
        }
        return
            readBytecode(
                pointer,
                DATA_OFFSET,
                pointer.code.length - DATA_OFFSET
            );
    }

    function read(address pointer, uint256 start)
        internal
        view
        returns (bytes memory)
    {
        start += DATA_OFFSET;
        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        if (pointer.code.length < end) {
            revert SSTORE2__ReadOutOfBounds();
        }

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 63 (32 + 31) to size and running the result through the logic
            // above ensures the memory pointer remains word-aligned, following
            // the Solidity convention.
            mstore(0x40, add(data, and(add(size, 63), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getAllRoleMembers(bytes32 role_)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    error AccessControl__Unauthorized();
    error AccessControl__RoleMissing(bytes32 role, address account);
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;

    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

error ERC1967UpgradeUpgradeable__NonZeroAddress();
error ERC1967UpgradeUpgradeable__ExecutionFailed();
error ERC1967UpgradeUpgradeable__TargetIsNotContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
error ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
error ERC1967UpgradeUpgradeable__DelegateCallToNonContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotContract();

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!_isContract(newImplementation))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT)
                    revert ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
            } catch {
                revert ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
            }

            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0))
            revert ERC1967UpgradeUpgradeable__NonZeroAddress();
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (!_isContract(newBeacon))
            revert ERC1967UpgradeUpgradeable__TargetIsNotContract();
        if (!_isContract(IBeaconUpgradeable(newBeacon).implementation()))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        if (!_isContract(target))
            revert ERC1967UpgradeUpgradeable__DelegateCallToNonContract();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata);
    }

    function _isContract(address addr_) internal view returns (bool) {
        return addr_.code.length != 0;
    }

    function _verifyCallResult(bool success, bytes memory returndata)
        internal
        pure
        returns (bytes memory)
    {
        if (success) return returndata;
        else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            } else revert ERC1967UpgradeUpgradeable__ExecutionFailed();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

//import "../../utils/AddressUpgradeable.sol";
error Initializable__Initializing();
error Initializable__NotInitializing();
error Initializable__AlreadyInitialized();

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint256 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    uint256 private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint256 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _initializing != 2;
        uint256 initialized = _initialized;
        if (
            !((isTopLevelCall && initialized == 0) ||
                (initialized == 1 && address(this).code.length == 0))
        ) revert Initializable__AlreadyInitialized();

        _initialized = 1;
        if (isTopLevelCall) _initializing = 2;
        _;
        if (isTopLevelCall) {
            _initializing = 1;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint256 version) {
        if (_initializing != 1 || _initialized >= version)
            revert Initializable__AlreadyInitialized();
        _initialized = version & ~uint8(0);
        _initializing = 2;
        _;
        _initializing = 1;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (_initializing != 2) revert Initializable__NotInitializing();
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        if (_initializing != 1) revert Initializable__Initializing();
        if (_initialized < ~uint8(0)) {
            _initialized = ~uint8(0);
            emit Initialized(~uint8(0));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

error UUPSUpgradeable__OnlyCall();
error UUPSUpgradeable__OnlyDelegateCall();
error UUPSUpgradeable__OnlyActiveProxy();

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        if (address(this) == __self) revert UUPSUpgradeable__OnlyDelegateCall();
        if (_getImplementation() != __self)
            revert UUPSUpgradeable__OnlyActiveProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        if (address(this) != __self) revert UUPSUpgradeable__OnlyCall();
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

error ReentrancyGuard__Locked();

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private _locked;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _locked = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        if (_locked == 2) revert ReentrancyGuard__Locked();

        _locked = 2;

        _;

        _locked = 1;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    error ERC20__Expired();
    error ERC20__StringTooLong();
    error ERC20__InvalidSignature();
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../utils/structs/BitMapsUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";

import "../../../libraries/Bytes32Address.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721Upgradeable is
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC721Upgradeable,
    IERC721MetadataUpgradeable
{
    using Bytes32Address for address;
    using Bytes32Address for bytes32;
    using Bytes32Address for uint256;

    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;
    string public symbol;

    function _baseURI() internal view virtual returns (string memory);

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _ownerOf;
    mapping(bytes32 => uint256) internal _balanceOf;

    function ownerOf(uint256 id)
        public
        view
        virtual
        override
        returns (address owner)
    {
        if ((owner = _ownerOf[id].fromFirst20Bytes()) == address(0))
            revert ERC721__NotMinted();
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert ERC721__NonZeroAddress();

        return _balanceOf[owner.fillLast12Bytes()];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bytes32) internal _getApproved;

    mapping(bytes32 => BitMapsUpgradeable.BitMap) internal _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32)
            revert ERC721__StringTooLong();
        name = name_;
        symbol = symbol_;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual override {
        address owner = _ownerOf[id].fromFirst20Bytes();
        address sender = _msgSender();
        if (
            sender != owner &&
            !_isApprovedForAll[owner.fillLast12Bytes()].get(
                sender.fillLast96Bits()
            )
        ) revert ERC721__Unauthorized();

        _getApproved[id] = spender.fillLast12Bytes();

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        address sender = _msgSender();
        _isApprovedForAll[sender.fillLast12Bytes()].setTo(
            operator.fillLast96Bits(),
            approved
        );

        emit ApprovalForAll(sender, operator, approved);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address operator)
    {
        return _getApproved[tokenId].fromFirst20Bytes();
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return
            _isApprovedForAll[owner.fillLast12Bytes()].get(
                operator.fillLast96Bits()
            );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            _isApprovedForAll[owner.fillLast12Bytes()].get(
                spender.fillLast96Bits()
            ) ||
            _getApproved[tokenId] == spender.fillLast12Bytes());
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        address sender = _msgSender();
        if (
            sender != from &&
            !_isApprovedForAll[from.fillLast12Bytes()].get(
                sender.fillLast96Bits()
            ) &&
            sender.fillLast12Bytes() != _getApproved[id]
        ) revert ERC721__Unauthorized();

        _transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                from,
                id,
                ""
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from != _ownerOf[tokenId].fromFirst20Bytes())
            revert ERC721__WrongFrom();
        if (to == address(0)) revert ERC721__InvalidRecipient();

        _beforeTokenTransfer(from, to, tokenId);

        bytes32 _to = to.fillLast12Bytes();

        unchecked {
            --_balanceOf[from.fillLast12Bytes()];
            ++_balanceOf[_to];
        }
        _ownerOf[tokenId] = _to;

        delete _getApproved[tokenId];

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        _transfer(from_, to_, tokenId_);
        __checkOnERC721Received(from_, to_, tokenId_, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override {
        transferFrom(from, to, id);
        __checkOnERC721Received(from, to, id, data);
    }

    function __checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) private {
        if (
            to_.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to_).onERC721Received(
                _msgSender(),
                from_,
                tokenId_,
                data_
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert ERC721__InvalidRecipient();
        if (_ownerOf[id] != 0) revert ERC721__AlreadyMinted();

        _beforeTokenTransfer(address(0), to, id);
        bytes32 _to = to.fillLast12Bytes();
        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[_to]++;
        }
        _ownerOf[id] = _to;

        emit Transfer(address(0), to, id);

        _afterTokenTransfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id].fromFirst20Bytes();

        if (owner == address(0)) revert ERC721__NotMinted();

        _beforeTokenTransfer(owner, address(0), id);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner.fillLast12Bytes()]--;
        }

        delete _ownerOf[id];

        delete _getApproved[id];

        emit Transfer(owner, address(0), id);

        _afterTokenTransfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                address(0),
                id,
                ""
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiverUpgradeable(to).onERC721Received(
                _msgSender(),
                address(0),
                id,
                data
            ) !=
            ERC721TokenReceiverUpgradeable.onERC721Received.selector
        ) revert ERC721__UnsafeRecipient();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiverUpgradeable {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiverUpgradeable.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    error ERC721__NotMinted();
    error ERC721__WrongFrom();
    error ERC721__Unauthorized();
    error ERC721__StringTooLong();
    error ERC721__AlreadyMinted();
    error ERC721__NonZeroAddress();
    error ERC721__UnsafeRecipient();
    error ERC721__InvalidRecipient();
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    ///@dev value is equal to keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant _TYPE_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        onlyInitializing
    {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

//import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // Directly load `s` from the calldata.
            let s := calldataload(add(signature.offset, 0x20))

            switch signature.length
            case 64 {
                // Here, `s` is actually `vs` that needs to be recovered into `v` and `s`.
                // Compute `v` and store it in the scratch space.
                mstore(0x20, add(shr(255, s), 27))
                // prettier-ignore
                s := and(s, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            }
            case 65 {
                // Compute `v` and store it in the scratch space.
                mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
            }

            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                calldatacopy(0x40, signature.offset, 0x20) // Directly copy `r` over.
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address result) {
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            mstore(0x20, v)
            // If `s` in lower half order, such that the signature is not malleable.
            // prettier-ignore
            if iszero(gt(s, 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0)) {
                mstore(0x00, hash)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32 result)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes.
            // The next multiple of 32 above 78 + 26 is 128.

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            for {
                let temp := sLength
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            // Move the pointer 32 bytes lower to make room for the string.
            // `start` marks the start of the memory which we will compute the keccak256 of.
            let start := sub(ptr, 32)
            // Copy the header over to the memory.
            mstore(
                start,
                "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n"
            )
            start := add(start, 6)

            // Compute the keccak256 of the memory.
            result := keccak256(start, sub(end, start))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(
                memPtr,
                0x1901000000000000000000000000000000000000000000000000000000000000
            ) // EIP191 header
            mstore(add(memPtr, 2), domainSeparator) // EIP712 domain hash
            mstore(add(memPtr, 34), structHash) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(
                account,
                type(IERC165Upgradeable).interfaceId
            ) && !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return
            supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(
                    account,
                    interfaceIds[i]
                );
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId)
        private
        view
        returns (bool)
    {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(
            IERC165Upgradeable.supportsInterface.selector,
            interfaceId
        );

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(
                30000,
                account,
                add(encodedParams, 0x20),
                mload(encodedParams),
                0x00,
                0x20
            )
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        return bitmap._data[index >> 8] & (1 << (index & 0xff)) != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) set(bitmap, index);
        else unset(bitmap, index);
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap._data[index >> 8] |= 1 << (index & 0xff);
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap._data[index >> 8] &= ~(1 << (index & 0xff));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.17;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) map;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool isSet)
    {
        uint256 value = bitmap.map[index >> 8] & (1 << (index & 0xff));

        assembly {
            isSet := value // Assign isSet to whether the value is non zero.
        }
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool shouldSet
    ) internal {
        uint256 value = bitmap.map[index >> 8];

        assembly {
            // The following sets the bit at `shift` without branching.
            let shift := and(index, 0xff)
            // Isolate the bit at `shift`.
            let x := and(shr(shift, value), 1)
            // Xor it with `shouldSet`. Results in 1 if both are different, else 0.
            x := xor(x, shouldSet)
            // Shifts the bit back. Then, xor with value.
            // Only the bit at `shift` will be flipped if they differ.
            // Every other bit will stay the same, as they are xor'ed with zeroes.
            value := xor(value, shl(shift, x))
        }
        bitmap.map[index >> 8] = value;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    function setBatch(BitMap storage bitmap_, uint256[] memory values_)
        internal
    {
        assembly {
            let length := mload(values_)
            let i := add(values_, 0x20)
            mstore(0x20, bitmap_.slot)
            for {
                let end := add(i, mul(length, 0x20))
            } lt(i, end) {
                i := add(i, 0x20)
            } {
                mstore(0x00, shr(8, mload(i)))
                let key := keccak256(0x00, 0x40)
                sstore(key, or(sload(key), shl(and(mload(i), 0xff), 1)))
            }
        }
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }
}