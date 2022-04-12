/**
 *Submitted for verification at snowtrace.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT 
 
 /*   ManyStaker - investment platform based on Matic blockchain smart-contract technology. Safe and legit!
 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect browser extension Metamask (see help: https://medium.com/stakingbits/setting-up-metamask-for-polygon-matic-network-838058f6d844 )
 *   2) Choose one of the tariff plans, enter the MATIC amount (10 MATIC minimum) using our website "Stake MATIC" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (~0.04% hourly) - only for new deposits
 *   - Minimal deposit: 10 MATIC, no maximal limit
 *   - Total income: based on your tarrif plan (from 5% to 8% daily!!!) + Basic interest rate !!!
 *   - Earnings every moment, withdraw any time (if you use capitalization of interest you can withdraw only after end of your deposit) 
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3-level referral commission: 5% - 2.5% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 82% Platform main balance, participants payouts
 *   - 7% Advertising and promotion expenses
 *   - 8% Affiliate program bonuses
 *   - 3% Support work, technical functioning, administration fee
 */

pragma solidity >=0.4.22 <0.9.0;

contract ManyStaker {
	using SafeMath for uint256;
	
	address private _owner;

	uint256 constant public INVEST_MIN_AMOUNT = 10 ether;
	uint256[] public REFERRAL_PERCENTS = [50, 25, 5];
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public WITHDRAW_FEE = 1000; //In base point
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalStaked;
	uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 totalBonus;
	}

	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;
	address payable public insuranceWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable _commissionWallet, address payable _insuranceWallet, uint256 startDate) {
		require(!isContract(_commissionWallet));
		require(!isContract(_insuranceWallet));
		commissionWallet = _commissionWallet;
		insuranceWallet = _insuranceWallet;
		if (startDate == 0) {
			startUNIX = block.timestamp.add(10 days);
		}else{
			startUNIX = startDate;
		}
		_owner = msg.sender;

        plans.push(Plan(14, 82));
        plans.push(Plan(21, 76));
        plans.push(Plan(28, 69));
        plans.push(Plan(14, 82));
        plans.push(Plan(21, 76));
        plans.push(Plan(28, 69));
	}

	modifier onlyOwner() {
    	require(isOwner(), "Function accessible only by the owner !!");
    	_;
  	}

	function isOwner() public view returns(bool) {
    	return msg.sender == _owner;
  	}

    function setCommissionWallet(address payable _commissionWallet) external onlyOwner {
        require(_commissionWallet != address(0), "invalid address");
        commissionWallet = _commissionWallet;
    }

    function setInsuranceWallet(address payable _insuranceWallet) external onlyOwner {
        require(_insuranceWallet != address(0), "invalid address");
        insuranceWallet = _insuranceWallet;
    }

	function setStartUNIX(uint256 startDate) public onlyOwner {
		require(block.timestamp < startUNIX, "contract has started");
		require(startDate > block.timestamp, "Invalid startDate");
		startUNIX = startDate;
	}

	function invest(address referrer, uint8 plan) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT, "Invalid invest amount");
        require(plan < 6, "Invalid plan");
        require(block.timestamp >= startUNIX, "contract hasn't started yet");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1); // TODDO: levels unuse
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
		user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(msg.value);
		emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
	}

	function reinvest(uint8 plan) public {
        require(plan < 6, "Invalid plan");
		require(block.timestamp >= startUNIX, "contract hasn't started yet");

        User storage user = users[msg.sender];
     
        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 userReferralBonus = getUserReferralBonus(msg.sender);
        if (userReferralBonus > 0) {
            totalAmount = totalAmount.add(userReferralBonus);
            user.bonus = 0;
        }
        require(totalAmount >= INVEST_MIN_AMOUNT, "Invalid invest amount");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        (uint256 percent, uint256 profit, uint256 finish) = getResult(plan, totalAmount);
        user.deposits.push(Deposit(plan, percent, totalAmount, profit, block.timestamp, finish));

        totalStaked = totalStaked.add(totalAmount);
        emit NewDeposit(msg.sender, plan, percent, totalAmount, profit, block.timestamp, finish);
    }

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		uint256 fees = totalAmount.mul(WITHDRAW_FEE).div(10000);
	    totalAmount = totalAmount.sub(fees);
		require(totalAmount > 0, "User has no dividends");

		user.checkpoint = block.timestamp;
		
		insuranceWallet.transfer(fees);
		payable(msg.sender).transfer(totalAmount); // UPDATE: msg.sender -> payable(msg.sender)

		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan < 3) {
					uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
					if (from < to) {
						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP)); // TODDO: test
					}
				} else if (block.timestamp > user.deposits[i].finish) {
					totalAmount = totalAmount.add(user.deposits[i].profit);
				}
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}