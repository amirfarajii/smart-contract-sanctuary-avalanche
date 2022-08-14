/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-13
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
library Address {
    
    function isContract(address account) internal view returns (bool) {
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
    function checkInsolvent(address _account) external;
    function doPayments(address _account,uint256 payments) external;
    function doFuturePayments(address _account,uint256 payments) external;
    function queryFuturePayment(address _account) external view returns (uint);
    function queryDuePayment(address _account) external view returns (uint);
    function getBoostList(uint256[3] memory tiers) external view returns(uint256[100] memory);
    function getNodesAmount(address _account) external view returns (uint256,uint256);
    function getNodesRewards(address _account, uint256 _time, uint256 k,uint _tier,uint256 _timeBoost) external view returns (uint256);
    function cashoutNodeReward(address _account, uint256 _time, uint256 k) external;
    function cashoutAllNodesRewards(address _account) external;
    function createNode(address _account, string memory nodeName) external;
    function getNodesNames(address _account) external view returns (string memory);
}
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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
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
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
library myLib {
   using SafeMath for uint256;
    function getBoostList(uint256[3] memory tiers,uint256[3] memory _boostMultiplier) internal pure returns (uint256[100] memory){
    	uint256[100] memory tier_ls;
    	for(uint i=0;i<100;i++){
    		tier_ls[i] = 0;
    	}
    	uint j;
    	for(uint i=0;i<tiers.length;i++){
    		tiers[i].mul(5);
    		uint j_st = j + tiers[i];
    		for(uint j=j;j<j_st;j++){
    			tier_ls[j] = _boostMultiplier[i];
    		}
    	}
    	return tier_ls;
    }
   function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
   	uint256 xx = x.div((10000)/(y*100));
    	return xx;
   }
   function takeFee(uint256 x, uint256 y) internal pure returns (uint256[2] memory) {
    	uint256 fee = doPercentage(x,y);
    	uint256 newOg = x.sub(fee);
    	return [newOg,fee];
   }
}
abstract contract overseer is Context {
	function getGreensAmount(address _account) external virtual returns(uint256[3] memory,uint256);
  	function getCurrGreens(address _account, uint i, uint k) external virtual returns(uint256,uint256) ;
}
pragma solidity ^0.8.0;
contract main is ERC20, Ownable {
    using SafeMath for uint256;
    address public joePair;
    address public joeRouterAddress = 0xeBA911B6378f1308CB4295F6b8575a1EB1414E38; // TraderJoe Router
    address public teamPool; 
    address public rewardsPool;
    address public treasury;
    address public NftStakingWallet;
    uint256 public swapTokensAmount;
    uint256 public rewardsFee;
    uint256 public liquidityPoolFee;
    uint256 public teamPoolFee;
    uint256 public cashoutFee;
    uint256 public treasuryFee;
    uint256 public overSeerFee;
    uint256 public transferFee;
    uint256 public supply;
    address public overSeer;
    address public _nodeManager;
    address public _overseer;
    overseer _overseer_;
    uint public Zero = 0;
    IERC20 _feeToken;
    address public feeToken;
    uint256[] public tier;
    uint256 public _totalSupply;
    address[] public structs;
    uint256[] public rndm_ls;
    uint256[] public rndm_ls2;
    uint256[] public rndm_ls3;
    uint256 public feeAmount = 15;
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
    struct AllFees {
    		   uint256 nodes;
    		   uint256 rewards;
    		   uint256 team;
    		   uint256 treasury;
    		   uint256 overSeer;
    		   uint256 nft;
    		   uint256 transfer;
    		   uint256 _boost;
    		   uint256 cashout;
    		   uint256 nodeFees;
    		   }
     struct TXNs { uint256 reward;
    		   uint256 team;
    		   uint256 treasury;
    		   uint256 nodeFees;
    		   uint256 overSeer;
    		   }
    //mapping
    mapping(address => AllFees) public allFees;
    mapping(address => bool) public isBlacklisted;
    mapping(address => TXNs) public TXns;
    address[] public alls;
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
        uint256 _nodeAmount,
        uint256 _feeAmount
        )ERC20("main", "BBN") {
    	for(uint i=0;i<addresses.length;i++){
    		require(addresses[i] != address(0),"address is burn wallet");
    	
    		}
        treasury = addresses[0];
        teamPool = addresses[1];
        rewardsPool = addresses[2];
        overSeer = addresses[3];
        _overseer = addresses[4];
        overseer _overseer_ =  overseer(_overseer);
        feeToken = addresses[5];
        _nodeManager = addresses[6];
        _feeToken = IERC20(feeToken);
        nodeManager = INodeManager(_nodeManager);
        require(joeRouterAddress != address(0), "router address is burn wallet");
        IJoeRouter02 _joeRouter = IJoeRouter02(joeRouterAddress);
        address _joePair = IJoeFactory(_joeRouter.factory())
        .createPair(address(this), _joeRouter.WETH());
        joeRouter = _joeRouter;
        joePair = _joePair;
        for(uint i=0;i<fees.length;i++){
    		require(fees[i] != 0,"fee is set to zero");
    	}
        teamPoolFee = fees[0];
        rewardsFee = fees[1];
        treasuryFee = fees[2];
        overSeerFee = fees[3];
        liquidityPoolFee = fees[4];
        cashoutFee = fees[5];
        rwSwap = fees[6];
        transferFee = fees[7];
        nodeAmount = _nodeAmount*(10**18);
        feeAmount = _feeAmount*(10**18);
        _totalSupply =  rachet*(10**18);
	_mint(address(this), myLib.doPercentage(_totalSupply,uint256(50)));
	makemoney();
	//logFees(Zero,Zero,Zero,Zero,Zero,Zero,Zero,Zero, address(this), Zero);
    }
    function queryERC20Balance(address _tokenAddress, address _addressToQuery) internal view returns (uint) {
        return IERC20(_tokenAddress).balanceOf(_addressToQuery);
    }
    function MakeAllFeePayment() external{
        address sender = msg.sender;
        nodeManager.checkInsolvent(sender);
    	uint256 payments = nodeManager.queryDuePayment(sender);
    	uint256 _fees;
    	for(uint i=0;i<payments;i++){
    		_fees += feeAmount;
    	}
    	SendFeeToken(sender,treasury,_fees);
    	nodeManager.doPayments(sender,payments);
    }
    function MakeAllFuturePayments() external{
        address sender = msg.sender;
        nodeManager.checkInsolvent(sender);
    	uint payments = nodeManager.queryFuturePayment(sender);
    	uint256 _fees;
    	for(uint i=0;i<payments;i++){
    		_fees += feeAmount;
    	}
    	SendFeeToken(sender,treasury,_fees);
    	nodeManager.doFuturePayments(sender,payments);
    }
    function payInPieces(uint256 _payments) external {
    	address sender = msg.sender;
    	uint256 count;
    	uint256 due = nodeManager.queryDuePayment(sender);
    	uint256 future = nodeManager.queryFuturePayment(sender);
    	uint256 total = (_payments).mul(feeAmount);
    	nodeManager.checkInsolvent(sender);
    	if (future+due < _payments) {
    		total = (future+due).mul(feeAmount);
    	}
    	require(total >= queryERC20Balance(feeToken,sender),"you need to select less payment, you dont have enough tokens to pay");
    	require(total > 0, "you are all paid up");
    	for(uint i=0;i<_payments;i++){
    		if(due > 0){
    			SendFeeToken(sender,treasury,feeAmount);
    			nodeManager.doPayments(sender,1);
    			due -= 1;
    			count +=1;
    		}
    		else if(future > 0){
    		    	SendFeeToken(sender,treasury,feeAmount);
    			nodeManager.doFuturePayments(sender,1);
    			future -= 1;
    			count +=1;
    		}	
    	}
    	logFees(Zero,Zero,Zero,Zero,Zero,Zero,Zero,total,sender,Zero);

   }	
    function makemoney() public {
    	_mint(owner(),myLib.doPercentage(_totalSupply,uint256(20)));
	_mint(treasury,myLib.doPercentage(_totalSupply,uint256(10)));
	_mint(rewardsPool,myLib.doPercentage(_totalSupply,uint256(10)));
	}
    function _transfer(address sender,address to,uint256 amount) internal override {
        require(!isBlacklisted[sender] && !isBlacklisted[to],"BLACKLISTED");
        require(sender != address(0), "ERC20:1");
        require(to != address(0), "ERC20:2");
        if (sender != owner() && to != joePair && to != address(joeRouter) && to != address(this) && sender != address(this)) {
            require(isTradingEnabled, "TRADING_DISABLED");
        }
        uint256[2] memory take = myLib.takeFee(amount,transferFee);
        Send_it(sender, address(this), take[1]);
        Send_it(sender, to, take[0]);
        logFees(Zero,Zero,Zero,take[1],Zero,Zero,Zero,Zero,sender,Zero);
    }
    function logFees(uint256 _rewardsPoolFee, uint256 _TreasuryFee, uint256 _teamFee, uint256 overSeerFee, uint256 _transferFee, uint256 _NFTFee,uint256 _cashoutFee, uint256 _nodeFees, address _account, uint256 _rewards) private{
	        AllFees storage all = allFees[_account];
	        TXNs storage txn = TXns[address(this)];
		rndm_ls2 = [_rewardsPoolFee,_transferFee,_teamFee,_NFTFee,_TreasuryFee,_cashoutFee];
    		all.rewards += rndm_ls2[0];
    		allFees[_account].transfer += rndm_ls2[1];
    		allFees[_account].team += rndm_ls2[2];
    		allFees[_account].overSeer += rndm_ls2[3];
    		allFees[_account].nft += rndm_ls2[4];
    		allFees[_account].treasury += rndm_ls2[5];
    		allFees[_account].cashout += rndm_ls2[6];
    		allFees[_account].nodeFees += rndm_ls2[7];
		txn.reward += rndm_ls2[0];
		txn.team += rndm_ls2[2];
		txn.treasury += rndm_ls2[5];
		txn.nodeFees += rndm_ls2[7];
		txn.overSeer += txn.treasury.add(txn.team).add(txn.reward);
	}	
    function SendToFee(address destination, uint256 tokens) private {
	if (tokens !=0 && balanceOf(address(this)) >= tokens) {
		payable(destination).transfer(tokens);
	    }
    }
    function SendFeeToken(address _account, address destination, uint256 tokens) private {
        require(!isBlacklisted[_account] && !isBlacklisted[destination],"BLACKLISTED");
        require(_account != address(0), "ERC20:1");
        require(destination != address(0), "ERC20:2");
    	if (tokens !=0 && queryERC20Balance(feeToken,_account) >= tokens) {
    		_feeToken.approve(_account,tokens);
    		_feeToken.transferFrom(_account,address(this),tokens);
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
        address[4] memory _takes = [rewardsPool,teamPool,treasury,overSeer];
        uint256[4] memory _fees =[myLib.doPercentage(nodeAmount,rewardsFee),myLib.doPercentage(nodeAmount,teamPoolFee),myLib.doPercentage(nodeAmount,treasuryFee),nodeAmount.sub(myLib.doPercentage(nodeAmount,rewardsFee)).sub(myLib.doPercentage(nodeAmount,treasuryFee)).sub(myLib.doPercentage(nodeAmount,rewardsFee))];
        for(uint i=0;i<_takes.length;i++){
        	Send_it(address(this),_takes[i], checkTXN(address(this),_fees[i]));
        }
        logFees(_fees[0],_fees[1],_fees[2],_fees[3],Zero,Zero,Zero,Zero,sender,Zero);
        nodeManager.createNode(sender, name);
        AllFees storage all = allFees[sender];
        all.nodes += 1;
    }
    function cashoutAll() external {
        address sender = msg.sender;
        nodeManager.checkInsolvent(sender);
        uint256[3] memory Tiers = [uint256(0),uint256(0),uint256(0)];
        uint256 amount = 0;//  _overseer_.getGreensAmount(sender);
        uint256 _cashoutFee = cashoutFee;
        if (Tiers[1] > 0) {
        	_cashoutFee = myLib.doPercentage(cashoutFee,50);
        }

        (uint256 length,uint256 time) = nodeManager.getNodesAmount(sender);
        uint256 rewards;
        uint256 _time;
        uint256 count = Zero;
        uint256 c;
        uint256[3] memory Tiers_mul = [Tiers[0].mul(5),(Tiers[0]+Tiers[1]).mul(5),(Tiers[0]+Tiers[1]+Tiers[2]).mul(5)];
        amount = amount.mul(5);
        for(uint i=0;i<length;i++){
        	address sender_ = msg.sender;
        	uint256 _boost = 0;
        	uint256 j;
        	if (amount > 0){
        		while (Tiers_mul[j] <= i && j < Tiers.length ){
        			j = j + 1;
        			c = Zero;
        		}
        		(_time ,_boost) = _overseer_.getCurrGreens(sender_,j,c);
        		count += 1;
        		if (count == 5) {
        			c += 1; 
        			count = Zero;
        		}
        		amount -= 1;
        	}  
        	rewards += nodeManager.getNodesRewards(sender_,time,i,_boost,_time);
        }
        require(rewards > 0, "you have no rewards to cash out");
        uint256[2] memory rew  = myLib.takeFee(rewards,_cashoutFee);
        Send_it(rewardsPool, sender, rew[0]);
        //logFees(Zero,Zero,Zero,Zero,Zero,Zero,Zero,rew[1],sender,rew[0]);
        for(i=0;i<length;i++){
        	nodeManager.cashoutNodeReward(sender,time,i);
        }
        totalClaimed += rew[0];
      //  emit Cashout(sender, rew[0], 0);
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
        _overseer = newVal;
        _overseer_ = overseer(_overseer);
    }
    function updateNodeManager(address newVal) external onlyOwner {
        _nodeManager = newVal;
        nodeManager = INodeManager(_nodeManager);
    }
    function updateoverSeer(address newVal) external onlyOwner {
        overSeer = newVal;
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
}