// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Owned.sol";
import "../interfaces/IJoeFactory.sol";
import "../interfaces/IJoeRouter02.sol";
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";

contract ExchangeAgentForJoe is Owned {
    IJoeRouter02 public dexRouter;
    address public WAVAX;
    address public USDC;
    address public SYNTH;

    event SetAssociatedContract(address contractAddress, uint16 contractType);
    event SwapAVAXToToken(address to, uint256 amountIn, address tokenOut, uint256 amountOut);
    event SwapTokenToToken(address to, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(
        address _wavax,
        address _usdc,
        address _synth,
        IJoeRouter02 _dexRouter,
        address _owner
    ) Owned(_owner) {
        WAVAX = _wavax;
        USDC = _usdc;
        SYNTH = _synth;
        dexRouter = _dexRouter;
    }

    /* =========== ADMIN FUNCTIONS =========== */
    function setAssociatedContracts(address _contract, uint16 _type) external onlyOwner {
        if (_type == 0) {
            WAVAX = _contract;
        } else if (_type == 1) {
            USDC = _contract;
        } else if (_type == 2) {
            SYNTH = _contract;
        } else {
            dexRouter = IJoeRouter02(_contract);
        }
        emit SetAssociatedContract(_contract, _type);
    }

    /* =========== VIEW FUNCTIONS ============= */
    function getSYNTHExpectedAmountFromETH(uint256 _amountIn) external view returns (uint256) {
        address[] memory path = _getPairPath(WAVAX, SYNTH);
        return _getTokenExpectedAmount(_amountIn, path);
    }

    function getSYNTHExpectedAmount(address _tokenIn, uint256 _amountIn) external view returns (uint256) {
        address[] memory path = _getPairPath(_tokenIn, SYNTH);
        return _getTokenExpectedAmount(_amountIn, path);
    }

    function getUSDCForSYNTH(uint256 amountIn) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = SYNTH;
        path[1] = USDC;
        uint256[] memory amounts = dexRouter.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function _getTokenExpectedAmount(uint256 _amountIn, address[] memory path) internal view returns (uint256 amountOut) {
        uint256[] memory amounts = dexRouter.getAmountsOut(_amountIn, path);
        amountOut = amounts[amounts.length - 1];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function swapETHToSYNTH(uint256 _amountIn, address _to) external payable returns (uint256) {
        require(_to != address(0), "ExchangeAgent: zero recipient address");
        (bool swapSuccess, uint256 swapResult) = _swapAVAXToToken(_amountIn, SYNTH, _to);
        require(swapSuccess, "ExchangeAgent: swap failed");
        return swapResult;
    }

    function swapTokenToSYNTH(
        address _tokenIn,
        uint256 _amountIn,
        address _to
    ) external returns (uint256) {
        require(_to != address(0), "ExchangeAgent: zero recipient address");
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);
        (bool swapSuccess, uint256 swapResult) = _swapTokenToToken(_tokenIn, _amountIn, SYNTH, _to);
        require(swapSuccess, "ExchangeAgent: swap failed");
        return swapResult;
    }

    /* ========== INTERNAL MUTATIVE FUNCTIONS ========== */
    function _swapAVAXToToken(
        uint256 _amountIn,
        address _tokenOut,
        address _to
    ) internal returns (bool, uint256) {
        address[] memory path = _getPairPath(WAVAX, _tokenOut);
        require(path.length > 1, "ExchangeAgent: no pair on dex");
        uint256 desiredAmount = _getTokenExpectedAmount(_amountIn, path);

        require(address(this).balance >= _amountIn, "ExchangeAgent: insufficient avax balance");

        uint256 tokenBalanceBefore = IERC20(_tokenOut).balanceOf(_to);

        dexRouter.swapExactAVAXForTokens{value: _amountIn}(desiredAmount, path, _to, block.timestamp);

        uint256 tokenBalanceAfter = IERC20(_tokenOut).balanceOf(_to);

        emit SwapAVAXToToken(_to, _amountIn, _tokenOut, tokenBalanceAfter - tokenBalanceBefore);

        return (true, tokenBalanceAfter - tokenBalanceBefore);
    }

    function _swapTokenToToken(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        address _to
    ) internal returns (bool, uint256) {
        address[] memory path = _getPairPath(_tokenIn, _tokenOut);
        require(path.length > 1, "ExchangeAgent: no pair on dex");
        uint256 desiredAmount = _getTokenExpectedAmount(_amountIn, path);

        require(IERC20(_tokenIn).balanceOf(address(this)) >= _amountIn, "ExchangeAgent: insufficient tokenIn balance");

        TransferHelper.safeApprove(_tokenIn, address(dexRouter), _amountIn);
        uint256 tokenBalanceBefore = IERC20(_tokenOut).balanceOf(_to);
        dexRouter.swapExactTokensForTokens(_amountIn, desiredAmount, path, _to, block.timestamp);
        uint256 tokenBalanceAfter = IERC20(_tokenOut).balanceOf(_to);

        emit SwapTokenToToken(_to, _tokenIn, _amountIn, _tokenOut, tokenBalanceAfter - tokenBalanceBefore);

        return (true, tokenBalanceAfter - tokenBalanceBefore);
    }

    function _getPairPath(address _tokenIn, address _tokenOut) internal view returns (address[] memory) {
        address _factory = dexRouter.factory();
        uint256 pathLength;
        if (IJoeFactory(_factory).getPair(_tokenIn, _tokenOut) != address(0)) {
            pathLength = 2;
        } else {
            if (IJoeFactory(_factory).getPair(_tokenIn, USDC) != address(0)) {
                pathLength = 3;
            } else {
                pathLength = 1;
            }
        }
        address[] memory path = new address[](pathLength);
        path[0] = _tokenIn;
        if (pathLength == 2) {
            path[1] = _tokenOut;
        } else if (pathLength == 3) {
            path[1] = USDC;
            path[2] = _tokenOut;
        }
        return path;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJoeFactory {
    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}