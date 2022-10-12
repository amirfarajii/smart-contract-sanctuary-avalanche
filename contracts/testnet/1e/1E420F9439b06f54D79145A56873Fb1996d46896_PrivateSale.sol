// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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

contract PrivateSale is Ownable {
    address USDT = 0x9a01bf917477dD9F5D715D188618fc8B7350cd22;
    address USDC = 0x6701dbeF919500c7B030253fE0de17A41efAa1dE;
    address USDCE = 0x45ea5d57BA80B5e3b0Ed502e9a08d568c96278F9;
    address BUSD = 0x2326546463a8bA834378920f78bce8B36872e7ba;
    address DAI = 0x6294225FC50D5fEa1B67BbD9fB543881757b57bE;
    address XDX = 0x7d34e3C25C6255267074bDEB5171b8F65592c3Bf;
    address public multisig;
    uint256 fee = 10;
    uint256 rate = 5;
    event Buy(address _executor, string token, uint256 _deposit, uint256 _withdraw);

    constructor(address _multisig) {
        require(_multisig != address(0), "Invalid multisig address");
        multisig = _multisig;
        IERC20(XDX).approve(address(this), 10000000000000000000000000);
    }

    function buy(uint256 amount, uint256 multiplier, string memory token) public returns (uint256 result) {
        uint256 decimal = 0;
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDT"))) decimal = 6;
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDC"))) decimal = 6;
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDCE"))) decimal = 18;
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("BUSD"))) decimal = 18;
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("DAI"))) decimal = 18;
        require(msg.sender != address(0), "Address is zero.");
        require(bytes(token).length != 0, "Token is empty.");
        require(amount != 0, "Amount is zero.");
        // require(amount >= 5000 * (10 ** decimal), "Min amount is 5000.");
        // require(amount <= 250000 * (10 ** decimal), "Max amount is 250000.");
        require(result * rate * multiplier < balance(), "Insufficient withdrawal amount.");

        result = amount;

        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDT"))) IERC20(USDT).transferFrom(msg.sender, multisig, result);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDC"))) IERC20(USDC).transferFrom(msg.sender, multisig, result);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDCE"))) IERC20(USDCE).transferFrom(msg.sender, multisig, result);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("BUSD"))) IERC20(BUSD).transferFrom(msg.sender, multisig, result);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("DAI"))) IERC20(DAI).transferFrom(msg.sender, multisig, result);
        IERC20(XDX).transfer(msg.sender, result * rate * multiplier);
        emit Buy(msg.sender, token, result, result * rate * multiplier);
        return result * rate * multiplier;
    }

    function balance() public view returns (uint256) {
        return IERC20(XDX).balanceOf(address(this));
    }

    function withdraw(uint256 amount, string memory token) public onlyOwner {
        require(amount != 0, "Amount is zero.");
        require(bytes(token).length != 0, "Token is empty.");
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDT"))) IERC20(USDT).transfer(msg.sender, amount);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDC"))) IERC20(USDC).transfer(msg.sender, amount);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("USDCE"))) IERC20(USDCE).transfer(msg.sender, amount);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("BUSD"))) IERC20(BUSD).transfer(msg.sender, amount);
        if(keccak256(abi.encodePacked(token)) == keccak256(abi.encodePacked("DAI"))) IERC20(DAI).transfer(msg.sender, amount);
    }

    function renounceRate(uint256 _rate) public onlyOwner {
        require(_rate != 0, "Amount is zero.");
        rate = _rate;
    }

    function renounceMultiSig(address _multisig) public onlyOwner {
        require(_multisig != address(0), "Invalid address");
        multisig = _multisig;
    }
}