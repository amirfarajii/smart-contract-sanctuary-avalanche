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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

interface IAnyswapRouter {
    function anySwapOut(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external;

    function anySwapOutUnderlying(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ILeechSwapper {
    /**
     * @notice Transfer an amount of the base token to the contract, then swap it for LP token according to the provided `baseToToken0` path.
     * @param amount The amount of base token to transfer.
     * @param lpAddr The address of the liquidity pool to deposit the swapped tokens into.
     * @param baseToToken0 The array of addresses representing the token contracts involved in the swap from the base token to the target token.
     */
    function leechIn(
        uint256 amount,
        address lpAddr,
        address[] memory baseToToken0
    ) external;

    /**
     *@notice Swaps out token from the liquidity pool to underlying base token
     *@param amount The amount of the token to be leeched out from liquidity pool.
     *@param lpAddr Address of the liquidity pool.
     *@param token0toBasePath Path of token0 in the liquidity pool to underlying base token.
     *@param token1toBasePath Path of token1 in the liquidity pool to underlying base token.
     */
    function leechOut(
        uint256 amount,
        address lpAddr,
        address[] memory token0toBasePath,
        address[] memory token1toBasePath
    ) external;

    /**
     * @notice Swap an amount of tokens for an equivalent amount of another token, according to the provided `path` of token contracts.
     * @param amountIn The amount of tokens being swapped.
     * @param path The array of addresses representing the token contracts involved in the swap.
     * @return swapedAmounts The array of amounts in the respective token after the swap.
     */
    function swap(
        uint256 amountIn,
        address[] memory path
    ) external payable returns (uint256[] memory swapedAmounts);
}

interface ILeechTransporter {
    /**
     * @notice This function requires that `leechSwapper` is properly initialized
     * The function first converts `amount` to base token on the target chain
     * The `amount` is then bridged to routerAddress on chain with id `destinationChainId`
     * The `AssetBridged` event is emitted after the bridging is successful
     *
     * @param destinationChainId The ID of the destination chain to send to
     * @param routerAddress The address of the router on the destination chain
     * @param amount The amount of asset to send
     */
    function sendTo(
        uint256 destinationChainId,
        address routerAddress,
        uint256 amount
    ) external;

    /**
     * @notice This function requires that `leechSwapper` is properly initialized
     * @param _destinationToken Address of the asset to be bridged
     * @param _bridgedAmount The amount of asset to send The ID of the destination chain to send to
     * @param _destinationChainId The ID of the destination chain to send to The address of the router on the destination chain
     * @param _destAddress The address on the destination chain
     */
    function bridgeOut(
        address _destinationToken,
        uint256 _bridgedAmount,
        uint256 _destinationChainId,
        address _destAddress
    ) external;

    /// @notice Emitted after successful bridging
    /// @param chainId Destination chain id
    /// @param routerAddress Destanation router address
    /// @param amount Amount of the underlying token
    event AssetBridged(uint256 chainId, address routerAddress, uint256 amount);

    /// @notice Emitted after initializing router
    /// @param anyswapV4Router address of v4 multichain router
    /// @param anyswapV6Router address of v6 multichain router
    /// @param multichainV7Router address of v7 multichain router
    /// @param leechSwapper address of the leechSwapper contract
    event Initialized(
        address anyswapV4Router,
        address anyswapV6Router,
        address multichainV7Router,
        address leechSwapper
    );
}

interface IMultichainV7Router {
    function anySwapOut(
        address token,
        string calldata to,
        uint256 amount,
        uint256 toChainID
    ) external;

    function anySwapOutUnderlying(
        address token,
        string calldata to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.17;

import "./interfaces/IAnyswapRouter.sol";
import "./interfaces/IMultichainV7Router.sol";
import "./interfaces/ILeechTransporter.sol";
import "./interfaces/ILeechSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LeechTransporter is Ownable, ILeechTransporter {
    using SafeERC20 for IERC20;

    /**
    @notice Current EVM Chain Id
    */
    uint256 public immutable chainID;

    /**
    @notice Mapping for storing base tokens on different chains
    */
    mapping(uint256 => address) public chainToBaseToken;

    /**
    @notice Anyswap has a multiple versions of router live. So we need to define it for each token
    */
    mapping(address => uint256) public destinationTokenToRouterId;

    mapping(address => address) public destinationTokenToAnyToken;

    /**
    @notice Multichain router instances
    */
    IAnyswapRouter public anyswapV4Router = IAnyswapRouter(address(0));
    IAnyswapRouter public anyswapV6Router = IAnyswapRouter(address(0));
    IMultichainV7Router public multichainV7Router =
        IMultichainV7Router(address(0));

    /**
    @notice LeechSwapper contract instance
    */
    ILeechSwapper public swapper;

    /**
     * The constructor sets the `chainID` variable to the current chain ID
     *
     * @dev The `chainid()` opcode is used to get the chain ID of the current network
     * The resulting value is stored in the `chainID` variable for later use in the contract
     */
    constructor() {
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainID = _chainId;
    }

    /**
     * @notice This function requires that `swapper` is properly initialized
     * The function first converts `amount` to base token on the target chain
     * The `amount` is then bridged to destAddress on chain with id `destinationChainId`
     * The `AssetBridged` event is emitted after the bridging is successful
     *
     * @param destinationChainId The ID of the destination chain to send to
     * @param destAddress The address of the router on the destination chain
     * @param amount The amount of asset to send
     */
    function sendTo(
        uint256 destinationChainId,
        address destAddress,
        uint256 amount
    ) external override {
        if (address(swapper) == address(0)) revert("Init swapper");
        if (destAddress == address(0)) revert("Wrong argument");
        if (amount == 0) revert("Wrong argument");

        address[] memory path = new address[](2);

        path[0] = chainToBaseToken[chainID];
        path[1] = chainToBaseToken[destinationChainId];

        if (path[0] != path[1]) {
            _approveTokenIfNeeded(path[0], address(swapper));

            uint256[] memory swapedAmounts = swapper.swap(amount, path);
            uint256 amount = swapedAmounts[swapedAmounts.length - 1];
        }

        bridgeOut(path[1], amount, destinationChainId, destAddress);

        emit AssetBridged(destinationChainId, destAddress, amount);
    }

    /**
     * @notice Initializes the instance with the router addresses and the leech swapper contract address
     * @dev We don't apply zero address validation because not all versions could be active on the current chain
     * @param _anyswapV4Router Address of the AnySwap V4 router contract
     * @param _anyswapV6Router Address of the AnySwap V6 router contract
     * @param _multichainV7Router Address of the Multi-chain V7 router contract
     * @param _swapper Address of the leech swapper contract
     */
    function initTransporter(
        address _anyswapV4Router,
        address _anyswapV6Router,
        address _multichainV7Router,
        address _swapper
    ) external onlyOwner {
        anyswapV4Router = IAnyswapRouter(_anyswapV4Router);
        anyswapV6Router = IAnyswapRouter(_anyswapV6Router);
        multichainV7Router = IMultichainV7Router(_multichainV7Router);
        swapper = ILeechSwapper(_swapper);

        emit Initialized(
            _anyswapV4Router,
            _anyswapV6Router,
            _multichainV7Router,
            _swapper
        );
    }

    /**
     * Sets the base token for a given chain ID
     *
     * @notice This function is restricted to the contract owner only and can be executed using the `onlyOwner` modifier
     * The function maps the given `chainId` to its corresponding base token `tokenAddress`
     * and stores it in the `chainToBaseToken` mapping
     * @param chainId destination EVM chain Id
     * @param tokenAddress base token address on the destination chain
     */
    function setBaseToken(
        uint256 chainId,
        address tokenAddress
    ) external onlyOwner {
        if (chainId == 0 || tokenAddress == address(0))
            revert("Wrong argument");
        chainToBaseToken[chainId] = tokenAddress;
    }

    /**
     * Sets the router ID for a given token address
     *
     * @notice This function is restricted to the contract owner only and can be executed using the `onlyOwner` modifier
     * The function maps the given `tokenAddress` to its corresponding router ID `routerId`
     * and stores it in the `destinationTokenToRouterId` mapping
     * @param tokenAddress base token address on the destination chain
     * @param routerId id of the multichain router that should be used
     */
    function setRouterIdForToken(
        address tokenAddress,
        uint256 routerId
    ) external onlyOwner {
        if (routerId == 0 || tokenAddress == address(0))
            revert("Wrong argument");
        destinationTokenToRouterId[tokenAddress] = routerId;
    }

    function setAnyToken(
        address tokenAddress,
        address anyTokenAddress
    ) external onlyOwner {
        destinationTokenToAnyToken[tokenAddress] = anyTokenAddress;
    }

    /**
     * @dev Transfers the specified amount of a token to the specified destination token on another chain
     * @param _destinationToken Address of the destination token on the other chain
     * @param _bridgedAmount Amount of the source token to transfer
     * @param _destinationChainId ID of the destination chain
     * @param _destAddress Address of the router contract responsible for handling the transfer
     */
    function bridgeOut(
        address _destinationToken,
        uint256 _bridgedAmount,
        uint256 _destinationChainId,
        address _destAddress
    ) public {
        uint256 routerId = destinationTokenToRouterId[_destinationToken];

        if (routerId == 1) {
            if (address(anyswapV4Router) == address(0)) revert("Init router");

            _approveTokenIfNeeded(_destinationToken, address(anyswapV4Router));
            anyswapV4Router.anySwapOutUnderlying(
                destinationTokenToAnyToken[_destinationToken],
                _destAddress,
                _bridgedAmount,
                _destinationChainId
            );

            return;
        }

        if (routerId == 2) {
            if (address(anyswapV6Router) == address(0)) revert("Init router");

            _approveTokenIfNeeded(_destinationToken, address(anyswapV6Router));
            anyswapV6Router.anySwapOutUnderlying(
                destinationTokenToAnyToken[_destinationToken],
                _destAddress,
                _bridgedAmount,
                _destinationChainId
            );

            return;
        }

        if (routerId == 3) {
            if (address(multichainV7Router) == address(0))
                revert("Init router");

            _approveTokenIfNeeded(_destinationToken, address(multichainV7Router));
            string memory routerAddressStringify = _toAsciiString(_destAddress);
            multichainV7Router.anySwapOutUnderlying(
                destinationTokenToAnyToken[_destinationToken],
                routerAddressStringify,
                _bridgedAmount,
                _destinationChainId
            );

            return;
        }

        revert("No router inited");
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }


    /**
     * @dev Converts an Ethereum address to its corresponding ASCII string representation
     * @param x Ethereum address
     * @return ASCII string representation of the address
     */
    function _toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(s);
    }

    /**
     * @dev Converts a hexadecimal character represented as a byte to its corresponding ASCII character
     * @param b Hexadecimal character represented as a byte
     * @return c ASCII character represented as a byte
     */
    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}