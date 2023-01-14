/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-13
*/

/**
 *Multistake Powered by: 
*/

pragma solidity 0.6.0;

contract MultiStake_BNB {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 0.01 ether;
    uint256[] public REFERRAL_PERCENTS = [50, 20, 10];
    uint256 public constant TOTAL_REF = 80;
    uint256 public constant FUND_FEE = 30;
    uint256 public constant DEV_FEE = 30;
    uint256 public constant MKT_FEE = 30;
    uint256 public constant SPONSOR_FEE = 30;
    uint256 public constant REINVEST_BONUS = 30;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;

    uint256 public totalInvested;
    uint256 public totalReferral;

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

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
    }

    mapping(address => User) internal users;

    uint256 public startDate;

    address payable public fundWallet;
    address payable public devWallet;
    address payable public mktWallet;
    address payable public sponsorWallet;

    event Newbie(address user);
    event NewDeposit(
        address indexed user,
        uint8 plan,
        uint256 amount,
        uint256 time
    );
    event Withdrawn(address indexed user, uint256 amount, uint256 time);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(
        address payable fundAddr,
        address payable devAddr,
        address payable mktAddr,
        address payable sponsorAddr,
        uint256 start
    ) public {
        require(
            !isContract(fundAddr) &&
                !isContract(devAddr) &&
                !isContract(mktAddr) &&
                !isContract(sponsorAddr)
        );
        fundWallet = fundAddr;
        devWallet = devAddr;
        mktWallet = mktAddr;
        sponsorWallet = sponsorAddr;

        if (start > 0) {
            startDate = start;
        } else {
            startDate = block.timestamp;
        }

        plans.push(Plan(100, 13));
        plans.push(Plan(180, 10));
        plans.push(Plan(360, 8));
    }

    function FeePayout(uint256 msgValue) internal {
        uint256 fFee = msgValue.mul(FUND_FEE).div(PERCENTS_DIVIDER);
        uint256 dFee = msgValue.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        uint256 mFee = msgValue.mul(MKT_FEE).div(PERCENTS_DIVIDER);
        uint256 sFee = msgValue.mul(SPONSOR_FEE).div(PERCENTS_DIVIDER);

        mktWallet.transfer(mFee);
        devWallet.transfer(dFee);
        fundWallet.transfer(fFee);
        sponsorWallet.transfer(sFee);

        emit FeePayed(msg.sender, fFee.add(dFee).add(mFee).add(sFee));
    }

    function invest(address referrer, uint8 plan) public payable {
        require(block.timestamp > startDate, "contract does not launch yet");
        require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

        FeePayout(msg.value);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        uint256 refsamount;
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    totalReferral = totalReferral.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    refsamount = refsamount.add(amount);
                }
            }
            if (refsamount > 0) {
                mktWallet.transfer(refsamount.div(4));
                devWallet.transfer(refsamount.div(4));
                fundWallet.transfer(refsamount.div(4));
                sponsorWallet.transfer(refsamount.div(4));
            }
        } else {
            uint256 amount = msg.value.mul(TOTAL_REF).div(PERCENTS_DIVIDER);
            mktWallet.transfer(amount.div(4));
            devWallet.transfer(amount.div(4));
            fundWallet.transfer(amount.div(4));
            sponsorWallet.transfer(amount.div(4));
            totalReferral = totalReferral.add(amount);
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, msg.value, block.timestamp));

        totalInvested = totalInvested.add(msg.value);

        emit NewDeposit(msg.sender, plan, msg.value, block.timestamp);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        require(
            user.checkpoint.add(TIME_STEP) < block.timestamp,
            "only once a day"
        );

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
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);

        msg.sender.transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount, block.timestamp);
    }

    function reinvest(uint8 plan) public {
        User storage user = users[msg.sender];

        require(
            user.checkpoint.add(TIME_STEP) < block.timestamp,
            "only once a day"
        );

        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        FeePayout(totalAmount);

        totalAmount = totalAmount.add(
            totalAmount.mul(REINVEST_BONUS).div(PERCENTS_DIVIDER)
        );

        require(block.timestamp > startDate, "contract does not launch yet");
        require(totalAmount >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

        user.deposits.push(Deposit(plan, totalAmount, block.timestamp));
        totalInvested = totalInvested.add(totalAmount);

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);

        emit NewDeposit(msg.sender, plan, totalAmount, block.timestamp);
    }

    function UpdateStartDate(uint256 _startDate) public {
        require(msg.sender == devWallet, "Only developer can update start date");
        require(block.timestamp < startDate, "Start date must be in future");
        startDate = _startDate;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(TIME_STEP)
            );
            if (user.checkpoint < finish) {
                uint256 share = user
                    .deposits[i]
                    .amount
                    .mul(plans[user.deposits[i].plan].percent)
                    .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.timestamp
                    ? finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
        }

        return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress)
        public
        view
        returns (uint256[3] memory referrals)
    {
        return (users[userAddress].levels);
    }

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            users[userAddress].levels[0] +
            users[userAddress].levels[1] +
            users[userAddress].levels[2];
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress).add(
                getUserDividends(userAddress)
            );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 start,
            uint256 finish
        )
    {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(
            plans[user.deposits[index].plan].time.mul(TIME_STEP)
        );
    }

    function getSiteInfo()
        public
        view
        returns (uint256 _totalInvested, uint256 _totalBonus)
    {
        return (totalInvested, totalReferral);
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 checkpoint,
            uint256 totalDeposit,
            uint256 totalWithdrawn,
            uint256 totalReferrals
        )
    {
        return (
            getUserCheckpoint(userAddress),
            getUserTotalDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            getUserTotalReferrals(userAddress)
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
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