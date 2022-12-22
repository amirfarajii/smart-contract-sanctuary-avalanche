// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pulse {

    struct PulseProject {
        bytes32 projectId;
        address owner;
        uint256 goal;
        uint256 deadlineBStamp;
        uint256 raised;
        bool    isCompleted;
        bool    isCancelled;
        bool    isWithdrawn;
        bool   isReimbursed;
    }

    struct PulseInvestment {
        address investor;
        uint256 amount;
    }

    mapping(address => bool) public admins;
    mapping(bytes32 => PulseProject) public projects;
    mapping(bytes32 => address[]) public projectInvestors;
    mapping(address => PulseInvestment[]) public investorInvestments;
    mapping(address => mapping(bytes32 => PulseInvestment[])) public investorProjectInvestments;
    mapping(bytes32 => PulseInvestment[]) public projectInvestments;
    mapping(address => bytes32[]) public projectOwnerIds;


    event ProjectCreated(
        bytes32 projectId,
        address owner,
        uint256 goal,
        uint256 deadlineBStamp
    );

    event ProjectFunded(
        bytes32 projectId,
        address investor,
        uint256 amount
    );

    event ProjectCompleted(
        bytes32 projectId,
        address owner,
        uint256 raised,
        uint256 goal
    );

    event ProjectCancelled(
        bytes32 projectId,
        address owner,
        uint256 raised,
        uint256 goal
    );

    event ProjectInvestorsReimbursed(
        bytes32 projectId,
        address owner,
        uint256 raised
    );

    address public usdtTokenAddress;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can call this function");
        _;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admins[_admin] = !admins[_admin];
    }

    function isAdmin(address _admin) public view returns(bool) {
        return admins[_admin];
    }

    function setUsdtTokenAddress(address _usdtTokenAddress) public onlyAdmin {
        usdtTokenAddress = _usdtTokenAddress;
    }

    function createProject(
        bytes32 _projectId,
        uint256 _goal,
        uint256 _blockstamp
    ) public onlyAdmin {
        require(_goal > 0, "Goal must be greater than 0");
        require(_blockstamp > block.timestamp, "deadlineBStamp must be in the future");
        require(projects[_projectId].owner == address(0), "Project already exists");

        projects[_projectId] = PulseProject(
            _projectId,
            msg.sender,
            _goal,
            _blockstamp,
            0,
            false,
            false,
            false,
            false
        );

        projectOwnerIds[msg.sender].push(_projectId);


        emit ProjectCreated(
            _projectId,
            msg.sender,
            _goal,
            projects[_projectId].deadlineBStamp
        );
    }

    function fundProject(bytes32 _projectId, uint256 _amount) public {
        require(projects[_projectId].owner != address(0), "Project does not exist");
        require(_amount > 0, "Amount must be greater than 0");
        require(!projects[_projectId].isCompleted, "Project is already completed");
        require(!projects[_projectId].isCancelled, "Project is already cancelled");
        require(projects[_projectId].deadlineBStamp > block.timestamp, "Project deadlineBStamp has passed");

        projects[_projectId].raised += _amount;
        // Make usdt token transfer here
        IERC20(usdtTokenAddress).transferFrom(msg.sender, address(this), _amount);

        investorInvestments[msg.sender].push(PulseInvestment(msg.sender, _amount));
        investorProjectInvestments[msg.sender][_projectId].push(PulseInvestment(msg.sender, _amount));

        projectInvestments[_projectId].push(PulseInvestment(msg.sender, _amount));
        bool investorExists = false;
        for(uint256 i = 0; i < projectInvestors[_projectId].length; i++) {
            if(projectInvestors[_projectId][i] == msg.sender) {
                investorExists = true;
                break;
            }
        }
        if(!investorExists) {
            projectInvestors[_projectId].push(msg.sender);
        }


        if(projects[_projectId].raised >= projects[_projectId].goal) {
            projects[_projectId].isCompleted = true;

            emit ProjectCompleted(
                _projectId,
                msg.sender,
                projects[_projectId].raised,
                projects[_projectId].goal
            );
        }

        emit ProjectFunded(
            _projectId,
            msg.sender,
            _amount
        );
    }

    function completeProject(bytes32 _projectId) public onlyAdmin {
        require(projects[_projectId].owner != address(0), "Project does not exist");
        require(!projects[_projectId].isCompleted, "Project is already completed");
        require(!projects[_projectId].isCancelled, "Project is already cancelled");
        require(projects[_projectId].deadlineBStamp > block.timestamp, "Project deadlineBStamp has passed");

        projects[_projectId].isCompleted = true;

        emit ProjectCompleted(
            _projectId,
            msg.sender,
            projects[_projectId].raised,
            projects[_projectId].goal
        );
    }

    function cancelProject(bytes32 _projectId) public onlyAdmin {
        require(projects[_projectId].owner != address(0), "Project does not exist");
        require(!projects[_projectId].isCompleted, "Project is already completed");
        require(!projects[_projectId].isCancelled, "Project is already cancelled");
        require(projects[_projectId].deadlineBStamp > block.timestamp, "Project deadlineBStamp has passed");

        projects[_projectId].isCancelled = true;

        emit ProjectCancelled(
            _projectId,
            msg.sender,
            projects[_projectId].raised,
            projects[_projectId].goal
        );
    }

    function reimbourseInvestors(bytes32 _projectId) public onlyAdmin {
        require(projects[_projectId].owner != address(0), "Project does not exist");
        require(!projects[_projectId].isCancelled, "Project is cancelled");
        require(projects[_projectId].raised > 0, "Project has no funds to withdraw");
        require(IERC20(usdtTokenAddress).balanceOf(address(this)) >= projects[_projectId].raised, "Contract does not have enough funds to withdraw");

        for(uint256 i = 0; i < projectInvestments[_projectId].length; i++) {
            IERC20(usdtTokenAddress).transfer(projectInvestments[_projectId][i].investor, projectInvestments[_projectId][i].amount);
        }

        projects[_projectId].isWithdrawn = true;
        projects[_projectId].isReimbursed = true;

        emit ProjectInvestorsReimbursed(
            _projectId,
            msg.sender,
            projects[_projectId].raised
        );
    }

    function withdrawProjectFunds(address _to, bytes32 _projectId) public onlyAdmin {
        require(projects[_projectId].owner != address(0), "Project does not exist");
        require(projects[_projectId].isCompleted, "Project is not completed");
        require(!projects[_projectId].isCancelled, "Project is cancelled");
        require(projects[_projectId].raised > 0, "Project has no funds to withdraw");
        require(IERC20(usdtTokenAddress).balanceOf(address(this)) >= projects[_projectId].raised, "Contract does not have enough funds to withdraw");

        projects[_projectId].isWithdrawn = true;

        IERC20(usdtTokenAddress).transfer(_to, projects[_projectId].raised);
    }

    function withdraw(address _to, uint256 _amount) public onlyAdmin {
        require(IERC20(usdtTokenAddress).balanceOf(address(this)) >= _amount, "Contract does not have enough funds to withdraw");
        require(_to != address(0), "Withdrawal address must be valid");
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= address(this).balance, "Amount must be less than or equal to contract balance");

        IERC20(usdtTokenAddress).transfer(_to, _amount);
    }

    function withdrawAll(address _to) public onlyAdmin {
        require(_to != address(0), "Withdrawal address must be valid");
        require(IERC20(usdtTokenAddress).balanceOf(address(this)) >= 0, "Contract does not have enough funds to withdraw");


        IERC20(usdtTokenAddress).transfer(_to, IERC20(usdtTokenAddress).balanceOf(address(this)));
    }

            /***********/
            /* GETTERS */
            /***********/
    
    function getProject(bytes32 _projectId) public view returns (PulseProject memory) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projects[_projectId];
    }

    function getProjectInvestors(bytes32 _projectId) public view returns (address[] memory) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projectInvestors[_projectId];
    }

    function getProjectInvestments(bytes32 _projectId) public view returns (PulseInvestment[] memory) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projectInvestments[_projectId];
    }

    function getProjectOwnerIds(address _owner) public view returns (bytes32[] memory) {
        require(_owner != address(0), "Owner must be valid");

        return projectOwnerIds[_owner];
    }

    function getInvestorInvestments(address _investor) public view returns (PulseInvestment[] memory) {
        require(_investor != address(0), "Investor must be valid");

        return investorInvestments[_investor];
    }

    function getInvestorProjectInvestments(address _investor, bytes32 _projectId) public view returns (PulseInvestment[] memory) {
        require(_investor != address(0), "Investor must be valid");
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return investorProjectInvestments[_investor][_projectId];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isProjectFunded(bytes32 _projectId) public view returns (bool) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projects[_projectId].isCompleted;
    }

    function isProjectCanceled(bytes32 _projectId) public view returns (bool) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projects[_projectId].isCancelled;
    }

    function isProjectActive(bytes32 _projectId) public view returns (bool) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return !projects[_projectId].isCompleted && !projects[_projectId].isCancelled && projects[_projectId].deadlineBStamp > block.timestamp;
    }

    function isProjectExpired(bytes32 _projectId) public view returns (bool) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return !projects[_projectId].isCompleted && !projects[_projectId].isCancelled && projects[_projectId].deadlineBStamp <= block.timestamp;
    }

    function getDeadline(bytes32 _projectId) public view returns (uint256) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projects[_projectId].deadlineBStamp;
    }

    function getFundsRaised(bytes32 _projectId) public view returns (uint256) {
        require(projects[_projectId].owner != address(0), "Project does not exist");

        return projects[_projectId].raised;
    }
}