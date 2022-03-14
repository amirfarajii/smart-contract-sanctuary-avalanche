/**
 *Submitted for verification at snowtrace.io on 2022-03-10
*/

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.9;

contract NMACVesting is Ownable {

    bool public saleOpen;
    bool public tokensWithdrawal;
    uint256 public tokensperbnb;

    address public nmacaddress;
    address public oracle;

    address[] public team;

    mapping(address => bool) public WhiteList;
    address payable public teamWallet;
    address public EmergencyAddress;

    event NMAC_Purchased (address _purchaser, uint _bnbamount, uint _tokenamount);
    event Disbursement (address _receipent, uint256 _disbursementnumber, uint256 _disbursemenamount);

    mapping(address => Sale) public Sales;

    uint256 public timeDenominator;

    struct Sale {
        uint256 bnbSpent;
        uint256 totalAllocation;
        bool tge_distributed;
        uint256 tge_distribution_time;
        uint256 lastClaimTime;
        uint256 releasePerSec;
        uint256 amountClaimed;
    }

    struct ImportedSale {
        uint256 bnbSpent;
        address spentBy;
    }

    constructor(address _team, address _token) {
        EmergencyAddress = msg.sender;
        tokensperbnb = 0;
        team = [msg.sender, _team];
        teamWallet = payable(_team);
        oracle = msg.sender;
        nmacaddress = _token;
        setMainnet();
    }

    function setMainnet() internal {
        timeDenominator = 7776000;
    }
    function setTestnet() internal {
        timeDenominator = 300;
    }

    function claim() public {
        require(tokensperbnb > 0, "NMAC PRICE NOT SET");
        if (Sales[msg.sender].tge_distributed) require(Sales[msg.sender].amountClaimed < Sales[msg.sender].totalAllocation, "No more to claim");

        if (!Sales[msg.sender].tge_distributed) {
            Sales[msg.sender].tge_distributed = true;
            Sales[msg.sender].tge_distribution_time = block.timestamp;
            Sales[msg.sender].lastClaimTime = block.timestamp;
            Sales[msg.sender].totalAllocation = Sales[msg.sender].bnbSpent * tokensperbnb;
            uint256 tgeAmount = Sales[msg.sender].totalAllocation / 4;
            Sales[msg.sender].releasePerSec = (tgeAmount * 3) / timeDenominator;
            Sales[msg.sender].amountClaimed = tgeAmount;
            IERC20 _nmactoken = IERC20(nmacaddress);
            _nmactoken.transfer(msg.sender, tgeAmount);
        } else {
            uint256 secondsPassed = block.timestamp - Sales[msg.sender].lastClaimTime;
            uint256 claimableAmount = secondsPassed * Sales[msg.sender].releasePerSec;
            if (claimableAmount >= (Sales[msg.sender].totalAllocation - Sales[msg.sender].amountClaimed)) {
                claimableAmount = Sales[msg.sender].totalAllocation - Sales[msg.sender].amountClaimed;
                Sales[msg.sender].amountClaimed = Sales[msg.sender].totalAllocation;
            } else {
                Sales[msg.sender].amountClaimed += claimableAmount;
            }
            Sales[msg.sender].lastClaimTime = block.timestamp;
            IERC20 _nmactoken = IERC20(nmacaddress);
            _nmactoken.transfer(msg.sender, claimableAmount);
        }
    }

    function claimableTokenAmount(address _address) public view returns (uint256) {
        uint256 secondsPassed = block.timestamp - Sales[_address].lastClaimTime;
        uint256 claimableAmount = secondsPassed * Sales[_address].releasePerSec;
        if (claimableAmount >= (Sales[_address].totalAllocation - Sales[_address].amountClaimed)) {
            claimableAmount = Sales[_address].totalAllocation - Sales[_address].amountClaimed;
        }

        if (!Sales[_address].tge_distributed) claimableAmount = (Sales[_address].bnbSpent * tokensperbnb) / 4;
        return claimableAmount;
    }

    function getAddressBNBSpend(address _address) public view returns (uint256) {
        return Sales[_address].bnbSpent;
    }
    function getAddressTokenAllocation(address _address) public view returns (uint256) {
        return Sales[_address].bnbSpent * tokensperbnb;
    }

    function withdrawToken(address _tokenaddress) public onlyEmergency {
        IERC20 _token = IERC20(_tokenaddress);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
    function withdrawBNB() public onlyEmergency {
        payable(msg.sender).transfer(address(this).balance);
    }
    function withdrawBNBEmergency() public onlyEmergency {
        payable(EmergencyAddress).transfer(address(this).balance);
    }

    function setOracle(address _oracle) public onlyTeam {
        oracle = _oracle;
    }
    function setTokensPerBNB(uint256 _tokensperbnb) public onlyOwner {
        tokensperbnb = _tokensperbnb;
    }
    function setTeam(address[] memory _team) public onlyOwner {
        team = _team;
    }
    function setNMACToken(address _nmacaddress) public onlyOwner {
        nmacaddress = _nmacaddress;
    }

    function setAddressCredit(address _address, uint256 _bnbamount) public onlyOracle {
        Sales[_address].bnbSpent += _bnbamount;
    }
    function setAddressCredits(ImportedSale[] memory _sales) public onlyOracle {
        for ( uint256 x=0; x< _sales.length ; x++ ){
            Sales[_sales[x].spentBy].bnbSpent += _sales[x].bnbSpent;
        }
    }
    function resetAddressCredit(address _address) public onlyOwner {
        Sales[_address].bnbSpent = 0;
    }
    function resetAddressCredits(address[] memory _addresses) public onlyOwner {
        for ( uint256 x=0; x< _addresses.length ; x++ ){
            Sales[_addresses[x]].bnbSpent = 0;
        }
    }

    modifier onlyEmergency() {
        require(msg.sender == EmergencyAddress, "Emergency Only");
        _;
    }
    modifier onlyOracle() {
        require(msg.sender == oracle, "Emergency Only");
        _;
    }
    modifier onlyTeam() {
        bool check;
        for (uint8 x = 0; x < team.length; x++) {
            if (team[x] == msg.sender) check = true;
        }
        require(check == true, "Team Only");
        _;
    }
}