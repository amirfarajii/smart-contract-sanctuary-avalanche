/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./CheemsxNFT.sol";

// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}




// 
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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
}

// 
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
    * @dev Burn `amount` tokens and decreasing the total supply.
    */
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }


    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
        );
        return true;
    }

  

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual{
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

  

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
}


contract StakeCheemsX {
    
    using SafeMath for uint256;
    
    event TransferOwnership(address oldOwner, address newOwner);
    
    event SetTestMode();
    event SetRealMode();

    event Deposit(address indexed user, uint256 amount, uint depositType);
    
    event Withdraw(address indexed user, uint256 amount);
    
    event Harvest(address indexed user, uint indexed depositType, uint256 amount);

    event Burn(uint256 amount);

    event SwapTokensForAVAX(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForUSDC(
        uint256 amountIn,
        address[] path
    );

    // Stacking with No lock
    struct DepositInfo {
        uint256 amount;        // How many tokens the user has deposited.
        uint256 depositTime;        // Deposit Time
        uint256 rewardLockedUp;     // Reward locked up.
        uint256 nextHarvestUntil;   // When can the user harvest again.
        uint256 lockedTime;         // Lock Time
    }

    // Info of each user.
    struct UserInfo {
        uint256 totalAmount;        // How many tokens the user has deposited.
        uint256 lastDepositTime;    // Last Deposit Time
    }

    // CheemsX
    ERC20 public cheemsX;

    // CheemsX NFT
    CheemsxNFT public cheemsxNFT;

    // Reward Token
    ERC20 public usdc;

    IJoeRouter public router;
    address public pair;
    
    address public owner;
    address public treasuryWallet;

    // Reward Pool Balance
    uint256 public rewardPoolBalance = 10000000000;

    // ThresholdMinimum Value
    uint256 public thresholdMinimum = 200000000000;

    // Reward Factor
    uint[] public x = [1, 2, 3, 4, 5, 10];

    // Locked Duration
    uint256[] public lockedDuration = [0 days, 30 days, 90 days, 180 days, 365 days, 0 days];

    // Reward Cycle
    uint256 public intervaLTime = 1 days;

    // Distribution Period
    uint256 public distributionPeriod = 10;

    // Total Deposit Amount
    uint256 public totalDepositAmount;

    // DepositInfo[] public userDepositInfo;
    
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    mapping(address => DepositInfo[]) public depositInfo;

    constructor(address _treasuryWallet) {
        owner = msg.sender;
        treasuryWallet = _treasuryWallet;
    }

    // Test Mode
    function setTestMode() public onlyOwner {
        cheemsX = ERC20(0x65CF1241F6d891346263a3F3EE5096a5527C90Af);
        cheemsxNFT = CheemsxNFT(0x28472A25Cf81B8c7084EAE700e23dA4b143B2Bc9);
        usdc = ERC20(0x27df2084435545386bdAB289C53644A63B520982);
        IJoeRouter _newJoeRouter = IJoeRouter(0x2D99ABD9008Dc933ff5c0CD271B88309593aB921);
        thresholdMinimum = 1;
        pair = IJoeFactory(_newJoeRouter.factory()).createPair(address(this), _newJoeRouter.WAVAX());
        router = _newJoeRouter;
        emit SetTestMode();
    }

    // Real Mode
    function setRealMode() public onlyOwner {
        cheemsX = ERC20(0x726573a7774317DD108ACcb2720Ac9848581F01D);
        cheemsxNFT = CheemsxNFT(0x28472A25Cf81B8c7084EAE700e23dA4b143B2Bc9);
        usdc = ERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
        IJoeRouter _newJoeRouter = IJoeRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        thresholdMinimum = 200000000000;
        pair = IJoeFactory(_newJoeRouter.factory()).createPair(address(this), _newJoeRouter.WAVAX());
        router = _newJoeRouter;
        emit SetRealMode();
    }
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /**
    Deposit
     type: 0 - staking with no lock
     type: 1 - 1 month
     type: 2 - 3 months
     type: 3 - 6 month
     type: 4 - 12 months
     type: 5 - Irreversible lock
    */ 
    function deposit(uint256 _amount, uint depositType) public {
        require(_amount > 0 && _amount > thresholdMinimum, "Invalid amount for staking");

        UserInfo storage user = userInfo[msg.sender];
        DepositInfo[] storage userDeposit = depositInfo[msg.sender];

        // initialize deposit info struct array
        if(userDeposit.length == 0) {
            for(uint i = 0; i < 6; i++) {
                userDeposit.push(DepositInfo({
                    amount: 0,
                    depositTime: 0,
                    rewardLockedUp: 0,     // Reward locked up.
                    nextHarvestUntil: 0,   // When can the user harvest again.
                    lockedTime: 0         // Lock Time
                }));
            }
        }

        if (_amount > 0) {
            cheemsX.transferFrom(address(msg.sender), address(this), _amount);
            user.lastDepositTime = block.timestamp;
            user.totalAmount = user.totalAmount.add(_amount);
            totalDepositAmount = totalDepositAmount.add(_amount);

            userDeposit[depositType].amount += _amount;
            userDeposit[depositType].depositTime = block.timestamp;
            userDeposit[depositType].lockedTime = block.timestamp + lockedDuration[depositType];

            if(depositType == 5) {
                cheemsxNFT.createToken(msg.sender, _amount);
                burnToken(_amount.mul(300).div(1000));
                swapTokensForAVAX(_amount.mul(200).div(1000));
                swapTokensForUSDC(_amount.mul(200).div(1000));
            }
        }
        
        emit Deposit(msg.sender, _amount, depositType);
    }

    function burnToken(uint256 amount) internal {
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        cheemsX.transfer(deadAddress, amount);
        emit Burn(amount);
    }

    function swapTokensForAVAX(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(cheemsX);
        path[1] = router.WAVAX();

        cheemsX.approve(address(router), tokenAmount);
        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            treasuryWallet,
            block.timestamp
        );
        
        emit SwapTokensForAVAX(tokenAmount, path);
    }

    function swapTokensForUSDC(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(cheemsX);
        path[1] = address(usdc);

        cheemsX.approve(address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            treasuryWallet,
            block.timestamp
        );
        
        emit SwapTokensForUSDC(tokenAmount, path);
    }


    
    // Withdraw Token by Deposit Type
    function withdraw(uint256 _amount, uint depositType) public {
        
        UserInfo storage user = userInfo[msg.sender];
        DepositInfo[] storage userDeposit = depositInfo[msg.sender];

        require(_amount > 0, "Can not withdraw zero amount");
        require(userDeposit[depositType].amount > _amount, "Invalid withdraw amount");

        if (_amount > 0 && canWithdraw(msg.sender, depositType)) {
            cheemsX.transfer(msg.sender, _amount);
            userDeposit[depositType].amount = userDeposit[depositType].amount.sub(_amount);
            user.totalAmount = user.totalAmount.sub(_amount);
        }

        emit Withdraw(msg.sender, _amount);
    }

    // View function to see if user can withdraw reward
    function canWithdraw(address _user, uint depositType) public view returns (bool) {
        // UserInfo storage user = userInfo[_user];
        DepositInfo[] storage userDeposit = depositInfo[_user];
        return block.timestamp > userDeposit[depositType].lockedTime && userDeposit[depositType].amount > 0 && depositType < 5;
    }
    
    event pendingAmount(uint256);
     
    // Harvest by Deposit Type
    function harvest(uint depositType) public {
         UserInfo storage user = userInfo[msg.sender];
        DepositInfo[] storage userDeposit = depositInfo[msg.sender];
        uint256 pending = 0;
        uint256 pendingDate = 0;

        if(canHarvest(msg.sender, depositType)) {
            if(userDeposit[depositType].nextHarvestUntil == 0) {
                pendingDate = (block.timestamp - userDeposit[depositType].depositTime).div(intervaLTime).add(1);
            } else {
                pendingDate = (block.timestamp - userDeposit[depositType].nextHarvestUntil).div(intervaLTime).add(1);
            }
            uint256 percentage = userDeposit[depositType].amount.mul(100).div(user.totalAmount);
            uint256 dailyPending = rewardPoolBalance.div(distributionPeriod).mul(percentage).div(100).mul(x[depositType]);
            pending = pendingDate.mul(dailyPending);
        }

        if (pending > 0) {
            userDeposit[depositType].nextHarvestUntil = block.timestamp.add(intervaLTime);
            // send rewards
            safeRewards(msg.sender, pending);
        }

        if (userDeposit[depositType].nextHarvestUntil == 0) {
            userDeposit[depositType].nextHarvestUntil = block.timestamp.add(intervaLTime);
        }

        emit Harvest(msg.sender, depositType, pending);
    }

    // Harvest
    function harvest() public {
        UserInfo storage user = userInfo[msg.sender];
        DepositInfo[] storage userDeposit = depositInfo[msg.sender];
        uint256 pending = 0;
        uint256 totalPending = 0;
        uint pendingDate = 0;

        for(uint depositType = 0; depositType < 6; depositType++) {
            if(canHarvest(msg.sender, depositType)) {
                if(userDeposit[depositType].nextHarvestUntil == 0) {
                    pendingDate = (block.timestamp - userDeposit[depositType].depositTime).div(intervaLTime).add(1);
                } else {
                    pendingDate = (block.timestamp - userDeposit[depositType].nextHarvestUntil).div(intervaLTime).add(1);
                }
                uint256 percentage = userDeposit[depositType].amount.mul(100).div(user.totalAmount);
                uint256 dailyPending = rewardPoolBalance.div(distributionPeriod).mul(percentage).div(100).mul(x[depositType]);
                pending = pendingDate.mul(dailyPending);
            }

            if (pending > 0) {
                userDeposit[depositType].nextHarvestUntil = block.timestamp.add(intervaLTime);
                totalPending += pending;
            }

            if (userDeposit[depositType].nextHarvestUntil == 0) {
                userDeposit[depositType].nextHarvestUntil = block.timestamp.add(intervaLTime);
            }
        }

        if(totalPending > 0)
            safeRewards(msg.sender, totalPending);  
       
        emit Harvest(msg.sender, 999, totalPending); // 999: Harvest All
    }
    
    // send reward
    function safeRewards(address _to, uint256 _amount) internal {
        uint256 rewardTokenBal = cheemsX.balanceOf(address(this));
        uint256 calcRewardAmount = _amount.mul(cheemsX.decimals());
        if (calcRewardAmount > rewardTokenBal) {
            cheemsX.transfer(_to, rewardTokenBal);
        } else {
            cheemsX.transfer(_to, calcRewardAmount);
        }
    }
    
    // View function to see if user can harvest reward
    function canHarvest(address _user, uint depositType) public view returns (bool) {
        // UserInfo storage user = userInfo[_user];
        DepositInfo[] storage userDeposit = depositInfo[_user];
        uint256 rewardDate = (block.timestamp - userDeposit[depositType].depositTime).div(1 days);

        return  (block.timestamp >= userDeposit[depositType].nextHarvestUntil && rewardDate < distributionPeriod);
    }

    // View function to see pending reward by type on frontend.
    function pendingTokenByType(address _user, uint depositType) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        DepositInfo[] storage userDeposit = depositInfo[_user];
        uint256 pending = 0;
        uint256 pendingDate = 0;

        if(canHarvest(msg.sender, depositType)) {
            if(userDeposit[depositType].nextHarvestUntil == 0) {
                pendingDate = (block.timestamp - userDeposit[depositType].depositTime).div(intervaLTime).add(1);
            } else {
                pendingDate = (block.timestamp - userDeposit[depositType].nextHarvestUntil).div(intervaLTime).add(1);
            }
            uint256 percentage = userDeposit[depositType].amount.mul(100).div(user.totalAmount);
            uint256 dailyPending = rewardPoolBalance.div(distributionPeriod).mul(percentage).div(100).mul(x[depositType]);
            pending = pendingDate.mul(dailyPending);
        }
        return pending;
    }

    // View function to see pending reward on frontend.
    function pendingToken(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        DepositInfo[] storage userDeposit = depositInfo[_user];
        uint256 pending = 0;
        uint256 pendingDate = 0;

        uint256 totalPending = 0;

        for(uint depositType = 0; depositType < 6; depositType++) {
            if(canHarvest(msg.sender, depositType)) {
                if(userDeposit[depositType].nextHarvestUntil == 0) {
                    pendingDate = (block.timestamp - userDeposit[depositType].depositTime).div(intervaLTime).add(1);
                } else {
                    pendingDate = (block.timestamp - userDeposit[depositType].nextHarvestUntil).div(intervaLTime).add(1);
                }
                uint256 percentage = userDeposit[depositType].amount.mul(100).div(user.totalAmount);
                uint256 dailyPending = rewardPoolBalance.div(distributionPeriod).mul(percentage).div(100).mul(x[depositType]);
                pending = pendingDate.mul(dailyPending);
            }
            totalPending += pending;
        }
        return totalPending;
    }
   
    // Transfer OwnerShip
    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
        emit TransferOwnership(msg.sender, newOwner);
    }

    // Withdraw Token For Emergency
    function withdrawTokenForEmergency(ERC20 _ERC20, address destination, uint256 amount) external onlyOwner{
        if(amount > _ERC20.balanceOf(address(this)))
            amount = _ERC20.balanceOf(address(this));
        _ERC20.transfer(destination, amount);
    }

    // Withdraw AVAX For Emergency
    function withdrawAvaxForEmergency(address destination, uint256 amount) external onlyOwner{
        if(amount > address(this).balance)
            amount = address(this).balance;
        payable(destination).transfer(amount);
    }
      
    // update cheemsX
    function updateCheemsX(ERC20 _cheemsX) public onlyOwner{
        cheemsX = _cheemsX;
    }
    
    // update reward cycle
    function updateIntervaLTime (uint256 _rewardCycle) public onlyOwner{
        intervaLTime = _rewardCycle;
    }

    // update treasury wallet
    function updateTreasuryWallet (address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    // update reward factor x
    function updateRewardFactor (uint[] memory _x) external onlyOwner {
        x = _x;
    }

    // udpate reward pool balance
    function udpateRewardPoolBalance (uint256 _rewardPoolBalance) external onlyOwner {
        rewardPoolBalance = _rewardPoolBalance;
    }

    // udpate distribution period
    function updateDistributionPeriod (uint256 _distributionPeriod) external onlyOwner {
        distributionPeriod = _distributionPeriod;
    }
    
}