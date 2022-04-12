/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-11
*/

// File: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

// File: contracts/flake/ERC20.sol


pragma solidity 0.6.12;
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

// File: contracts/interfaces/IERC20.sol


pragma solidity =0.6.12;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



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

// File: contracts/veFlake/veFlake.sol

pragma solidity 0.6.12;



contract veFlake is ERC20 {
    using SafeMath for uint256;
    IERC20 public flake;
    address public safeMulsig;

    modifier onlyOrigin() {
        require(msg.sender==safeMulsig, "not mulsafe");
        _;
    }

    event Enter(address indexed user, uint256 indexed flakeAmount,uint256 indexed veFlakeAmount);
    event Leave(address indexed user, uint256 indexed flakeAmount,uint256 indexed veFlakeAmount);
    event ApplyLeave(address indexed user, uint256 indexed veFlakeAmount);
    event CancelLeave(address indexed user, uint256 indexed veFlakeAmount);

    string private name_;
    string private symbol_;
    uint8  private decimals_;

    uint64 public LeavingTerm = 90 days;
    struct pendingItem {
        uint192 pendingAmount;
        uint64 releaseTime;
    }
    struct pendingGroup {
        pendingItem[] pendingAry;
        uint192 pendingDebt;
        uint64 firstIndex;
    }

    mapping(address=>pendingGroup) public userLeavePendingMap;
    // Define the token contract
    constructor(address _multiSignature,string memory tokenName,string memory tokenSymbol,uint256 tokenDecimal) public {
        safeMulsig = _multiSignature;
        name_ = tokenName;
        symbol_ = tokenSymbol;
        decimals_ = uint8(tokenDecimal);
    }

    function setFlake(IERC20 _flake) external onlyOrigin{
        flake = _flake;
    }

    function setLeavingTerm(uint64 _leavingTerm) external onlyOrigin{
        LeavingTerm = _leavingTerm;
    }

    function setMulsig(address _multiSignature) external onlyOrigin{
        safeMulsig = _multiSignature;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return name_;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return decimals_;
    }


    function enter(uint256 _amount) public {
        // Gets the amount of locked in the contract
        uint256 totalFlake = flake.balanceOf(address(this));
        // Gets the amount of veFlake in existence
        uint256 totalShares = totalSupply();
        // If no veFlake exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalFlake == 0) {
            _mint(msg.sender, _amount);
            emit Enter(msg.sender,_amount,_amount);
        }
        // Calculate and mint the amount of veFlake the flake is worth. The ratio will change overtime, as veFlake is burned/minted and flake deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalFlake);
            _mint(msg.sender, what);
            emit Enter(msg.sender,_amount,what);
        }

        // Lock the flake in the contract
        flake.transferFrom(msg.sender, address(this), _amount);


    }

    function leaveApply(uint256 _share) public {
        addPendingInfo(userLeavePendingMap[msg.sender],_share);
        _transfer(msg.sender, address(this), _share);
        emit ApplyLeave(msg.sender, _share);

        //require(getAllPendingAmount(userLeavePendingMap[msg.sender])>=_share,"veFlake: Leave insufficient amount");
    }

    function cancelLeave()public{
        pendingGroup storage userPendings = userLeavePendingMap[msg.sender];
        uint256 pendingLength = userPendings.pendingAry.length;
        require(pendingLength > 0,"veFlake : Empty leave pending queue!");
           // leave();
        uint256 amount = userPendings.pendingAry[uint256(pendingLength-1)].pendingAmount - userPendings.pendingDebt;
        transfer(msg.sender,amount);
        userPendings.firstIndex = uint64(pendingLength);
        userPendings.pendingDebt = userPendings.pendingAry[uint256(pendingLength-1)].pendingAmount;
        emit  CancelLeave(msg.sender,amount);
    }
    // Leave the bar. Claim back your flake.
    // Unlocks the staked + gained flake and burns veFlake
    function leave() public {
        // Gets the amount of veFlake in existence
        uint256 totalShares = totalSupply();
        uint256 _share = updateUserPending(userLeavePendingMap[msg.sender],LeavingTerm);
        // Calculates the amount of flake the veFlake is worth
        uint256 what = _share.mul(flake.balanceOf(address(this))).div(
            totalShares
        );

        _burn(address(this), _share);

        flake.transfer(msg.sender, what);

        emit Leave(msg.sender, what,_share);

    }

    function searchPendingIndex(pendingItem[] memory pendingAry,uint64 firstIndex,uint64 searchTime) internal pure returns (int256){
        uint256 length = pendingAry.length;
        if (uint256(firstIndex)>=length || pendingAry[firstIndex].releaseTime > searchTime) {
            return int256(firstIndex) - 1;
        }
        uint256 min = firstIndex;
        uint256 max = length - 1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (pendingAry[mid].releaseTime == searchTime) {
                min = mid;
                break;
            }
            if (pendingAry[mid].releaseTime < searchTime) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return int256(min);
    }


    function addPendingInfo(pendingGroup storage userPendings,uint256 amount) internal {
        uint256 len = userPendings.pendingAry.length;
        if (len != 0){
            amount = amount.add(userPendings.pendingAry[len-1].pendingAmount);
        }
        userPendings.pendingAry.push(pendingItem(uint192(amount),currentTime()));
    }

    function getUserReleasePendingAmount(address account) public view returns (uint256){
        return getReleasePendingAmount(userLeavePendingMap[account],LeavingTerm);
    }

    function getUserAllPendingAmount(address account) external view returns (uint256) {
        return getAllPendingAmount(userLeavePendingMap[account]);
    }

    function getAllPendingAmount(pendingGroup memory userPendings) internal pure returns (uint256){
        uint256 len = userPendings.pendingAry.length;
        if(len == 0){
            return 0;
        }
        return SafeMath.sub(userPendings.pendingAry[len-1].pendingAmount,userPendings.pendingDebt);
    }

    function getReleasePendingAmount(pendingGroup memory userPendings,uint64 releaseTerm) internal view returns (uint256){
        uint64 curTime = currentTime()-releaseTerm;
        int256 index = searchPendingIndex(userPendings.pendingAry,userPendings.firstIndex,curTime);
        if (index<int256(userPendings.firstIndex)){
            return 0;
        }
        return SafeMath.sub(userPendings.pendingAry[uint256(index)].pendingAmount,userPendings.pendingDebt);
    }

    function getFlakeAmount(uint256 _share) public view returns (uint256) {
        // Gets the amount of veFlake in existence
        uint256 totalShares = totalSupply();
        if(totalShares==0) {
            return _share;
        }
        // Calculates the amount of flake the veFlake is worth
        return _share.mul(flake.balanceOf(address(this))).div(totalShares);

    }

    function getVeFlakeShare(uint256 _amount) public view returns (uint256) {
        uint256 totalFlake = flake.balanceOf(address(this));
        // Gets the amount of veFlake in existence
        uint256 totalShares = totalSupply();
        // If no veFlake exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalFlake == 0) {
            return _amount;
        }
        // Calculate and mint the amount of veFlake the flake is worth. The ratio will change overtime, as veFlake is burned/minted and flake deposited + gained from fees / withdrawn.
        else {
            return _amount.mul(totalShares).div(totalFlake);
        }
    }


    function updateUserPending(pendingGroup storage userPendings,uint64 releaseTerm)internal returns (uint256){
        uint64 curTime = currentTime()-releaseTerm;
        int256 index = searchPendingIndex(userPendings.pendingAry,userPendings.firstIndex,curTime);
        if (index<int256(userPendings.firstIndex)){
            return 0;
        }
        userPendings.firstIndex = uint64(index + 1);
        uint256 amount = SafeMath.sub(userPendings.pendingAry[uint256(index)].pendingAmount,userPendings.pendingDebt);
        userPendings.pendingDebt = userPendings.pendingAry[uint256(index)].pendingAmount;
        return amount;
    }

    function currentTime() internal view virtual returns(uint64){
        return uint64(block.timestamp);
    }


    function getLeaveApplyHistory(address account) external view returns(uint256[] memory,uint256[] memory) {
        pendingGroup memory userPendings = userLeavePendingMap[account];
        uint256 firstIndex = userPendings.firstIndex;

        uint256 len = userPendings.pendingAry.length - userPendings.firstIndex;
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory timeStamps = new uint256[](len);

        for(uint256 i=firstIndex;i<len;i++) {
            uint256 idx = i-firstIndex;
            timeStamps[idx] = userPendings.pendingAry[i].releaseTime;

            if(i==0) {
                amounts[idx] = userPendings.pendingAry[i].pendingAmount;
            } else {
                amounts[idx] = userPendings.pendingAry[i].pendingAmount - userPendings.pendingAry[i-1].pendingAmount;
            }
        }


        return (amounts,timeStamps);
    }
}