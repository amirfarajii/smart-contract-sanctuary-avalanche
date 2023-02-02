// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IAdaptor {
    /* Cross-chain functions that is used to initiate a cross-chain message, should be invoked by Pool */

    function bridgeCreditAndSwapForTokens(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint32 nonce
    ) external payable returns (uint256 trackingId);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IMegaPool {
    function swapTokensForTokensCrossChain(
        address fromToken,
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint32 nonce
    )
        external
        payable
        returns (
            uint256 creditAmount,
            uint256 haircut,
            uint256 id
        );

    function swapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function swapCreditForTokensCrossChain(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint32 nonce
    ) external payable returns (uint256 id);

    /*
     * Permissioned Functions
     */

    function completeSwapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 trackingId
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function mintCredit(
        uint256 creditAmount,
        address receiver,
        uint256 trackingId
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IPool {
    function getTokens() external view returns (address[] memory);

    function addressOfAsset(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view returns (uint256 liquidity, uint256 reward);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view returns (uint256 amount, uint256 fee);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);
}

// SPDX-License-Identifier: GPL-3.0

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.5;

library DSMath {
    uint256 public constant WAD = 10 ** 18;

    // Babylonian Method
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    // Convert x to WAD (18 decimals) from d decimals.
    function toWad(uint256 x, uint8 d) internal pure returns (uint256) {
        if (d < 18) {
            return x * 10 ** (18 - d);
        } else if (d > 18) {
            return (x / (10 ** (d - 18)));
        }
        return x;
    }

    // Convert x from WAD (18 decimals) to d decimals.
    function fromWad(uint256 x, uint8 d) internal pure returns (uint256) {
        if (d < 18) {
            return (x / (10 ** (18 - d)));
        } else if (d > 18) {
            return x * 10 ** (d - 18);
        }
        return x;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.5;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    int256 public constant WAD = 10 ** 18;

    //rounds to zero if x*y < WAD / 2
    function wdiv(int256 x, int256 y) internal pure returns (int256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(int256 x, int256 y) internal pure returns (int256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    // Babylonian Method (typecast as int)
    function sqrt(int256 y) internal pure returns (int256 z) {
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Babylonian Method with initial guess (typecast as int)
    function sqrt(int256 y, int256 guess) internal pure returns (int256 z) {
        if (y > 3) {
            if (guess > 0 && guess <= y) {
                z = guess;
            } else if (guess < 0 && -guess <= y) {
                z = -guess;
            } else {
                z = y;
            }
            int256 x = (y / z + z) / 2;
            while (x != z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Convert x to WAD (18 decimals) from d decimals.
    function toWad(int256 x, uint8 d) internal pure returns (int256) {
        if (d < 18) {
            return x * int256(10 ** (18 - d));
        } else if (d > 18) {
            return (x / int256(10 ** (d - 18)));
        }
        return x;
    }

    // Convert x from WAD (18 decimals) to d decimals.
    function fromWad(int256 x, uint8 d) internal pure returns (int256) {
        if (d < 18) {
            return (x / int256(10 ** (18 - d)));
        } else if (d > 18) {
            return x * int256(10 ** (d - 18));
        }
        return x;
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'value must be positive');
        return uint256(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../interfaces/IAsset.sol';
import '../libraries/DSMath.sol';
import '../libraries/SignedSafeMath.sol';

/**
 * @title CoreV3
 * @notice Handles math operations of Wombat protocol. Assume all params are signed integer with 18 decimals
 * @dev Uses OpenZeppelin's SignedSafeMath and DSMath's WAD for calculations.
 * Change log:
 * - Move view functinos (quotes, high cov ratio fee) from the Pool contract to this contract
 * - Add quote functions for cross chain swaps
 */
library CoreV3 {
    using DSMath for uint256;
    using SignedSafeMath for int256;

    int256 internal constant WAD_I = 10 ** 18;
    uint256 internal constant WAD = 10 ** 18;

    error CORE_UNDERFLOW();
    error CORE_INVALID_VALUE();
    error CORE_INVALID_HIGH_COV_RATIO_FEE();
    error CORE_ZERO_LIQUIDITY();
    error CORE_CASH_NOT_ENOUGH();
    error CORE_COV_RATIO_LIMIT_EXCEEDED();

    /*
     * Public view functions
     */

    /**
     * This function calculate the exactly amount of liquidity of the deposit. Assumes r* = 1
     */
    function quoteDepositLiquidityInEquil(
        IAsset asset,
        uint256 amount,
        uint256 ampFactor
    ) public view returns (uint256 lpTokenToMint, uint256 liabilityToMint, uint256 reward) {
        liabilityToMint = exactDepositLiquidityInEquilImpl(
            int256(amount),
            int256(uint256(asset.cash())),
            int256(uint256(asset.liability())),
            int256(ampFactor)
        ).toUint256();

        if (liabilityToMint >= amount) {
            unchecked {
                reward = liabilityToMint - amount;
            }
        } else {
            // rounding error
            liabilityToMint = amount;
        }

        // Calculate amount of LP to mint : ( deposit + reward ) * TotalAssetSupply / Liability
        uint256 liability = asset.liability();
        lpTokenToMint = (liability == 0 ? liabilityToMint : (liabilityToMint * asset.totalSupply()) / liability);
    }

    /**
     * @notice Calculates fee and liability to burn in case of withdrawal
     * @param asset The asset willing to be withdrawn
     * @param liquidity The liquidity willing to be withdrawn
     * @return amount Total amount to be withdrawn from Pool
     * @return liabilityToBurn Total liability to be burned by Pool
     * @return fee
     */
    function quoteWithdrawAmount(
        IAsset asset,
        uint256 liquidity,
        uint256 ampFactor
    ) public view returns (uint256 amount, uint256 liabilityToBurn, uint256 fee) {
        liabilityToBurn = (asset.liability() * liquidity) / asset.totalSupply();
        if (liabilityToBurn == 0) revert CORE_ZERO_LIQUIDITY();

        amount = withdrawalAmountInEquilImpl(
            -int256(liabilityToBurn),
            int256(uint256(asset.cash())),
            int256(uint256(asset.liability())),
            int256(ampFactor)
        ).toUint256();

        if (liabilityToBurn >= amount) {
            fee = liabilityToBurn - amount;
        } else {
            // rounding error
            amount = liabilityToBurn;
        }
    }

    function quoteWithdrawAmountFromOtherAsset(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 liquidity,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) public view returns (uint256 finalAmount, uint256 withdrewAmount) {
        // quote withdraw
        (withdrewAmount, , ) = quoteWithdrawAmount(fromAsset, liquidity, ampFactor);

        // quote swap
        uint256 fromCash = fromAsset.cash() - withdrewAmount;
        uint256 fromLiability = fromAsset.liability() - liquidity;

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromCash = (fromCash * scaleFactor) / 1e18;
            fromLiability = (fromLiability * scaleFactor) / 1e18;
            withdrewAmount = (withdrewAmount * scaleFactor) / 1e18;
        }

        uint256 idealToAmount = swapQuoteFunc(
            int256(fromCash),
            int256(uint256(toAsset.cash())),
            int256(fromLiability),
            int256(uint256(toAsset.liability())),
            int256(withdrewAmount),
            int256(ampFactor)
        );

        // remove haircut
        finalAmount = idealToAmount - idealToAmount.wmul(haircutRate);

        if (startCovRatio > 0 || endCovRatio > 0) {
            // charge high cov ratio fee
            uint256 fee = highCovRatioFee(
                fromCash,
                fromLiability,
                withdrewAmount,
                finalAmount,
                startCovRatio,
                endCovRatio
            );
            unchecked {
                finalAmount -= fee;
            }
        }
    }

    /**
     * @notice Quotes the actual amount user would receive in a swap, taking in account slippage and haircut
     * @param fromAsset The initial asset
     * @param toAsset The asset wanted by user
     * @param fromAmount The amount to quote
     * @return actualToAmount The actual amount user would receive
     * @return haircut The haircut that will be applied
     */
    function quoteSwap(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate
    ) public view returns (uint256 actualToAmount, uint256 haircut) {
        // exact output swap quote should count haircut before swap
        if (fromAmount < 0) {
            fromAmount = fromAmount.wdiv(WAD_I - int256(haircutRate));
        }

        uint256 fromCash = uint256(fromAsset.cash());
        uint256 fromLiability = uint256(fromAsset.liability());
        uint256 toCash = uint256(toAsset.cash());

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromCash = (fromCash * scaleFactor) / 1e18;
            fromLiability = (fromLiability * scaleFactor) / 1e18;
            fromAmount = (fromAmount * int256(scaleFactor)) / 1e18;
        }

        uint256 idealToAmount = swapQuoteFunc(
            int256(fromCash),
            int256(toCash),
            int256(fromLiability),
            int256(uint256(toAsset.liability())),
            fromAmount,
            int256(ampFactor)
        );
        if ((fromAmount > 0 && toCash < idealToAmount) || (fromAmount < 0 && fromAsset.cash() < uint256(-fromAmount))) {
            revert CORE_CASH_NOT_ENOUGH();
        }

        if (fromAmount > 0) {
            // normal quote
            haircut = idealToAmount.wmul(haircutRate);
            actualToAmount = idealToAmount - haircut;
        } else {
            // exact output swap quote count haircut in the fromAmount
            actualToAmount = idealToAmount;
            haircut = (uint256(-fromAmount)).wmul(haircutRate);
        }
    }

    function quoteSwapTokensForCredit(
        IAsset fromAsset,
        uint256 fromAmount,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) public view returns (uint256 creditAmount, uint256 haircut) {
        uint256 fromCash = fromAsset.cash();
        uint256 fromLiability = fromAsset.liability();

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromCash = (fromCash * scaleFactor) / 1e18;
            fromLiability = (fromLiability * scaleFactor) / 1e18;
            fromAmount = (fromAmount * (scaleFactor)) / 1e18;
        }

        creditAmount = swapToCreditQuote(int256(fromCash), int256(fromLiability), int256(fromAmount), int256(ampFactor))
            .toUint256();

        uint256 fee = highCovRatioFee(
            fromAsset.cash(),
            fromAsset.liability(),
            fromAmount,
            creditAmount,
            startCovRatio,
            endCovRatio
        );
        if (fee > 0) {
            creditAmount -= fee;
            haircut += fee;
        }
    }

    function quoteSwapCreditForTokens(
        uint256 fromAmount,
        IAsset toAsset,
        uint256 ampFactor,
        uint256 scaleFactor,
        uint256 haircutRate
    ) public view returns (uint256 actualToAmount, uint256 haircut) {
        uint256 toCash = toAsset.cash();
        uint256 toLiability = toAsset.liability();

        if (scaleFactor != WAD) {
            // apply scale factor on from-amounts
            fromAmount = (fromAmount * scaleFactor) / 1e18;
        }

        uint256 idealToAmount = swapFromCreditQuote(
            int256(toCash),
            int256(toLiability),
            int256(fromAmount),
            int256(ampFactor)
        ).toUint256();
        if (fromAmount > 0 && toCash < idealToAmount) {
            revert CORE_CASH_NOT_ENOUGH();
        }

        if (fromAmount > 0) {
            // normal quote
            haircut = idealToAmount.wmul(haircutRate);
            actualToAmount = idealToAmount - haircut;
        } else {
            // exact output swap quote count haircut in the fromAmount
            actualToAmount = idealToAmount;
            haircut = fromAmount.wmul(haircutRate);
        }
    }

    function equilCovRatio(int256 D, int256 SL, int256 A) public pure returns (int256 er) {
        int256 b = -(D.wdiv(SL));
        er = _solveQuad(b, A);
    }

    /*
     * Pure calculating functions
     */

    /**
     * @notice Core Wombat stableswap equation
     * @dev This function always returns >= 0
     * @param Ax asset of token x
     * @param Ay asset of token y
     * @param Lx liability of token x
     * @param Ly liability of token y
     * @param Dx delta x, i.e. token x amount inputted
     * @param A amplification factor
     * @return quote The quote for amount of token y swapped for token x amount inputted
     */
    function swapQuoteFunc(
        int256 Ax,
        int256 Ay,
        int256 Lx,
        int256 Ly,
        int256 Dx,
        int256 A
    ) public pure returns (uint256 quote) {
        if (Lx == 0 || Ly == 0) {
            // in case div of 0
            revert CORE_UNDERFLOW();
        }
        int256 D = Ax + Ay - A.wmul((Lx * Lx) / Ax + (Ly * Ly) / Ay); // flattened _invariantFunc
        int256 rx_ = (Ax + Dx).wdiv(Lx);
        int256 b = (Lx * (rx_ - A.wdiv(rx_))) / Ly - D.wdiv(Ly); // flattened _coefficientFunc
        int256 ry_ = _solveQuad(b, A);
        int256 Dy = Ly.wmul(ry_) - Ay;
        if (Dy < 0) {
            quote = uint256(-Dy);
        } else {
            quote = uint256(Dy);
        }
    }

    /**
     * @return v positive value indicates a reward and negative value indicates a fee
     */
    function depositRewardImpl(
        int256 D,
        int256 SL,
        int256 delta_i,
        int256 A_i,
        int256 L_i,
        int256 A
    ) public pure returns (int256 v) {
        if (L_i == 0) {
            // early return in case of div of 0
            return 0;
        }
        if (delta_i + SL == 0) {
            return L_i - A_i;
        }

        int256 r_i_ = _targetedCovRatio(SL, delta_i, A_i, L_i, D, A);
        v = A_i + delta_i - (L_i + delta_i).wmul(r_i_);
    }

    /**
     * @dev should be used only when r* = 1
     */
    function withdrawalAmountInEquilImpl(
        int256 delta_i,
        int256 A_i,
        int256 L_i,
        int256 A
    ) public pure returns (int256 amount) {
        int256 L_i_ = L_i + delta_i;
        int256 r_i = A_i.wdiv(L_i);
        int256 rho = L_i.wmul(r_i - A.wdiv(r_i));
        int256 beta = (rho + delta_i.wmul(WAD_I - A)) / 2;
        int256 A_i_ = beta + (beta * beta + A.wmul(L_i_ * L_i_)).sqrt(beta);
        amount = A_i - A_i_;
    }

    /**
     * @notice return the deposit reward in token amount when target liquidity (LP amount) is known
     */
    function exactDepositLiquidityInEquilImpl(
        int256 D_i,
        int256 A_i,
        int256 L_i,
        int256 A
    ) public pure returns (int256 liquidity) {
        if (L_i == 0) {
            // if this is a deposit, there is no reward/fee
            // if this is a withdrawal, it should have been reverted
            return D_i;
        }
        if (A_i + D_i < 0) {
            // impossible
            revert CORE_UNDERFLOW();
        }

        int256 r_i = A_i.wdiv(L_i);
        int256 k = D_i + A_i;
        int256 b = k.wmul(WAD_I - A) + 2 * A.wmul(L_i);
        int256 c = k.wmul(A_i - (A * L_i) / r_i) - k.wmul(k) + A.wmul(L_i).wmul(L_i);
        int256 l = b * b - 4 * A * c;
        return (-b + l.sqrt(b)).wdiv(A) / 2;
    }

    function swapToCreditQuote(int256 Ax, int256 Lx, int256 Dx, int256 A) public pure returns (int256 quote) {
        int256 rx = Ax.wdiv(Lx);
        int256 rx_ = (Ax + Dx).wdiv(Lx);
        int256 x = rx_ - A.wdiv(rx_);
        int256 y = rx - A.wdiv(rx);

        // return Lx.wmul(x - y);
        return (Lx * (x - y)) / (WAD_I + A);
    }

    function swapFromCreditQuote(
        int256 Ax,
        int256 Lx,
        int256 delta_credit,
        int256 A
    ) public pure returns (int256 quote) {
        int256 rx = Ax.wdiv(Lx);
        // int256 b = delta_credit.wdiv(Lx) - rx + A.wdiv(rx); // flattened _coefficientFunc
        int256 b = (delta_credit * (WAD_I + A)) / Lx - rx + A.wdiv(rx); // flattened _coefficientFunc
        int256 rx_ = _solveQuad(b, A);
        int256 Dx = Ax - Lx.wmul(rx_);

        return Dx;
    }

    function highCovRatioFee(
        uint256 fromAssetCash,
        uint256 fromAssetLiability,
        uint256 fromAmount,
        uint256 quotedToAmount,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) public pure returns (uint256 fee) {
        uint256 finalFromAssetCovRatio = (fromAssetCash + fromAmount).wdiv(fromAssetLiability);

        if (finalFromAssetCovRatio > startCovRatio) {
            // charge high cov ratio fee
            uint256 feeRatio = _highCovRatioFee(
                fromAssetCash.wdiv(fromAssetLiability),
                finalFromAssetCovRatio,
                startCovRatio,
                endCovRatio
            );

            if (feeRatio > WAD) revert CORE_INVALID_HIGH_COV_RATIO_FEE();
            fee = feeRatio.wmul(quotedToAmount);
        }
    }

    /*
     * Internal functions
     */

    /**
     * @notice Solve quadratic equation
     * @dev This function always returns >= 0
     * @param b quadratic equation b coefficient
     * @param c quadratic equation c coefficient
     * @return x
     */
    function _solveQuad(int256 b, int256 c) internal pure returns (int256) {
        return (((b * b) + (c * 4 * WAD_I)).sqrt(b) - b) / 2;
    }

    /**
     * @notice Equation to get invariant constant between token x and token y
     * @dev This function always returns >= 0
     * @param Lx liability of token x
     * @param rx cov ratio of token x
     * @param Ly liability of token x
     * @param ry cov ratio of token y
     * @param A amplification factor
     * @return The invariant constant between token x and token y ("D")
     */
    function _invariantFunc(int256 Lx, int256 rx, int256 Ly, int256 ry, int256 A) internal pure returns (int256) {
        int256 a = Lx.wmul(rx) + Ly.wmul(ry);
        int256 b = A.wmul(Lx.wdiv(rx) + Ly.wdiv(ry));
        return a - b;
    }

    /**
     * @notice Equation to get quadratic equation b coefficient
     * @dev This function can return >= 0 or <= 0
     * @param Lx liability of token x
     * @param Ly liability of token y
     * @param rx_ new asset coverage ratio of token x
     * @param D invariant constant
     * @param A amplification factor
     * @return The quadratic equation b coefficient ("b")
     */
    function _coefficientFunc(int256 Lx, int256 Ly, int256 rx_, int256 D, int256 A) internal pure returns (int256) {
        return Lx.wmul(rx_ - A.wdiv(rx_)).wdiv(Ly) - D.wdiv(Ly);
    }

    function _targetedCovRatio(
        int256 SL,
        int256 delta_i,
        int256 A_i,
        int256 L_i,
        int256 D,
        int256 A
    ) internal pure returns (int256 r_i_) {
        int256 r_i = A_i.wdiv(L_i);
        int256 er = equilCovRatio(D, SL, A);
        int256 er_ = _newEquilCovRatio(er, SL, delta_i);
        int256 D_ = _newInvariantFunc(er_, A, SL, delta_i);

        // Summation of k∈T\{i} is D - L_i.wmul(r_i - A.wdiv(r_i))
        int256 b_ = (D - A_i + (L_i * A) / r_i - D_).wdiv(L_i + delta_i);
        r_i_ = _solveQuad(b_, A);
    }

    function _newEquilCovRatio(int256 er, int256 SL, int256 delta_i) internal pure returns (int256 er_) {
        er_ = (delta_i + SL.wmul(er)).wdiv(delta_i + SL);
    }

    function _newInvariantFunc(int256 er_, int256 A, int256 SL, int256 delta_i) internal pure returns (int256 D_) {
        D_ = (SL + delta_i).wmul(er_ - A.wdiv(er_));
    }

    /**
     * @notice Calculate the high cov ratio fee in the to-asset in a swap.
     * @dev When cov ratio is in the range [startCovRatio, endCovRatio], the marginal cov ratio is
     * (r - startCovRatio) / (endCovRatio - startCovRatio). Here we approximate the high cov ratio cut
     * by calculating the "average" fee.
     * Note: `finalCovRatio` should be greater than `initCovRatio`
     */
    function _highCovRatioFee(
        uint256 initCovRatio,
        uint256 finalCovRatio,
        uint256 startCovRatio,
        uint256 endCovRatio
    ) internal pure returns (uint256 fee) {
        if (finalCovRatio > endCovRatio) {
            // invalid swap
            revert CORE_COV_RATIO_LIMIT_EXCEEDED();
        } else if (finalCovRatio <= startCovRatio || finalCovRatio <= initCovRatio) {
            return 0;
        }

        unchecked {
            // 1. Calculate the area of fee(r) = (r - startCovRatio) / (endCovRatio - startCovRatio)
            // when r increase from initCovRatio to finalCovRatio
            // 2. Then multiply it by (endCovRatio - startCovRatio) / (finalCovRatio - initCovRatio)
            // to get the average fee over the range
            uint256 a = initCovRatio <= startCovRatio
                ? 0
                : (initCovRatio - startCovRatio) * (initCovRatio - startCovRatio);
            uint256 b = (finalCovRatio - startCovRatio) * (finalCovRatio - startCovRatio);
            fee = ((b - a) / (finalCovRatio - initCovRatio) / 2).wdiv(endCovRatio - startCovRatio);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../libraries/DSMath.sol';
import './PoolV2.sol';

/**
 * @title HighCovRatioFeePoolV2
 * @dev Pool with high cov ratio fee protection
 * Change log:
 * - add `gap` to prevent storage collision for future upgrades
 */
contract HighCovRatioFeePoolV2 is PoolV2 {
    using DSMath for uint256;

    uint128 public startCovRatio; // 1.5
    uint128 public endCovRatio; // 1.8

    uint256[50] private gap;

    error WOMBAT_COV_RATIO_LIMIT_EXCEEDED();

    function initialize(uint256 ampFactor_, uint256 haircutRate_) public override {
        super.initialize(ampFactor_, haircutRate_);
        startCovRatio = 15e17;
        endCovRatio = 18e17;
    }

    function setCovRatioFeeParam(uint128 startCovRatio_, uint128 endCovRatio_) external onlyOwner {
        if (startCovRatio_ < 1e18 || startCovRatio_ > endCovRatio_) revert WOMBAT_INVALID_VALUE();

        startCovRatio = startCovRatio_;
        endCovRatio = endCovRatio_;
    }

    /**
     * @dev Exact output swap (fromAmount < 0) should be only used by off-chain quoting function as it is a gas monster
     */
    function _quoteFrom(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount
    ) internal view override returns (uint256 actualToAmount, uint256 haircut) {
        (actualToAmount, haircut) = super._quoteFrom(fromAsset, toAsset, fromAmount);

        if (fromAmount >= 0) {
            uint256 highCovRatioFee = CoreV3.highCovRatioFee(
                fromAsset.cash(),
                fromAsset.liability(),
                uint256(fromAmount),
                actualToAmount,
                startCovRatio,
                endCovRatio
            );

            actualToAmount -= highCovRatioFee;
            unchecked {
                haircut += highCovRatioFee;
            }
        } else {
            // reverse quote
            uint256 toAssetCash = toAsset.cash();
            uint256 toAssetLiability = toAsset.liability();
            uint256 finalToAssetCovRatio = (toAssetCash + uint256(actualToAmount)).wdiv(toAssetLiability);
            if (finalToAssetCovRatio <= startCovRatio) {
                // happy path: no high cov ratio fee is charged
                return (actualToAmount, haircut);
            } else if (toAssetCash.wdiv(toAssetLiability) >= endCovRatio) {
                // the to-asset exceeds it's cov ratio limit, further swap to increase cov ratio is impossible
                revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();
            }

            // reverse quote: cov ratio of the to-asset exceed endCovRatio. direct reverse quote is not supported
            // we binary search for a upper bound
            actualToAmount = _findUpperBound(toAsset, fromAsset, uint256(-fromAmount));
            (, haircut) = _quoteFrom(toAsset, fromAsset, int256(actualToAmount));
        }
    }

    /**
     * @notice Binary search to find the upper bound of `fromAmount` required to swap `fromAsset` to `toAmount` of `toAsset`
     * @dev This function should only used as off-chain view function as it is a gas monster
     */
    function _findUpperBound(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 toAmount
    ) internal view returns (uint256 upperBound) {
        uint8 decimals = fromAsset.underlyingTokenDecimals();
        uint256 toWadFactor = DSMath.toWad(1, decimals);
        // the search value uses the same number of digits as the token
        uint256 high = (uint256(fromAsset.liability()).wmul(endCovRatio) - fromAsset.cash()).fromWad(decimals);
        uint256 low = 1;

        // verify `high` is a valid upper bound
        uint256 quote;
        (quote, ) = _quoteFrom(fromAsset, toAsset, int256(high * toWadFactor));
        if (quote < toAmount) revert WOMBAT_COV_RATIO_LIMIT_EXCEEDED();

        // Note: we might limit the maximum number of rounds if the request is always rejected by the RPC server
        while (low < high) {
            unchecked {
                uint256 mid = (low + high) / 2;
                (quote, ) = _quoteFrom(fromAsset, toAsset, int256(mid * toWadFactor));
                if (quote >= toAmount) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }
        }
        return high * toWadFactor;
    }

    /**
     * @dev take into account high cov ratio fee
     */
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view override returns (uint256 finalAmount, uint256 withdrewAmount) {
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);
        uint256 scaleFactor = _quoteFactor(fromAsset, toAsset);
        (finalAmount, withdrewAmount) = CoreV3.quoteWithdrawAmountFromOtherAsset(
            fromAsset,
            toAsset,
            liquidity,
            ampFactor,
            scaleFactor,
            haircutRate,
            startCovRatio,
            endCovRatio
        );

        withdrewAmount = withdrewAmount.fromWad(fromAsset.underlyingTokenDecimals());
        finalAmount = finalAmount.fromWad(toAsset.underlyingTokenDecimals());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import './HighCovRatioFeePoolV2.sol';
import '../interfaces/IAdaptor.sol';
import '../interfaces/IMegaPool.sol';

/**
 * @title Mega Pool
 * @notice Mega Pool is able to handle cross-chain swaps in addition to ordinary swap within its own chain
 * @dev Refer to note of `swapTokensForTokensCrossChain` for procedure of a cross-chain swap
 * @dev TODO: write documents for protection mechanism and implement it
 * Note: All variables are 18 decimals, except from that of parameters of external functions and underlying tokens
 */
contract MegaPool is HighCovRatioFeePoolV2, IMegaPool {
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    /**
     * Storage
     */

    IAdaptor public adaptor;
    bool internal swapCreditForTokensEnabled;
    bool internal swapTokensForCreditEnabled;

    uint64 public crossChainHaircut;

    uint128 public totalCreditMinted;
    uint128 public totalCreditBurned;

    /// @notice the maximum allowed amount of net mint credit. `totalCreditMinted - totalCreditBurned` should be smaller than this value
    uint128 public maximumNetMintedCredit;
    uint128 public maximumNetBurnedCredit;

    mapping(address => uint256) public creditBalance;

    uint256[50] private _gap;

    /**
     * Events
     */

    /**
     * @notice Event that is emitted when token is swapped into credit
     * @dev `trackingId` 0 means the swap is on the same chain. Otherwise a cross-chain swap with `trackingId` is followed
     */
    event SwapTokensForCredit(
        address indexed sender,
        address indexed fromToken,
        uint256 fromAmount,
        uint256 creditAmount,
        uint256 indexed trackingId
    );

    /**
     * @notice Event that is emitted when credit is swapped into token
     * @dev `trackingId` 0 means the swap is on the same chain. Otherwise it is a cross-chain swap with `trackingId`
     */
    event SwapCreditForTokens(
        uint256 creditAmount,
        address indexed toToken,
        uint256 toAmount,
        address indexed receiver,
        uint256 indexed trackingId
    );

    event MintCredit(address indexed receiver, uint256 creditAmount, uint256 indexed trackingId);

    /**
     * Errors
     */

    error POOL__CREDIT_NOT_ENOUGH();
    error POOL__REACH_MAXIMUM_MINTED_CREDIT();
    error POOL__REACH_MAXIMUM_BURNED_CREDIT();
    error POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
    error POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();

    /**
     * External/public functions
     */

    /**
     * @notice Initiate a cross chain swap
     * @dev Steps:
     * 1. Swap `fromToken` for credit;
     * 2. Notify relayer to bridge credit to the `toChain`;
     * 3. Relayer invoke `completeSwapCreditForTokens` to swap credit for `toToken` in the `toChain`
     * Note: haircut returned here is just high cov ratio fee.
     */
    function swapTokensForTokensCrossChain(
        address fromToken,
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint32 nonce
    )
        external
        payable
        override
        nonReentrant
        whenNotPaused
        returns (
            uint256 creditAmount,
            uint256 haircut,
            uint256 trackingId
        )
    {
        // Assumption: the adaptor should check `toChain` and `toToken`
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();
        requireAssetNotPaused(fromToken);
        _checkAddress(receiver);

        IAsset fromAsset = _assetOf(fromToken);
        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);

        (creditAmount, haircut) = _swapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            minimumCreditAmount
        );

        trackingId = adaptor.bridgeCreditAndSwapForTokens{value: msg.value}(
            toToken,
            toChain,
            creditAmount,
            minimumToAmount,
            receiver,
            nonce
        );

        emit SwapTokensForCredit(msg.sender, fromToken, fromAmount, creditAmount, trackingId);
    }

    /**
     * @notice Swap credit for tokens (same chain)
     */
    function swapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver
    ) external override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 haircut) {
        _beforeSwapCreditForTokens(fromAmount, receiver);
        (actualToAmount, haircut) = _doSwapCreditForTokens(toToken, fromAmount, minimumToAmount, receiver, 0);
    }

    /**
     * @notice Bridge credit and swap it for `toToken` in the `toChain`
     * Nonce must be non-zero, otherwise wormhole will revert the message
     */
    function swapCreditForTokensCrossChain(
        address toToken,
        uint256 toChain,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint32 nonce
    ) external payable override nonReentrant whenNotPaused returns (uint256 trackingId) {
        _beforeSwapCreditForTokens(fromAmount, receiver);

        trackingId = adaptor.bridgeCreditAndSwapForTokens{value: msg.value}(
            toToken,
            toChain,
            fromAmount,
            minimumToAmount,
            receiver,
            nonce
        );
    }

    /**
     * Internal functions
     */

    function _swapTokensForCredit(
        IAsset fromAsset,
        uint256 fromAmount,
        uint256 minimumCreditAmount
    ) internal returns (uint256 creditAmount, uint256 haircut) {
        // Assume credit has 18 decimals
        if (!swapTokensForCreditEnabled) revert POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
        // TODO: implement _quoteFactor for credit
        // uint256 quoteFactor = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        (creditAmount, haircut) = CoreV3.quoteSwapTokensForCredit(
            fromAsset,
            fromAmount,
            ampFactor,
            WAD,
            startCovRatio,
            endCovRatio
        );

        _checkAmount(minimumCreditAmount, creditAmount);

        creditBalance[feeTo] += haircut;
        fromAsset.addCash(fromAmount);
        totalCreditMinted += _to128(creditAmount + haircut);

        // Check it doesn't exceed maximum out-going credits
        if (totalCreditMinted > maximumNetMintedCredit + totalCreditBurned) revert POOL__REACH_MAXIMUM_MINTED_CREDIT();
    }

    function _beforeSwapCreditForTokens(uint256 fromAmount, address receiver) internal {
        _checkAddress(receiver);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();

        if (creditBalance[msg.sender] < fromAmount) revert POOL__CREDIT_NOT_ENOUGH();
        unchecked {
            creditBalance[msg.sender] -= fromAmount;
        }
    }

    function _doSwapCreditForTokens(
        address toToken,
        uint256 fromCreditAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 nonce
    ) internal returns (uint256 actualToAmount, uint256 haircut) {
        if (fromCreditAmount == 0) revert WOMBAT_ZERO_AMOUNT();

        IAsset toAsset = _assetOf(toToken);
        uint8 toDecimal = toAsset.underlyingTokenDecimals();
        (actualToAmount, haircut) = _swapCreditForTokens(toAsset, fromCreditAmount, minimumToAmount.toWad(toDecimal));
        actualToAmount = actualToAmount.fromWad(toDecimal);
        haircut = haircut.fromWad(toDecimal);

        toAsset.transferUnderlyingToken(receiver, actualToAmount);
        totalCreditBurned += _to128(fromCreditAmount);

        // Check it doesn't exceed maximum in-coming credits
        if (totalCreditBurned > maximumNetBurnedCredit + totalCreditMinted) revert POOL__REACH_MAXIMUM_BURNED_CREDIT();

        emit SwapCreditForTokens(fromCreditAmount, toToken, actualToAmount, receiver, nonce);
    }

    function _swapCreditForTokens(
        IAsset toAsset,
        uint256 fromCreditAmount,
        uint256 minimumToAmount
    ) internal returns (uint256 actualToAmount, uint256 haircut) {
        if (!swapCreditForTokensEnabled) revert POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();
        // TODO: implement _quoteFactor for credit
        (actualToAmount, haircut) = CoreV3.quoteSwapCreditForTokens(
            (fromCreditAmount),
            toAsset,
            ampFactor,
            WAD,
            crossChainHaircut
        );

        _checkAmount(minimumToAmount, actualToAmount);
        _feeCollected[toAsset] += haircut;

        // haircut is removed from cash to maintain r* = 1. It is distributed during _mintFee()
        toAsset.removeCash(actualToAmount + haircut);

        // revert if cov ratio < 1% to avoid precision error
        if (DSMath.wdiv(toAsset.cash(), toAsset.liability()) < WAD / 100) revert WOMBAT_FORBIDDEN();
    }

    /**
     * Read-only functions
     */

    function quoteSwapCreditForTokens(address toToken, uint256 fromCreditAmount)
        external
        view
        returns (uint256 amount)
    {
        IAsset toAsset = _assetOf(toToken);
        if (!swapCreditForTokensEnabled) revert POOL__SWAP_CREDIT_FOR_TOKENS_DISABLED();
        // TODO: implement _quoteFactor for credit
        (uint256 actualToAmount, ) = CoreV3.quoteSwapCreditForTokens(
            fromCreditAmount,
            toAsset,
            ampFactor,
            WAD,
            crossChainHaircut
        );

        uint8 toDecimal = toAsset.underlyingTokenDecimals();
        amount = actualToAmount.fromWad(toDecimal);

        // Check it doesn't exceed maximum in-coming credits
        if (totalCreditBurned + fromCreditAmount > maximumNetBurnedCredit + totalCreditMinted)
            revert POOL__REACH_MAXIMUM_BURNED_CREDIT();
    }

    function quoteSwapTokensForCredit(address fromToken, uint256 fromAmount)
        external
        view
        returns (uint256 creditAmount, uint256 haircut)
    {
        IAsset fromAsset = _assetOf(fromToken);

        // Assume credit has 18 decimals
        if (!swapTokensForCreditEnabled) revert POOL__SWAP_TOKENS_FOR_CREDIT_DISABLED();
        // TODO: implement _quoteFactor for credit
        // uint256 quoteFactor = IRelativePriceProvider(address(fromAsset)).getRelativePrice();
        (creditAmount, haircut) = CoreV3.quoteSwapTokensForCredit(
            fromAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            ampFactor,
            WAD,
            startCovRatio,
            endCovRatio
        );

        // Check it doesn't exceed maximum out-going credits
        if (totalCreditMinted + creditAmount + haircut > maximumNetMintedCredit + totalCreditBurned)
            revert POOL__REACH_MAXIMUM_MINTED_CREDIT();
    }

    /**
     * @notice Calculate the r* and invariant when all credits are settled
     */
    function globalEquilCovRatioWithCredit() external view returns (uint256 equilCovRatio, uint256 invariantInUint) {
        int256 invariant;
        int256 SL;
        (invariant, SL) = _globalInvariantFunc();
        int256 creditOffset = (int256(uint256(totalCreditBurned)) - int256(uint256(totalCreditMinted))).wmul(
            int256(WAD + ampFactor)
        );
        // int256 creditOffset = (int256(uint256(totalCreditBurned)) - int256(uint256(totalCreditMinted)));
        invariant += creditOffset;
        equilCovRatio = uint256(CoreV3.equilCovRatio(invariant, SL, int256(ampFactor)));
        invariantInUint = uint256(invariant);
    }

    function _to128(uint256 val) internal pure returns (uint128) {
        require(val <= type(uint128).max, 'uint128 overflow');
        return uint128(val);
    }

    /**
     * Permisioneed functions
     */

    /**
     * @notice Swap credit to tokens; should be called by the adaptor
     */
    function completeSwapCreditForTokens(
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address receiver,
        uint256 trackingId
    ) external override whenNotPaused returns (uint256 actualToAmount, uint256 haircut) {
        require(msg.sender == address(adaptor));
        // Note: `_checkAddress(receiver)` could be skipped at it is called at the `fromChain`
        (actualToAmount, haircut) = _doSwapCreditForTokens(toToken, fromAmount, minimumToAmount, receiver, trackingId);
    }

    /**
     * @notice In case `completeSwapCreditForTokens` fails, adaptor should mint credit to the respective user
     */
    function mintCredit(
        uint256 creditAmount,
        address receiver,
        uint256 trackingId
    ) external override whenNotPaused {
        require(msg.sender == address(adaptor));
        creditBalance[receiver] += creditAmount;
        emit MintCredit(receiver, creditAmount, trackingId);
    }

    function setSwapTokensForCreditEnabled(bool enable) external onlyOwner {
        swapTokensForCreditEnabled = enable;
    }

    function setSwapCreditForTokensEnabled(bool enable) external onlyOwner {
        swapCreditForTokensEnabled = enable;
    }

    function setMaximumNetMintedCredit(uint128 _maximumNetMintedCredit) external onlyOwner {
        maximumNetMintedCredit = _maximumNetMintedCredit;
    }

    function setMaximumNetBurnedCredit(uint128 _maximumNetBurnedCredit) external onlyOwner {
        maximumNetBurnedCredit = _maximumNetBurnedCredit;
    }

    function setAdaptorAddr(IAdaptor _adaptor) external onlyOwner {
        adaptor = _adaptor;
    }

    function setCrossChainHaircut(uint64 _crossChainHaircut) external onlyOwner {
        require(_crossChainHaircut < 1e18);
        crossChainHaircut = _crossChainHaircut;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

/**
 * @title PausableAssets
 * @notice Handles assets pause and unpause of Wombat protocol.
 * @dev Allows pausing and unpausing of deposit and swap operations
 */
contract PausableAssets {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event PausedAsset(address asset, address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event UnpausedAsset(address asset, address account);

    mapping(address => bool) private _pausedAssets;

    error WOMBAT_ASSET_ALREADY_PAUSED();
    error WOMBAT_ASSET_NOT_PAUSED();

    /**
     * @dev Function to make a function callable only when the asset is not paused.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function requireAssetNotPaused(address asset) internal view {
        if (_pausedAssets[asset]) revert WOMBAT_ASSET_ALREADY_PAUSED();
    }

    /**
     * @dev Function to make a function callable only when the asset is paused.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function requireAssetPaused(address asset) internal view {
        if (!_pausedAssets[asset]) revert WOMBAT_ASSET_NOT_PAUSED();
    }

    /**
     * @dev Triggers paused state.
     *
     * Requirements:
     *
     * - The asset must not be paused.
     */
    function _pauseAsset(address asset) internal {
        requireAssetNotPaused(asset);
        _pausedAssets[asset] = true;
        emit PausedAsset(asset, msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The asset must be paused.
     */
    function _unpauseAsset(address asset) internal {
        requireAssetPaused(asset);
        _pausedAssets[asset] = false;
        emit UnpausedAsset(asset, msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './CoreV3.sol';
import '../interfaces/IAsset.sol';
import './PausableAssets.sol';
import '../../wombat-governance/interfaces/IMasterWombat.sol';
import '../interfaces/IPool.sol';

/**
 * @title Pool V2
 * @notice Manages deposits, withdrawals and swaps. Holds a mapping of assets and parameters.
 * @dev The main entry-point of Wombat protocol
 * Note: All variables are 18 decimals, except from that of underlying tokens
 * Change log:
 * - add `gap` to prevent storage collision for future upgrades
 */
contract PoolV2 is
    Initializable,
    IPool,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PausableAssets
{
    using DSMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;

    /// @notice Asset Map struct holds assets
    struct AssetMap {
        address[] keys;
        mapping(address => IAsset) values;
        mapping(address => uint256) indexOf;
    }

    int256 internal constant WAD_I = 10 ** 18;
    uint256 internal constant WAD = 10 ** 18;

    /* Storage */

    /// @notice Amplification factor
    uint256 public ampFactor;

    /// @notice Haircut rate
    uint256 public haircutRate;

    /// @notice Retention ratio: the ratio of haircut that should stay in the pool
    uint256 public retentionRatio;

    /// @notice LP dividend ratio : the ratio of haircut that should distribute to LP
    uint256 public lpDividendRatio;

    /// @notice The threshold to mint fee (unit: WAD)
    uint256 public mintFeeThreshold;

    /// @notice Dev address
    address public dev;

    address public feeTo;

    address public masterWombat;

    /// @notice Dividend collected by each asset (unit: WAD)
    mapping(IAsset => uint256) internal _feeCollected;

    /// @notice A record of assets inside Pool
    AssetMap internal _assets;

    // Slots reserved for future use
    uint128 internal _used1; // Remember to initialize before use.
    uint128 internal _used2; // Remember to initialize before use.
    uint256[49] private gap;

    /* Events */

    /// @notice An event thats emitted when an asset is added to Pool
    event AssetAdded(address indexed token, address indexed asset);

    /// @notice An event thats emitted when asset is removed from Pool
    event AssetRemoved(address indexed token, address indexed asset);

    /// @notice An event thats emitted when a deposit is made to Pool
    event Deposit(address indexed sender, address token, uint256 amount, uint256 liquidity, address indexed to);

    /// @notice An event thats emitted when a withdrawal is made from Pool
    event Withdraw(address indexed sender, address token, uint256 amount, uint256 liquidity, address indexed to);

    /// @notice An event thats emitted when a swap is made in Pool
    event Swap(
        address indexed sender,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address indexed to
    );

    event SetDev(address addr);
    event SetMasterWombat(address addr);
    event SetFeeTo(address addr);

    event SetMintFeeThreshold(uint256 value);
    event SetFee(uint256 lpDividendRatio, uint256 retentionRatio);
    event SetAmpFactor(uint256 value);
    event SetHaircutRate(uint256 value);

    event FillPool(address token, uint256 amount);
    event TransferTipBucket(address token, uint256 amount, address to);

    /* Errors */

    error WOMBAT_FORBIDDEN();
    error WOMBAT_EXPIRED();

    error WOMBAT_ASSET_NOT_EXISTS();
    error WOMBAT_ASSET_ALREADY_EXIST();

    error WOMBAT_ZERO_ADDRESS();
    error WOMBAT_ZERO_AMOUNT();
    error WOMBAT_ZERO_LIQUIDITY();
    error WOMBAT_INVALID_VALUE();
    error WOMBAT_SAME_ADDRESS();
    error WOMBAT_AMOUNT_TOO_LOW();
    error WOMBAT_CASH_NOT_ENOUGH();

    /* Pesudo modifiers to safe gas */

    function _checkLiquidity(uint256 liquidity) internal pure {
        if (liquidity == 0) revert WOMBAT_ZERO_LIQUIDITY();
    }

    function _checkAddress(address to) internal pure {
        if (to == address(0)) revert WOMBAT_ZERO_ADDRESS();
    }

    function _checkSameAddress(address from, address to) internal pure {
        if (from == to) revert WOMBAT_SAME_ADDRESS();
    }

    function _checkAmount(uint256 minAmt, uint256 amt) internal pure {
        if (minAmt > amt) revert WOMBAT_AMOUNT_TOO_LOW();
    }

    function _ensure(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert WOMBAT_EXPIRED();
    }

    function _onlyDev() internal view {
        if (dev != msg.sender) revert WOMBAT_FORBIDDEN();
    }

    /* Construtor and setters */

    /**
     * @notice Initializes pool. Dev is set to be the account calling this function.
     */
    function initialize(uint256 ampFactor_, uint256 haircutRate_) public virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        ampFactor = ampFactor_;
        haircutRate = haircutRate_;

        lpDividendRatio = WAD;

        dev = msg.sender;
    }

    /**
     * Permisioneed functions
     */

    /**
     * @notice Adds asset to pool, reverts if asset already exists in pool
     * @param token The address of token
     * @param asset The address of the Wombat Asset contract
     */
    function addAsset(address token, address asset) external onlyOwner {
        _checkAddress(asset);
        _checkAddress(token);

        if (_containsAsset(token)) revert WOMBAT_ASSET_ALREADY_EXIST();
        _assets.values[token] = IAsset(asset);
        _assets.indexOf[token] = _assets.keys.length;
        _assets.keys.push(token);

        emit AssetAdded(token, asset);
    }

    /**
     * @notice Removes asset from asset struct
     * @dev Can only be called by owner
     * @param token The address of token to remove
     */
    function removeAsset(address token) external onlyOwner {
        if (!_containsAsset(token)) revert WOMBAT_ASSET_NOT_EXISTS();

        address asset = address(_getAsset(token));
        delete _assets.values[token];

        uint256 index = _assets.indexOf[token];
        uint256 lastIndex = _assets.keys.length - 1;
        address lastKey = _assets.keys[lastIndex];

        _assets.indexOf[lastKey] = index;
        delete _assets.indexOf[token];

        _assets.keys[index] = lastKey;
        _assets.keys.pop();

        emit AssetRemoved(token, asset);
    }

    /**
     * @notice Changes the contract dev. Can only be set by the contract owner.
     * @param dev_ new contract dev address
     */
    function setDev(address dev_) external onlyOwner {
        _checkAddress(dev_);
        dev = dev_;
        emit SetDev(dev_);
    }

    function setMasterWombat(address masterWombat_) external onlyOwner {
        _checkAddress(masterWombat_);
        masterWombat = masterWombat_;
        emit SetMasterWombat(masterWombat_);
    }

    /**
     * @notice Changes the pools amplification factor. Can only be set by the contract owner.
     * @param ampFactor_ new pool's amplification factor
     */
    function setAmpFactor(uint256 ampFactor_) external onlyOwner {
        if (ampFactor_ > WAD) revert WOMBAT_INVALID_VALUE(); // ampFactor_ should not be set bigger than 1
        ampFactor = ampFactor_;
        emit SetAmpFactor(ampFactor_);
    }

    /**
     * @notice Changes the pools haircutRate. Can only be set by the contract owner.
     * @param haircutRate_ new pool's haircutRate_
     */
    function setHaircutRate(uint256 haircutRate_) external onlyOwner {
        if (haircutRate_ > WAD) revert WOMBAT_INVALID_VALUE(); // haircutRate_ should not be set bigger than 1
        haircutRate = haircutRate_;
        emit SetHaircutRate(haircutRate_);
    }

    function setFee(uint256 lpDividendRatio_, uint256 retentionRatio_) external onlyOwner {
        unchecked {
            if (retentionRatio_ + lpDividendRatio_ > WAD) revert WOMBAT_INVALID_VALUE();
        }
        _mintAllFees();
        retentionRatio = retentionRatio_;
        lpDividendRatio = lpDividendRatio_;
        emit SetFee(lpDividendRatio_, retentionRatio_);
    }

    /**
     * @dev unit of amount should be in WAD
     */
    function transferTipBucket(address token, uint256 amount, address to) external onlyOwner {
        IAsset asset = _assetOf(token);
        uint256 tipBucketBal = tipBucketBalance(token);

        if (amount > tipBucketBal) {
            // revert if there's not enough amount in the tip bucket
            revert WOMBAT_INVALID_VALUE();
        }

        asset.transferUnderlyingToken(to, amount.fromWad(asset.underlyingTokenDecimals()));
        emit TransferTipBucket(token, amount, to);
    }

    /**
     * @notice Changes the fee beneficiary. Can only be set by the contract owner.
     * This value cannot be set to 0 to avoid unsettled fee.
     * @param feeTo_ new fee beneficiary
     */
    function setFeeTo(address feeTo_) external onlyOwner {
        _checkAddress(feeTo_);
        feeTo = feeTo_;
        emit SetFeeTo(feeTo_);
    }

    /**
     * @notice Set min fee to mint
     */
    function setMintFeeThreshold(uint256 mintFeeThreshold_) external onlyOwner {
        mintFeeThreshold = mintFeeThreshold_;
        emit SetMintFeeThreshold(mintFeeThreshold_);
    }

    /**
     * @dev pause pool, restricting certain operations
     */
    function pause() external {
        _onlyDev();
        _pause();
    }

    /**
     * @dev unpause pool, enabling certain operations
     */
    function unpause() external {
        _onlyDev();
        _unpause();
    }

    /**
     * @dev pause asset, restricting deposit and swap operations
     */
    function pauseAsset(address token) external {
        _onlyDev();
        _pauseAsset(token);
    }

    /**
     * @dev unpause asset, enabling deposit and swap operations
     */
    function unpauseAsset(address token) external {
        _onlyDev();
        _unpauseAsset(token);
    }

    /**
     * @notice Move fund from tip bucket to the pool to keep r* = 1 as error accumulates
     * unit of amount should be in WAD
     */
    function fillPool(address token, uint256 amount) external {
        _onlyDev();
        IAsset asset = _assetOf(token);
        uint256 tipBucketBal = asset.underlyingTokenBalance().toWad(asset.underlyingTokenDecimals()) -
            asset.cash() -
            _feeCollected[asset];

        if (amount > tipBucketBal) {
            // revert if there's not enough amount in the tip bucket
            revert WOMBAT_INVALID_VALUE();
        }

        asset.addCash(amount);
        emit FillPool(token, amount);
    }

    /* Assets */

    /**
     * @notice Return list of tokens in the pool
     */
    function getTokens() external view override returns (address[] memory) {
        return _assets.keys;
    }

    /**
     * @notice get length of asset list
     * @return the size of the asset list
     */
    function _sizeOfAssetList() internal view returns (uint256) {
        return _assets.keys.length;
    }

    /**
     * @notice Gets asset with token address key
     * @param key The address of token
     * @return the corresponding asset in state
     */
    function _getAsset(address key) internal view returns (IAsset) {
        return _assets.values[key];
    }

    /**
     * @notice Gets key (address) at index
     * @param index the index
     * @return the key of index
     */
    function _getKeyAtIndex(uint256 index) internal view returns (address) {
        return _assets.keys[index];
    }

    /**
     * @notice Looks if the asset is contained by the list
     * @param token The address of token to look for
     * @return bool true if the asset is in asset list, false otherwise
     */
    function _containsAsset(address token) internal view returns (bool) {
        return _assets.values[token] != IAsset(address(0));
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Pool.
     * @param token The address of ERC20 token
     */
    function _assetOf(address token) internal view returns (IAsset) {
        if (!_containsAsset(token)) revert WOMBAT_ASSET_NOT_EXISTS();
        return _assets.values[token];
    }

    /**
     * @notice Gets Asset corresponding to ERC20 token. Reverts if asset does not exists in Pool.
     * @dev to be used externally
     * @param token The address of ERC20 token
     */
    function addressOfAsset(address token) external view override returns (address) {
        return address(_assetOf(token));
    }

    /* Deposit */

    /**
     * @notice Deposits asset in Pool
     * @param asset The asset to be deposited
     * @param amount The amount to be deposited
     * @param to The user accountable for deposit, receiving the Wombat assets (lp)
     * @return liquidity Total asset liquidity minted
     */
    function _deposit(
        IAsset asset,
        uint256 amount,
        uint256 minimumLiquidity,
        address to
    ) internal returns (uint256 liquidity) {
        // collect fee before deposit
        _mintFee(asset);

        uint256 liabilityToMint;
        (liquidity, liabilityToMint, ) = CoreV3.quoteDepositLiquidityInEquil(asset, amount, ampFactor);

        _checkLiquidity(liquidity);
        _checkAmount(minimumLiquidity, liquidity);

        asset.addCash(amount);
        asset.addLiability(liabilityToMint);
        asset.mint(to, liquidity);
    }

    /**
     * @notice Deposits amount of tokens into pool ensuring deadline
     * @dev Asset needs to be created and added to pool before any operation. This function assumes tax free token.
     * @param token The token address to be deposited
     * @param amount The amount to be deposited
     * @param to The user accountable for deposit, receiving the Wombat assets (lp)
     * @param deadline The deadline to be respected
     * @return liquidity Total asset liquidity minted
     */
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external override nonReentrant whenNotPaused returns (uint256 liquidity) {
        if (amount == 0) revert WOMBAT_ZERO_AMOUNT();
        _checkAddress(to);
        _ensure(deadline);
        requireAssetNotPaused(token);

        IAsset asset = _assetOf(token);
        IERC20(token).safeTransferFrom(address(msg.sender), address(asset), amount);

        if (!shouldStake) {
            liquidity = _deposit(asset, amount.toWad(asset.underlyingTokenDecimals()), minimumLiquidity, to);
        } else {
            _checkAddress(masterWombat);
            // deposit and stake on behalf of the user
            liquidity = _deposit(asset, amount.toWad(asset.underlyingTokenDecimals()), minimumLiquidity, address(this));

            asset.approve(masterWombat, liquidity);

            uint256 pid = IMasterWombat(masterWombat).getAssetPid(address(asset));
            IMasterWombat(masterWombat).depositFor(pid, liquidity, to);
        }

        emit Deposit(msg.sender, token, amount, liquidity, to);
    }

    /**
     * @notice Quotes potential deposit from pool
     * @dev To be used by frontend
     * @param token The token to deposit by user
     * @param amount The amount to deposit
     * @return liquidity The potential liquidity user would receive
     * @return reward
     */
    function quotePotentialDeposit(
        address token,
        uint256 amount
    ) external view override returns (uint256 liquidity, uint256 reward) {
        IAsset asset = _assetOf(token);
        (liquidity, , reward) = CoreV3.quoteDepositLiquidityInEquil(
            asset,
            amount.toWad(asset.underlyingTokenDecimals()),
            ampFactor
        );
    }

    /* Withdraw */

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param asset The asset to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @return amount The total amount withdrawn
     */
    function _withdraw(IAsset asset, uint256 liquidity, uint256 minimumAmount) internal returns (uint256 amount) {
        // collect fee before withdraw
        _mintFee(asset);

        // calculate liabilityToBurn and Fee
        uint256 liabilityToBurn;
        (amount, liabilityToBurn, ) = CoreV3.quoteWithdrawAmount(asset, liquidity, ampFactor);
        _checkAmount(minimumAmount, amount);

        asset.burn(address(asset), liquidity);
        asset.removeCash(amount);
        asset.removeLiability(liabilityToBurn);

        // revert if cov ratio < 1% to avoid precision error
        if (asset.liability() > 0 && uint256(asset.cash()).wdiv(asset.liability()) < WAD / 100)
            revert WOMBAT_FORBIDDEN();
    }

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param token The token to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @return amount The total amount withdrawn
     */
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external override nonReentrant whenNotPaused returns (uint256 amount) {
        _checkLiquidity(liquidity);
        _checkAddress(to);
        _ensure(deadline);

        IAsset asset = _assetOf(token);
        // request lp token from user
        IERC20(asset).safeTransferFrom(address(msg.sender), address(asset), liquidity);
        uint8 decimals = asset.underlyingTokenDecimals();
        amount = _withdraw(asset, liquidity, minimumAmount.toWad(decimals)).fromWad(decimals);
        asset.transferUnderlyingToken(to, amount);

        emit Withdraw(msg.sender, token, amount, liquidity, to);
    }

    /**
     * @notice Enables withdrawing liquidity from an asset using LP from a different asset
     * @param fromToken The corresponding token user holds the LP (Asset) from
     * @param toToken The token wanting to be withdrawn (needs to be well covered)
     * @param liquidity The liquidity to be withdrawn (in fromToken decimal)
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @return toAmount The total amount withdrawn
     */
    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external override nonReentrant whenNotPaused returns (uint256 toAmount) {
        _checkAddress(to);
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);
        _ensure(deadline);
        requireAssetNotPaused(fromToken);

        // Withdraw and swap
        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);

        IERC20(fromAsset).safeTransferFrom(address(msg.sender), address(fromAsset), liquidity);
        uint256 fromAmountInWad = _withdraw(fromAsset, liquidity, 0);
        (toAmount, ) = _swap(
            fromAsset,
            toAsset,
            fromAmountInWad,
            minimumAmount.toWad(toAsset.underlyingTokenDecimals())
        );

        toAmount = toAmount.fromWad(toAsset.underlyingTokenDecimals());
        toAsset.transferUnderlyingToken(to, toAmount);

        emit Withdraw(msg.sender, toToken, toAmount, liquidity, to);
    }

    /**
     * @notice Quotes potential withdrawal from pool
     * @dev To be used by frontend
     * @param token The token to be withdrawn by user
     * @param liquidity The liquidity (amount of lp assets) to be withdrawn
     * @return amount The potential amount user would receive
     * @return fee The fee that would be applied
     */
    function quotePotentialWithdraw(
        address token,
        uint256 liquidity
    ) external view override returns (uint256 amount, uint256 fee) {
        _checkLiquidity(liquidity);
        IAsset asset = _assetOf(token);
        (amount, , fee) = CoreV3.quoteWithdrawAmount(asset, liquidity, ampFactor);
        amount = amount.fromWad(asset.underlyingTokenDecimals());
    }

    /**
     * @notice Quotes potential withdrawal from other asset from the pool
     * @dev To be used by frontend
     * @param fromToken The corresponding token user holds the LP (Asset) from
     * @param toToken The token wanting to be withdrawn (needs to be well covered)
     * @param liquidity The liquidity (amount of the lp assets) to be withdrawn
     * @return finalAmount The potential amount user would receive
     * @return withdrewAmount The amount of the from-token that is withdrew
     */
    function quotePotentialWithdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity
    ) external view virtual returns (uint256 finalAmount, uint256 withdrewAmount) {
        _checkLiquidity(liquidity);
        _checkSameAddress(fromToken, toToken);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);
        uint256 scaleFactor = _quoteFactor(fromAsset, toAsset);
        (finalAmount, withdrewAmount) = CoreV3.quoteWithdrawAmountFromOtherAsset(
            fromAsset,
            toAsset,
            liquidity,
            ampFactor,
            scaleFactor,
            haircutRate,
            0,
            0
        );

        withdrewAmount = withdrewAmount.fromWad(fromAsset.underlyingTokenDecimals());
        finalAmount = finalAmount.fromWad(toAsset.underlyingTokenDecimals());
    }

    /* Swap */

    /**
     * @notice Return the scale factor that should applied on from-amounts in a swap given
     * the from-asset and the to-asset.
     * @dev not applicable to a plain pool
     */
    function _quoteFactor(
        IAsset, // fromAsset
        IAsset // toAsset
    ) internal view virtual returns (uint256) {
        // virtual function; do nothing
        return 1e18;
    }

    /**
     * @notice Quotes the actual amount user would receive in a swap, taking in account slippage and haircut
     * @param fromAsset The initial asset
     * @param toAsset The asset wanted by user
     * @param fromAmount The amount to quote
     * @return actualToAmount The actual amount user would receive
     * @return haircut The haircut that will be applied
     */
    function _quoteFrom(
        IAsset fromAsset,
        IAsset toAsset,
        int256 fromAmount
    ) internal view virtual returns (uint256 actualToAmount, uint256 haircut) {
        uint256 scaleFactor = _quoteFactor(fromAsset, toAsset);
        return CoreV3.quoteSwap(fromAsset, toAsset, fromAmount, ampFactor, scaleFactor, haircutRate);
    }

    /**
     * expect fromAmount and minimumToAmount to be in WAD
     */
    function _swap(
        IAsset fromAsset,
        IAsset toAsset,
        uint256 fromAmount,
        uint256 minimumToAmount
    ) internal returns (uint256 actualToAmount, uint256 haircut) {
        (actualToAmount, haircut) = _quoteFrom(fromAsset, toAsset, int256(fromAmount));
        _checkAmount(minimumToAmount, actualToAmount);

        unchecked {
            _feeCollected[toAsset] += haircut;
        }

        fromAsset.addCash(fromAmount);

        // haircut is removed from cash to maintain r* = 1. It is distributed during _mintFee()
        unchecked {
            toAsset.removeCash(actualToAmount + haircut);
        }

        // revert if cov ratio < 1% to avoid precision error
        if (uint256(toAsset.cash()).wdiv(toAsset.liability()) < WAD / 100) revert WOMBAT_FORBIDDEN();
    }

    /**
     * @notice Swap fromToken for toToken, ensures deadline and minimumToAmount and sends quoted amount to `to` address
     * @dev This function assumes tax free token.
     * @param fromToken The token being inserted into Pool by user for swap
     * @param toToken The token wanted by user, leaving the Pool
     * @param fromAmount The amount of from token inserted
     * @param minimumToAmount The minimum amount that will be accepted by user as result
     * @param to The user receiving the result of swap
     * @param deadline The deadline to be respected
     */
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external override nonReentrant whenNotPaused returns (uint256 actualToAmount, uint256 haircut) {
        _checkSameAddress(fromToken, toToken);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();
        _checkAddress(to);
        _ensure(deadline);
        requireAssetNotPaused(fromToken);

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);

        uint8 toDecimal = toAsset.underlyingTokenDecimals();

        (actualToAmount, haircut) = _swap(
            fromAsset,
            toAsset,
            fromAmount.toWad(fromAsset.underlyingTokenDecimals()),
            minimumToAmount.toWad(toDecimal)
        );

        actualToAmount = actualToAmount.fromWad(toDecimal);
        haircut = haircut.fromWad(toDecimal);

        IERC20(fromToken).safeTransferFrom(msg.sender, address(fromAsset), fromAmount);
        toAsset.transferUnderlyingToken(to, actualToAmount);

        emit Swap(msg.sender, fromToken, toToken, fromAmount, actualToAmount, to);
    }

    /**
     * @notice Given an input asset amount and token addresses, calculates the
     * maximum output token amount (accounting for fees and slippage).
     * @dev In reverse quote, the haircut is in the `fromAsset`
     * @param fromToken The initial ERC20 token
     * @param toToken The token wanted by user
     * @param fromAmount The given input amount
     * @return potentialOutcome The potential amount user would receive
     * @return haircut The haircut that would be applied
     */
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) public view override returns (uint256 potentialOutcome, uint256 haircut) {
        _checkSameAddress(fromToken, toToken);
        if (fromAmount == 0) revert WOMBAT_ZERO_AMOUNT();

        IAsset fromAsset = _assetOf(fromToken);
        IAsset toAsset = _assetOf(toToken);

        fromAmount = fromAmount.toWad(fromAsset.underlyingTokenDecimals());
        (potentialOutcome, haircut) = _quoteFrom(fromAsset, toAsset, fromAmount);
        potentialOutcome = potentialOutcome.fromWad(toAsset.underlyingTokenDecimals());
        if (fromAmount >= 0) {
            haircut = haircut.fromWad(toAsset.underlyingTokenDecimals());
        } else {
            haircut = haircut.fromWad(fromAsset.underlyingTokenDecimals());
        }
    }

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * @dev To be used by frontend
     * @param fromToken The initial ERC20 token
     * @param toToken The token wanted by user
     * @param toAmount The given output amount
     * @return amountIn The input amount required
     * @return haircut The haircut that would be applied
     */
    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view override returns (uint256 amountIn, uint256 haircut) {
        return quotePotentialSwap(toToken, fromToken, -toAmount);
    }

    /* Queries */

    /**
     * @notice Returns the exchange rate of the LP token
     * @param token The address of the token
     * @return xr The exchange rate of LP token
     */
    function exchangeRate(address token) external view returns (uint256 xr) {
        IAsset asset = _assetOf(token);
        if (asset.totalSupply() == 0) return WAD;
        return xr = uint256(asset.liability()).wdiv(uint256(asset.totalSupply()));
    }

    function globalEquilCovRatio() external view returns (uint256 equilCovRatio, uint256 invariantInUint) {
        int256 invariant;
        int256 SL;
        (invariant, SL) = _globalInvariantFunc();
        equilCovRatio = uint256(CoreV3.equilCovRatio(invariant, SL, int256(ampFactor)));
        invariantInUint = uint256(invariant);
    }

    function tipBucketBalance(address token) public view returns (uint256 balance) {
        IAsset asset = _assetOf(token);
        unchecked {
            return
                asset.underlyingTokenBalance().toWad(asset.underlyingTokenDecimals()) -
                asset.cash() -
                _feeCollected[asset];
        }
    }

    /* Utils */

    function _globalInvariantFunc() internal view virtual returns (int256 D, int256 SL) {
        int256 A = int256(ampFactor);

        for (uint256 i; i < _sizeOfAssetList(); ++i) {
            IAsset asset = _getAsset(_getKeyAtIndex(i));

            // overflow is unrealistic
            int256 A_i = int256(uint256(asset.cash()));
            int256 L_i = int256(uint256(asset.liability()));

            // Assume when L_i == 0, A_i always == 0
            if (L_i == 0) {
                // avoid division of 0
                continue;
            }

            int256 r_i = A_i.wdiv(L_i);
            SL += L_i;
            D += L_i.wmul(r_i - A.wdiv(r_i));
        }
    }

    /**
     * @notice Private function to send fee collected to the fee beneficiary
     * @param asset The address of the asset to collect fee
     */
    function _mintFee(IAsset asset) internal {
        uint256 feeCollected = _feeCollected[asset];
        if (feeCollected == 0 || feeCollected < mintFeeThreshold) {
            // early return
            return;
        }
        {
            // dividend to veWOM
            uint256 dividend = feeCollected.wmul(WAD - lpDividendRatio - retentionRatio);

            if (dividend > 0) {
                asset.transferUnderlyingToken(feeTo, dividend.fromWad(asset.underlyingTokenDecimals()));
            }
        }
        {
            // dividend to LP
            uint256 lpDividend = feeCollected.wmul(lpDividendRatio);
            if (lpDividend > 0) {
                // exact deposit to maintain r* = 1
                // increase the value of the LP token, i.e. assetsPerShare
                (, uint256 liabilityToMint, ) = CoreV3.quoteDepositLiquidityInEquil(asset, lpDividend, ampFactor);
                asset.addLiability(liabilityToMint);
                asset.addCash(lpDividend);
            }
        }

        _feeCollected[asset] = 0;
    }

    function _mintAllFees() internal {
        for (uint256 i; i < _sizeOfAssetList(); ++i) {
            IAsset asset = _getAsset(_getKeyAtIndex(i));
            _mintFee(asset);
        }
    }

    /**
     * @notice Send fee collected to the fee beneficiary
     * @param token The address of the token to collect fee
     */
    function mintFee(address token) external {
        _mintFee(_assetOf(token));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

/**
 * @dev Interface of the MasterWombat
 */
interface IMasterWombat {
    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(
        uint256 _pid,
        address _user
    )
        external
        view
        returns (
            uint256 pendingRewards,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function rewarderBonusTokenInfo(
        uint256 _pid
    ) external view returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(
        uint256[] memory _pids
    ) external returns (uint256 transfered, uint256[] memory rewards, uint256[] memory additionalRewards);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(uint256 _pid, uint256 _amount, address _user) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;
}