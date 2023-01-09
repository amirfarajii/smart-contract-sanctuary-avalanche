// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Receiver.sol)

pragma solidity ^0.8.0;

interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Address } from "openzeppelin-contracts/utils/Address.sol";
import { IERC1363Receiver } from "openzeppelin-contracts/interfaces/IERC1363Receiver.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { Initializable } from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import { IFunnel } from "./interfaces/IFunnel.sol";
import { IERC5827 } from "./interfaces/IERC5827.sol";
import { IERC5827Proxy } from "./interfaces/IERC5827Proxy.sol";
import { IERC5827Spender } from "./interfaces/IERC5827Spender.sol";
import { IERC5827Payable } from "./interfaces/IERC5827Payable.sol";
import { IFunnelErrors } from "./interfaces/IFunnelErrors.sol";
import { MetaTxContext } from "./lib/MetaTxContext.sol";
import { NativeMetaTransaction } from "./lib/NativeMetaTransaction.sol";
import { MathUtil } from "./lib/MathUtil.sol";

/// @title Funnel contracts for ERC20
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
/// @notice This contract is a funnel for ERC20 tokens. It enforces renewable allowances
contract Funnel is IFunnel, NativeMetaTransaction, MetaTxContext, Initializable, IFunnelErrors {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    ///                      EIP-5827 STORAGE
    //////////////////////////////////////////////////////////////

    /// address of the base token (e.g. USDC, DAI, WETH)
    IERC20 private _baseToken;

    /// @notice RenewableAllowance struct that is stored on the contract
    /// @param maxAmount The maximum amount of allowance possible
    /// @param remaining The remaining allowance left at the last updated time
    /// @param recoveryRate The rate at which the allowance recovers
    /// @param lastUpdated Timestamp that the allowance is last updated.
    /// @dev The actual remaining allowance at any point of time must be derived from recoveryRate, lastUpdated and maxAmount.
    /// See getter function for implementation details.
    struct RenewableAllowance {
        uint256 maxAmount;
        uint256 remaining;
        uint192 recoveryRate;
        uint64 lastUpdated;
    }

    // owner => spender => renewableAllowance
    mapping(address => mapping(address => RenewableAllowance)) rAllowance;

    //////////////////////////////////////////////////////////////
    ///                        EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////

    /// INITIAL_CHAIN_ID to be set during initiailisation
    /// @dev This value will not change
    uint256 internal INITIAL_CHAIN_ID;

    /// INITIAL_DOMAIN_SEPARATOR to be set during initiailisation
    /// @dev This value will not change
    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    /// constant for the given struct type that do not need to be runtime computed. Required for EIP712-typed data
    bytes32 internal constant PERMIT_RENEWABLE_TYPEHASH =
        keccak256(
            "PermitRenewable(address owner,address spender,uint256 value,uint256 recoveryRate,uint256 nonce,uint256 deadline)"
        );

    /// constant for the given struct type that do not need to be runtime computed. Required for EIP712-typed data
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @notice Called when the contract is being initialised.
    /// @dev Sets the INITIAL_CHAIN_ID and INITIAL_DOMAIN_SEPARATOR that might be used in future permit calls
    function initialize(address _token) external initializer {
        if (_token == address(0)) {
            revert InvalidAddress({ _input: _token });
        }
        _baseToken = IERC20(_token);

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// @dev Fallback function
    /// implemented entirely in `_fallback`.
    fallback() external {
        _fallback(address(_baseToken));
    }

    /// @notice Sets fixed allowance with signed approval.
    /// @dev The address cannot be zero
    /// @param owner The address of the token owner
    /// @param spender The address of the spender.
    /// @param value fixed amount to approve
    /// @param deadline deadline for the approvals in the future
    /// @param v, r, s valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }

        uint256 nonce;
        unchecked {
            nonce = _nonces[owner]++;
        }

        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        _verifySig(owner, hashStruct, v, r, s);

        _approve(owner, spender, value, 0);
    }

    /// @notice Sets renewable allowance with signed approval.
    /// @dev The address cannot be zero
    /// @param owner The address of the token owner
    /// @param spender The address of the spender.
    /// @param value fixed amount to approve
    /// @param recoveryRate recovery rate for the renewable allowance
    /// @param deadline deadline for the approvals in the future
    /// @param v, r, s valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
    function permitRenewable(
        address owner,
        address spender,
        uint256 value,
        uint256 recoveryRate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }
        uint256 nonce;
        unchecked {
            nonce = _nonces[owner]++;
        }

        bytes32 hashStruct = keccak256(
            abi.encode(PERMIT_RENEWABLE_TYPEHASH, owner, spender, value, recoveryRate, nonce, deadline)
        );

        _verifySig(owner, hashStruct, v, r, s);

        _approve(owner, spender, value, recoveryRate);
    }

    /// @inheritdoc IERC5827
    function approve(address _spender, uint256 _value) external returns (bool success) {
        _approve(_msgSender(), _spender, _value, 0);
        return true;
    }

    /// @inheritdoc IERC5827
    function approveRenewable(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) external returns (bool success) {
        _approve(_msgSender(), _spender, _value, _recoveryRate);
        return true;
    }

    /// @inheritdoc IERC5827
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        uint256 _baseAllowance = _baseToken.allowance(_owner, address(this));
        uint256 _renewableAllowance = _remainingAllowance(_owner, _spender);
        return _baseAllowance < _renewableAllowance ? _baseAllowance : _renewableAllowance;
    }

    /// @inheritdoc IERC5827Payable
    function approveRenewableAndCall(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes calldata data
    ) external returns (bool) {
        _approve(_msgSender(), _spender, _value, _recoveryRate);

        // if there is an issue in the checks, it should revert within the function
        _checkOnApprovalReceived(_spender, _value, _recoveryRate, data);
        return true;
    }

    /// @inheritdoc IERC5827
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        uint256 remainingAllowance = _remainingAllowance(from, _msgSender());
        if (remainingAllowance < amount) {
            revert InsufficientRenewableAllowance({ available: remainingAllowance });
        }

        if (remainingAllowance != type(uint256).max) {
            rAllowance[from][_msgSender()].remaining = remainingAllowance - amount;
            rAllowance[from][_msgSender()].lastUpdated = uint64(block.timestamp);
        }

        _baseToken.safeTransferFrom(from, to, amount);
        return true;
    }

    /// @inheritdoc IERC5827Payable
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool) {
        transferFrom(from, to, value);
        _checkOnTransferReceived(from, to, value, data);
        return true;
    }

    /// @notice Transfer tokens from the sender to the recipient
    /// @param to The address of the recipient
    /// @param amount uint256 The amount of tokens to be transferred
    function transfer(address to, uint256 amount) external returns (bool) {
        _baseToken.safeTransferFrom(_msgSender(), to, amount);
        return true;
    }

    /// =================================================================
    ///                 Getter Functions
    /// =================================================================

    /// @notice fetch approved max amount and recovery rate
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @return amount initial and maximum allowance given to spender
    /// @return recoveryRate recovery amount per second
    function renewableAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 amount, uint256 recoveryRate)
    {
        RenewableAllowance memory a = rAllowance[_owner][_spender];
        return (a.maxAmount, a.recoveryRate);
    }

    /// @inheritdoc IERC5827Proxy
    function baseToken() external view returns (address) {
        return address(_baseToken);
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) external view returns (uint256 balance) {
        return _baseToken.balanceOf(account);
    }

    /// @inheritdoc IERC20
    function totalSupply() external view returns (uint256) {
        return _baseToken.totalSupply();
    }

    /// @notice Gets the name of the token
    /// @dev Fallback to token address if not found
    function name() public view returns (string memory) {
        string memory _name;
        (bool success, bytes memory result) = address(_baseToken).staticcall(abi.encodeWithSignature("name()"));

        if (success && result.length > 0) {
            _name = abi.decode(result, (string));
        } else {
            _name = Strings.toHexString(uint160(address(_baseToken)), 20);
        }

        return string.concat(_name, " (funnel)");
    }

    /// @notice Gets the domain seperator
    /// @dev DOMAIN_SEPARATOR should be unique to the contract and chain to prevent replay attacks from
    /// other domains, and satisfy the requirements of EIP-712
    /// @return bytes32 the domain separator
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. See https://eips.ethereum.org/EIPS/eip-165
    /// @return `true` if the contract implements `interfaceID`
    function supportsInterface(bytes4 interfaceId) external pure virtual returns (bool) {
        return
            interfaceId == type(IERC5827).interfaceId ||
            interfaceId == type(IERC5827Payable).interfaceId ||
            interfaceId == type(IERC5827Proxy).interfaceId;
    }

    /// =================================================================
    ///                 Internal Functions
    /// =================================================================

    /// @notice Fallback implementation
    /// @dev Delegates execution to an implementation contract (i.e. base token)
    /// This is a low level function that doesn't return to its internal call site.
    /// It will return to the external caller whatever the implementation returns.
    /// @param implementation Address to delegate.
    function _fallback(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := staticcall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// @notice Internal function to process the approve
    /// Updates the mapping of `RenewableAllowance`
    /// @dev recoveryRate must be lesser than the value
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @param _value The amount of tokens to be approved
    /// @param _recoveryRate The amount of tokens to be recovered per second
    function _approve(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) internal {
        if (_recoveryRate > _value) {
            revert RecoveryRateExceeded();
        }

        rAllowance[_owner][_spender] = RenewableAllowance({
            maxAmount: _value,
            remaining: _value,
            recoveryRate: uint192(_recoveryRate),
            lastUpdated: uint64(block.timestamp)
        });
        emit Approval(_owner, _spender, _value);
        emit RenewableApproval(_owner, _spender, _value, _recoveryRate);
    }

    /// @notice Internal function to invoke {IERC1363Receiver-onTransferReceived} on a target address
    /// The call is not executed if the target address is not a contract
    /// @param from address Representing the previous owner of the given token amount
    /// @param recipient address Target address that will receive the tokens
    /// @param value uint256 The amount tokens to be transferred
    /// @param data bytes Optional data to send along with the call
    function _checkOnTransferReceived(
        address from,
        address recipient,
        uint256 value,
        bytes memory data
    ) internal {
        if (!Address.isContract(recipient)) {
            revert NotContractError();
        }

        try
            IERC1363Receiver(recipient).onTransferReceived(
                _msgSender(), // operator
                from,
                value,
                data
            )
        returns (bytes4 retVal) {
            if (retVal != IERC1363Receiver.onTransferReceived.selector) {
                revert InvalidReturnSelector();
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                // Attempted to transfer to a non-IERC1363Receiver implementer
                revert NotIERC1363Receiver();
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @notice Internal functionn that is called after `approve` function.
    /// `onRenewableApprovalReceived` may revert. Function also checks if the address called is a IERC5827Spender
    /// @param _spender The address which will spend the funds
    /// @param _value The amount of tokens to be spent
    /// @param _recoveryRate The amount of tokens to be recovered per second
    /// @param data bytes Additional data with no specified format
    function _checkOnApprovalReceived(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes memory data
    ) internal {
        if (!Address.isContract(_spender)) {
            revert NotContractError();
        }

        try IERC5827Spender(_spender).onRenewableApprovalReceived(_msgSender(), _value, _recoveryRate, data) returns (
            bytes4 retVal
        ) {
            if (retVal != IERC5827Spender.onRenewableApprovalReceived.selector) {
                revert InvalidReturnSelector();
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                // attempting to approve a non IERC5827Spender implementer
                revert NotIERC5827Spender();
            } else {
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /// @notice fetch remaining allowance between _owner and _spender while accounting for base token allowance.
    /// @param _owner address of the owner
    /// @param _spender address of spender
    /// @return remaining allowance left
    function _remainingAllowance(address _owner, address _spender) private view returns (uint256) {
        RenewableAllowance memory a = rAllowance[_owner][_spender];

        uint256 recovered = a.recoveryRate * uint64(block.timestamp - a.lastUpdated);
        uint256 remainingAllowance = MathUtil.saturatingAdd(a.remaining, recovered);

        return remainingAllowance > a.maxAmount ? a.maxAmount : remainingAllowance;
    }

    /// @notice compute the domain seperator that is required for the approve by signature functionality
    /// Stops replay attacks from happening because of approvals on different contracts on different chains
    /// @dev Reference https://eips.ethereum.org/EIPS/eip-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name())),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IFunnelFactory } from "./interfaces/IFunnelFactory.sol";
import { IERC5827Proxy } from "./interfaces/IERC5827Proxy.sol";
import { IFunnelErrors } from "./interfaces/IFunnelErrors.sol";
import { Funnel } from "./Funnel.sol";
import { Clones } from "openzeppelin-contracts/proxy/Clones.sol";

/// @title Factory for all the funnel contracts
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
contract FunnelFactory is IFunnelFactory, IFunnelErrors {
    using Clones for address;

    /// Stores the mapping between tokenAddress => funnelAddress
    mapping(address => address) deployments;

    /// address of the implementation. This is immutable due to security as implementation is not
    /// supposed to change after deployment
    address public immutable funnelImplementation;

    /// @notice Deploys the FunnelFactory contract
    /// @dev requires a valid funnelImplementation address
    /// @param _funnelImplementation The address of the implementation
    constructor(address _funnelImplementation) {
        if (_funnelImplementation == address(0)) {
            revert InvalidAddress({ _input: _funnelImplementation });
        }
        funnelImplementation = _funnelImplementation;
    }

    /// @inheritdoc IFunnelFactory
    function deployFunnelForToken(address _tokenAddress) external returns (address _funnelAddress) {
        if (deployments[_tokenAddress] != address(0)) {
            revert FunnelAlreadyDeployed();
        }

        if (_tokenAddress.code.length == 0) {
            revert InvalidToken();
        }

        _funnelAddress = funnelImplementation.cloneDeterministic(bytes32(uint256(uint160(_tokenAddress))));

        deployments[_tokenAddress] = _funnelAddress;
        Funnel(_funnelAddress).initialize(_tokenAddress);
        emit DeployedFunnel(_tokenAddress, _funnelAddress);
    }

    /// @inheritdoc IFunnelFactory
    function getFunnelForToken(address _tokenAddress) public view returns (address _funnelAddress) {
        if (deployments[_tokenAddress] == address(0)) {
            revert FunnelNotDeployed();
        }

        return deployments[_tokenAddress];
    }

    /// @inheritdoc IFunnelFactory
    function isFunnel(address _funnelAddress) external view returns (bool) {
        // Not a deployed contract
        if (_funnelAddress.code.length == 0) {
            return false;
        }

        try IERC5827Proxy(_funnelAddress).baseToken() returns (address baseToken) {
            if (baseToken == address(0)) {
                return false;
            }
            return _funnelAddress == getFunnelForToken(baseToken);
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC165.sol";

/// @title Interface for IERC5827 contracts
/// @notice Please see https://eips.ethereum.org/EIPS/eip-5827 for more details on the goals of this interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827 is IERC20, IERC165 {
    /// Note: the ERC-165 identifier for this interface is 0x93cd7af6.
    /// 0x93cd7af6 ===
    ///   bytes4(keccak256('approveRenewable(address,uint256,uint256)')) ^
    ///   bytes4(keccak256('renewableAllowance(address,address)')) ^
    ///   bytes4(keccak256('approve(address,uint256)') ^
    ///   bytes4(keccak256('transferFrom(address,address,uint256)') ^
    ///   bytes4(keccak256('allowance(address,address)') ^

    ///   @dev Thrown when there available allowance is lesser than transfer amount
    ///   @param available Allowance available, 0 if unset
    error InsufficientRenewableAllowance(uint256 available);

    /// @notice Emitted when a new renewable allowance is set.
    /// @param _owner owner of token
    /// @param _spender allowed spender of token
    /// @param _value   initial and maximum allowance given to spender
    /// @param _recoveryRate recovery amount per second
    event RenewableApproval(address indexed _owner, address indexed _spender, uint256 _value, uint256 _recoveryRate);

    /// @notice Grants an allowance of `_value` to `_spender` initially, which recovers over time based on `_recoveryRate` up to a limit of `_value`.
    /// SHOULD throw when `_recoveryRate` is larger than `_value`.
    /// MUST emit `RenewableApproval` event.
    /// @param _spender allowed spender of token
    /// @param _value   initial and maximum allowance given to spender
    /// @param _recoveryRate recovery amount per second
    function approveRenewable(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) external returns (bool success);

    /// Overridden EIP-20 functions

    /// @notice Returns approved max amount and recovery rate.
    /// @return amount initial and maximum allowance given to spender
    /// @return recoveryRate recovery amount per second
    function renewableAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 amount, uint256 recoveryRate);

    /// @notice Grants a (non-increasing) allowance of _value to _spender.
    /// MUST clear set _recoveryRate to 0 on the corresponding renewable allowance, if any.
    /// @param _spender allowed spender of token
    /// @param _value   allowance given to spender
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @notice Moves `amount` tokens from `from` to `to` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance factoring in recovery rate logic.
    /// SHOULD throw when there is insufficient allowance
    /// @param from token owner address
    /// @param to token recipient
    /// @param amount amount of token to transfer
    /// @return success True if the function is successful, false if otherwise
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    /// @notice Returns amounts spendable by `_spender`.
    /// @param _owner Address of the owner
    /// @param _spender spender of token
    /// @return remaining allowance at the current point in time
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC165.sol";

/// @title IERC5827Payable interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827Payable is IERC165 {
    /// Note: the ERC-165 identifier for this interface is 0x3717806a
    /// 0x3717806a ===
    ///   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
    ///   bytes4(keccak256('approveRenewableAndCall(address,uint256,uint256,bytes)')) ^

    /// @dev Transfer tokens from one address to another and then call IERC1363Receiver `onTransferReceived` on receiver
    /// @param from address The address which you want to send tokens from
    /// @param to address The address which you want to transfer to
    /// @param value uint256 The amount of tokens to be transferred
    /// @param data bytes Additional data with no specified format, sent in call to `to`
    /// @return success true unless throwing
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    /// @notice Approve renewable allowance for spender and then call `onRenewableApprovalReceived` on IERC5827Spender
    /// @param _spender address The address which will spend the funds
    /// @param _value uint256 The amount of tokens to be spent
    /// @param _recoveryRate period duration in minutes
    /// @param data bytes Additional data with no specified format, sent in call to `spender`
    /// @return true unless throwing
    function approveRenewableAndCall(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IERC5827Proxy interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827Proxy {
    /// Note: the ERC-165 identifier for this interface is 0xc55dae63.
    /// 0xc55dae63 ===
    ///   bytes4(keccak256('baseToken()')

    /// @notice Get the underlying base token being proxied.
    /// @return address address of the base token
    function baseToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IERC5827Spender defines a callback function that is called when renewable allowance is approved
/// @author Zlace
/// @notice This interface must be implemented if the spender contract wants to react to an renewable approval
/// @dev Allow transfer/approval call chaining inspired by https://eips.ethereum.org/EIPS/eip-1363
interface IERC5827Spender {
    /// Note: the ERC-165 identifier for this interface is 0xb868618d.
    /// 0xb868618d === bytes4(keccak256("onRenewableApprovalReceived(address,uint256,uint256,bytes)"))

    /// @notice Handle the approval of IERC5827Payable tokens
    /// @dev IERC5827Payable calls this function on the recipient
    /// after an `approve`. This function MAY throw to revert and reject the
    /// approval. Return of other than the magic value MUST result in the
    /// transaction being reverted.
    /// Note: the token contract address is always the message sender.
    /// @param owner address owner of the funds
    /// @param amount uint256 The initial and maximum amount of tokens to be spent
    /// @param recoveryRate uint256 amount recovered per second
    /// @param data bytes Additional data with no specified format
    /// @return `bytes4(keccak256("onRenewableApprovalReceived(address,uint256,uint256,bytes)"))`
    ///  unless throwing
    function onRenewableApprovalReceived(
        address owner,
        uint256 amount,
        uint256 recoveryRate,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC5827 } from "./IERC5827.sol";
import { IERC5827Payable } from "./IERC5827Payable.sol";
import { IERC5827Proxy } from "./IERC5827Proxy.sol";

/// @title Interface for Funnel contracts for ERC20
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnel is IERC5827, IERC5827Proxy, IERC5827Payable {
    /// @dev Invalid selector returned
    error InvalidReturnSelector();

    /// @dev Error thrown when attempting to transfer to a non IERC1363Receiver
    error NotIERC1363Receiver();

    /// @dev Error thrown when attempting to transfer to a non IERC5827Spender
    error NotIERC5827Spender();

    /// @dev Error thrown if the Recovery Rate exceeds the max allowance
    error RecoveryRateExceeded();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Shared errors for Funnel Contracts and FunnelFactory
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnelErrors {
    /// @dev Invalid address, could be due to zero address
    /// @param _input address that caused the error.
    error InvalidAddress(address _input);

    /// Error thrown when the token is invalid
    error InvalidToken();

    /// @dev Thrown when attempting to interact with a non-contract.
    error NotContractError();

    /// @dev Error thrown when the permit deadline expires
    error PermitExpired();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for Funnel Factory
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnelFactory {
    /// ==== Factory Errors =====

    /// Error thrown when funnel is not deployed
    error FunnelNotDeployed();

    /// Error thrown when funnel is already deployed.
    error FunnelAlreadyDeployed();

    /// @notice Event emitted when the funnel contract is deployed
    /// @param tokenAddress of the base token (indexed)
    /// @param funnelAddress of the deployed funnel contract (indexed)
    event DeployedFunnel(address indexed tokenAddress, address indexed funnelAddress);

    /// @notice Deploys a new Funnel contract
    /// @param _tokenAddress The address of the token
    /// @return _funnelAddress The address of the deployed Funnel contract
    /// @dev Throws if `_tokenAddress` has already been deployed
    function deployFunnelForToken(address _tokenAddress) external returns (address _funnelAddress);

    /// @notice Retrieves the Funnel contract address for a given token address
    /// @param _tokenAddress The address of the token
    /// @return _funnelAddress The address of the deployed Funnel contract
    /// @dev Reverts with FunnelNotDeployed if `_tokenAddress` has not been deployed
    function getFunnelForToken(address _tokenAddress) external view returns (address _funnelAddress);

    /// @notice Checks if a given address is a deployed Funnel contract
    /// @param _funnelAddress The address that you want to query
    /// @return true if contract address is a deployed Funnel contract
    function isFunnel(address _funnelAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC1271 } from "openzeppelin-contracts/interfaces/IERC1271.sol";

/// @title EIP712
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
/// @notice https://eips.ethereum.org/EIPS/eip-712
abstract contract EIP712 {
    /// @dev Invalid signature
    error InvalidSignature();

    /// @dev Signature is invalid (IERC1271)
    error IERC1271InvalidSignature();

    /// @notice Gets the domain seperator
    /// @dev DOMAIN_SEPARATOR should be unique to the contract and chain to prevent replay attacks from
    /// other domains, and satisfy the requirements of EIP-712
    /// @return bytes32 the domain separator
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32);

    /// @notice Checks if signer's signature matches the data
    /// @param signer address of the signer
    /// @param hashStruct hash of the typehash & abi encoded data, see https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct]
    /// @param v recovery identifier
    /// @param r signature parameter
    /// @param s signature parameter
    /// @return bool true if the signature is valid, false otherwise
    function _verifySig(
        address signer,
        bytes32 hashStruct,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(signer)
        }

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct));

        if (size > 0) {
            // signer is a contract
            if (
                IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) !=
                IERC1271(signer).isValidSignature.selector
            ) {
                revert IERC1271InvalidSignature();
            }
        } else {
            // EOA signer
            address recoveredAddress = ecrecover(digest, v, r, s);

            if (recoveredAddress == address(0) || recoveredAddress != signer) {
                revert InvalidSignature();
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Common library for math utils
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
library MathUtil {
    /// @dev returns the sum of two uint256 values, saturating at 2**256 - 1
    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Context } from "openzeppelin-contracts/utils/Context.sol";

/// @notice Provides information about the current execution context, including the
/// sender of the transaction and its data. While these are generally available
/// via msg.sender and msg.data, they should not be accessed in such a direct
/// manner, since when dealing with meta-transactions the account sending and
/// paying for execution may not be the actual sender (as far as an application
/// is concerned).
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
abstract contract MetaTxContext is Context {
    /// @notice Allows the recipient contract to retrieve the original sender
    /// in the case of a meta-transaction sent by the relayer
    /// @dev Required since the msg.sender in metatx will be the relayer's address
    /// @return sender Address of the original sender
    function _msgSender() internal view virtual override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { EIP712 } from "./EIP712.sol";
import { Nonces } from "./Nonces.sol";

/// @title NativeMetaTransaction
/// @notice Functions that enables meta transactions
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
abstract contract NativeMetaTransaction is EIP712, Nonces {
    /// Precomputed typeHash as defined in EIP712
    /// keccak256("MetaTransaction(uint256 nonce,address from,bytes functionSignature)")
    bytes32 public constant META_TRANSACTION_TYPEHASH =
        0x23d10def3caacba2e4042e0c75d44a42d2558aabcf5ce951d0642a8032e1e653;

    /// Event that is emited if a meta-transaction is emitted
    /// @dev Useful for off-chain services to pick up these events
    /// @param userAddress Address of the user that sent the meta-transaction
    /// @param relayerAddress Address of the relayer that executed the meta-transaction
    /// @param functionSignature Signature of the function
    event MetaTransactionExecuted(address indexed userAddress, address payable relayerAddress, bytes functionSignature);

    /// @dev Function call is not successful
    error FunctionCallError();

    /// @dev Error thrown when invalid signer
    error InvalidSigner();

    /// Meta transaction structure.
    /// No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
    /// He should call the desired function directly in that case.
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    /// @notice Executes a meta transaction in the context of the signer
    /// Allows a relayer to send another user's transaction and pay the gas
    /// @param userAddress Address of the user the sender is performing on behalf of
    /// @param functionSignature The signature of the user
    /// @param sigR Output of the ECDSA signature
    /// @param sigS Output of the ECDSA signature
    /// @param sigV recovery identifier
    /// @return data encoded return data of the underlying function call
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory data) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: _nonces[userAddress]++,
            from: userAddress,
            functionSignature: functionSignature
        });

        _verifyMetaTx(userAddress, metaTx, sigV, sigR, sigS);

        // Appends userAddress at the end to extract it from calling context
        // solhint-disable-next-line avoid-low-level-calls
        (bool isSuccess, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        if (!isSuccess) {
            revert FunctionCallError();
        }

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);

        return returnData;
    }

    /// @notice verify if the meta transaction is valid
    /// @dev Performs some validity check and checks if the signature matches the hash struct
    /// See EIP712.sol for details about `_verifySig`
    /// @return isValid bool that is true if the signature is valid. False if otherwise
    function _verifyMetaTx(
        address signer,
        MetaTransaction memory metaTx,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool isValid) {
        if (signer == address(0)) {
            revert InvalidSigner();
        }

        bytes32 hashStruct = keccak256(
            abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature))
        );

        return _verifySig(signer, hashStruct, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Handles nonces mapping. Required for EIP712-based signatures
abstract contract Nonces {
    /// mapping between the user and the nonce of the account
    mapping(address => uint256) internal _nonces;

    /// @notice Nonce for permit / meta-transactions
    /// @param owner Token owner's address
    /// @return nonce nonce of the owner
    function nonces(address owner) external view returns (uint256 nonce) {
        return _nonces[owner];
    }
}