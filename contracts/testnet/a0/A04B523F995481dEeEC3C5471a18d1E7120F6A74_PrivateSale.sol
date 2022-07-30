/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract PrivateSale is Ownable {

    address tokenAddress;
    uint256 totalSellAmount;
    uint256 launchTime;

    mapping(address => bool) whiteList;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function privateSaleStart() external onlyOwner {
        launchTime = block.timestamp;
    }

    function buy(address _account, uint256 _amount) external payable {
        
        require(whiteList[_account], "This address not exist in whitelist");
        require(IERC20(tokenAddress).balanceOf(owner()) >= _amount, "Balance is not enough");
        require(msg.value * 500 >= _amount, "Less price");

        require(block.timestamp - launchTime > 1 days, "Not allowed private sale");

        uint256 allowAmount = IERC20(tokenAddress).totalSupply() * 5 / 100;

        if (block.timestamp - launchTime < 30 days) {
            require(totalSellAmount + _amount <= allowAmount * 14 / 100, "Allowed amount is not enough");
        } else if (block.timestamp - launchTime < 60 days) {
            require(totalSellAmount + _amount <= allowAmount * 28 / 100, "Allowed amount is not enough");
        } else if (block.timestamp - launchTime < 90 days) {
            require(totalSellAmount + _amount <= allowAmount * 42 / 100, "Allowed amount is not enough");
        } else if (block.timestamp - launchTime < 120 days) {
            require(totalSellAmount + _amount <= allowAmount * 56 / 100, "Allowed amount is not enough");
        } else if (block.timestamp - launchTime < 150 days) {
            require(totalSellAmount + _amount <= allowAmount * 70 / 100, "Allowed amount is not enough");
        } else if (block.timestamp - launchTime < 180 days) {
            require(totalSellAmount + _amount <= allowAmount * 84 / 100, "Allowed amount is not enough");
        } else{
            require(totalSellAmount + _amount <= allowAmount, "Allowed amount is not enough");
        }

        totalSellAmount += _amount;

        IERC20(tokenAddress).transfer(_account, _amount);
    }

    function setWhiteList(address _account, bool _boolean) external onlyOwner {
        require(whiteList[_account] != _boolean, "Already registered account");

        whiteList[_account] = _boolean;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Smaller amount");
        
        (bool success, ) = address(msg.sender).call{value: address(this).balance}('');
        
        require(success, "Withdraw failure");
    }
}