/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-04
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-03
*/

// SPDX-License-Identifier: (Unlicense)
// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
pragma solidity ^0.8.0;
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
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
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    
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

pragma solidity ^0.8.0;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    
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
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
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
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
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
pragma solidity ^0.8.0;
interface INodeManager {
    function getMinPrice() external view returns (uint256);
    function compileVars(address _account,uint256[3] memory tier) external;
    function createNode(address account, string memory nodeName) external;
    function getNodeReward(address _account, uint256 i) external view returns (uint256);
    function getAllNodesRewards(address _account) external view returns (uint256);
    function cashoutNodeReward(address account, uint256 i) external;
    function cashoutAllNodesRewards(address _account) external;
    function transferOwnership(address newOwner) external;
}
// File: @openzeppelin/contracts/utils/Address.sol
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
pragma solidity ^0.8.0;
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
// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity ^0.8.0;
interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
}
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;
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


pragma solidity ^0.8.0;
interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
pragma solidity >=0.6.2;
interface IJoeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;
interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.8.0;
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC165/IERC165.sol)
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)
pragma solidity ^0.8.0;
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

abstract contract over_og is Context {
    function getTokenPrice() public view returns(uint) {}
    function getNFTdata(address _account) public view returns (uint256[3] memory) {}
}
pragma solidity ^0.8.0;
contract beta_main is ERC20, Ownable {
    using SafeMath for uint256;
    address public joePair;
    address public joeRouterAddress = 0xeBA911B6378f1308CB4295F6b8575a1EB1414E38; // TraderJoe Router
    address public teamPool; 
    address public rewardsPool;
    address public treasury;
    address public NftStakingWallet;
    //NFTs

    
    //Fees will be .div(100)
    uint256 public swapTokensAmount;
    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public teamPoolFee;
    uint256 public cashoutFee;
    uint256 public treasuryFee;
    uint256 public supply;
    address public Mars;
    address public _nodeManager;
    address overseer;
    over_og _overseer =  over_og(overseer);
    uint public Zero = 0;
    uint256[] public feeTook;
    uint256[] public tier;
    uint256 public _totalSupply;
    address[] public structs;
    uint256[] public rndm_ls;
    uint256[] public rndm_ls2;
    uint256[] public rndm_ls3;
    uint256 public nodeAmount = 10;
    uint i;
    uint j;
    uint256 private rwSwap;
    
    uint256 public totalClaimed = 0;
    
    //bools
    bool public isTradingEnabled = true;
    bool public swapLiquifyEnabled = true;
    bool private swapping = false;
    //interfaces
    IJoeRouter02 private joeRouter;
    INodeManager private nodeManager;
    struct AllFees {address accounts;
    		   uint256 nodes;
    		   uint256 rewards;
    		   uint256 team;
    		   uint256 treasury;
    		   uint256 nft;
    		   uint256 transfer;
    		   uint256 _boost;
    		   uint256 cashout;
    		   }
     struct TXNs { uint256 reward;
    		   uint256 team;
    		   uint256 treasury;
    		   uint256 mars;
    		   }
    //mapping
    mapping(address => AllFees) public allFees;
    address[] public allfees;

    mapping(address => bool) public isBlacklisted;
    mapping(uint256 => TXNs) public TXns;
    uint256[] public Txns;
    
    //events
    event UpdateJoeRouter(
        address indexed newAddress,
        address indexed oldAddress
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event Cashout(
        address indexed account,
        uint256 amount,
        uint256 indexed blockTime
    );
    constructor(
        address[] memory addresses,
        uint256[] memory fees,
        uint256 rachet,
        uint256 _nodeAmount
        
    )
        ERC20("main", "BBN")

    {

        require(
            addresses[0] != address(0) && addresses[1] != address(0) && addresses[2] != address(0),
            "CONSTR:1"
        );
        treasury = addresses[0];
        teamPool = addresses[1];
        rewardsPool = addresses[2];
        Mars = addresses[3];
        overseer = addresses[4];
        _nodeManager = addresses[5];
        nodeManager = INodeManager(_nodeManager);
        require(joeRouterAddress != address(0), "CONSTR:2");
        IJoeRouter02 _joeRouter = IJoeRouter02(joeRouterAddress);
        
        address _joePair = IJoeFactory(_joeRouter.factory())
        .createPair(address(this), _joeRouter.WETH());
        joeRouter = _joeRouter;
        joePair = _joePair;
        
        require(
            fees[0] != 0 && fees[1] != 0 && fees[2] != 0 && fees[3] != 0,
            "CONSTR:3"
        );
        teamPoolFee = fees[0];
        rewardsFee = fees[1];
        treasuryFee = fees[2];
        liquidityPoolFee = fees[3];
        cashoutFee = fees[4];
        rwSwap = fees[5];
        nodeAmount = _nodeAmount*(10**18);
        _totalSupply =  rachet*(10**18);
	_mint(address(this), doPercentage(_totalSupply,uint256(50)));
    }
    function makemoney() public {
    	_mint(owner(),doPercentage(_totalSupply,uint256(20)));
	_mint(treasury,doPercentage(_totalSupply,uint256(10)));
	_mint(rewardsPool,doPercentage(_totalSupply,uint256(10)));
	}
    function _transfer(address from,address to,uint256 amount) internal override {
        require(!isBlacklisted[from] && !isBlacklisted[to],"BLACKLISTED");
        require(from != address(0), "ERC20:1");
        require(to != address(0), "ERC20:2");
        if (from != owner() && to != joePair && to != address(joeRouter) && to != address(this) && from != address(this)) {
            require(isTradingEnabled, "TRADING_DISABLED");
        }
        Send_it(from, to, amount);
    }
    function logFees(uint256 _rewardsPoolFee, uint256 _TreasuryFee, uint256 _teamFee, uint256 _transferFee, uint256 _NFTFee,uint256 _cashoutFee, address _account, uint256 _rewards) private {
    	structs = [_account,owner()];
    	uint256 allfees_ = 0;
    	for(i = 0; i < 2; i++) {
		AllFees storage all = allFees[structs[i]];
		allfees_ = 0;
		rndm_ls2 = [_rewardsPoolFee,_TreasuryFee,_teamFee,_transferFee,_NFTFee,_cashoutFee];
		rndm_ls = [all.transfer,all.team,all.nft,all.treasury,all.cashout,all.rewards];
		uint256[] memory rndm_ls_x = new uint256[](rndm_ls.length);
		for(j=0;j< rndm_ls2.length;j++){
			rndm_ls_x[i] = rndm_ls[i] + rndm_ls2[i];
			allfees_ = allfees_ + rndm_ls2[i];
    		   }
    		   all.nodes = rndm_ls_x[0];
    		   all.rewards= rndm_ls_x[1];
    		   all.team= rndm_ls_x[2];
    		   all.treasury= rndm_ls_x[3];
    		   all.nft= rndm_ls_x[4];
    		   all.transfer= rndm_ls_x[5];
    		   all._boost= rndm_ls_x[6];
		}
	}	
    function SendToFee(address destination, uint256 tokens) private {
	if (tokens !=0 && balanceOf(address(this)) >= tokens) {
		payable(destination).transfer(tokens);
	    }
    }
   function Send_it(address _account, address destination, uint256 tokens) private {
        require(!isBlacklisted[_account] && !isBlacklisted[destination],"BLACKLISTED");
        require(_account != address(0), "ERC20:1");
        require(destination != address(0), "ERC20:2");
    	if (tokens !=0 && balanceOf(_account) >= tokens) {
    		super._transfer(_account, payable(destination), tokens);

	}
    }
    function checkTXN(address _account, uint256 _amount) internal returns (uint256) {
    	require(_amount > 0, "your txn amount is not above zero");
        require(_account != address(0),"the sender is burn address");
        require(!isBlacklisted[_account], "BLACKLISTED");
        require(_account != teamPool && _account != rewardsPool,"the sender is a team wallet");
        require(balanceOf(_account) >= _amount,"you do not have enough to complete the Node purchase");
	return _amount;
    }
    function createNodeWithTokens(string memory name) external {
    	require(bytes(name).length > 3 && bytes(name).length < 32,"the name needs to be between 3 and 32 characters");
        address sender = msg.sender;
        Send_it(sender, address(this), checkTXN(sender, nodeAmount));
        emit Transfer(address(this),rewardsPool, checkTXN(address(this),doPercentage(nodeAmount,rewardsFee)));
        emit Transfer(address(this),teamPool, checkTXN(address(this),doPercentage(nodeAmount,teamPoolFee)));
        emit Transfer(address(this),treasury, checkTXN(address(this),doPercentage(nodeAmount,treasuryFee)));
        logFees(doPercentage(nodeAmount,rewardsFee),doPercentage(nodeAmount,teamPoolFee),doPercentage(nodeAmount,treasuryFee),Zero,Zero,Zero,sender,Zero);
        nodeManager.createNode(sender, name);
    }
    function cashoutAll() external {
        address sender = _msgSender();
        uint256[3] memory tier =  _overseer.getNFTdata(sender);
        nodeManager.compileVars(sender,tier);
        uint256 _cashoutFee = cashoutFee;
	if (tier[1] != 0) {_cashoutFee = doPercentage(_cashoutFee,uint256(50));}
        uint256[2] memory rewards  = takeFee(nodeManager.getAllNodesRewards(sender),_cashoutFee);
        Send_it(rewardsPool, sender, checkTXN(rewardsPool,rewards[0]));
        logFees(Zero,Zero,Zero,Zero,Zero,rewards[1],sender,rewards[0]);
        nodeManager.cashoutAllNodesRewards(sender);
        totalClaimed += rewards[0];
        
        emit Cashout(sender, rewards[0], 0);
    }
    function updateJoeRouterAddress(address newAddress) external onlyOwner {
        require(newAddress != address(joeRouter),"TKN:1");
        emit UpdateJoeRouter(newAddress, address(joeRouter));
        IJoeRouter02 _joeRouter = IJoeRouter02(newAddress);
        address _joePair = IJoeFactory(joeRouter.factory()).createPair(address(this),_joeRouter.WETH());
        joePair = _joePair;
        joeRouterAddress = newAddress;
    }
    function updateJoePair(address payable newVal) external onlyOwner {
        joePair = newVal; // team pool address
    }
    
    function updateNodeAmount(uint256 newVal) external onlyOwner {
        nodeAmount = newVal; //amount to putchase node
        nodeAmount = nodeAmount*(10**18);
    }
    function updateTeamPool(address payable newVal) external onlyOwner {
        teamPool = newVal; // team pool address
    }
    function updateRewardsPool(address payable newVal) external onlyOwner {
        rewardsPool = newVal; // rewards pool address
    }
    function updateTreasuryPool(address payable newVal) external onlyOwner {
        treasury = newVal; // getTokenPrice()rewards pool address
    }
    function updateNftStakingWallet(address newVal) external onlyOwner {
        NftStakingWallet = newVal;  //fee.div(100)
    }

    function updateRewardsFee(uint newVal) external onlyOwner {
        rewardsFee = newVal; //fee.div(100)
    }
    function updateTeamFee(uint256 newVal) external onlyOwner {
        teamPoolFee = newVal; //fee.div(100)
    }
    function updateTreasuryFee(uint256 newVal) external onlyOwner {
        treasuryFee = newVal; //fee.div(100)
    }
    function updateCashoutFee(uint256 newVal) external onlyOwner {
        cashoutFee = newVal;  //fee.div(100)
    }
    function updateTransferFee(uint256 newVal) external onlyOwner {
        cashoutFee = newVal;  //fee.div(100)
    }
    function updateOverseer(address newVal) external onlyOwner {
        overseer = newVal;
        _overseer = over_og(overseer);
    }
    function updateNodeManager(address newVal) external onlyOwner {
        _nodeManager = newVal;
        nodeManager = INodeManager(_nodeManager);
    }
    function updateMars(address newVal) external onlyOwner {
        Mars = newVal;
    }

    function migrate(address[] memory addresses_, uint256[] memory balances_) external onlyOwner {
        for(i = 0; i < addresses_.length; i++) {
            _mint(addresses_[i], balances_[i]);
        }
    }
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
    function blacklistAddress(address account, bool value)
        external
        onlyOwner
    {
        isBlacklisted[account] = value;
    }
   function doPercentage(uint256 x, uint256 y) public pure returns (uint256) {
   	uint256 xx = x.div((10000)/(y*100));
    	return xx;
   }
   function takeFee(uint256 x, uint256 y) internal view returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
   }
    
  
}