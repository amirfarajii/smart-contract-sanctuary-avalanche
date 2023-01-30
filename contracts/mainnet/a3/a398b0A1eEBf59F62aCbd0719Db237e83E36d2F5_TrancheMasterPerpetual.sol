//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../refs/CoreRef.sol";
import "../interfaces/ITrancheMasterPerpetual.sol";
import "../interfaces/IMasterWTF.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";
import "../interfaces/IWETH.sol";

contract TrancheMasterPerpetual is ITrancheMasterPerpetual, CoreRef, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TrancheParams {
        uint256 fee;
        bool principalFee;
    }

    struct Tranche {
        uint256 principal;
        uint256 autoPrincipal;
        uint256 validPercent;
        uint256 fee;
        uint256 autoValid;
        bool principalFee;
    }

    struct TrancheSnapshot {
        uint256 principal;
        uint256 capital;
        uint256 validPercent;
        uint256 rate;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
        bool rebalanced;
    }

    struct UserInfo {
        uint256 balance;
        bool isAuto;
    }

    uint256 public constant PercentageParamScale = 1e5;
    uint256 public constant PercentageScale = 1e18;
    uint256 private constant MaxFee = 50000;
    uint256 public pendingStrategyWithdrawal = 0;

    uint256 public override producedFee;
    uint256 public override duration = 7 days;
    uint256 public override cycle;
    uint256 public override actualStartAt;
    bool public override active;
    Tranche[] public override tranches;
    address public immutable wNative;
    address public override currency;
    address public override staker;
    address public override strategy;

    address public override devAddress;
    address[] public zeroAddressArr;
    address[] public userInvestPendingAddressArr;

    mapping(address => UserInfo) public override userInfo;
    // userAddress => tid => pendingAmount
    mapping(address => mapping(uint256 => uint256)) public userInvestPending;
    mapping(address => mapping(uint256 => Investment)) public override userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public override trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event WithdrawFee(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 fee, bool principalFee);

    event TrancheUpdated(uint256 tid, uint256 fee, bool principalFee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    event SetDevAddress(address dev);

    modifier checkTranches() {
        require(tranches.length > 1, "tranches is incomplete");
        _;
    }

    modifier checkTrancheID(uint256 tid) {
        require(tid < tranches.length, "invalid tranche id");
        _;
    }

    modifier checkActive() {
        require(active, "not active");
        _;
    }

    modifier checkNotActive() {
        require(!active, "already active");
        _;
    }

    modifier checkNotAuto() {
        require(!userInfo[msg.sender].isAuto, "user autorolling");
        _;
    }

    modifier checkNoPendingStrategyWithdrawal() {
        require(pendingStrategyWithdrawal == 0, "at least 1 strategy is pending for withdrawal");
        _;
    }

    modifier updateInvest(address userAddress) {
        _updateInvest(userAddress);
        _;
    }

    modifier transferTokenToVault(uint256 value) {
        if (msg.value != 0) {
            require(currency == wNative, "currency is not wNative");
            require(value == msg.value, "value != msg.value");
            IWETH(currency).deposit{ value: msg.value }();
        } else {
            IERC20(currency).safeTransferFrom(msg.sender, address(this), value);
        }
        _;
    }

    constructor(
        address _core,
        address _wNative,
        address _currency,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        TrancheParams[] memory _params
    ) public CoreRef(_core) {
        wNative = _wNative;
        currency = _currency;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;

        approveToken();

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].fee, _params[i].principalFee);
        }
        zeroAddressArr.push( address(0) );
    }

    function approveToken() public {
        IERC20(currency).safeApprove(strategy, uint256(-1));
    }

    function setDuration(uint256 _duration) public override onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public override onlyGovernor {
        devAddress = _devAddress;
        emit SetDevAddress(_devAddress);
    }

    function _add(
        uint256 fee,
        bool principalFee
    ) internal {
        require(fee <= MaxFee, "invalid fee");
        tranches.push(
            Tranche({
                fee: fee,
                principal: 0,
                autoPrincipal: 0,
                validPercent: 0,
                autoValid: 0,
                principalFee: principalFee
            })
        );
        emit TrancheAdd(tranches.length - 1, fee, principalFee);
    }

    function add(
        uint256 fee,
        bool principalFee
    ) public override onlyGovernor {
        _add(fee, principalFee);
    }

    function set(
        uint256 tid,
        uint256 fee,
        bool principalFee
    ) public override onlyTimelock checkTrancheID(tid) {
        require(fee <= MaxFee, "invalid fee");
        tranches[tid].fee = fee;
        tranches[tid].principalFee = principalFee;
        emit TrancheUpdated(tid, fee, principalFee);
    }

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        uint256 valid;
        uint256 principal;
        uint256 total;
        uint256 capital;
        uint256 left;
        for (uint i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            principal = inv.principal;
            if (principal == 0) {
                inv.cycle = cycle;
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        inv.rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    emit Harvest(account, i, j, valid, capital);
                    principal = total;
                }
                if (active && !inv.rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    inv.rebalanced = true;
                    inv.principal = valid;
                    u.balance = u.balance.add(left);
                    tranches[i].autoPrincipal = tranches[i].autoPrincipal.sub(left);
                } else {
                    inv.principal = principal;
                }
                IMasterWTF(staker).updateStake(i, account, inv.principal);
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        left = 0;
                        inv.rebalanced = false;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    u.balance = u.balance.add(total);
                    inv.principal = 0;
                    IMasterWTF(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, valid, capital);
                } else if (active && !inv.rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    inv.rebalanced = true;
                    inv.principal = valid;
                    u.balance = u.balance.add(left);
                    tranches[i].principal = tranches[i].principal.sub(left);
                    IMasterWTF(staker).updateStake(i, account, inv.principal);
                }
            }
            inv.cycle = cycle;
        }
    }

    function balanceOf(address account) public view override returns (uint256 balance, uint256 invested) {
        UserInfo memory u = userInfo[account];
        uint256 principal;
        uint256 valid;
        uint256 total;
        uint256 capital;
        uint256 left;
        bool rebalanced;

        balance = u.balance;
        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[account][i];
            rebalanced = inv.rebalanced;
            principal = inv.principal;
            if (principal == 0) {
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    if (rebalanced) {
                        valid = principal;
                        rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    principal = left.add(capital);
                }
                if (active && !rebalanced) {
                    valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                    left = principal
                        .mul(PercentageScale.sub(tranches[i].validPercent))
                        .div(PercentageScale);
                    if (left > 0) {
                        left -= 1;
                    }
                    invested = invested.add(valid);
                    balance = balance.add(left);
                } else {
                    invested = invested.add(principal);
                }
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    if (inv.rebalanced) {
                        valid = principal;
                        rebalanced = false;
                        left = 0;
                    } else {
                        valid = principal.mul(snapshot.validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(snapshot.validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                    }
                    capital = valid.mul(snapshot.rate).div(PercentageScale);
                    total = left.add(capital);
                    balance = balance.add(total);
                } else {
                    if (active && !rebalanced) {
                        valid = principal.mul(tranches[i].validPercent).div(PercentageScale);
                        left = principal
                            .mul(PercentageScale.sub(tranches[i].validPercent))
                            .div(PercentageScale);
                        if (left > 0) {
                            left -= 1;
                        }
                        invested = invested.add(valid);
                        balance = balance.add(left);
                    } else {
                        invested = invested.add(principal);
                    }
                }
            }
        }
    }

    function queueWithdrawal() public nonReentrant {
        _switchAuto(false, msg.sender);
    }

    function _switchAuto(bool _auto, address userAddress) internal updateInvest(userAddress) {
        if (_auto) {
            require(active == false, "cannot switch ON autoroll while the fall is active");
        }
        UserInfo storage u = userInfo[userAddress];
        if (u.isAuto == _auto) {
            return;
        }

        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[userAddress][i];
            if (inv.principal == 0) {
                continue;
            }

            Tranche storage t = tranches[i];
            if (_auto) {
                t.principal = t.principal.sub(inv.principal);
                t.autoPrincipal = t.autoPrincipal.add(inv.principal);
            } else {
                t.principal = t.principal.add(inv.principal);
                t.autoPrincipal = t.autoPrincipal.sub(inv.principal);
                if (active) {
                    t.autoValid = t.autoValid > inv.principal ? t.autoValid.sub(inv.principal) : 0;
                }
            }
        }

        u.isAuto = _auto;
    }

    function _tryStart() internal returns (bool) {
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            if (t.principal.add(t.autoPrincipal) <= 0) {
                return false;
            }
        }

        _startCycle();

        return true;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    )
        public
        override
        payable
        checkTrancheID(tid)
        checkNotActive
        checkNoPendingStrategyWithdrawal
        updateInvest(msg.sender)
        nonReentrant
        transferTokenToVault(amountIn)
    {
        require(amountIn > 0, "invalid amountIn");
        require(amountInvest > 0, "invalid amountInvest");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "balance not enough");

        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, false, msg.sender);
        _switchAuto(true, msg.sender);
    }

    function investDirectPending(
        uint256 amountIn,
        uint256 tid
    )
        public
        payable
        checkTrancheID(tid)
        checkNoPendingStrategyWithdrawal
        nonReentrant
        transferTokenToVault(amountIn)
    {
        require(amountIn > 0, "invalid amountIn");

        userInvestPending[msg.sender][tid] = userInvestPending[msg.sender][tid].add(amountIn);
        userInvestPendingAddressArr.push(msg.sender);
    }

    function _executeInvestDirectPending() private
    {
        for (uint16 i = 0; i < userInvestPendingAddressArr.length; i++) {
            for (uint8 j = 0; j < tranches.length; j++) {
                if (userInvestPending[userInvestPendingAddressArr[i]][j] > 0) {
                    _investDirectPending(userInvestPending[userInvestPendingAddressArr[i]][j], j, userInvestPendingAddressArr[i]);
                    userInvestPending[userInvestPendingAddressArr[i]][j] = 0;
                }
            }
            delete userInvestPendingAddressArr[i];
        }
    }

    function _investDirectPending(
        uint256 amountIn,
        uint256 tid,
        address userAddress
    )
        private
        updateInvest(userAddress)
    {

        UserInfo storage u = userInfo[userAddress];

        u.balance = u.balance.add(amountIn);
        emit Deposit(userAddress, amountIn);

        _invest(tid, amountIn, false, userAddress);
        _switchAuto(true, userAddress);
    }

    function deposit(uint256 amount)
        public
        override
        payable
        updateInvest(msg.sender)
        nonReentrant
        transferTokenToVault(amount)
    {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.add(amount);
        emit Deposit(msg.sender, amount);
    }

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) public override checkTrancheID(tid) checkNotActive checkNoPendingStrategyWithdrawal updateInvest(msg.sender) nonReentrant {
        require(amount > 0, "invalid amount");
        _invest(tid, amount, returnLeft, msg.sender);
    }

    function _invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft,
        address userAddress
    ) private {
        UserInfo storage u = userInfo[userAddress];
        require(amount <= u.balance, "balance not enough");

        Tranche storage t = tranches[tid];
        Investment storage inv = userInvest[userAddress][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        if (u.isAuto) {
            t.autoPrincipal = t.autoPrincipal.add(amount);
        } else {
            t.principal = t.principal.add(amount);
        }

        IMasterWTF(staker).updateStake(tid, userAddress, inv.principal);

        emit Invest(userAddress, tid, cycle, amount);

        if (returnLeft && u.balance > 0) {
            _safeUnwrap(userAddress, u.balance);
            emit Withdraw(userAddress, u.balance);
            u.balance = 0;
        }

    }

    function redeem(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        checkNotAuto
        updateInvest(msg.sender)
        nonReentrant
    {
        _redeem(tid);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;
        require(principal > 0, "not enough principal");

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);

        IMasterWTF(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect(uint256 tid)
        public
        override
        checkTrancheID(tid)
        checkNotActive
        checkNotAuto
        updateInvest(msg.sender)
        nonReentrant
    {
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function redeemDirectPending(uint256 tid)
        public
        checkTrancheID(tid)
        nonReentrant
    {
        uint256 amount = userInvestPending[msg.sender][tid];
        require(amount > 0, "nothing for redemption");
        userInvestPending[msg.sender][tid] = 0;
        _safeUnwrap(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateInvest(msg.sender) nonReentrant {
        require(amount > 0, "invalid amount");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "balance not enough");
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function start() public onlyGovernor checkNoPendingStrategyWithdrawal {
        _startCycle();
    }

    function _startCycle() internal checkNotActive {
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal).add(t.autoPrincipal);
        }

        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche storage t = tranches[i];
            t.validPercent = (t.principal.add(t.autoPrincipal)).mul(PercentageScale).div(t.principal.add(t.autoPrincipal));
            t.autoValid = t.principal == 0 ? t.principal.add(t.autoPrincipal) : t.autoPrincipal.mul(t.validPercent).div(PercentageScale);
            emit TrancheStart(i, cycle, t.principal.add(t.autoPrincipal));
        }
        IMasterWTF(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle(address[] memory _strategyAddresses) internal {
        _processExit(_strategyAddresses);
        active = false;
        cycle++;
        IMasterWTF(staker).next(cycle);
    }

    function _calculateExchangeRate(uint256 current, uint256 base) internal pure returns (uint256) {
        if (current == base) {
            return PercentageScale;
        } else if (current > base) {
            return PercentageScale.add((current - base).mul(PercentageScale).div(base));
        } else {
            return PercentageScale.sub((base - current).mul(PercentageScale).div(base));
        }
    }

    struct ProcessExitVariables {
        uint256 totalPrincipal;
        uint256 totalYield;
        uint256 seniorYield;
        uint256 seniorYieldDistribution;
        uint256 seniorProportion;
        uint256 seniorIndex;
        uint256 juniorIndex;
    }

    function _processExit(address[] memory _strategyAddresses) internal {
        require(tranches.length == 2, "MUST be 2 tranches");
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw(_strategyAddresses);

        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        uint256 restCapital = total;
        uint256 interestShouldBe;
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 _now = block.timestamp;

        ProcessExitVariables memory p;
        p.seniorIndex = 0;
        Tranche storage senior = tranches[p.seniorIndex];
        p.juniorIndex = tranches.length - 1;
        Tranche storage junior = tranches[p.juniorIndex];
        p.totalPrincipal = senior.principal.add(senior.autoPrincipal).add(junior.principal).add(junior.autoPrincipal);
        if (restCapital >= p.totalPrincipal) {
            p.totalYield = restCapital.sub(p.totalPrincipal);
        } else {
            p.totalYield = 0;
        }
        principal = senior.principal + senior.autoPrincipal;
        capital = 0;
        p.seniorProportion = principal.mul(PercentageScale).div(p.totalPrincipal);
        if (p.seniorProportion <= 25e16) {
            p.seniorYieldDistribution = p.seniorProportion;
        } else if (p.seniorProportion <= 50e16) {
            // linear eqaution y = mx + c when x=25, y=25 and when x=50, y=35 (c is much larger to fit with 18 decimals)
            p.seniorYieldDistribution = p.seniorProportion.mul(2).div(5).add(15e16);
        } else {
            // linear eqaution y = mx + c when x=50, y=35 and when x=99, y=40
            p.seniorYieldDistribution = (p.seniorProportion.mul(5).add(1465e16)).div(49);
        }
        p.seniorYield = p.totalYield.mul(p.seniorYieldDistribution).div(PercentageScale);

        uint256 all = principal.add(p.seniorYield);
        bool satisfied = restCapital >= all;
        if (!satisfied) {
            capital = restCapital;
            restCapital = 0;
        } else {
            capital = all;
            restCapital = restCapital.sub(all);
        }

        uint256 fee;
        if (senior.principalFee) {
            fee = satisfied ? capital.mul(senior.fee).div(PercentageParamScale) : 0;
        } else if (capital > principal) {
            fee = capital.sub(principal).mul(senior.fee).div(PercentageParamScale);
        }
        if (fee > 0) {
            producedFee = producedFee.add(fee);
            capital = capital.sub(fee);
        }

        cycleExchangeRate = _calculateExchangeRate(capital, principal);
        trancheSnapshots[cycle][p.seniorIndex] = TrancheSnapshot({
            principal: principal,
            capital: capital,
            validPercent: senior.validPercent,
            rate: cycleExchangeRate,
            fee: senior.fee,
            startAt: actualStartAt,
            stopAt: _now
        });

        senior.principal = 0;

        senior.autoPrincipal = senior.autoValid
            .mul(cycleExchangeRate)
            .div(PercentageScale)
            .add(senior.autoPrincipal > senior.autoValid ? senior.autoPrincipal.sub(senior.autoValid) : 0);

        emit TrancheSettle(p.seniorIndex, cycle, principal, capital, cycleExchangeRate);

        principal = junior.principal + junior.autoPrincipal;
        capital = restCapital;
        if (junior.principalFee) {
            fee = capital.mul(junior.fee).div(PercentageParamScale);
        } else if (capital > principal) {
            fee = capital.sub(principal).mul(junior.fee).div(PercentageParamScale);
        }
        if (fee > 0) {
            producedFee = producedFee.add(fee);
            capital = capital.sub(fee);
        }
        cycleExchangeRate = _calculateExchangeRate(capital, principal);
        trancheSnapshots[cycle][p.juniorIndex] = TrancheSnapshot({
            principal: principal,
            capital: capital,
            validPercent: junior.validPercent,
            rate: cycleExchangeRate,
            fee: junior.fee,
            startAt: actualStartAt,
            stopAt: now
        });

        junior.principal = 0;
        junior.autoPrincipal = junior.autoValid
            .mul(cycleExchangeRate)
            .div(PercentageScale)
            .add(junior.autoPrincipal > junior.autoValid ? junior.autoPrincipal.sub(junior.autoValid) : 0);

        emit TrancheSettle(p.juniorIndex, cycle, principal, capital, cycleExchangeRate);
    }

    function stop() public override checkActive nonReentrant {        
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _stopCycle(zeroAddressArr);
        _executeInvestDirectPending();
        _tryStart();
    }

    function stopAndUpdateStrategiesAndRatios(address[] calldata _strategies, uint256[] calldata _ratios) public override checkActive nonReentrant onlyTimelock {
        require(block.timestamp >= actualStartAt + duration, "cycle not expired");
        _stopCycle(zeroAddressArr);
        _executeInvestDirectPending();
        IMultiStrategyToken(strategy).updateStrategiesAndRatios(_strategies, _ratios);
        _tryStart();
    }

    function emergencyStop(address[] memory _strategyAddresses) public checkActive nonReentrant onlyGovernor {
        pendingStrategyWithdrawal = IMultiStrategyToken(strategy).strategyCount() - _strategyAddresses.length;
        _stopCycle(_strategyAddresses);
    }

    function recoverFund(address[] memory _strategyAddresses) public checkNotActive nonReentrant onlyGovernor {
        require(pendingStrategyWithdrawal > 0, "no strategy is pending for withdrawal");
        pendingStrategyWithdrawal -= _strategyAddresses.length;
        uint256 before = IERC20(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw(_strategyAddresses);
        uint256 total = IERC20(currency).balanceOf(address(this)).sub(before);
        _safeUnwrap(devAddress, total);
    }

    function setStaker(address _staker) public override onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public override onlyGovernor {
        strategy = _strategy;
    }

    function withdrawFee(uint256 amount) public override {
        require(amount <= producedFee, "not enough balance for fee");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            _safeUnwrap(devAddress, amount);
            emit WithdrawFee(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public override onlyGovernor {
        require(_amount > 0, "Zero amount");
        IERC20(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }

    function _safeUnwrap(address to, uint256 amount) internal {
        if (currency == wNative) {
            IWETH(currency).withdraw(amount);
            Address.sendValue(payable(to), amount);
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/ICore.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

abstract contract CoreRef is Pausable {
    event CoreUpdate(address indexed _core);

    ICore private _core;

    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    constructor(address core_) public {
        _core = ICore(core_);
    }

    modifier onlyGovernor() {
        require(_core.isGovernor(msg.sender), "CoreRef::onlyGovernor: Caller is not a governor");
        _;
    }

    modifier onlyGuardian() {
        require(_core.isGuardian(msg.sender), "CoreRef::onlyGuardian: Caller is not a guardian");
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef::onlyGuardianOrGovernor: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyMultistrategy() {
        require(_core.isMultistrategy(msg.sender), "CoreRef::onlyMultistrategy: Caller is not a multistrategy");
        _;
    }

    modifier onlyTimelock() {
        require(_core.hasRole(TIMELOCK_ROLE, msg.sender), "CoreRef::onlyTimelock: Caller is not a timelock");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "CoreRef::onlyRole: Not permit");
        _;
    }

    modifier onlyRoleOrOpenRole(bytes32 role) {
        require(
            _core.hasRole(role, address(0)) || _core.hasRole(role, msg.sender),
            "CoreRef::onlyRoleOrOpenRole: Not permit"
        );
        _;
    }

    modifier onlyNonZeroAddress(address targetAddress) {
        require(targetAddress != address(0), "address cannot be set to 0x0");
        _;
    }

    modifier onlyNonZeroAddressArray(address[] calldata targetAddresses) {
        for (uint256 i = 0; i < targetAddresses.length; i++) {
            require(targetAddresses[i] != address(0), "address cannot be set to 0x0");
        }
        _;
    }

    function setCore(address core_) external onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function pause() public onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public onlyGuardianOrGovernor {
        _unpause();
    }

    function core() public view returns (ICore) {
        return _core;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface ITrancheMasterPerpetual {
    function setDuration(uint256 _duration) external;

    function setDevAddress(address _devAddress) external;

    function add(
        uint256 fee,
        bool principalFee
    ) external;

    function set(
        uint256 tid,
        uint256 fee,
        bool principalFee
    ) external;

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested);

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) external payable;

    function deposit(uint256 amount) external payable;

    function invest(
        uint256 tid,
        uint256 amount,
        bool returnLeft
    ) external;

    function redeem(uint256 tid) external;

    function redeemDirect(uint256 tid) external;

    function withdraw(uint256 amount) external;

    function stop() external;

    function stopAndUpdateStrategiesAndRatios(address[] calldata _strategies, uint256[] calldata _ratios) external;

    function setStaker(address _staker) external;

    function setStrategy(address _strategy) external;

    function withdrawFee(uint256 amount) external;

    function transferFeeToStaking(uint256 _amount, address _pool) external;

    function producedFee() external view returns (uint256);

    function duration() external view returns (uint256);

    function cycle() external view returns (uint256);

    function actualStartAt() external view returns (uint256);

    function active() external view returns (bool);

    function tranches(uint256 id)
        external
        view
        returns (
            uint256 principal,
            uint256 autoPrincipal,
            uint256 validPercent,
            uint256 fee,
            uint256 autoValid,
            bool principalFee
        );

    function currency() external view returns (address);

    function staker() external view returns (address);

    function strategy() external view returns (address);

    function devAddress() external view returns (address);

    function userInfo(address account) external view returns (uint256, bool);

    function userInvest(address account, uint256 tid)
        external
        view
        returns (
            uint256 cycle,
            uint256 principal,
            bool rebalanced
        );

    function trancheSnapshots(uint256 cycle, uint256 tid)
        external
        view
        returns (
            uint256 principal,
            uint256 capital,
            uint256 validPercent,
            uint256 rate,
            uint256 fee,
            uint256 startAt,
            uint256 stopAt
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IMasterWTF {
    function rewardToken() external view returns (address);

    function rewardPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function cycleId() external view returns (uint256);

    function rewarding() external view returns (bool);

    function votingEscrow() external view returns (address);

    function poolInfo(uint256 pid) external view returns (uint256);

    function userInfo(uint256 pid, address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 cid,
            uint256 earned
        );

    function poolSnapshot(uint256 cid, uint256 pid)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare
        );

    function poolLength() external view returns (uint256);

    function add(uint256 _allocPoint) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setVotingEscrow(address _votingEscrow) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingReward(address _user, uint256 _pid) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) external;

    function start(uint256 _endBlock) external;

    function next(uint256 _cid) external;

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfNoLock,
        uint256 _newLockExpiryTsIfLockExists
    ) external;

    function claimAll(uint256 _lockDurationIfNoLock, uint256 _newLockExpiryTsIfLockExists) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IStrategyToken {
    function token() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdraw(address[] memory _strategyAddresses) external;

    function approveToken() external;
}

interface IMultiStrategyToken is IStrategyToken {
    function strategies(uint256 idx) external view returns (address);

    function strategyCount() external view returns (uint256);

    function ratios(address _strategy) external view returns (uint256);

    function ratioTotal() external view returns (uint256);

    function updateStrategiesAndRatios(address[] calldata _strategies, uint256[] calldata _ratios) external;

    function changeRatio(uint256 _index, uint256 _value) external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IFeeRewards {
    function sendRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICore {
    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isMultistrategy(address _address) external view returns (bool);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function grantMultistrategy(address multistrategy) external;

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}