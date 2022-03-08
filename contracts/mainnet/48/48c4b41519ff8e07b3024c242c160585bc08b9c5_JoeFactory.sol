/**
 *Submitted for verification at snowtrace.io on 2022-03-08
*/

/*

JoeFactory contract, hire workers to earn JFT.
Website: www.joefactory.finance
Telegram: joefactory

*/


// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

contract JoeFactory {
    using SafeMath for uint256;

    IERC20 public token_1;
	address erctoken = 0x3777C53230589a8d8c293C00249eAcdC6895b052; 

    /** base parameters **/
    uint256 public FACTORIES_TO_HIRE_1WORKERS = 1720000;
    uint256 public FACTORIES_TO_HIRE_1WORKERS_COMPOUND = 1080000;
    uint256 public REFERRAL = 40;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public LOTTERY = 100;
    uint256 public PROJECT = 20;
    uint256 public BUYBACK = 10;
    uint256 public MARKETING = 10;
    uint256 public MARKET_FACTORIES_DIVISOR = 8;
    uint256 public MARKET_FACTORIES_DIVISOR_SELL = 2;

    /** bonus **/
	uint256 public COMPOUND_BONUS = 50; /** 5% **/
	uint256 public COMPOUND_BONUS_MAX_TIMES = 20; /** 20 times / 20 days. **/
    uint256 public COMPOUND_STEP = 24 * 60 * 60; /** every 24 hours. **/

    /** withdrawal tax **/
    uint256 public WITHDRAWAL_TAX = 400;
    uint256 public WITHDRAWAL_TAX_DAYS = 2;

    /** special bonuses **/
    uint256 public COMPOUND_SPECIAL_BONUS;
    uint256 public REFERRAL_EVENT_BONUS;
    uint256 public EVENT_MAX_LOTTERY_TICKET;

    /* lottery */
	bool public LOTTERY_ACTIVATED;
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 10;
    uint256 public LOTTERY_STEP = 4 * 60 * 60; /** every 4 hours. **/
    uint256 public LOTTERY_TICKET_PRICE = 3 ether; /** 3 JFT **/
    uint256 public MAX_LOTTERY_TICKET = 50;
    uint256 public MAX_LOTTERY_PARTICIPANTS = 100;
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;

    /* statistics */
    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;
    uint256 public totalLotteryBonus;

    /* miner parameters */
    uint256 public marketFactories;
    uint256 public PSNS = 50000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;
    bool public specialEventBonus;

    /** whale control features **/
	uint256 public CUTOFF_STEP = 36 * 60 * 60; /** 36 hours  **/
    uint256 public MIN_INVEST = 10 ether; /** 10 JFT  **/
	uint256 public WITHDRAW_COOLDOWN = 12 * 60 * 60; /** 12 hours  **/
    uint256 public WITHDRAW_LIMIT = 6000 ether; /** 6000 JFT  **/
    uint256 public WALLET_DEPOSIT_LIMIT = 30000 ether; /** 30,000 JFT  **/

    /* addresses */
    address payable public owner;
    address payable public marketing;
    address payable public buyback;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 workers;
        uint256 claimedFactories;
        uint256 totalLotteryBonus;
        uint256 lastHatch;
        address referrer;
        uint256 referralsCount;
        uint256 referralFactoryRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 withdrawCount;
        uint256 lastWithdrawTime;
    }

    struct LotteryHistory {
        uint256 round;
        address winnerAddress;
        uint256 pot;
        uint256 totalLotteryParticipants;
        uint256 totalLotteryTickets;
    }

    LotteryHistory[] internal lotteryHistory;
    mapping(address => User) public users;
    mapping(uint256 => mapping(address => uint256)) public ticketOwners; /** round => address => amount of owned points **/
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; /** round => id => address **/
    event LotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);

    constructor(address payable _owner, address payable _marketing, address payable _buyback) {
		require(!isContract(_owner) && !isContract(_marketing) && !isContract(_buyback));
        token_1 = IERC20(erctoken);
        owner = _owner;
        marketing = _marketing;
        buyback = _buyback;
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function hatchFactories(bool isCompound) public {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");

        uint256 factoriesUsed = getMyFactories();
        uint256 factoriesForCompound = factoriesUsed;
        /** isCompound -- only true when compounding. **/
        if(isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, factoriesForCompound);
            if(specialEventBonus) {
                factoriesForCompound = factoriesForCompound.add(factoriesForCompound.mul(COMPOUND_SPECIAL_BONUS).div(PERCENTS_DIVIDER));
            }
            factoriesForCompound = factoriesForCompound.add(dailyCompoundBonus);
            uint256 factoriesUsedValue = calculateFactorySell(factoriesForCompound);
            user.userDeposit = user.userDeposit.add(factoriesUsedValue);
            totalCompound = totalCompound.add(factoriesUsedValue);

            /** use factoriesUsedValue if lottery entry is from compound, bonus will be included.
                check the value if it can buy a ticket. if not, skip lottery. **/
            if (LOTTERY_ACTIVATED && factoriesUsedValue >= LOTTERY_TICKET_PRICE) {
                _buyTickets(msg.sender, factoriesUsedValue);
            }
        } 

        /** compounding bonus add count if greater than COMPOUND_STEP. **/
        if(block.timestamp.sub(user.lastHatch) >= COMPOUND_STEP) {
            if(user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        /**  miner increase -- check if for compound, new deposit and compound can have different percentage basis. **/
        uint256 newWorkers;
        if(isCompound) {
            newWorkers = factoriesForCompound.div(FACTORIES_TO_HIRE_1WORKERS_COMPOUND);
        }else{
            newWorkers = factoriesForCompound.div(FACTORIES_TO_HIRE_1WORKERS);
        }
        user.workers = user.workers.add(newWorkers);
        
        user.claimedFactories = 0;
        user.lastHatch = block.timestamp;

        if(block.timestamp.sub(user.lastWithdrawTime) >= COMPOUND_STEP){
            user.withdrawCount = 0;
        }

    /** lower the increase of marketFactories value for every compound/deposit, this will make the inflation slower.  20%(5) to 8%(12). **/
        marketFactories = marketFactories.add(factoriesUsed.div(MARKET_FACTORIES_DIVISOR));
    }

    function sellFactories() public{
        require(contractStarted);
        User storage user = users[msg.sender];
        uint256 hasFactories = getMyFactories();
        uint256 factoryValue = calculateFactorySell(hasFactories);

        if(user.lastHatch.add(WITHDRAW_COOLDOWN) > block.timestamp) revert("Withdrawals can only be done after withdraw cooldown.");

        /** Excess amount will be sent back to user claimedFactories available for next withdrawal
            if WITHDRAW_LIMIT is not 0 and factoryValue is greater than or equal WITHDRAW_LIMIT **/
        if(WITHDRAW_LIMIT != 0 && factoryValue >= WITHDRAW_LIMIT) {
            user.claimedFactories = factoryValue.sub(WITHDRAW_LIMIT);
            factoryValue = WITHDRAW_LIMIT;
        }else{
            /** reset claim. **/
            user.claimedFactories = 0;
        }
        
        /** reset hatch time. **/      
        user.lastHatch = block.timestamp;
        
        /** reset daily compound bonus. **/
        user.dailyCompoundBonus = 0;

        /** if user withdraw count added 1 is >= 2, implement = 40% tax. **/
        if(user.withdrawCount.add(1) >= WITHDRAWAL_TAX_DAYS){
          factoryValue = factoryValue.sub(factoryValue.mul(WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        }

        user.withdrawCount = user.withdrawCount.add(1); 
        
        /** set last withdrawal time **/
        user.lastWithdrawTime = block.timestamp;

        /** lowering the amount of factories that is being added to the total factories supply to only 5% for each sell **/
        marketFactories = marketFactories.add(hasFactories.div(MARKET_FACTORIES_DIVISOR_SELL));
        
        /** check if contract has enough funds to pay -- one last ride. **/
        if(getBalance() < factoryValue) {
            factoryValue = getBalance();
        }

        uint256 factoriesPayout = factoryValue.sub(payFeesSell(factoryValue));
        
        token_1.transfer(msg.sender, factoriesPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(factoriesPayout);
        totalWithdrawn = totalWithdrawn.add(factoriesPayout);

        /** if no new investment or compound, sell will also trigger lottery. **/
        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants >= MAX_LOTTERY_PARTICIPANTS){
            chooseWinner();
        }
    }

    /** transfer amount of JFT **/
    function buyFactories(address ref, uint256 amount) public payable{
        User storage user = users[msg.sender];
        if (!contractStarted) {
    		if (msg.sender == owner) {
    		    require(marketFactories == 0);
    			contractStarted = true;
                marketFactories = 259200000000;
                LOTTERY_ACTIVATED = true;
                LOTTERY_START_TIME = block.timestamp;
    		} else revert("Contract not yet started.");
    	}
        require(amount >= MIN_INVEST, "Mininum investment not met.");
        require(user.initialDeposit.add(amount) <= WALLET_DEPOSIT_LIMIT, "Max deposit limit reached.");
        
        token_1.transferFrom(address(msg.sender), address(this), amount);
        uint256 factoriesBought = calculateFactoryBuy(amount, getBalance().sub(amount));
        user.userDeposit = user.userDeposit.add(amount);
        user.initialDeposit = user.initialDeposit.add(amount);
        user.claimedFactories = user.claimedFactories.add(factoriesBought);
        /** if lottery entry is from new deposit use deposit amount. **/
        if (LOTTERY_ACTIVATED) {
			_buyTickets(msg.sender, amount);
		}

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1].referralsCount.add(1);
            }
        }
                
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                /** referral rewards will be in JFT **/
                uint256 refRewards = amount.mul(REFERRAL).div(PERCENTS_DIVIDER);
                if(specialEventBonus) {
                    refRewards = refRewards.add(amount.mul(REFERRAL_EVENT_BONUS).div(PERCENTS_DIVIDER));
                }
                token_1.transfer(upline, refRewards);
                /** referral rewards will be in JFT value **/
                users[upline].referralFactoryRewards = users[upline].referralFactoryRewards.add(refRewards);
                totalRefBonus = totalRefBonus.add(refRewards);
            }
        }

        uint256 factoriesPayout = payFees(amount);
        /** less the fee on total Staked to give more transparency of data. **/
        totalStaked = totalStaked.add(amount.sub(factoriesPayout));
        totalDeposits = totalDeposits.add(1);
        hatchFactories(false);
    }

    function payFees(uint256 factoryValue) internal returns(uint256){
        uint256 marketingFee = getFees(factoryValue);
        uint256 buybackFee = factoryValue.mul(BUYBACK).div(PERCENTS_DIVIDER);
        token_1.transfer(marketing, marketingFee);
        token_1.transfer(buyback, buybackFee);
        return marketingFee.add(buybackFee);
    }

    function payFeesSell(uint256 factoryValue) internal returns(uint256){
        uint256 prj = factoryValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        uint256 mkt = factoryValue.mul(MARKETING).div(PERCENTS_DIVIDER);
        uint256 bbk = factoryValue.mul(BUYBACK).div(PERCENTS_DIVIDER);
        token_1.transfer(marketing, prj);
        token_1.transfer(buyback, bbk);
        return prj.add(mkt).add(bbk);
    }

    function getFees(uint256 factoryValue) public view returns(uint256 _marketingFee) {
        _marketingFee = factoryValue.mul(PROJECT).div(PERCENTS_DIVIDER);
    }

    /** lottery section! **/
    function _buyTickets(address userAddress, uint256 amount) private {
        require(amount != 0, "zero purchase amount");
        uint256 userTickets = ticketOwners[lotteryRound][userAddress];
        uint256 numTickets = amount.div(LOTTERY_TICKET_PRICE);

        /** if the user has no tickets before this point, but they just purchased a ticket **/
        if(userTickets == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;

            if(numTickets > 0){
              participants = participants.add(1);
            }
        }

        if(specialEventBonus) {
            MAX_LOTTERY_TICKET = MAX_LOTTERY_TICKET.add(EVENT_MAX_LOTTERY_TICKET);
        }

        if (userTickets.add(numTickets) > MAX_LOTTERY_TICKET) {
            numTickets = MAX_LOTTERY_TICKET.sub(userTickets);
        }

        ticketOwners[lotteryRound][userAddress] = userTickets.add(numTickets);
        /** percentage of deposit/compound amount will be put into the pot **/
        currentPot = currentPot.add(amount.mul(LOTTERY_PERCENT).div(PERCENTS_DIVIDER));
        totalTickets = totalTickets.add(numTickets);

        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants >= MAX_LOTTERY_PARTICIPANTS){
            chooseWinner();
        }
    }

   /** will auto execute, when condition is met. buy, hatch and sell, can be triggered manually by admin if theres no user action. **/
    function chooseWinner() public {
       require(((block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) || participants >= MAX_LOTTERY_PARTICIPANTS),
        "Lottery must run for LOTTERY_STEP or there must be MAX_LOTTERY_PARTICIPANTS particpants");
        /** only draw winner if participant > 0. **/
        if(participants != 0){
            uint256[] memory init_range = new uint256[](participants);
            uint256[] memory end_range = new uint256[](participants);

            uint256 last_range = 0;

            for(uint256 i = 0; i < participants; i++){
                uint256 range0 = last_range.add(1);
                uint256 range1 = range0.add(ticketOwners[lotteryRound][participantAdresses[lotteryRound][i]].div(1e18));

                init_range[i] = range0;
                end_range[i] = range1;
                last_range = range1;
            }

            uint256 random = _getRandom().mod(last_range).add(1);

            for(uint256 i = 0; i < participants; i++){
                if((random >= init_range[i]) && (random <= end_range[i])){

                    /** winner found **/
                    address winnerAddress = participantAdresses[lotteryRound][i];
                    User storage user = users[winnerAddress];

                    /** winner will have the prize in their claimable rewards. **/
                    uint256 factories = currentPot.mul(9).div(10);
                    
                    /** lottery price will be converted to buy workers **/
                    uint256 factoriesReward = calculateFactoryBuy(factories, getBalance().sub(factories));
                    user.workers = user.workers.add(factoriesReward.div(FACTORIES_TO_HIRE_1WORKERS_COMPOUND));

                    /** record users total lottery rewards **/
                    user.totalLotteryBonus = user.totalLotteryBonus.add(factoriesReward);
                    totalLotteryBonus = totalLotteryBonus.add(factoriesReward);
                    uint256 back = currentPot.mul(LOTTERY).div(PERCENTS_DIVIDER);
                    token_1.transfer(buyback, back);

                    /** record round **/
                    lotteryHistory.push(LotteryHistory(lotteryRound, winnerAddress, factories, participants, totalTickets));
                    emit LotteryWinner(winnerAddress, factories, lotteryRound);

                    /** reset lotteryRound **/
                    currentPot = 0;
                    participants = 0;
                    totalTickets = 0;
                    LOTTERY_START_TIME = block.timestamp;
                    lotteryRound = lotteryRound.add(1);
                    break;
                }
            }
        }else{
            /** if lottery step is done but no participant, reset lottery start time. **/
            LOTTERY_START_TIME = block.timestamp;
        }
       
    }

    /** select lottery winner **/
    function _getRandom() private view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,currentPot,block.difficulty, marketFactories, getBalance())));
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns(uint256){
        if(users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            /** add compound bonus percentage **/
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(COMPOUND_BONUS); 
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getLotteryHistory(uint256 index) public view returns(uint256 round, address winnerAddress, uint256 pot,
	  uint256 totalLotteryParticipants, uint256 totalLotteryTickets) {
		round = lotteryHistory[index].round;
		winnerAddress = lotteryHistory[index].winnerAddress;
		pot = lotteryHistory[index].pot;
		totalLotteryParticipants = lotteryHistory[index].totalLotteryParticipants;
		totalLotteryTickets = lotteryHistory[index].totalLotteryTickets;
	}

    function getLotteryInfo() public view returns (uint256 lotteryStartTime,  uint256 lotteryStep, uint256 lotteryCurrentPot,
	  uint256 lotteryParticipants, uint256 maxLotteryParticipants, uint256 totalLotteryTickets, uint256 lotteryTicketPrice, 
      uint256 maxLotteryTicket, uint256 lotteryPercent, uint256 round){
		lotteryStartTime = LOTTERY_START_TIME;
		lotteryStep = LOTTERY_STEP;
		lotteryTicketPrice = LOTTERY_TICKET_PRICE;
		maxLotteryParticipants = MAX_LOTTERY_PARTICIPANTS;
		round = lotteryRound;
		lotteryCurrentPot = currentPot;
		lotteryParticipants = participants;
	    totalLotteryTickets = totalTickets;
        maxLotteryTicket = MAX_LOTTERY_TICKET;
        lotteryPercent = LOTTERY_PERCENT;
	}

    function getUserInfo(address _adr) public view returns(uint256 _initialDeposit, uint256 _userDeposit, uint256 _workers,
     uint256 _claimedFactories, uint256 _totalLotteryBonus, uint256 _lastHatch, address _referrer, uint256 _referrals,
	 uint256 _totalWithdrawn, uint256 _referralFactoryRewards, uint256 _dailyCompoundBonus, uint256 _lastWithdrawTime, uint256 _withdrawCount) {
         _initialDeposit = users[_adr].initialDeposit;
         _userDeposit = users[_adr].userDeposit;
         _workers = users[_adr].workers;
         _claimedFactories = users[_adr].claimedFactories;
         _totalLotteryBonus = users[_adr].totalLotteryBonus;
         _lastHatch = users[_adr].lastHatch;
         _referrer = users[_adr].referrer;
         _referrals = users[_adr].referralsCount;
         _totalWithdrawn = users[_adr].totalWithdrawn;
         _referralFactoryRewards = users[_adr].referralFactoryRewards;
         _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
         _lastWithdrawTime = users[_adr].lastWithdrawTime;
         _withdrawCount = users[_adr].withdrawCount;
	}

    function getBalance() public view returns (uint256) {
        return token_1.balanceOf(address(this));
	}

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserTickets(address _userAddress) public view returns(uint256) {
         return ticketOwners[lotteryRound][_userAddress];
    }

    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(LOTTERY_STEP);
    }

    function getAvailableEarnings(address _adr) public view returns(uint256) {
        uint256 userFactories = users[_adr].claimedFactories.add(getFactoriesSinceLastHatch(_adr));
        return calculateFactorySell(userFactories);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateFactorySell(uint256 factories) public view returns(uint256){
        return calculateTrade(factories, marketFactories, getBalance());
    }

    function calculateFactoryBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth, contractBalance, marketFactories);
    }

    function calculateFactoryBuySimple(uint256 eth) public view returns(uint256){
        return calculateFactoryBuy(eth, getBalance());
    }

    function getFactoriesYield(uint256 amount) public view returns(uint256,uint256) {
        uint256 factoriesAmount = calculateFactoryBuy(amount , getBalance().add(amount).sub(amount));
        uint256 workers = factoriesAmount.div(FACTORIES_TO_HIRE_1WORKERS);
        uint256 day = 1 days;
        uint256 factoriesPerDay = day.mul(workers);
        uint256 earningsPerDay = calculateFactorySellForYield(factoriesPerDay, amount);
        return(workers, earningsPerDay);
    }

    function calculateFactorySellForYield(uint256 factories,uint256 amount) public view returns(uint256){
        return calculateTrade(factories,marketFactories, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (uint256 _totalStaked, uint256 _totalDeposits, uint256 _totalCompound, uint256 _totalRefBonus, uint256 _totalLotteryBonus) {
        return (totalStaked, totalDeposits, totalCompound, totalRefBonus, totalLotteryBonus);
    }

    function getMyWorkers() public view returns(uint256){
        return users[msg.sender].workers;
    }

    function getMyFactories() public view returns(uint256){
        return users[msg.sender].claimedFactories.add(getFactoriesSinceLastHatch(msg.sender));
    }

    function getFactoriesSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsSinceLastHatch = block.timestamp.sub(users[adr].lastHatch);
                            /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastHatch, CUTOFF_STEP);
        uint256 secondsPassed = min(FACTORIES_TO_HIRE_1WORKERS, cutoffTime);
        return secondsPassed.mul(users[adr].workers);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** lottery enabler **/
    function ENABLE_LOTTERY() public {
        require(msg.sender == owner, "Admin use only.");
        require(contractStarted);
        LOTTERY_ACTIVATED = true;
        LOTTERY_START_TIME = block.timestamp;
    }

    function DISABLE_LOTTERY() public {
        require(msg.sender == owner, "Admin use only.");
        require(contractStarted);
        LOTTERY_ACTIVATED = false;
    }

    function PROMO_EVENT_SPECIAL(bool value, uint256 addCompoundBonus, uint256 addReferralEvent, uint256 addMaxTicket) external returns (bool){
        require(msg.sender == owner, "Admin use only.");
        require(addCompoundBonus <= 900, "Additional compound bonus max value is 900(90%)."); /** 90% max **/
        require(addReferralEvent <= 100, "Additional referral bonus max value is 100(10%).");  /** 10% max **/
        require(addMaxTicket <= 100, "Additional ticket bonus max value is 100 tickets."); /** 100 max **/
        specialEventBonus = value;
        COMPOUND_SPECIAL_BONUS = addCompoundBonus;
        REFERRAL_EVENT_BONUS = addReferralEvent;
        EVENT_MAX_LOTTERY_TICKET = addMaxTicket;
        return value;
    }

    /** setup for partners **/
    function hatchFactory(address _addr, uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        User storage user = users[_addr];
        require(value > 0 && value <= PSNS);
        user.workers = user.workers.add(value);
    }

    /** wallet addresses **/
    function CHANGE_OWNERSHIP(address value) external {
        require(msg.sender == owner, "Admin use only.");
        owner = payable(value);
    }

    function CHANGE_PROJECT(address value) external {
        require(msg.sender == owner, "Admin use only.");
        marketing = payable(value);
    }

    /** percentage **/

    /**
        2592000 - 3%
        2160000 - 4%
        1728000 - 5%
        1440000 - 6%
        1200000 - 7%
        1080000 - 8%
         959000 - 9%
         864000 - 10%
         720000 - 12%
         575424 - 15%
         540000 - 16%
         479520 - 18%
    **/
    function PRC_FACTORIES_TO_HIRE_1WORKERS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 479520 && value <= 2592000); /** min 3% max 12%**/
        FACTORIES_TO_HIRE_1WORKERS = value;
    }

    function PRC_FACTORIES_TO_HIRE_1WORKERS_COMPOUND(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 479520 && value <= 2592000); /** min 3% max 12%**/
        FACTORIES_TO_HIRE_1WORKERS_COMPOUND = value;
    }

    function PRC_PROJECT(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        PROJECT = value;
    }

    function PRC_MARKETING(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 20); /** 2% max **/
        MARKETING = value;
    }

    function PRC_LOTTERY(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        LOTTERY = value;
    }

    function PRC_REFERRAL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 100); /** 10% max **/
        REFERRAL = value;
    }

    function PRC_MARKET_FACTORIES_DIVISOR(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 50); /** 50 = 2% **/
        MARKET_FACTORIES_DIVISOR = value;
    }

    function PRC_MARKET_FACTORIES_DIVISOR_SELL(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 50); /** 50 = 2% **/
        MARKET_FACTORIES_DIVISOR_SELL = value;
    }

    /** withdrawal tax **/
    function SET_WITHDRAWAL_TAX(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 500); /** Max Tax is 50% or lower **/
        WITHDRAWAL_TAX = value;
    }

    function SET_WITHDRAW_DAYS_TAX(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 2); /** Minimum 3 days **/
        WITHDRAWAL_TAX_DAYS = value;
    }

    /** bonus **/
    function BONUS_DAILY_COMPOUND(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 10 && value <= 900); /** 90% max **/
        COMPOUND_BONUS = value;
    }

    function BONUS_DAILY_COMPOUND_BONUS_MAX_TIMES(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 30); /** 30 max **/
        COMPOUND_BONUS_MAX_TIMES = value;
    }

    function BONUS_COMPOUND_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
         /** hour conversion **/
        COMPOUND_STEP = value * 60 * 60;
    }

    function SET_BONUS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value <= 70000);
        PSNS = value;
    }

    /* lottery setters */

    function SET_LOTTERY_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
         /** hour conversion **/
        LOTTERY_STEP = value * 60 * 60;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 10 && value <= 50); /** 5% max **/
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        LOTTERY_TICKET_PRICE = value * 1 ether;
    }

    function SET_MAX_LOTTERY_TICKET(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 1 && value <= 100);
        MAX_LOTTERY_TICKET = value;
    }

    function SET_MAX_LOTTERY_PARTICIPANTS(uint256 value) external {
        require(msg.sender == owner, "Admin use only.");
        require(value >= 2 && value <= 200); /** min 10, max 200 **/
        MAX_LOTTERY_PARTICIPANTS = value;
    }

    function SET_INVEST_MIN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        MIN_INVEST = value * 1 ether;
    }

    function SET_CUTOFF_STEP(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value <= 24);
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_WITHDRAW_LIMIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value == 0 || value >= 1);
        WITHDRAW_LIMIT = value * 1 ether;
    }

    function SET_WALLET_DEPOSIT_LIMIT(uint256 value) external {
        require(msg.sender == owner, "Admin use only");
        require(value >= 20);
        WALLET_DEPOSIT_LIMIT = value * 1 ether;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}