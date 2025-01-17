// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "../FractBaseStrategy.sol";
import "../interfaces/gmx/IGlpManager.sol";
import "../interfaces/gmx/IRewardRouter.sol";
import "../interfaces/gmx/IVester.sol";

contract FractGmxAvax is FractBaseStrategy {
    using SafeERC20 for IERC20;

    //reward router
    address constant REWARD_ROUTER = 0x82147C5A7E850eA4E28155DF107F2590fD4ba327;
    //glp manager
    address constant GLP_MANAGER = 0xe1ae4d4b06A5Fe1fc288f6B4CD72f9F8323B107F;
    //glp vester
    address constant GLP_VESTER = 0x62331A7Bd1dfB3A7642B7db50B5509E57CA3154A;
    //glp token
    address constant GLP = 0x01234181085565ed162a948b6a5e88758CD7c7b8;
    //wavax token
    address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    //usdc
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    //gmx
    address constant GMX = 0x62edc0692BD897D2295872a9FFCac5425011c661;
    //esgmx
    address constant ESGMX = 0xFf1489227BbAAC61a9209A08929E4c2a526DdD17;
    //price precision for glp
    uint256 constant PRICE_PRECISION = 1000000000000000000000000000000;

    /**
     * @notice Function to run approvals for all tokens and spenders.
     * @dev Used to save gas instead of approving everytime we run a transaction
     */
    function runApprovals() public onlyOwner{
        IERC20(USDC).approve(GLP_MANAGER, type(uint256).max);
        IERC20(USDC).approve(REWARD_ROUTER, type(uint256).max);
        IERC20(WAVAX).approve(TOKENTRANSFERPROXY, type(uint256).max);
        IERC20(GMX).approve(TOKENTRANSFERPROXY, type(uint256).max);
        IERC20(ESGMX).approve(GLP_VESTER, type(uint256).max);
    }
        
    /*///////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/


    /**
     * @notice Withdraw from the strategy. Send to owner of Contract. 
     * @param depositToken token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdrawToOwner(address depositToken, uint256 amount) public onlyController
    {
        require(amount > 0, "0 amount");

        address owner = owner();

        IERC20(depositToken).safeTransfer(owner, amount);
    }

    /**
     * @notice Deposit USDC into GMX to receive GLP.
     * @param amount Amount of USDC to deposit.
     * @param minGlpAmount Minimum amount of GLP to receive upon staking. Calculated offchain.
     */
    function depositGlp(uint256 amount, uint256 minGlpAmount) public  onlyController
    {
        require(amount > 0, '0 Amount');

        IRewardRouter(REWARD_ROUTER).mintAndStakeGlp(USDC, amount, 0, minGlpAmount);

    }

    /**
     * @notice Withdraw USDC from GMX.
     * @param amount Amount of USDC to deposit.
     * @param minUsdcAmount Minimum amount of USDC to receive upon withdrawing. Calculated offchain.
     */
    function withdrawGlp(uint256 amount, uint256 minUsdcAmount) public  onlyController
    {

        require(amount > 0, '0 Amount');

        IRewardRouter(REWARD_ROUTER).unstakeAndRedeemGlp(USDC, amount, minUsdcAmount, address(this));

    }

    /**
     * @notice Deposit esGMX. 
     */
    function depositEsGmx() public onlyController
    {

        uint256 esGmxBalance = IERC20(ESGMX).balanceOf(address(this));

        IVester(GLP_VESTER).deposit(esGmxBalance);

    }

    function withdrawEsGmx() public onlyController
    {
       IVester(GLP_VESTER).withdraw();
    }

    /*///////////////////////////////////////////////////////////////
                        HARVEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getRewards() public onlyController {
        IRewardRouter(REWARD_ROUTER).handleRewards(
            true,
            false,
            true,
            false,
            false,
            true,
            false
        );
    }
    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get current price of GLP.
     */ 
    function getCurrentGlpPrice() public view returns (uint256) 
    {
        uint256 currentGlpPrice = IGlpManager(GLP_MANAGER).getAumInUsdg(true) * ONE_ETHER / IERC20(GLP).totalSupply();

        return currentGlpPrice;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./lib/openzeppelin/Ownable.sol";
import "./lib/openzeppelin/IERC20.sol";
import "./lib/openzeppelin/SafeERC20.sol";

/**
 * @notice FractBaseStrategy should be inherited by new strategies.
 */

abstract contract FractBaseStrategy is Ownable {
    using SafeERC20 for IERC20;

    // Fractal Vault address;
    address internal fractVault;

    //controller address used to call specific functions offchain.
    address internal controller;

    //paraswap swapper contract
    address constant PARASWAP = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    //token transfer proxy
    address constant TOKENTRANSFERPROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;
    
    // Constant used as a bips divisor. 
    uint256 constant BIPS_DIVISOR = 10000;

    // Constant for scaling values.
    uint256 constant ONE_ETHER = 10**18;

    /**
     * @notice This event is fired when the strategy receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address indexed account, uint amount);

    /**
     * @notice This event is fired when the strategy receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address indexed account, uint amount);

    /**
     * @notice This event is fired when tokens are withdrawn to an EOA.
     * @param token Specifies the token that was recovered.
     * @param amount Specifies the amount that was recovered.
     */
    event WithdrawToEoa(address token, uint amount);

    /**
     * @notice This event is fired when the vault contract address is set. 
     * @param vaultAddress Specifies the address of the fractVault. 
     */
    event SetVault(address indexed vaultAddress);
    
    /**
     * @notice Only called by vault
     */
    modifier onlyVault() {
        require(msg.sender == fractVault, "Only Vault");
        _;
    }

    /**
     * @notice Only called by controller
     */
    modifier onlyController() {
        require(msg.sender == controller, "Only Controller");
        _;
    }


    /**
     * @notice Sets the vault address the strategy will receive deposits from. 
     * @param controllerAddress Specifies the address of the poolContract. 
     */
    function setControllerAddress(address controllerAddress) external onlyOwner {
        controller = controllerAddress;
    }

    /**
     * @notice Sets the vault address the strategy will receive deposits from. 
     * @param vaultAddress Specifies the address of the poolContract. 
     */
    function setVaultAddress(address vaultAddress) external onlyOwner {
        fractVault = vaultAddress;
        emit SetVault(fractVault);

    }
    
    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0), "Revoke Failed");
    }

    /**
     * @notice Deposit into the strategy. 
     * @param depositToken token to deposit.
     * @param amount amount of tokens to deposit.
     */

    function deposit(address depositToken, uint256 amount) public onlyOwner
    {
        emit Deposit(msg.sender, amount);

        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Withdraw from the strategy. 
     * @param depositToken token to withdraw.
     * @param amount amount of tokens to withdraw.
     */
    function withdraw(address depositToken, uint256 amount) public onlyOwner
    {
        emit Withdraw(msg.sender, amount);

        IERC20(depositToken).safeTransfer(msg.sender, amount);
    }


    /**
     * @notice Swap rewards via the paraswap router. 
     * @param callData The callData to pass to the paraswap router. Generated offchain.
     */
    function swap(bytes memory callData) public payable onlyController
    {
        (bool success,) = PARASWAP.call(callData);

        require(success, "swap failed");  
    }
    
    /**
     * @notice Withdraw ERC20 from contract to EOA
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function withdrawToEoa(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        emit WithdrawToEoa(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "Withdraw Failed"); 
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IGlpManager {
    function getAum(bool) external view returns (uint256);
    function getAumInUsdg(bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewardRouter {

    function mintAndStakeGlp(
        address _token, 
        uint256 _amount, 
        uint256 _minUsdg, 
        uint256 _minGlp
    ) external returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function unstakeAndRedeemGlp(
        address _tokenOut, 
        uint256 _glpAmount, 
        uint256 _minOut, 
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IVester {
    function deposit(uint256 pglAmount) external;
    function withdraw() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.10;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.10;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.10;

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