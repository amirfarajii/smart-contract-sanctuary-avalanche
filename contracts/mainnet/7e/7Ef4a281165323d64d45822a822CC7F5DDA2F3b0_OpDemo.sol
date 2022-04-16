/**
 *Submitted for verification at snowtrace.io on 2022-04-16
*/

// File: contracts/IERC20.sol


pragma solidity >=0.6.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/OpDemo.sol

pragma solidity >=0.6.0 <=0.9.0;

// import "hardhat/console.sol";

contract OpDemo {
    address public routerV4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    event Data(bool, uint256 returnAmount, uint256 spentAmount, uint256 gasLeft);

    // constructor() payable public {
    // }

    function swap(bytes calldata data) public {    
        (bool success, bytes memory result) =routerV4.call(data);
        (uint256 returnAmount, uint256 spentAmount, uint256 gasLeft) = abi.decode(result, (uint256, uint256, uint256));
        emit Data(success, returnAmount, spentAmount, gasLeft);
    }

    function getBalance(address[] calldata _tokens) public view returns(uint256, uint256[] memory) {
        uint256[] memory array = new uint256[](_tokens.length);

        for (uint8 i=0;i<_tokens.length;i++) {
            array[i] = IERC20(_tokens[i]).balanceOf(address(this));
        }
        return (address(this).balance, array);
    }

    function getBack(address _oea, address[] memory _tokens) public {
        payable(_oea).transfer(address(this).balance);
        for (uint8 i=0;i<_tokens.length;i++) {
            uint b = IERC20(_tokens[i]).balanceOf(address(this));
            IERC20(_tokens[i]).transfer(_oea, b);
        }
    }

    function approveToRouter(address _token) public {
        IERC20(_token).approve(routerV4 ,uint256(-1));
    }

    function change() public payable{}
}