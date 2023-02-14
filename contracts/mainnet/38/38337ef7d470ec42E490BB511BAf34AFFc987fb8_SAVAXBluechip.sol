// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { DCABaseUpgradeableCutted } from "../base/DCABaseUpgradeableCutted.sol";
import { DCABaseUpgradeable } from "../base/DCABaseUpgradeable.sol";
import { IAltPool } from "../../../dependencies/platypus/IAltPool.sol";
import { IMasterPlatypusV4 } from "../../../dependencies/platypus/IMasterPlatypusV4.sol";
import { SwapLib } from "../libraries/SwapLib.sol";
import { InvestableLib } from "../../../common/libraries/InvestableLib.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SAVAXBluechip is UUPSUpgradeable, DCABaseUpgradeableCutted {
    using SwapLib for SwapLib.Router;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct PlatypusInfo {
        IAltPool altPoolAvax;
        IMasterPlatypusV4 masterPlatypusV4;
        IERC20Upgradeable altSAvaxLpToken;
        IERC20Upgradeable platypusToken;
        IERC20Upgradeable qiToken;
        uint256 poolId; // 13
    }

    TokenInfo public bluechipTokenInfo;

    PlatypusInfo public platypusInfo;

    address[] public ptpIntoBluechipSwapPath;
    address[] public qiIntoBluechipSwapPath;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        DCAStrategyInitArgs calldata args,
        TokenInfo calldata bluechipTokenInfo_,
        PlatypusInfo calldata platypusInfo_,
        address[] calldata ptpIntoBluechipSwapPath_,
        address[] calldata qiIntoBluechipSwapPath_
    ) external initializer {
        __UUPSUpgradeable_init();
        __DCABaseUpgradeable_init(args);

        bluechipTokenInfo = bluechipTokenInfo_;
        platypusInfo = platypusInfo_;
        ptpIntoBluechipSwapPath = ptpIntoBluechipSwapPath_;
        qiIntoBluechipSwapPath = qiIntoBluechipSwapPath_;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ----- Base Contract Overrides -----
    function _invest(uint256 amount)
        internal
        virtual
        override
        returns (uint256 receivedAltLp)
    {
        // 1. Approve bluechip to alt pool
        bluechipTokenInfo.token.safeIncreaseAllowance(
            address(platypusInfo.altPoolAvax),
            amount
        );

        // 2. Deposit bluechip into alt pool. Receive minted alt pool lp token
        receivedAltLp = platypusInfo.altPoolAvax.deposit(
            address(bluechipTokenInfo.token),
            amount,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        // 3. Approve alt lp token to master platypus
        platypusInfo.altSAvaxLpToken.safeIncreaseAllowance(
            address(platypusInfo.masterPlatypusV4),
            receivedAltLp
        );

        // 4. Deposit alt lp into master platypus
        platypusInfo.masterPlatypusV4.deposit(
            platypusInfo.poolId,
            receivedAltLp
        );
    }

    function _claimRewards() internal virtual override returns (uint256) {
        // fetch earned rewards
        (
            uint256 pendingPtp,
            ,
            ,
            uint256[] memory pendingBonusTokens
        ) = platypusInfo.masterPlatypusV4.pendingTokens(
                platypusInfo.poolId,
                address(this)
            );

        // check if we can claim something
        if (pendingPtp == 0 && pendingBonusTokens[0] == 0) {
            return 0;
        }

        uint256[] memory pids = new uint256[](1);
        pids[0] = platypusInfo.poolId;

        // 1. Claim rewards from master platypus
        platypusInfo.masterPlatypusV4.multiClaim(pids);

        // 2. Receive qi + ptp token rewards
        uint256 receivedPtp = platypusInfo.platypusToken.balanceOf(
            address(this)
        );
        uint256 receivedQi = platypusInfo.qiToken.balanceOf(address(this));

        // 3. Swap received rewawrds into bluechip
        return _swapRewards(receivedPtp, receivedQi);
    }

    function _withdrawInvestedBluechip(uint256 amount)
        internal
        virtual
        override
        returns (uint256 receivedBluechip)
    {
        // 1. Unstake alp lp from master platypus
        platypusInfo.masterPlatypusV4.withdraw(platypusInfo.poolId, amount);

        // 2. Approve alt lp to alt pool avax
        platypusInfo.altSAvaxLpToken.safeIncreaseAllowance(
            address(platypusInfo.altPoolAvax),
            amount
        );

        // 3. Withdraw bluechip from alt pool avax
        receivedBluechip = platypusInfo.altPoolAvax.withdraw(
            address(bluechipTokenInfo.token),
            amount,
            0,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function _transferBluechip(address to, uint256 amount)
        internal
        virtual
        override
    {
        bluechipTokenInfo.token.safeTransfer(to, amount);
    }

    function _totalBluechipInvested()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
            // in case of investing all bluechip funds are invested into master platypus
            return
                platypusInfo
                    .masterPlatypusV4
                    .getUserInfo(platypusInfo.poolId, address(this))
                    .amount;
        }

        if (bluechipInvestmentState == BluechipInvestmentState.Withdrawn) {
            // in case of withdrawn all bluechip is hodling on contract balance
            return bluechipTokenInfo.token.balanceOf(address(this));
        }

        // When emergency exit was triggered the strategy
        // no longer holds any bluechip asset
        return 0;
    }

    function _bluechipAddress()
        internal
        view
        virtual
        override
        returns (address)
    {
        return address(bluechipTokenInfo.token);
    }

    function _bluechipDecimals()
        internal
        view
        virtual
        override
        returns (uint8)
    {
        return bluechipTokenInfo.decimals;
    }

    // ----- Private Helper Functions -----
    function _swapRewards(uint256 ptpReward, uint256 qiReward)
        private
        returns (uint256 receivedBleuchip)
    {
        uint256 ptpToBluechip = router.getAmountOut(
            ptpReward,
            ptpIntoBluechipSwapPath
        );
        if (ptpToBluechip > 0) {
            receivedBleuchip += router.swapTokensForTokens(
                ptpReward,
                ptpIntoBluechipSwapPath
            );
        }

        uint256 qiToBluechip = router.getAmountOut(
            qiReward,
            qiIntoBluechipSwapPath
        );
        if (qiToBluechip > 0) {
            receivedBleuchip += router.swapTokensForTokens(
                qiReward,
                qiIntoBluechipSwapPath
            );
        }
    }

    // ----- Setter Functions -----
    function setRewardsSwapPath(
        address[] memory newPtpIntoAvaxSwapPath,
        address[] memory newQiIntoBluechipSwapPath
    ) external onlyOwner {
        ptpIntoBluechipSwapPath = newPtpIntoAvaxSwapPath;
        qiIntoBluechipSwapPath = newQiIntoBluechipSwapPath;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { InvestQueueLib } from "../libraries/InvestQueueLib.sol";
import { DCAHistoryLib } from "../libraries/DCAHistoryLib.sol";
import { IDCAStrategy } from "../interfaces/IDCAStrategy.sol";
import { SwapLib } from "../libraries/SwapLib.sol";
import { PortfolioAccessBaseUpgradeable } from "./PortfolioAccessBaseUpgradeable.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// solhint-disable-next-line max-states-count
abstract contract DCABaseUpgradeableCutted is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    PortfolioAccessBaseUpgradeable
{
    error TooSmallDeposit();
    error PositionsLimitReached();
    error NothingToInvest();
    error NothingToWithdraw();

    event Deposit(address indexed sender, uint256 amount, uint256 amountSplit);
    event Invest(
        uint256 depositAmountSpent,
        uint256 bluechipReceived,
        uint256 investedAt,
        uint256 historicalIndex
    );
    event Withdraw(
        address indexed sender,
        uint256 withdrawnDeposit,
        uint256 withdrawnBluechip
    );
    event StatusChanged(
        BluechipInvestmentState indexed prevStatus,
        BluechipInvestmentState indexed newStatus
    );

    struct DCAEquityValuation {
        uint256 totalDepositToken;
        uint256 totalBluechipToken;
        address bluechipToken;
    }

    struct DCAStrategyInitArgs {
        DepositFee depositFee;
        address dcaInvestor;
        TokenInfo depositTokenInfo;
        uint256 investmentPeriod;
        uint256 lastInvestmentTimestamp;
        uint256 minDepositAmount;
        uint16 positionsLimit;
        SwapLib.Router router;
        address[] depositToBluechipSwapPath;
        address[] bluechipToDepositSwapPath;
    }

    struct DepositFee {
        address feeReceiver;
        uint16 fee; // .0000 number
    }

    struct TokenInfo {
        IERC20Upgradeable token;
        uint8 decimals;
    }

    struct Position {
        uint256 depositAmount;
        uint8 amountSplit;
        uint256 investedAt;
        uint256 investedAtHistoricalIndex;
    }

    struct DCADepositor {
        Position[] positions;
    }

    enum BluechipInvestmentState {
        Investing,
        Withdrawn,
        EmergencyExited
    }

    using InvestQueueLib for InvestQueueLib.InvestQueue;
    using DCAHistoryLib for DCAHistoryLib.DCAHistory;
    using SwapLib for SwapLib.Router;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    DepositFee public depositFee;

    address public dcaInvestor;

    TokenInfo public depositTokenInfo;
    uint256 private depositTokenScale;

    uint256 public investmentPeriod;
    uint256 public lastInvestmentTimestamp;
    uint256 public minDepositAmount;

    uint16 public positionsLimit;

    address[] public depositToBluechipSwapPath;
    address[] public bluechipToDepositSwapPath;

    BluechipInvestmentState public bluechipInvestmentState;

    InvestQueueLib.InvestQueue private globalInvestQueue;
    DCAHistoryLib.DCAHistory private dcaHistory;
    SwapLib.Router public router;

    TokenInfo public emergencyExitDepositToken;
    uint256 public emergencySellDepositPrice;
    TokenInfo public emergencyExitBluechipToken;
    uint256 public emergencySellBluechipPrice;

    mapping(address => DCADepositor) private depositors;

    uint256[10] private __gap;

    // solhint-disable-next-line
    function __DCABaseUpgradeable_init(DCAStrategyInitArgs calldata args)
        internal
        onlyInitializing
    {
        __PortfolioAccessBaseUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        setBluechipInvestmentState(BluechipInvestmentState.Investing);
        setDepositFee(args.depositFee);
        setDCAInvestor(args.dcaInvestor);
        // setDepositTokenInto(args.depositTokenInfo);
        depositTokenInfo = args.depositTokenInfo;
        depositTokenScale = 10**args.depositTokenInfo.decimals;
        setInvestmentPeriod(args.investmentPeriod);
        setLastInvestmentTimestamp(args.lastInvestmentTimestamp);
        setMinDepositAmount(args.minDepositAmount);
        setPositionsLimit(args.positionsLimit);
        setRouter(args.router);
        setSwapPath(
            args.depositToBluechipSwapPath,
            args.bluechipToDepositSwapPath
        );
    }

    modifier nonEmergencyExited() {
        require(
            bluechipInvestmentState != BluechipInvestmentState.EmergencyExited,
            "Strategy is emergency exited"
        );

        _;
    }

    receive() external payable {}

    // ----- Base Class Methods -----
    function deposit(uint256 amount, uint8 amountSplit)
        public
        virtual
        nonReentrant
        whenNotPaused
        nonEmergencyExited
    {
        _deposit(_msgSender(), amount, amountSplit);
    }

    function depositFor(
        address sender,
        uint256 amount,
        uint8 amountSplit
    )
        public
        virtual
        onlyPortfolio
        nonReentrant
        whenNotPaused
        nonEmergencyExited
    {
        _deposit(sender, amount, amountSplit);
    }

    function _deposit(
        address sender,
        uint256 amount,
        uint8 amountSplit
    ) private {
        // assert valid amount sent
        if (amount < minDepositAmount) {
            revert TooSmallDeposit();
        }

        // transfer deposit token from portfolio
        depositTokenInfo.token.safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );

        // compute actual deposit and transfer fee to receiver
        if (depositFee.fee > 0) {
            uint256 actualDeposit = (amount * (10000 - depositFee.fee)) / 10000;

            uint256 feeAmount = amount - actualDeposit;
            if (feeAmount != 0) {
                depositTokenInfo.token.safeTransfer(
                    depositFee.feeReceiver,
                    feeAmount
                );
            }

            amount = actualDeposit;
        }

        DCADepositor storage depositor = depositors[sender];

        // assert positions limit is not reached
        if (depositor.positions.length == positionsLimit) {
            revert PositionsLimitReached();
        }

        // add splitted amounts to the queue
        globalInvestQueue.splitUserInvestmentAmount(amount, amountSplit);

        // if not started position with the same split exists - increase deposit amount
        for (uint256 i = 0; i < depositor.positions.length; i++) {
            // calculate amount of passed investment epochs
            uint256 passedInvestPeriods = (lastInvestmentTimestamp -
                depositor.positions[i].investedAt) / investmentPeriod;

            if (
                passedInvestPeriods == 0 &&
                depositor.positions[i].amountSplit == amountSplit
            ) {
                // not started position with the same amount split exists
                // just add invested amount here
                depositor.positions[i].depositAmount += amount;

                emit Deposit(sender, amount, amountSplit);
                return;
            }
        }

        // otherwise create new position
        depositor.positions.push(
            Position(
                amount,
                amountSplit,
                lastInvestmentTimestamp,
                dcaHistory.currentHistoricalIndex()
            )
        );

        emit Deposit(sender, amount, amountSplit);
    }

    function invest()
        public
        virtual
        nonReentrant
        whenNotPaused
        nonEmergencyExited
    {
        require(_msgSender() == dcaInvestor, "Unauthorized");

        // declare total amount for event data
        uint256 totalDepositSpent;
        uint256 totalBluechipReceived;

        // assert triggered at valid period
        uint256 passedInvestPeriods = _getPassedInvestPeriods();
        if (passedInvestPeriods == 0) {
            revert NothingToInvest();
        }

        // iterate over passed invest periods
        for (uint256 i = 0; i < passedInvestPeriods; i++) {
            uint256 depositedAmount = globalInvestQueue
                .getCurrentInvestmentAmountAndMoveNext();

            // nobody invested in the queue, just skip this period
            if (depositedAmount == 0) {
                continue;
            }

            // swap deposit amount into invest token
            uint256 receivedBluechip = router.swapTokensForTokens(
                depositedAmount,
                depositToBluechipSwapPath
            );

            if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
                // invest exchanged amount
                // since protocol might mint less or more tokens refresh amount
                receivedBluechip = _invest(receivedBluechip);
            }

            // store information about spent asset and received asset
            dcaHistory.addHistoricalGauge(depositedAmount, receivedBluechip);

            // compute totals for event
            totalDepositSpent += depositedAmount;
            totalBluechipReceived += receivedBluechip;
        }

        if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
            // claim rewards
            uint256 claimedBluechipRewards = _claimRewards();

            // if something was claimed invest rewards and increase current gauge
            if (claimedBluechipRewards > 0) {
                claimedBluechipRewards = _invest(claimedBluechipRewards);
                dcaHistory.increaseHistoricalGaugeAt(
                    claimedBluechipRewards,
                    dcaHistory.currentHistoricalIndex() - 1
                );

                // increase total amount for event
                totalBluechipReceived += claimedBluechipRewards;
            }
        }

        // update last invest timestamp
        lastInvestmentTimestamp += passedInvestPeriods * investmentPeriod;

        emit Invest(
            totalDepositSpent,
            totalBluechipReceived,
            lastInvestmentTimestamp,
            dcaHistory.currentHistoricalIndex()
        );
    }

    function withdrawAll(bool convertBluechipIntoDepositAsset)
        public
        virtual
        nonReentrant
        whenNotPaused
    {
        if (isEmergencyExited()) {
            _emergencyWithdrawUserDeposit(_msgSender());
            return;
        }
        _withdrawAll(_msgSender(), convertBluechipIntoDepositAsset);
    }

    function withdrawAllFor(
        address sender,
        bool convertBluechipIntoDepositAsset
    ) public virtual onlyPortfolio nonReentrant whenNotPaused {
        if (isEmergencyExited()) {
            _emergencyWithdrawUserDeposit(sender);
            return;
        }
        _withdrawAll(sender, convertBluechipIntoDepositAsset);
    }

    function _withdrawAll(address sender, bool convertBluechipIntoDepositAsset)
        private
    {
        // define total not invested yet amount by user
        // and total bought bluechip asset amount
        uint256 notInvestedYet;
        uint256 investedIntoBluechip;

        DCADepositor storage depositor = depositors[sender];
        for (uint256 i = 0; i < depositor.positions.length; i++) {
            (
                uint256 positionBluechipInvestment,
                uint256 positionNotInvestedYet
            ) = _computePositionWithdrawAll(depositor.positions[i]);

            // increase users total amount
            investedIntoBluechip += positionBluechipInvestment;
            notInvestedYet += positionNotInvestedYet;
        }

        // since depositor withdraws everything
        // we can remove his data completely
        delete depositors[sender];

        // if convertion requested swap bluechip -> deposit asset
        if (investedIntoBluechip != 0) {
            if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
                investedIntoBluechip = _withdrawInvestedBluechip(
                    investedIntoBluechip
                );
            }

            if (convertBluechipIntoDepositAsset) {
                notInvestedYet += router.swapTokensForTokens(
                    investedIntoBluechip,
                    bluechipToDepositSwapPath
                );
                investedIntoBluechip = 0;
            }
        }

        if (notInvestedYet != 0) {
            depositTokenInfo.token.safeTransfer(sender, notInvestedYet);
        }

        if (investedIntoBluechip != 0) {
            _transferBluechip(sender, investedIntoBluechip);
        }

        emit Withdraw(sender, notInvestedYet, investedIntoBluechip);
    }

    function _computePositionWithdrawAll(Position memory position)
        private
        returns (uint256 investedIntoBluechip, uint256 notInvestedYet)
    {
        // calculate amount of passed investment epochs
        uint256 passedInvestPeriods = (lastInvestmentTimestamp -
            position.investedAt) / investmentPeriod;

        // in case everything was already invested
        // just set amount of epochs to be equal to amount split
        if (passedInvestPeriods > position.amountSplit) {
            passedInvestPeriods = position.amountSplit;
        }

        // compute per period investment - depositAmount / split
        uint256 perPeriodInvestment = position.depositAmount /
            position.amountSplit;

        uint8 futureInvestmentsToRemove = position.amountSplit -
            uint8(passedInvestPeriods);

        // remove not invested yet amount from invest queue
        if (futureInvestmentsToRemove > 0) {
            globalInvestQueue.removeUserInvestment(
                perPeriodInvestment,
                futureInvestmentsToRemove
            );
        }

        // if investment period already started then we should calculate
        // both not invested deposit asset and owned bluechip asset
        if (passedInvestPeriods > 0) {
            (
                uint256 bluechipInvestment,
                uint256 depositAssetInvestment
            ) = _removeUserInvestmentFromHistory(
                    position,
                    passedInvestPeriods,
                    perPeriodInvestment
                );

            investedIntoBluechip += bluechipInvestment;
            notInvestedYet += position.depositAmount - depositAssetInvestment;
        } else {
            // otherwise investment not started yet
            // so we remove whole deposit token amount
            notInvestedYet += position.depositAmount;
        }
    }

    function withdrawBluechipFromPool() external onlyOwner {
        require(
            bluechipInvestmentState == BluechipInvestmentState.Investing,
            "Invalid investment state"
        );

        uint256 bluechipBalance = _totalBluechipInvested();
        uint256 actualReceived = _withdrawInvestedBluechip(bluechipBalance);
        _spreadDiffAfterReinvestment(bluechipBalance, actualReceived);

        setBluechipInvestmentState(BluechipInvestmentState.Withdrawn);

        emit StatusChanged(
            BluechipInvestmentState.Investing,
            BluechipInvestmentState.Withdrawn
        );
    }

    function reInvestBluechipIntoPool() external onlyOwner {
        require(
            bluechipInvestmentState == BluechipInvestmentState.Withdrawn,
            "Invalid investment state"
        );

        uint256 bluechipBalance = _totalBluechipInvested();
        uint256 actualReceived = _invest(bluechipBalance);
        _spreadDiffAfterReinvestment(bluechipBalance, actualReceived);

        setBluechipInvestmentState(BluechipInvestmentState.Investing);

        emit StatusChanged(
            BluechipInvestmentState.Withdrawn,
            BluechipInvestmentState.Investing
        );
    }

    function _spreadDiffAfterReinvestment(
        uint256 bluechipBalance,
        uint256 actualReceived
    ) private {
        if (actualReceived > bluechipBalance) {
            // in case we received more increase current gauge
            dcaHistory.increaseHistoricalGaugeAt(
                actualReceived - bluechipBalance,
                dcaHistory.currentHistoricalIndex() - 1
            );
        } else if (actualReceived < bluechipBalance) {
            // in case we received less we should take loss from gauges
            // so that users will be able to withdraw exactly owned amounts
            // _deductLossFromGauges(bluechipBalance - actualReceived);

            uint256 diff = bluechipBalance - actualReceived;
            for (
                uint256 i = dcaHistory.currentHistoricalIndex() - 1;
                i >= 0;
                i--
            ) {
                (, uint256 gaugeBluechipBalancee) = dcaHistory
                    .historicalGaugeByIndex(i);

                // if gauge balance is higher then diff simply remove diff from it
                if (gaugeBluechipBalancee >= diff) {
                    dcaHistory.decreaseHistoricalGaugeByIndex(i, 0, diff);
                    return;
                } else {
                    // otherwise deduct as much as possible and go to the next one
                    diff -= gaugeBluechipBalancee;
                    dcaHistory.decreaseHistoricalGaugeByIndex(
                        i,
                        0,
                        gaugeBluechipBalancee
                    );
                }
            }
        }
    }

    function emergencyWithdrawFunds(
        TokenInfo calldata emergencyExitDepositToken_,
        address[] calldata depositSwapPath,
        TokenInfo calldata emergencyExitBluechipToken_,
        address[] calldata bluechipSwapPath
    ) external onlyOwner nonEmergencyExited {
        // if status Investing we should first withdraw bluechip from pool
        uint256 currentBluechipBalance;
        if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
            currentBluechipBalance = _withdrawInvestedBluechip(
                _totalBluechipInvested()
            );
        }

        // set status to withdrawn to refetch actual bluechip balance
        setBluechipInvestmentState(BluechipInvestmentState.Withdrawn);
        currentBluechipBalance = _totalBluechipInvested();

        // store emergency exit token info
        emergencyExitDepositToken = emergencyExitDepositToken_;
        emergencyExitBluechipToken = emergencyExitBluechipToken_;

        // if deposit token != emergency exit token then swap it
        if (depositTokenInfo.token != emergencyExitDepositToken.token) {
            // swap deposit into emergency exit token
            uint256 currentDepositTokenBalance = depositTokenInfo
                .token
                .balanceOf(address(this));
            uint256 receivedEmergencyExitDepositAsset = router
                .swapTokensForTokens(
                    currentDepositTokenBalance,
                    depositSwapPath
                );

            // store token price for future conversions
            emergencySellDepositPrice =
                (_scaleAmount(
                    receivedEmergencyExitDepositAsset,
                    emergencyExitDepositToken.decimals,
                    depositTokenInfo.decimals
                ) * depositTokenScale) /
                currentDepositTokenBalance;
        }

        // if bluechip token != emergency exit token then swap it
        if (_bluechipAddress() != address(emergencyExitBluechipToken.token)) {
            // swap bluechip into emergency exit token
            uint256 receivedEmergencyExitBluechipAsset = router
                .swapTokensForTokens(currentBluechipBalance, bluechipSwapPath);

            // store token price for future conversions
            emergencySellBluechipPrice =
                (_scaleAmount(
                    receivedEmergencyExitBluechipAsset,
                    emergencyExitBluechipToken.decimals,
                    _bluechipDecimals()
                ) * _bluechipTokenScale()) /
                currentBluechipBalance;
        }

        // set proper strategy state
        setBluechipInvestmentState(BluechipInvestmentState.EmergencyExited);

        emit StatusChanged(
            BluechipInvestmentState.Investing,
            BluechipInvestmentState.EmergencyExited
        );
    }

    function _emergencyWithdrawUserDeposit(address sender) private {
        uint256 notInvestedYet;
        uint256 investedIntoBluechip;

        DCADepositor storage depositor = depositors[sender];
        for (uint256 i = 0; i < depositor.positions.length; i++) {
            (
                uint256 positionBluechipInvestment,
                uint256 positionNotInvestedYet
            ) = _computePositionWithdrawAll(depositor.positions[i]);

            investedIntoBluechip += positionBluechipInvestment;
            notInvestedYet += positionNotInvestedYet;
        }

        // since depositor withdraws everything
        // we can remove his data completely
        delete depositors[sender];

        // if deposit token != emergency exit token compute share
        if (depositTokenInfo.token != emergencyExitDepositToken.token) {
            uint256 payout = _scaleAmount(
                (notInvestedYet * emergencySellDepositPrice) /
                    depositTokenScale,
                depositTokenInfo.decimals,
                emergencyExitDepositToken.decimals
            );

            if (payout != 0) {
                emergencyExitDepositToken.token.safeTransfer(sender, payout);
            }
        } else {
            // otherwise send deposit token
            if (notInvestedYet != 0) {
                depositTokenInfo.token.safeTransfer(sender, notInvestedYet);
            }
        }

        // if bluechip != emergency exit token compute share
        if (_bluechipAddress() != address(emergencyExitBluechipToken.token)) {
            uint256 payout = _scaleAmount(
                (investedIntoBluechip * emergencySellBluechipPrice) /
                    _bluechipTokenScale(),
                _bluechipDecimals(),
                emergencyExitBluechipToken.decimals
            );

            if (payout != 0) {
                emergencyExitBluechipToken.token.safeTransfer(sender, payout);
            }
        } else {
            // otherwise send bluechip token
            if (investedIntoBluechip != 0) {
                _transferBluechip(sender, investedIntoBluechip);
            }
        }
    }

    // ----- Base Class Setters -----
    function setBluechipInvestmentState(BluechipInvestmentState newState)
        private
        onlyOwner
    {
        bluechipInvestmentState = newState;
    }

    function setDepositFee(DepositFee memory newDepositFee) public onlyOwner {
        require(
            newDepositFee.feeReceiver != address(0),
            "Invalid fee receiver"
        );
        require(newDepositFee.fee <= 10000, "Invalid fee percentage");
        depositFee = newDepositFee;
    }

    function setDCAInvestor(address newDcaInvestor) public onlyOwner {
        require(newDcaInvestor != address(0), "Invalid DCA investor");
        dcaInvestor = newDcaInvestor;
    }

    // function setDepositTokenInto(TokenInfo memory newDepositTokenInfo) private {
    //     require(
    //         address(newDepositTokenInfo.token) != address(0),
    //         "Invalid deposit token address"
    //     );
    //     depositTokenInfo = newDepositTokenInfo;
    //     depositTokenScale = 10**depositTokenInfo.decimals;
    // }

    function setInvestmentPeriod(uint256 newInvestmentPeriod) public onlyOwner {
        require(newInvestmentPeriod > 0, "Invalid investment period");
        investmentPeriod = newInvestmentPeriod;
    }

    function setLastInvestmentTimestamp(uint256 newLastInvestmentTimestamp)
        private
    {
        require(
            // solhint-disable-next-line not-rely-on-time
            newLastInvestmentTimestamp >= block.timestamp,
            "Invalid last invest ts"
        );
        lastInvestmentTimestamp = newLastInvestmentTimestamp;
    }

    function setMinDepositAmount(uint256 newMinDepositAmount) public onlyOwner {
        require(newMinDepositAmount > 0, "Invalid min deposit amount");
        minDepositAmount = newMinDepositAmount;
    }

    function setPositionsLimit(uint16 newPositionsLimit) public onlyOwner {
        require(newPositionsLimit > 0, "Invalid positions limit");
        positionsLimit = newPositionsLimit;
    }

    function setRouter(SwapLib.Router memory newRouter) public onlyOwner {
        require(newRouter.router != address(0), "Invalid router");
        router = newRouter;
    }

    function setSwapPath(
        address[] memory depositToBluechip,
        address[] memory bluechipToDeposit
    ) public onlyOwner {
        require(
            depositToBluechip[0] ==
                bluechipToDeposit[bluechipToDeposit.length - 1] &&
                depositToBluechip[depositToBluechip.length - 1] ==
                bluechipToDeposit[0],
            "Invalid swap path"
        );

        depositToBluechipSwapPath = depositToBluechip;
        bluechipToDepositSwapPath = bluechipToDeposit;
    }

    // ----- Pausable -----
    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    // ----- Query Methods -----
    function canInvest() public view virtual returns (bool) {
        return _getPassedInvestPeriods() > 0 && !isEmergencyExited();
    }

    function depositorInfo(address depositor)
        public
        view
        virtual
        returns (DCADepositor memory)
    {
        return depositors[depositor];
    }

    function equityValuation()
        public
        view
        virtual
        returns (DCAEquityValuation[] memory)
    {
        DCAEquityValuation[] memory valuation = new DCAEquityValuation[](1);
        if (isEmergencyExited()) {
            valuation[0].totalDepositToken = emergencyExitDepositToken
                .token
                .balanceOf(address(this));
            valuation[0].totalBluechipToken = emergencyExitBluechipToken
                .token
                .balanceOf(address(this));
            valuation[0].bluechipToken = address(
                emergencyExitBluechipToken.token
            );

            return valuation;
        }

        valuation[0].totalDepositToken = depositTokenInfo.token.balanceOf(
            address(this)
        );
        valuation[0].totalBluechipToken = _totalBluechipInvested();
        valuation[0].bluechipToken = _bluechipAddress();

        return valuation;
    }

    function getInvestAmountAt(uint8 index) external view returns (uint256) {
        return globalInvestQueue.investAmounts[index];
    }

    function currentInvestQueueIndex() external view returns (uint8) {
        return globalInvestQueue.current;
    }

    function getHistoricalGaugeAt(uint256 index)
        external
        view
        returns (uint256, uint256)
    {
        return dcaHistory.historicalGaugeByIndex(index);
    }

    function currentDCAHistoryIndex() external view returns (uint256) {
        return dcaHistory.currentHistoricalIndex();
    }

    function isEmergencyExited() public view virtual returns (bool) {
        return
            bluechipInvestmentState == BluechipInvestmentState.EmergencyExited;
    }

    function depositToken() public view returns (IERC20Upgradeable) {
        return depositTokenInfo.token;
    }

    // ----- Private Base Class Helper Functions -----
    function _getPassedInvestPeriods() private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp - lastInvestmentTimestamp) / investmentPeriod;
    }

    function _removeUserInvestmentFromHistory(
        Position memory position,
        uint256 passedInvestPeriods,
        uint256 perPeriodInvestment
    )
        private
        returns (uint256 bluechipInvestment, uint256 depositAssetInvestment)
    {
        // iterate over historical gauges since initial deposit
        for (
            uint256 j = position.investedAtHistoricalIndex;
            j < position.investedAtHistoricalIndex + passedInvestPeriods;
            j++
        ) {
            // total spent and received at selected investment day
            (
                uint256 totalAmountSpent,
                uint256 totalAmountExchanged
            ) = dcaHistory.historicalGaugeByIndex(j);

            // calculate amount that user ownes in current gauge
            uint256 depositorOwnedBluechip = (totalAmountExchanged *
                perPeriodInvestment) / totalAmountSpent;

            bluechipInvestment += depositorOwnedBluechip;
            depositAssetInvestment += perPeriodInvestment;

            // decrease gauge info
            dcaHistory.decreaseHistoricalGaugeByIndex(
                j,
                perPeriodInvestment,
                depositorOwnedBluechip
            );
        }

        return (bluechipInvestment, depositAssetInvestment);
    }

    function _bluechipTokenScale() private view returns (uint256) {
        return 10**_bluechipDecimals();
    }

    function _scaleAmount(
        uint256 amount,
        uint8 decimals,
        uint8 scaleToDecimals
    ) internal pure returns (uint256) {
        if (decimals < scaleToDecimals) {
            return amount * uint256(10**uint256(scaleToDecimals - decimals));
        } else if (decimals > scaleToDecimals) {
            return amount / uint256(10**uint256(decimals - scaleToDecimals));
        }
        return amount;
    }

    // ----- Functions For Child Contract -----
    function _invest(uint256 amount) internal virtual returns (uint256);

    function _claimRewards() internal virtual returns (uint256);

    function _withdrawInvestedBluechip(uint256 amount)
        internal
        virtual
        returns (uint256);

    function _transferBluechip(address to, uint256 amount) internal virtual;

    function _totalBluechipInvested() internal view virtual returns (uint256);

    function _bluechipAddress() internal view virtual returns (address);

    function _bluechipDecimals() internal view virtual returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { InvestQueueLib } from "../libraries/InvestQueueLib.sol";
import { DCAHistoryLib } from "../libraries/DCAHistoryLib.sol";
import { IDCAStrategy } from "../interfaces/IDCAStrategy.sol";
import { SwapLib } from "../libraries/SwapLib.sol";
import { PortfolioAccessBaseUpgradeable } from "./PortfolioAccessBaseUpgradeable.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// solhint-disable-next-line max-states-count
abstract contract DCABaseUpgradeable is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    PortfolioAccessBaseUpgradeable,
    IDCAStrategy
{
    using InvestQueueLib for InvestQueueLib.InvestQueue;
    using DCAHistoryLib for DCAHistoryLib.DCAHistory;
    using SwapLib for SwapLib.Router;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    DepositFee public depositFee;

    address public dcaInvestor;

    TokenInfo public depositTokenInfo;
    uint256 private depositTokenScale;

    uint256 public investmentPeriod;
    uint256 public lastInvestmentTimestamp;
    uint256 public minDepositAmount;

    uint16 public positionsLimit;

    address[] public depositToBluechipSwapPath;
    address[] public bluechipToDepositSwapPath;

    BluechipInvestmentState public bluechipInvestmentState;

    InvestQueueLib.InvestQueue private globalInvestQueue;
    DCAHistoryLib.DCAHistory private dcaHistory;
    SwapLib.Router public router;

    TokenInfo public emergencyExitDepositToken;
    uint256 public emergencySellDepositPrice;
    TokenInfo public emergencyExitBluechipToken;
    uint256 public emergencySellBluechipPrice;

    mapping(address => DCADepositor) private depositors;

    uint256[10] private __gap;

    // solhint-disable-next-line
    function __DCABaseUpgradeable_init(DCAStrategyInitArgs calldata args)
        internal
        onlyInitializing
    {
        __PortfolioAccessBaseUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        setBluechipInvestmentState(BluechipInvestmentState.Investing);
        setDepositFee(args.depositFee);
        setDCAInvestor(args.dcaInvestor);
        setDepositTokenInto(args.depositTokenInfo);
        setInvestmentPeriod(args.investmentPeriod);
        setLastInvestmentTimestamp(args.lastInvestmentTimestamp);
        setMinDepositAmount(args.minDepositAmount);
        setPositionsLimit(args.positionsLimit);
        setRouter(args.router);
        setSwapPath(
            args.depositToBluechipSwapPath,
            args.bluechipToDepositSwapPath
        );
    }

    modifier onlyDCAInvestor() {
        require(_msgSender() == dcaInvestor, "Unauthorized");
        _;
    }

    modifier nonEmergencyExited() {
        require(
            bluechipInvestmentState != BluechipInvestmentState.EmergencyExited,
            "Strategy is emergency exited"
        );

        _;
    }

    modifier emergencyWithdrawOnEmergencyExitedStatus(address sender) {
        // if emergency exited then user should receive everything in deposit asset
        if (isEmergencyExited()) {
            _emergencyWithdrawUserDeposit(sender);
            return;
        }

        _;
    }

    receive() external payable {}

    // ----- Base Class Methods -----
    function deposit(uint256 amount, uint8 amountSplit)
        public
        virtual
        nonReentrant
        whenNotPaused
        nonEmergencyExited
    {
        _deposit(_msgSender(), amount, amountSplit);
    }

    function depositFor(
        address sender,
        uint256 amount,
        uint8 amountSplit
    )
        public
        virtual
        onlyPortfolio
        nonReentrant
        whenNotPaused
        nonEmergencyExited
    {
        _deposit(sender, amount, amountSplit);
    }

    function _deposit(
        address sender,
        uint256 amount,
        uint8 amountSplit
    ) private {
        // assert valid amount sent
        if (amount < minDepositAmount) {
            revert TooSmallDeposit();
        }

        // transfer deposit token from portfolio
        depositTokenInfo.token.safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );

        // compute actual deposit and transfer fee to receiver
        amount = _takeFee(amount);

        DCADepositor storage depositor = depositors[sender];

        // assert positions limit is not reached
        if (depositor.positions.length == positionsLimit) {
            revert PositionsLimitReached();
        }

        // add splitted amounts to the queue
        globalInvestQueue.splitUserInvestmentAmount(amount, amountSplit);

        // if not started position with the same split exists - increase deposit amount
        for (uint256 i = 0; i < depositor.positions.length; i++) {
            // calculate amount of passed investment epochs
            uint256 passedInvestPeriods = (lastInvestmentTimestamp -
                depositor.positions[i].investedAt) / investmentPeriod;

            if (
                passedInvestPeriods == 0 &&
                depositor.positions[i].amountSplit == amountSplit
            ) {
                // not started position with the same amount split exists
                // just add invested amount here
                depositor.positions[i].depositAmount += amount;

                emit Deposit(sender, amount, amountSplit);
                return;
            }
        }

        // otherwise create new position
        depositor.positions.push(
            Position(
                amount,
                amountSplit,
                lastInvestmentTimestamp,
                dcaHistory.currentHistoricalIndex()
            )
        );

        emit Deposit(sender, amount, amountSplit);
    }

    function invest()
        public
        virtual
        onlyDCAInvestor
        nonReentrant
        whenNotPaused
        nonEmergencyExited
    {
        // declare total amount for event data
        uint256 totalDepositSpent;
        uint256 totalBluechipReceived;

        // assert triggered at valid period
        uint256 passedInvestPeriods = _getPassedInvestPeriods();
        if (passedInvestPeriods == 0) {
            revert NothingToInvest();
        }

        // iterate over passed invest periods
        for (uint256 i = 0; i < passedInvestPeriods; i++) {
            uint256 depositedAmount = globalInvestQueue
                .getCurrentInvestmentAmountAndMoveNext();

            // nobody invested in the queue, just skip this period
            if (depositedAmount == 0) {
                continue;
            }

            // swap deposit amount into invest token
            uint256 receivedBluechip = _swapIntoBluechipAsset(depositedAmount);

            if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
                // invest exchanged amount
                // since protocol might mint less or more tokens refresh amount
                receivedBluechip = _invest(receivedBluechip);
            }

            // store information about spent asset and received asset
            dcaHistory.addHistoricalGauge(depositedAmount, receivedBluechip);

            // compute totals for event
            totalDepositSpent += depositedAmount;
            totalBluechipReceived += receivedBluechip;
        }

        if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
            // claim rewards
            uint256 claimedBluechipRewards = _claimRewards();

            // if something was claimed invest rewards and increase current gauge
            if (claimedBluechipRewards > 0) {
                claimedBluechipRewards = _invest(claimedBluechipRewards);
                dcaHistory.increaseHistoricalGaugeAt(
                    claimedBluechipRewards,
                    dcaHistory.currentHistoricalIndex() - 1
                );

                // increase total amount for event
                totalBluechipReceived += claimedBluechipRewards;
            }
        }

        // update last invest timestamp
        lastInvestmentTimestamp += passedInvestPeriods * investmentPeriod;

        emit Invest(
            totalDepositSpent,
            totalBluechipReceived,
            lastInvestmentTimestamp,
            dcaHistory.currentHistoricalIndex()
        );
    }

    function withdrawAll(bool convertBluechipIntoDepositAsset)
        public
        virtual
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(_msgSender())
    {
        _withdrawAll(_msgSender(), convertBluechipIntoDepositAsset);
    }

    function withdrawAllFor(
        address sender,
        bool convertBluechipIntoDepositAsset
    )
        public
        virtual
        onlyPortfolio
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(sender)
    {
        _withdrawAll(sender, convertBluechipIntoDepositAsset);
    }

    function _withdrawAll(address sender, bool convertBluechipIntoDepositAsset)
        private
    {
        // define total not invested yet amount by user
        // and total bought bluechip asset amount
        uint256 notInvestedYet;
        uint256 investedIntoBluechip;

        DCADepositor storage depositor = depositors[sender];
        for (uint256 i = 0; i < depositor.positions.length; i++) {
            (
                uint256 positionBluechipInvestment,
                uint256 positionNotInvestedYet
            ) = _computePositionWithdrawAll(depositor.positions[i]);

            // increase users total amount
            investedIntoBluechip += positionBluechipInvestment;
            notInvestedYet += positionNotInvestedYet;
        }

        // since depositor withdraws everything
        // we can remove his data completely
        delete depositors[sender];

        // withdraw user deposit
        _withdrawDepositorInvestment(
            sender,
            notInvestedYet,
            investedIntoBluechip,
            convertBluechipIntoDepositAsset
        );
    }

    function withdrawAll(
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    )
        public
        virtual
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(_msgSender())
    {
        _withdrawAll(
            _msgSender(),
            positionIndex,
            convertBluechipIntoDepositAsset
        );
    }

    function withdrawAllFor(
        address sender,
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    )
        public
        virtual
        onlyPortfolio
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(sender)
    {
        _withdrawAll(sender, positionIndex, convertBluechipIntoDepositAsset);
    }

    function _withdrawAll(
        address sender,
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    ) private {
        DCADepositor storage depositor = depositors[sender];

        (
            uint256 positionBluechipInvestment,
            uint256 positionNotInvestedYet
        ) = _computePositionWithdrawAll(depositor.positions[positionIndex]);

        // remove position from user data
        depositor.positions[positionIndex] = depositor.positions[
            depositor.positions.length - 1
        ];
        depositor.positions.pop();

        // withdraw user deposit
        _withdrawDepositorInvestment(
            sender,
            positionNotInvestedYet,
            positionBluechipInvestment,
            convertBluechipIntoDepositAsset
        );
    }

    function _computePositionWithdrawAll(Position memory position)
        private
        returns (uint256 investedIntoBluechip, uint256 notInvestedYet)
    {
        // calculate amount of passed investment epochs
        uint256 passedInvestPeriods = (lastInvestmentTimestamp -
            position.investedAt) / investmentPeriod;

        // in case everything was already invested
        // just set amount of epochs to be equal to amount split
        if (passedInvestPeriods > position.amountSplit) {
            passedInvestPeriods = position.amountSplit;
        }

        // compute per period investment - depositAmount / split
        uint256 perPeriodInvestment = position.depositAmount /
            position.amountSplit;

        uint8 futureInvestmentsToRemove = position.amountSplit -
            uint8(passedInvestPeriods);

        // remove not invested yet amount from invest queue
        if (futureInvestmentsToRemove > 0) {
            globalInvestQueue.removeUserInvestment(
                perPeriodInvestment,
                futureInvestmentsToRemove
            );
        }

        // if investment period already started then we should calculate
        // both not invested deposit asset and owned bluechip asset
        if (passedInvestPeriods > 0) {
            (
                uint256 bluechipInvestment,
                uint256 depositAssetInvestment
            ) = _removeUserInvestmentFromHistory(
                    position,
                    passedInvestPeriods,
                    perPeriodInvestment
                );

            investedIntoBluechip += bluechipInvestment;
            notInvestedYet += position.depositAmount - depositAssetInvestment;
        } else {
            // otherwise investment not started yet
            // so we remove whole deposit token amount
            notInvestedYet += position.depositAmount;
        }
    }

    function withdrawBluechip(bool convertBluechipIntoDepositAsset)
        public
        virtual
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(_msgSender())
    {
        _withdrawBluechip(_msgSender(), convertBluechipIntoDepositAsset);
    }

    function withdrawBluechipFor(
        address sender,
        bool convertBluechipIntoDepositAsset
    )
        public
        virtual
        onlyPortfolio
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(sender)
    {
        _withdrawBluechip(sender, convertBluechipIntoDepositAsset);
    }

    function _withdrawBluechip(
        address sender,
        bool convertBluechipIntoDepositAsset
    ) private {
        DCADepositor storage depositor = depositors[sender];

        uint256 investedIntoBluechip;
        uint256 i;

        // since we might remove position we use while loop to iterate over all positions
        while (i < depositor.positions.length) {
            (
                uint256 positionInvestedIntoBluechip,
                uint256 positionNotInvestedYet,
                uint8 newPositionSplit
            ) = _computePositionWithdrawBluechip(depositor.positions[i]);

            // investment not started yet, skip
            if (positionInvestedIntoBluechip == 0) {
                i++;
                continue;
            }

            investedIntoBluechip += positionInvestedIntoBluechip;
            _updateOrRemovePosition(
                depositor,
                i,
                positionNotInvestedYet,
                newPositionSplit
            );

            i++;
        }

        if (investedIntoBluechip == 0) {
            revert NothingToWithdraw();
        }

        // withdraw bluechip asset and transfer to depositor
        _withdrawDepositorInvestment(
            sender,
            0,
            investedIntoBluechip,
            convertBluechipIntoDepositAsset
        );
    }

    function withdrawBluechip(
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    )
        public
        virtual
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(_msgSender())
    {
        _withdrawBluechip(
            _msgSender(),
            positionIndex,
            convertBluechipIntoDepositAsset
        );
    }

    function withdrawBluechipFor(
        address sender,
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    )
        public
        virtual
        onlyPortfolio
        nonReentrant
        whenNotPaused
        emergencyWithdrawOnEmergencyExitedStatus(sender)
    {
        _withdrawBluechip(
            sender,
            positionIndex,
            convertBluechipIntoDepositAsset
        );
    }

    function _withdrawBluechip(
        address sender,
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    ) private {
        DCADepositor storage depositor = depositors[sender];

        (
            uint256 positionInvestedIntoBluechip,
            uint256 positionNotInvestedYet,
            uint8 newPositionSplit
        ) = _computePositionWithdrawBluechip(
                depositor.positions[positionIndex]
            );

        if (positionInvestedIntoBluechip == 0) {
            revert NothingToWithdraw();
        }

        _updateOrRemovePosition(
            depositor,
            positionIndex,
            positionNotInvestedYet,
            newPositionSplit
        );

        // withdraw bluechip asset and transfer to depositor
        _withdrawDepositorInvestment(
            sender,
            0,
            positionInvestedIntoBluechip,
            convertBluechipIntoDepositAsset
        );
    }

    function _computePositionWithdrawBluechip(Position memory position)
        private
        returns (
            uint256 investedIntoBluechip,
            uint256 notInvestedYet,
            uint8 newPositionSplit
        )
    {
        // calculate amount of passed investment epochs
        uint256 passedInvestPeriods = (lastInvestmentTimestamp -
            position.investedAt) / investmentPeriod;

        // in case everything was already invested
        // just set amount of epochs to be equal to amount split
        if (passedInvestPeriods > position.amountSplit) {
            passedInvestPeriods = position.amountSplit;
        }

        if (passedInvestPeriods != 0) {
            // compute per period investment - depositAmount / split
            uint256 perPeriodInvestment = position.depositAmount /
                position.amountSplit;

            (
                uint256 bluechipInvestment,
                uint256 depositAssetInvestment
            ) = _removeUserInvestmentFromHistory(
                    position,
                    passedInvestPeriods,
                    perPeriodInvestment
                );

            newPositionSplit =
                position.amountSplit -
                uint8(passedInvestPeriods);

            // remove not invested yet amount from invest queue
            globalInvestQueue.removeUserInvestment(
                perPeriodInvestment,
                newPositionSplit
            );

            investedIntoBluechip = bluechipInvestment;
            notInvestedYet = position.depositAmount - depositAssetInvestment;
        }
    }

    function withdrawBluechipFromPool() external onlyOwner {
        require(
            bluechipInvestmentState == BluechipInvestmentState.Investing,
            "Invalid investment state"
        );

        uint256 bluechipBalance = _totalBluechipInvested();
        uint256 actualReceived = _withdrawInvestedBluechip(bluechipBalance);
        _spreadDiffAfterReinvestment(bluechipBalance, actualReceived);

        setBluechipInvestmentState(BluechipInvestmentState.Withdrawn);

        emit StatusChanged(
            BluechipInvestmentState.Investing,
            BluechipInvestmentState.Withdrawn
        );
    }

    function reInvestBluechipIntoPool() external onlyOwner {
        require(
            bluechipInvestmentState == BluechipInvestmentState.Withdrawn,
            "Invalid investment state"
        );

        uint256 bluechipBalance = _totalBluechipInvested();
        uint256 actualReceived = _invest(bluechipBalance);
        _spreadDiffAfterReinvestment(bluechipBalance, actualReceived);

        setBluechipInvestmentState(BluechipInvestmentState.Investing);

        emit StatusChanged(
            BluechipInvestmentState.Withdrawn,
            BluechipInvestmentState.Investing
        );
    }

    function _spreadDiffAfterReinvestment(
        uint256 bluechipBalance,
        uint256 actualReceived
    ) private {
        if (actualReceived > bluechipBalance) {
            // in case we received more increase current gauge
            dcaHistory.increaseHistoricalGaugeAt(
                actualReceived - bluechipBalance,
                dcaHistory.currentHistoricalIndex() - 1
            );
        } else if (actualReceived < bluechipBalance) {
            // in case we received less we should take loss from gauges
            // so that users will be able to withdraw exactly owned amounts
            _deductLossFromGauges(bluechipBalance - actualReceived);
        }
    }

    function _deductLossFromGauges(uint256 diff) private {
        // start iterating over gauges
        for (uint256 i = dcaHistory.currentHistoricalIndex() - 1; i >= 0; i--) {
            (, uint256 gaugeBluechipBalancee) = dcaHistory
                .historicalGaugeByIndex(i);

            // if gauge balance is higher then diff simply remove diff from it
            if (gaugeBluechipBalancee >= diff) {
                dcaHistory.decreaseHistoricalGaugeByIndex(i, 0, diff);
                return;
            } else {
                // otherwise deduct as much as possible and go to the next one
                diff -= gaugeBluechipBalancee;
                dcaHistory.decreaseHistoricalGaugeByIndex(
                    i,
                    0,
                    gaugeBluechipBalancee
                );
            }
        }
    }

    function emergencyWithdrawFunds(
        TokenInfo calldata emergencyExitDepositToken_,
        address[] calldata depositSwapPath,
        TokenInfo calldata emergencyExitBluechipToken_,
        address[] calldata bluechipSwapPath
    ) external onlyOwner nonEmergencyExited {
        // if status Investing we should first withdraw bluechip from pool
        uint256 currentBluechipBalance;
        if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
            currentBluechipBalance = _withdrawInvestedBluechip(
                _totalBluechipInvested()
            );
        }

        // set status to withdrawn to refetch actual bluechip balance
        setBluechipInvestmentState(BluechipInvestmentState.Withdrawn);
        currentBluechipBalance = _totalBluechipInvested();

        // store emergency exit token info
        emergencyExitDepositToken = emergencyExitDepositToken_;
        emergencyExitBluechipToken = emergencyExitBluechipToken_;

        // if deposit token != emergency exit token then swap it
        if (depositTokenInfo.token != emergencyExitDepositToken.token) {
            // swap deposit into emergency exit token
            uint256 currentDepositTokenBalance = depositTokenInfo
                .token
                .balanceOf(address(this));
            uint256 receivedEmergencyExitDepositAsset = router
                .swapTokensForTokens(
                    currentDepositTokenBalance,
                    depositSwapPath
                );

            // store token price for future conversions
            emergencySellDepositPrice =
                (_scaleAmount(
                    receivedEmergencyExitDepositAsset,
                    emergencyExitDepositToken.decimals,
                    depositTokenInfo.decimals
                ) * depositTokenScale) /
                currentDepositTokenBalance;
        }

        // if bluechip token != emergency exit token then swap it
        if (_bluechipAddress() != address(emergencyExitBluechipToken.token)) {
            // swap bluechip into emergency exit token
            uint256 receivedEmergencyExitBluechipAsset = router
                .swapTokensForTokens(currentBluechipBalance, bluechipSwapPath);

            // store token price for future conversions
            emergencySellBluechipPrice =
                (_scaleAmount(
                    receivedEmergencyExitBluechipAsset,
                    emergencyExitBluechipToken.decimals,
                    _bluechipDecimals()
                ) * _bluechipTokenScale()) /
                currentBluechipBalance;
        }

        // set proper strategy state
        setBluechipInvestmentState(BluechipInvestmentState.EmergencyExited);

        emit StatusChanged(
            BluechipInvestmentState.Investing,
            BluechipInvestmentState.EmergencyExited
        );
    }

    function _emergencyWithdrawUserDeposit(address sender) private {
        uint256 notInvestedYet;
        uint256 investedIntoBluechip;

        DCADepositor storage depositor = depositors[sender];
        for (uint256 i = 0; i < depositor.positions.length; i++) {
            (
                uint256 positionBluechipInvestment,
                uint256 positionNotInvestedYet
            ) = _computePositionWithdrawAll(depositor.positions[i]);

            investedIntoBluechip += positionBluechipInvestment;
            notInvestedYet += positionNotInvestedYet;
        }

        // since depositor withdraws everything
        // we can remove his data completely
        delete depositors[sender];

        // if deposit token != emergency exit token compute share
        if (depositTokenInfo.token != emergencyExitDepositToken.token) {
            uint256 convertedDepositShare = (notInvestedYet *
                emergencySellDepositPrice) / depositTokenScale;

            uint256 payout = _scaleAmount(
                convertedDepositShare,
                depositTokenInfo.decimals,
                emergencyExitDepositToken.decimals
            );

            if (payout != 0) {
                emergencyExitDepositToken.token.safeTransfer(sender, payout);
            }
        } else {
            // otherwise send deposit token
            if (notInvestedYet != 0) {
                depositTokenInfo.token.safeTransfer(sender, notInvestedYet);
            }
        }

        // if bluechip != emergency exit token compute share
        if (_bluechipAddress() != address(emergencyExitBluechipToken.token)) {
            uint256 convertedBluechipShare = (investedIntoBluechip *
                emergencySellBluechipPrice) / _bluechipTokenScale();

            uint256 payout = _scaleAmount(
                convertedBluechipShare,
                _bluechipDecimals(),
                emergencyExitBluechipToken.decimals
            );

            if (payout != 0) {
                emergencyExitBluechipToken.token.safeTransfer(sender, payout);
            }
        } else {
            // otherwise send bluechip token
            if (investedIntoBluechip != 0) {
                _transferBluechip(sender, investedIntoBluechip);
            }
        }
    }

    // ----- Base Class Setters -----
    function setBluechipInvestmentState(BluechipInvestmentState newState)
        public
        onlyOwner
    {
        bluechipInvestmentState = newState;
    }

    function setDepositFee(DepositFee memory newDepositFee) public onlyOwner {
        require(
            newDepositFee.feeReceiver != address(0),
            "Invalid fee receiver"
        );
        require(newDepositFee.fee <= 10000, "Invalid fee percentage");
        depositFee = newDepositFee;
    }

    function setDCAInvestor(address newDcaInvestor) public onlyOwner {
        require(newDcaInvestor != address(0), "Invalid DCA investor");
        dcaInvestor = newDcaInvestor;
    }

    function setDepositTokenInto(TokenInfo memory newDepositTokenInfo) private {
        require(
            address(newDepositTokenInfo.token) != address(0),
            "Invalid deposit token address"
        );
        depositTokenInfo = newDepositTokenInfo;
        depositTokenScale = 10**depositTokenInfo.decimals;
    }

    function setInvestmentPeriod(uint256 newInvestmentPeriod) public onlyOwner {
        require(newInvestmentPeriod > 0, "Invalid investment period");
        investmentPeriod = newInvestmentPeriod;
    }

    function setLastInvestmentTimestamp(uint256 newLastInvestmentTimestamp)
        private
    {
        require(
            // solhint-disable-next-line not-rely-on-time
            newLastInvestmentTimestamp >= block.timestamp,
            "Invalid last invest ts"
        );
        lastInvestmentTimestamp = newLastInvestmentTimestamp;
    }

    function setMinDepositAmount(uint256 newMinDepositAmount) public onlyOwner {
        require(newMinDepositAmount > 0, "Invalid min deposit amount");
        minDepositAmount = newMinDepositAmount;
    }

    function setPositionsLimit(uint16 newPositionsLimit) public onlyOwner {
        require(newPositionsLimit > 0, "Invalid positions limit");
        positionsLimit = newPositionsLimit;
    }

    function setRouter(SwapLib.Router memory newRouter) public onlyOwner {
        require(newRouter.router != address(0), "Invalid router");
        router = newRouter;
    }

    function setSwapPath(
        address[] memory depositToBluechip,
        address[] memory bluechipToDeposit
    ) public onlyOwner {
        require(
            depositToBluechip[0] ==
                bluechipToDeposit[bluechipToDeposit.length - 1] &&
                depositToBluechip[depositToBluechip.length - 1] ==
                bluechipToDeposit[0],
            "Invalid swap path"
        );

        depositToBluechipSwapPath = depositToBluechip;
        bluechipToDepositSwapPath = bluechipToDeposit;
    }

    // ----- Pausable -----
    function pause() external onlyOwner {
        super._pause();
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    // ----- Query Methods -----
    function canInvest() public view virtual returns (bool) {
        return _getPassedInvestPeriods() > 0 && !isEmergencyExited();
    }

    function depositorInfo(address depositor)
        public
        view
        virtual
        returns (DCADepositor memory)
    {
        return depositors[depositor];
    }

    function equityValuation()
        public
        view
        virtual
        returns (DCAEquityValuation[] memory)
    {
        DCAEquityValuation[] memory valuation = new DCAEquityValuation[](1);
        if (isEmergencyExited()) {
            valuation[0].totalDepositToken = emergencyExitDepositToken
                .token
                .balanceOf(address(this));
            valuation[0].totalBluechipToken = emergencyExitBluechipToken
                .token
                .balanceOf(address(this));
            valuation[0].bluechipToken = address(
                emergencyExitBluechipToken.token
            );

            return valuation;
        }

        valuation[0].totalDepositToken = depositTokenInfo.token.balanceOf(
            address(this)
        );
        valuation[0].totalBluechipToken = _totalBluechipInvested();
        valuation[0].bluechipToken = _bluechipAddress();

        return valuation;
    }

    function getInvestAmountAt(uint8 index) external view returns (uint256) {
        return globalInvestQueue.investAmounts[index];
    }

    function currentInvestQueueIndex() external view returns (uint8) {
        return globalInvestQueue.current;
    }

    function getHistoricalGaugeAt(uint256 index)
        external
        view
        returns (uint256, uint256)
    {
        return dcaHistory.historicalGaugeByIndex(index);
    }

    function currentDCAHistoryIndex() external view returns (uint256) {
        return dcaHistory.currentHistoricalIndex();
    }

    function isEmergencyExited() public view virtual returns (bool) {
        return
            bluechipInvestmentState == BluechipInvestmentState.EmergencyExited;
    }

    function depositToken() public view returns (IERC20Upgradeable) {
        return depositTokenInfo.token;
    }

    // ----- Private Base Class Helper Functions -----
    function _takeFee(uint256 amount) private returns (uint256 actualDeposit) {
        // if fee is set to 0 then skip it
        if (depositFee.fee == 0) {
            return amount;
        }

        // actual deposit = amount * (100% - fee%)
        actualDeposit = (amount * (10000 - depositFee.fee)) / 10000;

        uint256 feeAmount = amount - actualDeposit;
        if (feeAmount != 0) {
            depositTokenInfo.token.safeTransfer(
                depositFee.feeReceiver,
                feeAmount
            );
        }
    }

    function _swapIntoBluechipAsset(uint256 amountIn)
        private
        returns (uint256)
    {
        return router.swapTokensForTokens(amountIn, depositToBluechipSwapPath);
    }

    function _swapIntoDepositAsset(uint256 amountIn) private returns (uint256) {
        return router.swapTokensForTokens(amountIn, bluechipToDepositSwapPath);
    }

    function _getPassedInvestPeriods() private view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp - lastInvestmentTimestamp) / investmentPeriod;
    }

    function _removeUserInvestmentFromHistory(
        Position memory position,
        uint256 passedInvestPeriods,
        uint256 perPeriodInvestment
    )
        private
        returns (uint256 bluechipInvestment, uint256 depositAssetInvestment)
    {
        // iterate over historical gauges since initial deposit
        for (
            uint256 j = position.investedAtHistoricalIndex;
            j < position.investedAtHistoricalIndex + passedInvestPeriods;
            j++
        ) {
            // total spent and received at selected investment day
            (
                uint256 totalAmountSpent,
                uint256 totalAmountExchanged
            ) = dcaHistory.historicalGaugeByIndex(j);

            // calculate amount that user ownes in current gauge
            uint256 depositorOwnedBluechip = (totalAmountExchanged *
                perPeriodInvestment) / totalAmountSpent;

            bluechipInvestment += depositorOwnedBluechip;
            depositAssetInvestment += perPeriodInvestment;

            // decrease gauge info
            dcaHistory.decreaseHistoricalGaugeByIndex(
                j,
                perPeriodInvestment,
                depositorOwnedBluechip
            );
        }

        return (bluechipInvestment, depositAssetInvestment);
    }

    function _updateOrRemovePosition(
        DCADepositor storage depositor,
        uint256 positionIndex,
        uint256 notInvestedYet,
        uint8 newPositionSplit
    ) private {
        // if not invested yet amount is > 0 then update position
        if (notInvestedYet > 0) {
            // add newly splitted amounts to the queue
            globalInvestQueue.splitUserInvestmentAmount(
                notInvestedYet,
                newPositionSplit
            );

            depositor.positions[positionIndex].depositAmount = notInvestedYet;
            depositor.positions[positionIndex].amountSplit = newPositionSplit;
            depositor
                .positions[positionIndex]
                .investedAt = lastInvestmentTimestamp;
            depositor
                .positions[positionIndex]
                .investedAtHistoricalIndex = dcaHistory
                .currentHistoricalIndex();
        } else {
            // otherwise remove position
            depositor.positions[positionIndex] = depositor.positions[
                depositor.positions.length - 1
            ];
            depositor.positions.pop();
        }
    }

    function _withdrawDepositorInvestment(
        address sender,
        uint256 depositAssetAmount,
        uint256 bluechipAssetAmount,
        bool convertBluechipIntoDepositAsset
    ) private {
        // if convertion requested swap bluechip -> deposit asset
        if (bluechipAssetAmount != 0) {
            if (bluechipInvestmentState == BluechipInvestmentState.Investing) {
                bluechipAssetAmount = _withdrawInvestedBluechip(
                    bluechipAssetAmount
                );
            }

            if (convertBluechipIntoDepositAsset) {
                depositAssetAmount += _swapIntoDepositAsset(
                    bluechipAssetAmount
                );
                bluechipAssetAmount = 0;
            }
        }

        if (depositAssetAmount != 0) {
            depositTokenInfo.token.safeTransfer(sender, depositAssetAmount);
        }

        if (bluechipAssetAmount != 0) {
            _transferBluechip(sender, bluechipAssetAmount);
        }

        emit Withdraw(sender, depositAssetAmount, bluechipAssetAmount);
    }

    function _bluechipTokenScale() private view returns (uint256) {
        return 10**_bluechipDecimals();
    }

    function _scaleAmount(
        uint256 amount,
        uint8 decimals,
        uint8 scaleToDecimals
    ) internal pure returns (uint256) {
        if (decimals < scaleToDecimals) {
            return amount * uint256(10**uint256(scaleToDecimals - decimals));
        } else if (decimals > scaleToDecimals) {
            return amount / uint256(10**uint256(decimals - scaleToDecimals));
        }
        return amount;
    }

    // ----- Functions For Child Contract -----
    function _invest(uint256 amount) internal virtual returns (uint256);

    function _claimRewards() internal virtual returns (uint256);

    function _withdrawInvestedBluechip(uint256 amount)
        internal
        virtual
        returns (uint256);

    function _transferBluechip(address to, uint256 amount) internal virtual;

    function _totalBluechipInvested() internal view virtual returns (uint256);

    function _bluechipAddress() internal view virtual returns (address);

    function _bluechipDecimals() internal view virtual returns (uint8);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IAltPool {
    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IMasterPlatypusV4 {
    struct UserInfo {
        uint128 amount; // How many LP tokens the user has provided.
        uint128 factor;
        uint128 rewardDebt;
        uint128 claimablePtp;
    }

    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function multiClaim(uint256[] memory _pids)
        external
        returns (
            uint256 reward,
            uint256[] memory amounts,
            uint256[][] memory additionalRewards
        );

    function withdraw(uint256 _pid, uint256 _amount)
        external
        returns (uint256 reward, uint256[] memory additionalRewards);

    function getUserInfo(uint256 _pid, address _user)
        external
        view
        returns (UserInfo memory);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingPtp,
            IERC20Upgradeable[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusTokens
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ITraderJoeRouter } from "../../../dependencies/traderjoe/ITraderJoeRouter.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library SwapLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum Dex {
        TraderJoeV2
    }

    struct Router {
        Dex dex;
        address router;
    }

    function swapTokensForTokens(
        Router memory router,
        uint256 amountIn,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        if (router.dex == Dex.TraderJoeV2) {
            ITraderJoeRouter traderjoeRouter = ITraderJoeRouter(router.router);

            IERC20Upgradeable(path[0]).safeIncreaseAllowance(
                address(traderjoeRouter),
                amountIn
            );

            amountOut = traderjoeRouter.swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[path.length - 1];
        } else {
            // solhint-disable-next-line reason-string
            revert("SwapLib: Invalid swap service provider");
        }
    }

    function swapAvaxForTokens(
        Router memory router,
        uint256 amountIn,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        if (router.dex == Dex.TraderJoeV2) {
            amountOut = ITraderJoeRouter(router.router).swapExactAVAXForTokens{
                value: amountIn
            }(
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[path.length - 1];
        } else {
            // solhint-disable-next-line reason-string
            revert("SwapLib: Invalid swap service provider");
        }
    }

    function swapTokensForAvax(
        Router memory router,
        uint256 amountIn,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        if (router.dex == Dex.TraderJoeV2) {
            ITraderJoeRouter traderjoeRouter = ITraderJoeRouter(router.router);

            IERC20Upgradeable(path[0]).safeIncreaseAllowance(
                address(traderjoeRouter),
                amountIn
            );

            amountOut = traderjoeRouter.swapExactTokensForAVAX(
                amountIn,
                0,
                path,
                address(this),
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            )[path.length - 1];
        } else {
            // solhint-disable-next-line reason-string
            revert("SwapLib: Invalid swap service provider");
        }
    }

    function getAmountOut(
        Router memory router,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256) {
        if (router.dex == Dex.TraderJoeV2) {
            return
                ITraderJoeRouter(router.router).getAmountsOut(amountIn, path)[
                    path.length - 1
                ];
        } else {
            // solhint-disable-next-line reason-string
            revert("SwapLib: Invalid swap service provider");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Math.sol";

struct TokenDesc {
    uint256 total;
    uint256 acquired;
}

library InvestableLib {
    address public constant NATIVE_AVAX =
        0x0000000000000000000000000000000000000001;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant USDT = 0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7;
    address public constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    uint8 public constant PRICE_PRECISION_DIGITS = 6;
    uint256 public constant PRICE_PRECISION_FACTOR = 10**PRICE_PRECISION_DIGITS;

    function convertPricePrecision(
        uint256 price,
        uint256 currentPrecision,
        uint256 desiredPrecision
    ) internal pure returns (uint256) {
        if (currentPrecision > desiredPrecision)
            return (price / (currentPrecision / desiredPrecision));
        else if (currentPrecision < desiredPrecision)
            return price * (desiredPrecision / currentPrecision);
        else return price;
    }

    function calculateMintAmount(
        uint256 equitySoFar,
        uint256 amountInvestedNow,
        uint256 investmentTokenSupplySoFar
    ) internal pure returns (uint256) {
        if (investmentTokenSupplySoFar == 0) return amountInvestedNow;
        else
            return
                (amountInvestedNow * investmentTokenSupplySoFar) / equitySoFar;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library InvestQueueLib {
    uint256 public constant QUEUE_LEN = 254;

    struct InvestQueue {
        uint256[QUEUE_LEN + 1] investAmounts;
        uint8 current;
    }

    function getCurrentInvestmentAmountAndMoveNext(InvestQueue storage queue)
        internal
        returns (uint256)
    {
        uint256 amount = queue.investAmounts[queue.current];
        queue.investAmounts[queue.current] = 0;
        queue.current = _nextQueueIndex(queue.current);

        return amount;
    }

    function splitUserInvestmentAmount(
        InvestQueue storage queue,
        uint256 amountToInvest,
        uint8 amountSplit
    ) internal {
        // solhint-disable-next-line reason-string
        require(
            amountSplit < queue.investAmounts.length,
            "InvestQueueLib: Invalid amount split"
        );

        uint8 current = queue.current;
        uint256 perPeriodInvestment = amountToInvest / amountSplit;
        for (uint256 i = 0; i < amountSplit; i++) {
            queue.investAmounts[current] += perPeriodInvestment;
            current = _nextQueueIndex(current);
        }
    }

    function removeUserInvestment(
        InvestQueue storage queue,
        uint256 perPeriodInvestment,
        uint8 investmentsToRemove
    ) internal {
        uint8 current = queue.current;
        for (uint256 i = 0; i < investmentsToRemove; i++) {
            queue.investAmounts[current] -= perPeriodInvestment;
            current = _nextQueueIndex(current);
        }
    }

    function _nextQueueIndex(uint8 current) private pure returns (uint8) {
        if (current == QUEUE_LEN) {
            return 0;
        } else {
            return current + 1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DCAHistoryLib {
    struct HistoricalGauge {
        uint256 amountSpent;
        uint256 amountExchanged;
    }

    struct DCAHistory {
        HistoricalGauge[] gauges;
        uint256 current;
    }

    function addHistoricalGauge(
        DCAHistory storage history,
        uint256 amountSpent,
        uint256 amountExchanged
    ) internal {
        history.gauges.push(HistoricalGauge(amountSpent, amountExchanged));
        history.current++;
    }

    function increaseHistoricalGaugeAt(
        DCAHistory storage history,
        uint256 rewards,
        uint256 index
    ) internal {
        history.gauges[index].amountExchanged += rewards;
    }

    function decreaseHistoricalGaugeByIndex(
        DCAHistory storage history,
        uint256 index,
        uint256 amountSpent,
        uint256 amountExchanged
    ) internal {
        history.gauges[index].amountSpent -= amountSpent;
        history.gauges[index].amountExchanged -= amountExchanged;
    }

    function currentHistoricalIndex(DCAHistory storage history)
        internal
        view
        returns (uint256)
    {
        return history.current;
    }

    function historicalGaugeByIndex(DCAHistory storage history, uint256 index)
        internal
        view
        returns (uint256, uint256)
    {
        require(index <= history.current, "DCAHistoryLib: Out of bounds");
        return (
            history.gauges[index].amountSpent,
            history.gauges[index].amountExchanged
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IDCAInvestable } from "./IDCAInvestable.sol";
import { SwapLib } from "../libraries/SwapLib.sol";

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IDCAStrategy is IDCAInvestable {
    error TooSmallDeposit();
    error PositionsLimitReached();
    error NothingToInvest();
    error NothingToWithdraw();

    event Deposit(address indexed sender, uint256 amount, uint256 amountSplit);
    event Invest(
        uint256 depositAmountSpent,
        uint256 bluechipReceived,
        uint256 investedAt,
        uint256 historicalIndex
    );
    event Withdraw(
        address indexed sender,
        uint256 withdrawnDeposit,
        uint256 withdrawnBluechip
    );
    event StatusChanged(
        BluechipInvestmentState indexed prevStatus,
        BluechipInvestmentState indexed newStatus
    );

    struct DCAStrategyInitArgs {
        DepositFee depositFee;
        address dcaInvestor;
        TokenInfo depositTokenInfo;
        uint256 investmentPeriod;
        uint256 lastInvestmentTimestamp;
        uint256 minDepositAmount;
        uint16 positionsLimit;
        SwapLib.Router router;
        address[] depositToBluechipSwapPath;
        address[] bluechipToDepositSwapPath;
    }

    struct DepositFee {
        address feeReceiver;
        uint16 fee; // .0000 number
    }

    struct TokenInfo {
        IERC20Upgradeable token;
        uint8 decimals;
    }

    struct Position {
        uint256 depositAmount;
        uint8 amountSplit;
        uint256 investedAt;
        uint256 investedAtHistoricalIndex;
    }

    struct DCADepositor {
        Position[] positions;
    }

    enum BluechipInvestmentState {
        Investing,
        Withdrawn,
        EmergencyExited
    }

    function invest() external;

    function canInvest() external view returns (bool);

    function depositorInfo(address depositor)
        external
        view
        returns (DCADepositor memory);

    function getInvestAmountAt(uint8 index) external view returns (uint256);

    function currentInvestQueueIndex() external view returns (uint8);

    function getHistoricalGaugeAt(uint256 index)
        external
        view
        returns (uint256, uint256);

    function currentDCAHistoryIndex() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PortfolioAccessBaseUpgradeable is OwnableUpgradeable {
    error PortfolioAlreadyWhitelisted();
    error PortfolioNotFound();

    event PortfolioAdded(address indexed newPortfolio);
    event PortfolioRemoved(address indexed removedPortfolio);

    address[] public whitelistedPortfolios;

    // solhint-disable-next-line
    function __PortfolioAccessBaseUpgradeable_init() internal onlyInitializing {
        __Ownable_init();
    }

    modifier onlyPortfolio() {
        bool authorized;
        for (uint256 i = 0; i < whitelistedPortfolios.length; i++) {
            if (whitelistedPortfolios[i] == _msgSender()) {
                authorized = true;
            }
        }

        require(authorized, "Unauthorized");
        _;
    }

    function addPortfolio(address newPortfolio) public virtual onlyOwner {
        for (uint256 i = 0; i < whitelistedPortfolios.length; i++) {
            if (whitelistedPortfolios[i] == newPortfolio) {
                revert PortfolioAlreadyWhitelisted();
            }
        }

        whitelistedPortfolios.push(newPortfolio);
        emit PortfolioAdded(newPortfolio);
    }

    function removePortfolio(address portfolio) public virtual onlyOwner {
        for (uint256 i = 0; i < whitelistedPortfolios.length; i++) {
            if (whitelistedPortfolios[i] == portfolio) {
                whitelistedPortfolios[i] = whitelistedPortfolios[
                    whitelistedPortfolios.length - 1
                ];
                whitelistedPortfolios.pop();

                emit PortfolioRemoved(portfolio);
                return;
            }
        }

        revert PortfolioNotFound();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IDCA } from "./IDCA.sol";
import { IDCAFor } from "./IDCAFor.sol";
import { IDCAEquity } from "./IDCAEquity.sol";
import { IDCALimits } from "./IDCALimits.sol";
import { IDCAStatus } from "./IDCAStatus.sol";

interface IDCAInvestable is IDCA, IDCAFor, IDCAEquity, IDCALimits, IDCAStatus {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IDCA {
    function deposit(uint256 amount, uint8 amountSplit) external;

    function withdrawAll(bool convertBluechipIntoDepositAsset) external;

    function withdrawAll(
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    ) external;

    function withdrawBluechip(bool convertBluechipIntoDepositAsset) external;

    function withdrawBluechip(
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    ) external;

    function depositToken() external view returns (IERC20Upgradeable);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDCAFor {
    function depositFor(
        address sender,
        uint256 amount,
        uint8 amountSplit
    ) external;

    function withdrawAllFor(
        address sender,
        bool convertBluechipIntoDepositAsset
    ) external;

    function withdrawAllFor(
        address sender,
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    ) external;

    function withdrawBluechipFor(
        address sender,
        bool convertBluechipIntoDepositAsset
    ) external;

    function withdrawBluechipFor(
        address sender,
        uint256 positionIndex,
        bool convertBluechipIntoDepositAsset
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDCAEquity {
    struct DCAEquityValuation {
        uint256 totalDepositToken;
        uint256 totalBluechipToken;
        address bluechipToken;
    }

    function equityValuation()
        external
        view
        returns (DCAEquityValuation[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDCALimits {
    function minDepositAmount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDCAStatus {
    function isEmergencyExited() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Math {
    uint16 public constant SHORT_FIXED_DECIMAL_FACTOR = 10**3;
    uint24 public constant MEDIUM_FIXED_DECIMAL_FACTOR = 10**6;
    uint256 public constant LONG_FIXED_DECIMAL_FACTOR = 10**30;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}