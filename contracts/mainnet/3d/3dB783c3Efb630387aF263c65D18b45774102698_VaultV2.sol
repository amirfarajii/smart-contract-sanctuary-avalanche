//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../interfaces/IStrat.sol";
import "../../interfaces/IVault.sol";
import "./DividendToken.sol";
import "./FeeManagerVaultV2.sol";
import "../../utils/Timelock.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../interfaces/IMasterChefDistribution.sol";
import "../../interfaces/IFeeManager.sol";

contract VaultV2 is FeeManagerVaultV2, Pausable, DividendToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Detailed;
    using SafeERC20 for IERC20;

    // EVENTS
    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event Claim(address indexed user, uint amount);
    event HarvesterChanged(address newHarvester);
    event StrategyChanged(address newStrat);
    event DepositLimitUpdated(uint256 newLimit);
    event NewDistribution(address newDistribution);

    IERC20Detailed public underlying;
    IERC20 public rewards;
    IStrat public strat;
    Timelock public timelock;

    address public harvester;

    // if depositLimit = 0 then there is no deposit limit
    uint256 public depositLimit;
    uint256 public lastDistribution;
    address public distribution;

    modifier onlyHarvester() {
        require(msg.sender == harvester);
        _;
    }

    constructor(
        IERC20Detailed underlying_,
        IERC20 target_,
        IERC20 rewards_,
        address harvester_,
        string memory name_,
        string memory symbol_
    ) DividendToken(target_, name_, symbol_, underlying_.decimals()) {
        underlying = underlying_;
        rewards = rewards_;
        harvester = harvester_;
        // feeRecipient = msg.sender;
        depositLimit = 20000 * (10**underlying_.decimals()); // 20k initial deposit limit
        timelock = new Timelock(msg.sender, 3 days);
        _pause(); // paused until a strategy is connected
    }

    function _payWithdrawalFees(uint256 amt) internal returns (uint256 feesPaid) {
        if (withdrawalFee > 0 && amt > 0) {
            require(feeRecipient != address(0), "ZERO ADDRESS");

            feesPaid = amt.mul(withdrawalFee).div(MAX_FEE);

            underlying.safeTransfer(feeRecipient, feesPaid);
        }
    }

    function calcTotalValue() public view returns (uint256 underlyingAmount) {
        return strat.calcTotalValue();
    }

    function totalYield() public returns (uint256) {
        return strat.totalYield();
    }

    function deposit(uint256 amount) external whenNotPaused {
        require(amount > 0, "ZERO-AMOUNT");

        if (depositLimit > 0) {
            // if deposit limit is 0, then there is no deposit limit
            require(totalSupply().add(amount) <= depositLimit);
        }

        uint initialValue = calcTotalValue();

        underlying.safeTransferFrom(msg.sender, address(strat), amount);
        strat.invest();

        uint deposited = calcTotalValue() - initialValue;

        // Update MasterChefDistribution contract state and distribute unclaimed rewards(if any)
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).stake(msg.sender, deposited);
        }

        _mint(msg.sender, deposited);

        emit Deposit(msg.sender, deposited);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "ZERO-AMOUNT");

        uint initialValue = calcTotalValue();

        strat.divest(amount);

        uint withdrawn = initialValue - calcTotalValue();

        // Update MasterChefDistribution contract state and distribute unclaimed rewards(if any)
        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).withdraw(msg.sender, withdrawn);
        }

        _burn(msg.sender, withdrawn);

        // Withdrawal fees
        uint feesPaid = _payWithdrawalFees(withdrawn);

        underlying.safeTransfer(msg.sender, withdrawn - feesPaid);

        emit Withdraw(msg.sender, withdrawn);
    }

    function unclaimedProfit(address user) external view returns (uint256) {
        return withdrawableDividendOf(user);
    }

    function claim() public returns (uint256 claimed) {
        claimed = withdrawDividend(msg.sender);

        if (distribution != address(0)) {
            IMasterChefDistribution(distribution).getReward(msg.sender);
        }

        emit Claim(msg.sender, claimed);
    }

    // Used to claim on behalf of certain contracts e.g. Uniswap pool
    function claimOnBehalf(address recipient) external {
        require(msg.sender == harvester || msg.sender == owner());
        withdrawDividend(recipient);
    }

    // ==== ONLY OWNER ===== //

    function updateDistribution(address newDistribution) public onlyOwner {
        distribution = newDistribution;
        emit NewDistribution(newDistribution);
    }

    function pauseDeposits(bool trigger) external onlyOwner {
        if (trigger) _pause();
        else _unpause();
    }

    function changeHarvester(address harvester_) external onlyOwner {
        require(harvester_ != address(0), "!ZERO ADDRESS");

        harvester = harvester_;

        emit HarvesterChanged(harvester_);
    }

    // if limit == 0 then there is no deposit limit
    function setDepositLimit(uint256 limit) external onlyOwner {
        depositLimit = limit;

        emit DepositLimitUpdated(limit);
    }

    // Any tokens (other than the target) that are sent here by mistake are recoverable by the owner
    function sweep(address _token) external onlyOwner {
        require(_token != address(target));
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    // ==== ONLY HARVESTER ===== //

    function harvest() external onlyHarvester returns (uint256 afterFee) {
        // Divest and claim rewards
        uint256 claimed = strat.claim();

        require(claimed > 0, "Nothing to harvest");

        if (profitFee > 0) {
            // Calculate fees on underlying
            uint256 fee = claimed.mul(profitFee).div(MAX_FEE);
            afterFee = claimed.sub(fee);
            rewards.safeTransfer(feeRecipient, fee);
        } else {
            afterFee = claimed;
        }

        // Transfer rewards to harvester
        rewards.safeTransfer(harvester, afterFee);
    }

    function distribute(uint256 amount) external onlyHarvester {
        distributeDividends(amount);
        lastDistribution = block.timestamp;
    }

    // ==== ONLY TIMELOCK ===== //

    // The owner has to wait 2 days to confirm changing the strat.
    // This protects users from an upgrade to a malicious strategy
    // Users must watch the timelock contract on Etherscan for any transactions
    function setStrat(IStrat strat_, bool force) external {
        if (address(strat) != address(0)) {
            require(msg.sender == address(timelock), "Only Timelock");
            uint256 prevTotalValue = strat.calcTotalValue();

            strat.divest(prevTotalValue);
            underlying.safeTransfer(address(strat_), underlying.balanceOf(address(this)));
            strat_.invest();

            if (!force) {
                require(strat_.calcTotalValue() >= prevTotalValue);
                require(strat.calcTotalValue() == 0);
            }
        } else {
            require(msg.sender == owner());
            _unpause();
        }
        strat = strat_;

        emit StrategyChanged(address(strat));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IStrat {
    function invest() external virtual; // underlying amount must be sent from vault to strat address before

    function divest(uint256 amount) external virtual; // should send requested amount to vault directly, not less or more

    function totalYield() external virtual returns (uint256);

    function calcTotalValue() external view virtual returns (uint256);

    function claim() external virtual returns (uint256 claimed);

    function router() external virtual returns (address);

    function outputToTarget() external virtual returns (address[] memory);

    function setSwapRoute(address[] memory) external virtual;

    function setRouter(address) external virtual;

    function rescue(
        address _token,
        address _to,
        uint256 _amount
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

interface IVault {
    function totalSupply() external view returns (uint256);

    function harvest() external returns (uint256);

    function distribute(uint256 amount) external;

    function rewards() external view returns (IERC20);

    function underlying() external view returns (IERC20Detailed);

    function target() external view returns (IERC20);

    function harvester() external view returns (address);

    function owner() external view returns (address);

    function distribution() external view returns (address);

    function strat() external view returns (address);

    function timelock() external view returns (address payable);

    function feeRecipient() external view returns (address);

    function claimOnBehalf(address recipient) external;

    function lastDistribution() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function totalYield() external returns (uint256);

    function calcTotalValue() external view returns (uint256);

    function deposit(uint256 amount) external;

    function depositAndWait(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawPending(uint256 amount) external;

    function changePerformanceFee(uint256 fee) external;

    function claim() external returns (uint256 claimed);

    function unclaimedProfit(address user) external view returns (uint256);

    function pending(address user) external view returns (uint256);

    function name() external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../libs/SafeMathUint.sol";
import "../../libs/SafeMathInt.sol";

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute a target token
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendToken is ERC20 {
	using SafeMath for uint256;
	using SafeMathUint for uint256;
	using SafeMathInt for int256;
	using SafeERC20 for IERC20;

	IERC20 public target;

	uint8 _decimals;

	// With `MAGNITUDE`, we can properly distribute dividends even if the amount of received target is small.
	// For more discussion about choosing the value of `MAGNITUDE`,
	//  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
	uint256 internal constant MAGNITUDE = 2**165;

	uint256 internal magnifiedDividendPerShare;

	// About dividendCorrection:
	// If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
	//   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
	// When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
	//   `dividendOf(_user)` should not be changed,
	//   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
	// To keep the `dividendOf(_user)` unchanged, we add a correction term:
	//   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
	//   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
	//   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
	// So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
	mapping(address => int256) internal magnifiedDividendCorrections;
	mapping(address => uint256) internal withdrawnDividends;

	constructor(
		IERC20 target_,
		string memory name_,
		string memory symbol_,
		uint8 decimals_
	) ERC20(name_, symbol_) {
		_decimals = decimals_;
		target = target_;
	}

	function decimals() public view override returns (uint8) {
		return _decimals;
	}

	/// @notice Distributes target to token holders as dividends.
	/// @dev It reverts if the total supply of tokens is 0.
	/// It emits the `DividendsDistributed` event if the amount of received target is greater than 0.
	/// About undistributed target tokens:
	///   In each distribution, there is a small amount of target not distributed,
	///     the magnified amount of which is
	///     `(amount * MAGNITUDE) % totalSupply()`.
	///   With a well-chosen `MAGNITUDE`, the amount of undistributed target
	///     (de-magnified) in a distribution can be less than 1 wei.
	///   We can actually keep track of the undistributed target in a distribution
	///     and try to distribute it in the next distribution,
	///     but keeping track of such data on-chain costs much more than
	///     the saved target, so we don't do that.
	function distributeDividends(uint256 amount) internal {
		require(totalSupply() > 0, "ZERO SUPPLY");
		require(amount > 0, "!AMOUNT");

		magnifiedDividendPerShare = magnifiedDividendPerShare.add(
			(amount).mul(MAGNITUDE) / totalSupply()
		);

		target.safeTransferFrom(msg.sender, address(this), amount);

		emit DividendsDistributed(msg.sender, amount);
	}

	/// @notice Withdraws the target distributed to the sender.
	/// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn target is greater than 0.
	function withdrawDividend(address user)
		internal
		returns (uint256 _withdrawableDividend)
	{
		_withdrawableDividend = withdrawableDividendOf(user);
		if (_withdrawableDividend > 0) {
			withdrawnDividends[user] = withdrawnDividends[user].add(
				_withdrawableDividend
			);
			emit DividendWithdrawn(user, _withdrawableDividend);
			target.safeTransfer(user, _withdrawableDividend);
		}
	}

	/// @notice View the amount of dividend in wei that an address can withdraw.
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` can withdraw.
	function dividendOf(address _owner) external view returns (uint256) {
		return withdrawableDividendOf(_owner);
	}

	/// @notice View the amount of dividend in wei that an address can withdraw.
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` can withdraw.
	function withdrawableDividendOf(address _owner)
		internal
		view
		returns (uint256)
	{
		return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
	}

	/// @notice View the amount of dividend in wei that an address has withdrawn.
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` has withdrawn.
	function withdrawnDividendOf(address _owner)
		external
		view
		returns (uint256)
	{
		return withdrawnDividends[_owner];
	}

	/// @notice View the amount of dividend in wei that an address has earned in total.
	/// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
	/// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / MAGNITUDE
	/// @param _owner The address of a token holder.
	/// @return The amount of dividend in wei that `_owner` has earned in total.
	function accumulativeDividendOf(address _owner)
		public
		view
		returns (uint256)
	{
		return
			magnifiedDividendPerShare
				.mul(balanceOf(_owner))
				.toInt256Safe()
				.add(magnifiedDividendCorrections[_owner])
				.toUint256Safe() / MAGNITUDE;
	}

	/// @dev Internal function that transfer tokens from one address to another.
	/// Update magnifiedDividendCorrections to keep dividends unchanged.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param value The amount to be transferred.
	function _transfer(
		address from,
		address to,
		uint256 value
	) internal override {
		super._transfer(from, to, value);

		int256 _magCorrection = magnifiedDividendPerShare
			.mul(value)
			.toInt256Safe();
		magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from]
			.add(_magCorrection);
		magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(
			_magCorrection
		);
	}

	/// @dev Internal function that mints tokens to an account.
	/// Update magnifiedDividendCorrections to keep dividends unchanged.
	/// @param account The account that will receive the created tokens.
	/// @param value The amount that will be created.
	function _mint(address account, uint256 value) internal override {
		super._mint(account, value);

		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
			account
		].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
	}

	/// @dev Internal function that burns an amount of the token of a given account.
	/// Update magnifiedDividendCorrections to keep dividends unchanged.
	/// @param account The account whose tokens will be burnt.
	/// @param value The amount that will be burnt.
	function _burn(address account, uint256 value) internal override {
		super._burn(account, value);

		magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
			account
		].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
	}

	/// @dev This event MUST emit when target is distributed to token holders.
	/// @param from The address which sends target to this contract.
	/// @param weiAmount The amount of distributed target in wei.
	event DividendsDistributed(address indexed from, uint256 weiAmount);

	/// @dev This event MUST emit when an address withdraws their dividend.
	/// @param to The address which withdraws target from this contract.
	/// @param weiAmount The amount of withdrawn target in wei.
	event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeeManagerVaultV2 is Ownable {
    address public feeRecipient;
    address public keeper;

    // Used to calculate final fee (denominator)
    uint256 public constant MAX_FEE = 10000;

    // Max value for fees
    uint256 public constant WITHDRAWAL_FEE_CAP = 150; // 1.5%
    uint256 public constant PROFIT_FEE_CAP = 3000; // 30%

    // Initial fee values
    uint256 public withdrawalFee = 10; // 0.1%
    uint256 public profitFee = 2000; // 20% of profits harvested

    // Events to be emitted when fees are charged
    event NewProfitFee(uint256 fee);
    event NewWithdrawalFee(uint256 fee);
    event NewFeeRecipient(address newFeeRecipient);
    event NewKeeper(address newKeeper);

    constructor() {
        feeRecipient = msg.sender;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    function setProfitFee(uint256 _fee) public onlyManager {
        require(_fee <= PROFIT_FEE_CAP, "!cap");

        profitFee = _fee;
        emit NewProfitFee(_fee);
    }

    function setWithdrawalFee(uint256 _fee) public onlyManager {
        require(_fee <= WITHDRAWAL_FEE_CAP, "!cap");

        withdrawalFee = _fee;
        emit NewWithdrawalFee(_fee);
    }

    function changeFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "ZERO ADDRESS");

        feeRecipient = newFeeRecipient;
        emit NewFeeRecipient(newFeeRecipient);
    }

    function changeKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "ZERO ADDRESS");

        keeper = newKeeper;
        emit NewKeeper(newKeeper);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Timelock {
	using SafeMath for uint256;

	event NewAdmin(address indexed newAdmin);
	event NewPendingAdmin(address indexed newPendingAdmin);
	event NewDelay(uint256 indexed newDelay);
	event CancelTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event ExecuteTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);
	event QueueTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

	uint256 public constant GRACE_PERIOD = 14 days;
	uint256 public constant MINIMUM_DELAY = 0;
	uint256 public constant MAXIMUM_DELAY = 30 days;

	address public admin;
	address public pendingAdmin;
	uint256 public delay;

	mapping(bytes32 => bool) public queuedTransactions;

	constructor(address admin_, uint256 delay_) {
		require(
			delay_ >= MINIMUM_DELAY,
			"Timelock::constructor: Delay must exceed minimum delay."
		);
		require(
			delay_ <= MAXIMUM_DELAY,
			"Timelock::setDelay: Delay must not exceed maximum delay."
		);

		admin = admin_;
		delay = delay_;
	}

	receive() external payable {}

	function setDelay(uint256 delay_) public {
		require(
			msg.sender == address(this),
			"Timelock::setDelay: Call must come from Timelock."
		);
		require(
			delay_ >= MINIMUM_DELAY,
			"Timelock::setDelay: Delay must exceed minimum delay."
		);
		require(
			delay_ <= MAXIMUM_DELAY,
			"Timelock::setDelay: Delay must not exceed maximum delay."
		);
		delay = delay_;

		emit NewDelay(delay);
	}

	function acceptAdmin() public {
		require(
			msg.sender == pendingAdmin,
			"Timelock::acceptAdmin: Call must come from pendingAdmin."
		);
		admin = msg.sender;
		pendingAdmin = address(0);

		emit NewAdmin(admin);
	}

	function setPendingAdmin(address pendingAdmin_) public {
		require(
			msg.sender == address(this),
			"Timelock::setPendingAdmin: Call must come from Timelock."
		);
		pendingAdmin = pendingAdmin_;

		emit NewPendingAdmin(pendingAdmin);
	}

	function queueTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public returns (bytes32) {
		require(
			msg.sender == admin,
			"Timelock::queueTransaction: Call must come from admin."
		);
		require(
			eta >= getBlockTimestamp().add(delay),
			"Timelock::queueTransaction: Estimated execution block must satisfy delay."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		queuedTransactions[txHash] = true;

		emit QueueTransaction(txHash, target, value, signature, data, eta);
		return txHash;
	}

	function cancelTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public {
		require(
			msg.sender == admin,
			"Timelock::cancelTransaction: Call must come from admin."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		queuedTransactions[txHash] = false;

		emit CancelTransaction(txHash, target, value, signature, data, eta);
	}

	function executeTransaction(
		address target,
		uint256 value,
		string memory signature,
		bytes memory data,
		uint256 eta
	) public payable returns (bytes memory) {
		require(
			msg.sender == admin,
			"Timelock::executeTransaction: Call must come from admin."
		);

		bytes32 txHash = keccak256(
			abi.encode(target, value, signature, data, eta)
		);
		require(
			queuedTransactions[txHash],
			"Timelock::executeTransaction: Transaction hasn't been queued."
		);
		require(
			getBlockTimestamp() >= eta,
			"Timelock::executeTransaction: Transaction hasn't surpassed time lock."
		);
		require(
			getBlockTimestamp() <= eta.add(GRACE_PERIOD),
			"Timelock::executeTransaction: Transaction is stale."
		);

		queuedTransactions[txHash] = false;

		bytes memory callData;

		if (bytes(signature).length == 0) {
			callData = data;
		} else {
			callData = abi.encodePacked(
				bytes4(keccak256(bytes(signature))),
				data
			);
		}

		// solium-disable-next-line security/no-call-value
		(bool success, bytes memory returnData) = target.call{value: value}(
			callData
		);
		require(
			success,
			"Timelock::executeTransaction: Transaction execution reverted."
		);

		emit ExecuteTransaction(txHash, target, value, signature, data, eta);

		return returnData;
	}

	function getBlockTimestamp() internal view returns (uint256) {
		// solium-disable-next-line security/no-block-members
		return block.timestamp;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefDistribution {
    function setFeeAddress(address _feeAddress) external;

    function setPoolId(address _vault, uint256 _id) external;

    function updateVaultAddresses(address _vaultAddress, bool _status) external;

    function balanceOf(address _user) external returns (uint256);

    function getReward(address _user) external;

    function poolLength() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function fund(uint256 _amount) external;

    function add(
        uint256 _allocPoint,
        IERC20 _vault,
        bool _withUpdate,
        uint16 _depositFeeBP
    ) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function deposited(uint256 _pid, address _user) external view returns (uint256);

    function pending(uint256 _pid, address _user) external view returns (uint256);

    function getBoosts(address userAddress) external view returns (uint256);

    function vaultToPoolId(address vaultAddress) external view returns (uint256);

    function totalPending() external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function stake(address userAddress, uint256 _amount) external;

    function withdraw(address userAddress, uint256 _amount) external;

    function poolInfo(uint256 poolId)
        external
        view
        returns (
            address depositToken,
            uint allocPoint,
            uint lastRewardBlock,
            uint accERC20PerShare
        );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeManager {
	function MAX_FEE() external view returns (uint256);

	function getVaultFee(address _vault) external view returns (uint256);

	function setVaultFee(address _vault, uint256 _fee) external;

	function getLendingFee(address _asset) external view returns (uint256);

	function setLendingFee(address _asset, uint256 _fee) external;

	function getSwapFee() external view returns (uint256);

	function setSwapFee(uint256 _swapFee) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
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
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
	function toInt256Safe(uint256 a) internal pure returns (int256) {
		int256 b = int256(a);
		require(b >= 0);
		return b;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SafeMathInt
 * @dev Math operations with safety checks that revert on error
 * @dev SafeMath adapted for int256
 * Based on code of  https://github.com/RequestNetwork/requestNetwork/blob/master/packages/requestNetworkSmartContracts/contracts/base/math/SafeMathInt.sol
 */
library SafeMathInt {
	function mul(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when multiplying INT256_MIN with -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == -2**255 && b == -1) && !(b == -2**255 && a == -1));

		int256 c = a * b;
		require((b == 0) || (c / b == a));
		return c;
	}

	function div(int256 a, int256 b) internal pure returns (int256) {
		// Prevent overflow when dividing INT256_MIN by -1
		// https://github.com/RequestNetwork/requestNetwork/issues/43
		require(!(a == -2**255 && b == -1) && (b > 0));

		return a / b;
	}

	function sub(int256 a, int256 b) internal pure returns (int256) {
		require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

		return a - b;
	}

	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require((b >= 0 && c >= a) || (b < 0 && c < a));
		return c;
	}

	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0);
		return uint256(a);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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