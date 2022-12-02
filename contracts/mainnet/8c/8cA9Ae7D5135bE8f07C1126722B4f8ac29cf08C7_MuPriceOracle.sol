/**
 *Submitted for verification at snowtrace.io on 2022-12-02
*/

// File: MuOracle.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
    function decimals() external view  returns (uint8);
}

interface Router {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)external view returns (uint256[] memory amounts);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);  
    function swapTokensForExactTokens(uint256 amountOut,uint256 amountInMax,address[] calldata path,address to,uint256 deadline) external returns (uint256[] memory amounts);
    function addLiquidity(address tokenA,address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin,address to,uint256 deadline)external returns (uint256 amountA,uint256 amountB,uint256 liquidity);
    function removeLiquidity(address tokenA,address tokenB,uint256 liquidity,uint256 amountAMin,uint256 amountBMin,address to,uint256 deadline) external returns (uint256 amountA, uint256 amountB);
}

interface Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
  function getReserves()external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract MuPriceOracle{

    address _mu_mug_lp = 0x67d9aAb77BEDA392b1Ed0276e70598bf2A22945d;
    address _mu_usdc_lp = 0xfacB3892F9A8D55Eb50fDeee00F2b3fA8a85DED5;
    address _mu_mume_lp = 0xdFC2BAD5Fe360e9DcDA553d645B52Ff709B1434a;



    function _getLPreserves(address LP) internal  view returns(uint112 reserve0, uint112 reserve1) {
            uint112 _reserve0;
            uint112 _reserve1;
            uint32 blockTimestampLast;
            (_reserve0, _reserve1,  blockTimestampLast) = Pair(LP).getReserves();
            return (_reserve0, _reserve1);
    }

    function get_mu_usd_price() public  view returns(uint112 reserve0, uint112 reserve1){
        //MU-USDC.e TJ LP Pool token0 is USDC.e (6) and token1 is MU Coin (18)
        return  _getLPreserves(_mu_usdc_lp);
        

    }



}