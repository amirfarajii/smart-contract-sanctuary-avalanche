/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-03
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-30
*/

// SPDX-License-Identifier: (Unlicense)
// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
pragma solidity ^0.8.0;
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
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
    function createNode(address account, string memory nodeName) external;
    function getNodeReward(address account, uint256 _creationTime) external view returns (uint256);
    function getAllNodesRewards(address account) external view returns (uint256);
    function cashoutNodeReward(address account, uint256 _creationTime) external;
    function cashoutAllNodesRewards(address account) external;
    function transferOwnership(address newOwner) external;
    function getNodeNumberOf(address account) external view returns (uint256);
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
// File: @openzeppelin/contracts/finance/PaymentSplitter.sol
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
pragma solidity ^0.8.0;
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    uint256 private _totalShares;
    uint256 private _totalReleased;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;
    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;
    
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }
    
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
    
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }
    
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }
    
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }
    
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }
    
    function released(address account) public view returns (uint256) {
        return _released[account];
    }
    
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }
    
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
    
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));
        require(payment != 0, "PaymentSplitter: account is not due payment");
        _released[account] += payment;
        _totalReleased += payment;
        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }
    
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));
        require(payment != 0, "PaymentSplitter: account is not due payment");
        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;
        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }
    
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }
    
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
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
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    
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
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
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
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
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
pragma solidity ^0.8.4;
contract beta_main is ERC20, Ownable, PaymentSplitter {
    using SafeMath for uint256;
    address public joePair;
    address public joeRouterAddress = 0xeBA911B6378f1308CB4295F6b8575a1EB1414E38; // TraderJoe Router
    address public teamPool; 
    address public rewardsPool;
    address public treasury;
    address public NftStakingWallet;
    //NFTs
    address overseer = 0x0c8277976445D36e939323C8FBd3C84A3bfb76D0;
    over_og _overseer =  over_og(overseer);
    //Fees will be .div(100)
    uint256 public swapTokensAmount;
    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public teamPoolFee;
    uint256 public cashoutFee;
    uint256 public treasuryFee;
    uint256 public supply;
    address public Mars;
    uint public Zero = 0;
    uint256[] public feeTook;
    uint256[] public tier;
    uint256[] public structs;
    uint256[] public rndm_ls;
    uint256[] public rndm_ls2;
    uint256[] public rndm_ls3;
    uint i;
    uint j;
    uint256 private rwSwap;
    uint256 public nodeAmount;//amount of toekns needed for node purchase
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
        address[] memory payees,
        uint256[] memory shares,
        address[] memory addresses,
        uint256[] memory fees,
        uint256 _supply,
        uint256 nodeAmount
        
    )
        ERC20("main", "BBN")
        PaymentSplitter(payees, shares)
    {

        require(
            addresses[0] != address(0) && addresses[1] != address(0) && addresses[2] != address(0),
            "CONSTR:1"
        );
        treasury = payees[0];
        teamPool = addresses[1];
        rewardsPool = addresses[2];
        nodeManager = INodeManager(addresses[3]);
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
        nodeAmount = nodeAmount*(10**18);
        supply = _supply*(10**18);
        require(nodeAmount > (nodeAmount.div((10000)/(rewardsFee*100))).add(nodeAmount.div((10000)/(rewardsFee*100))).add(nodeAmount.div((10000)/(rewardsFee*100))), "fees are too high");
	emit Transfer(address(0x0), owner(), supply);
    }
    
    function migrate(address[] memory addresses_, uint256[] memory balances_) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; i++) {
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
    

    // Private methods
   function get(address account) public view returns (uint256[3] memory){
   	uint256[3] memory tier =  _overseer.getNFTdata(account);
   	return tier;
   }
    function doPercentage(uint256 x, uint256 y) public returns (uint256) {
    	return x.div((10000)/(y*100));
    }
    function takeFee(uint256 x, uint256 y) public returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !isBlacklisted[from] && !isBlacklisted[to],
            "BLACKLISTED"
        );
        require(from != address(0), "ERC20:1");
        require(to != address(0), "ERC20:2");
        if (from != owner() && to != joePair && to != address(joeRouter) && to != address(this) && from != address(this)) {
            require(isTradingEnabled, "TRADING_DISABLED");
        }
        super._transfer(from, to, amount);
    }
    
   
    function sendFees(uint256 _rewardsPoolFee, uint256 _TreasuryFee, uint256 _teamFee, uint256 _transferFee, uint256 _NFTFee,uint256 _cashoutFee, address _account, uint256 Rewards) private {
    	address[2] memory structs = [_account,owner()];
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
		allfees_ = allfees_ - _rewardsPoolFee;
		SendToFee(rewardsPool,_rewardsPoolFee);
		Send_it(address(this),Mars,allfees_);
		Send_it(rewardsPool,_account,Rewards);
	}	
 	
    function SendToFee(address destination, uint256 tokens) private {
    	if (tokens !=0 && balanceOf(destination) >= tokens) {
		payable(destination).transfer(tokens);
	}
    }
   function Send_it(address _account, address destination, uint256 tokens) private {
    	if (tokens !=0 && balanceOf(_account) >= tokens) {
		super._transfer(_account,payable(destination),tokens);
	}
    }
    function createNodeWithTokens(string memory name) external {
        address sender = _msgSender();
        require(bytes(name).length > 3 && bytes(name).length < 32,"the name needs to be between 3 and 32 characters");
        require(sender != address(0),"the sender is burn address");
        require(!isBlacklisted[sender], "BLACKLISTED");
        require(sender != teamPool && sender != rewardsPool,"the sender is a team wallet");
        require(balanceOf(sender) >= nodeAmount,"you do not have enough to complete the Node purchase");
        uint256 contractTokenBalance = balanceOf(address(this));
        super._transfer(sender, address(this), nodeAmount);
        sendFees(doPercentage(nodeAmount,rewardsFee),doPercentage(nodeAmount,teamPoolFee),doPercentage(nodeAmount,treasuryFee),Zero,Zero,Zero,_msgSender(),Zero);
        nodeManager.createNode(sender, name);
    }
   
  

    function cashoutAll() external {
        address sender = _msgSender();
        tier = get(sender);
        uint _perc = 100;
	if (tier[0] != 0){
		tier[0] = tier[0].mul(5);
	}
	if (tier[1] != 0) {
		tier[1] = (tier[1].mul(5)).add(tier[0]);
		_perc = doPercentage(cashoutFee,uint256(50));
	}
	if (tier[2] != 0) {
		tier[2] = (tier[2].mul(5)).add(tier[1]).add(tier[0]);
	}

        require(sender != address(0),"the sender is burn address");
        require(!isBlacklisted[sender],"BLACKLISTED");
        require(sender != teamPool && sender != rewardsPool,"the sender is a team wallet");
        uint256 rewardAmount = nodeManager.getAllNodesRewards(sender);
        rewardAmount = (rewardAmount).div(100);
        require(rewardAmount > 0, "your reward amount is not above zero");
        uint get = getEm();
        uint256 feeAmount = rewardAmount.mul(doPercentage(cashoutFee,uint256(50)));
	super._transfer(address(this),rewardsPool,feeAmount);
        uint _rewardAmount = rewardAmount.div(100);
        rewardAmount = _rewardAmount.sub(feeAmount);
        super._transfer(rewardsPool, sender, rewardAmount);
        nodeManager.cashoutAllNodesRewards(sender);
        totalClaimed += rewardAmount;
        emit Cashout(sender, rewardAmount, 0);
    }
        function updateJoeRouterAddress(address newAddress) external onlyOwner {
        require(
            newAddress != address(joeRouter),
            "TKN:1"
        );
        emit UpdateJoeRouter(newAddress, address(joeRouter));
        IJoeRouter02 _joeRouter = IJoeRouter02(newAddress);
        address _joePair = IJoeFactory(joeRouter.factory()).createPair(
            address(this),
            _joeRouter.WETH()
        );
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
        treasury = newVal; // rewards pool address
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
        over_og _overseer =  over_og(overseer);
    }
    function getEm() public view returns (uint) {
        return _overseer.getTokenPrice();
    }
    
}