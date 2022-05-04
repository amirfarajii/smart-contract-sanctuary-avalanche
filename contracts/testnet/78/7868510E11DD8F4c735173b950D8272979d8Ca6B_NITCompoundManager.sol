/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-02
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-22
 */

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/interfaces/IBep20.sol

pragma solidity ^0.8.7;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

// File: contracts/helpers/Auth.sol

pragma solidity ^0.8.7;

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

// File: contracts/libs/SafeMath.sol

pragma solidity ^0.8.7;

/*
 * SAFEMATH LIBRARY
 */

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

// File: contracts/helpers/DividendDistributor.sol

pragma solidity ^0.8.7;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded; // excluded dividend
        uint256 totalRealised;
    }

    IBEP20 USDC = IBEP20(0xA504a04A67A6316d4df257242ba6704B4b2Da83E); // USDC reflection
    address WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    IDEXRouter router;

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed; // to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 10 * (10**18);

    uint256 currentIndex;

    bool initialized;

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x7E3411B04766089cFaa52DB688855356A12f05D1);
        _token = msg.sender;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount)
        external
        override
        onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = USDC.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(USDC);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(0, path, address(this), block.timestamp);

        uint256 amount = USDC.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function shouldDistribute(address shareholder)
        internal
        view
        returns (bool)
    {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        // short circuit
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);

        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            USDC.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    /** Public getUnpaidEarnings, used to display on the UI */
    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }
}

// File: contracts/CoinToken.sol

pragma solidity ^0.8.7;

contract CoinToken is IBEP20, Auth {
    using SafeMath for uint256;

    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    event SwapBack(uint256 amountSwapped);

    uint256 public constant MASK = type(uint128).max;

    /** Addresses */
    address USDC = 0xA504a04A67A6316d4df257242ba6704B4b2Da83E;
    address public WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    /** Token constants */
    string constant _name = "Node Investment Trust v2";
    string constant _symbol = "NIT";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1000000000000000 * (10**_decimals);

    /** Transaction and Wallet Limiters */
    uint256 public _maxTxAmount = _totalSupply.div(100); // 1%
    uint256 public _maxWallet = _totalSupply.div(40); // 2.5%

    /** Internal Mappings */
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) public _isFree;

    /** Fees and fee breakdown */
    /**
        Total Fee: 18%
        10% Reflection
        2% Liquidity
        6% Treasury
     */
    uint256 reflectionBuyFee = 600;
    uint256 treasuryBuyFee = 400;
    uint256 devBuyFee = 300;
    uint256 liquidityBuyFee = 200;
    uint256 burnBuyFee = 200;
    uint256 totalBuyFee = 1700;

    uint256 reflectionSellFee = 900;
    uint256 treasurySellFee = 600;
    uint256 devSellFee = 400;
    uint256 liquiditySellFee = 300;
    uint256 burnSellFee = 300;
    uint256 totalSellFee = 2500;

    uint256 buybackFee = 0;
    uint256 feeDenominator = 10000;

    address public autoLiquidityReceiver =
        0x62eA762d9f2672f82d26b94f56849881831B9eaB;

    address public treasuryFeeReceiver =
        0x62eA762d9f2672f82d26b94f56849881831B9eaB;

    address public devFeeReceiver = 0x62eA762d9f2672f82d26b94f56849881831B9eaB;

    uint256 targetLiquidity = 10;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    bool public autoBuybackEnabled = false;
    mapping(address => bool) buyBacker;
    uint256 autoBuybackCap;
    uint256 autoBuybackAccumulator;
    uint256 autoBuybackAmount;
    uint256 autoBuybackBlockPeriod;
    uint256 autoBuybackBlockLast;

    DividendDistributor distributor;
    address public distributorAddress;

    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000; // 0.1%;
    uint256 public lastSwapTime = block.timestamp;
    uint256 public swapTimeLock = 1 hours;

    bool inSwap;

    constructor() Auth(msg.sender) {
        address _router = 0x7E3411B04766089cFaa52DB688855356A12f05D1;
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WAVAX = router.WAVAX();
        distributor = new DividendDistributor(_router);
        distributorAddress = address(distributor);

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        buyBacker[msg.sender] = true;

        autoLiquidityReceiver = msg.sender;

        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        // Max  tx check
        address routerAddress = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
        bool isSell = recipient == pair || recipient == routerAddress;

        checkTxLimit(sender, amount);

        // Max wallet check excluding pair and router
        if (!isSell && !_isFree[recipient]) {
            require(
                (_balances[recipient] + amount) < _maxWallet,
                "Max wallet has been triggered"
            );
        }

        if (shouldSwapBack()) {
            swapBack(sender != pair);
        }

        if (shouldAutoBuyback()) {
            triggerAutoBuyback();
        }
        // if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, recipient, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        // try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getReflectionFee(bool selling) internal view returns (uint256) {
        return selling ? reflectionSellFee : reflectionBuyFee;
    }

    function getTreasuryFee(bool selling) internal view returns (uint256) {
        return selling ? treasurySellFee : treasuryBuyFee;
    }

    function getDevFee(bool selling) internal view returns (uint256) {
        return selling ? devSellFee : devBuyFee;
    }

    function getLiquidityFee(bool selling) internal view returns (uint256) {
        return selling ? liquiditySellFee : liquidityBuyFee;
    }

    function getBurnFee(bool selling) internal view returns (uint256) {
        return selling ? burnSellFee : burnBuyFee;
    }

    function getTotalFee(bool selling) internal view returns (uint256) {
        return selling ? totalSellFee : totalBuyFee;
    }

    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(
            feeDenominator
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            block.timestamp > lastSwapTime + swapTimeLock &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack(bool selling) internal swapping {
        lastSwapTime = block.timestamp;

        uint256 amountTokenBurn = swapThreshold.mul(getBurnFee(selling)).div(
            getTotalFee(selling)
        );
        _balances[address(this)] = _balances[address(this)].sub(
            amountTokenBurn
        );
        _balances[DEAD] = _balances[DEAD].add(amountTokenBurn);

        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : getLiquidityFee(selling);
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(getTotalFee(selling))
            .div(2);
        uint256 amountToSwap = swapThreshold.sub(amountTokenBurn).sub(
            amountToLiquify
        );

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance.sub(balanceBefore);

        uint256 totalAVAXFee = getTotalFee(selling)
            .sub(dynamicLiquidityFee.div(2))
            .sub(getBurnFee(selling));

        uint256 amountAVAXLiquidity = amountAVAX
            .mul(dynamicLiquidityFee)
            .div(totalAVAXFee)
            .div(2);
        uint256 amountAVAXReflection = amountAVAX
            .mul(getReflectionFee(selling))
            .div(totalAVAXFee);
        uint256 amountAVAXTreasury = amountAVAX
            .mul(getTreasuryFee(selling))
            .div(totalAVAXFee);

        try distributor.deposit{value: amountAVAXReflection}() {} catch {}

        payable(treasuryFeeReceiver).transfer(amountAVAXTreasury);
        payable(devFeeReceiver).transfer(
            amountAVAX.sub(amountAVAXLiquidity).sub(amountAVAXReflection).sub(
                amountAVAXTreasury
            )
        );

        if (amountToLiquify > 0) {
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }
    }

    function shouldAutoBuyback() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            autoBuybackEnabled &&
            autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number && // After N blocks from last buyback
            address(this).balance >= autoBuybackAmount;
    }

    function triggerZeusBuyback(uint256 amount, bool triggerBuybackMultiplier)
        external
        authorized
    {
        buyTokens(amount, DEAD);
        if (triggerBuybackMultiplier) {
            buybackMultiplierTriggeredAt = block.timestamp;
            emit BuybackMultiplierActive(buybackMultiplierLength);
        }
    }

    function clearBuybackMultiplier() external authorized {
        buybackMultiplierTriggeredAt = 0;
    }

    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
        if (autoBuybackAccumulator > autoBuybackCap) {
            autoBuybackEnabled = false;
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(this);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public authorized {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function setAutoBuybackSettings(
        bool _enabled,
        uint256 _cap,
        uint256 _amount,
        uint256 _period
    ) external authorized {
        autoBuybackEnabled = _enabled;
        autoBuybackCap = _cap;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setBuybackMultiplierSettings(
        uint256 numerator,
        uint256 denominator,
        uint256 length
    ) external authorized {
        require(numerator / denominator <= 2 && numerator > denominator);
        buybackMultiplierNumerator = numerator;
        buybackMultiplierDenominator = denominator;
        buybackMultiplierLength = length;
    }

    function setMaxWallet(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        authorized
    {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setSwapBackTimeLock(uint256 time) public authorized {
        require(time >= 0, "No Negative Time, Pal.");
        swapTimeLock = time * 1 minutes;
    }

    function setFree(address holder) public onlyOwner {
        _isFree[holder] = true;
    }

    function unSetFree(address holder) public onlyOwner {
        _isFree[holder] = false;
    }

    function checkFree(address holder) public view onlyOwner returns (bool) {
        return _isFree[holder];
    }

    function setBuyFees(
        uint256 _reflectionBuyFee,
        uint256 _treasuryBuyFee,
        uint256 _devBuyFee,
        uint256 _liquidityBuyFee,
        uint256 _burnBuyFee
    ) external authorized {
        reflectionBuyFee = _reflectionBuyFee;
        treasuryBuyFee = _treasuryBuyFee;
        devBuyFee = _devBuyFee;
        liquidityBuyFee = _liquidityBuyFee;
        burnBuyFee = _burnBuyFee;
        totalBuyFee = reflectionBuyFee
            .add(treasuryBuyFee)
            .add(devBuyFee)
            .add(liquidityBuyFee)
            .add(burnBuyFee);

        require(totalBuyFee < feeDenominator / 4);
    }

    function setSellFees(
        uint256 _reflectionSellFee,
        uint256 _treasurySellFee,
        uint256 _devSellFee,
        uint256 _liquiditySellFee,
        uint256 _burnSellFee
    ) external authorized {
        reflectionSellFee = _reflectionSellFee;
        treasurySellFee = _treasurySellFee;
        devSellFee = _devSellFee;
        liquiditySellFee = _liquiditySellFee;
        burnSellFee = _burnSellFee;

        totalSellFee = reflectionSellFee
            .add(treasurySellFee)
            .add(devSellFee)
            .add(liquiditySellFee)
            .add(burnSellFee);

        require(totalSellFee < feeDenominator / 4);
    }

    function setOtherFees(uint256 _buybackFee, uint256 _feeDenominator)
        external
        authorized
    {
        buybackFee = _buybackFee;
        feeDenominator = _feeDenominator;

        require(totalBuyFee < feeDenominator / 4);
        require(totalSellFee < feeDenominator / 4);
    }

    function setLiquidityReceiver(address _autoLiquidityReceiver)
        external
        authorized
    {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }

    function setTreasuryReciever(address _treasuryFeeReceiver)
        external
        authorized
    {
        treasuryFeeReceiver = _treasuryFeeReceiver;
    }

    function setDevReciever(address _devFeeReceiver) external authorized {
        devFeeReceiver = _devFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator)
        external
        authorized
    {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }

    /** Public views */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    /** Modifiers */
    modifier onlyBuybacker() {
        require(buyBacker[msg.sender] == true, "");
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
}

contract NITCompoundManager {
    using SafeMath for uint256;
    address internal owner;
    mapping(address => bool) internal authorizations;

    event Holder(address);
    event AmountUSDC(uint256);
    event AmountTaxFree(uint256);

    /** Fees and fee breakdown */
    /**
        Total Fee: 18%
        10% Reflection
        2% Liquidity
        6% Treasury
     */
    uint256 reflectionBuyFee = 600;
    uint256 treasuryBuyFee = 400;
    uint256 devBuyFee = 300;
    uint256 liquidityBuyFee = 200;
    uint256 burnBuyFee = 200;
    uint256 totalBuyFee = 1700;

    uint256 reflectionSellFee = 900;
    uint256 treasurySellFee = 600;
    uint256 devSellFee = 400;
    uint256 liquiditySellFee = 300;
    uint256 burnSellFee = 300;
    uint256 totalSellFee = 2500;

    uint256 buybackFee = 0;
    uint256 feeDenominator = 10000;

    address public NITNodes = 0x2E653cA02e5bbc86B51Df7DaF96df89c5094A132;
    address public USDC = 0xA504a04A67A6316d4df257242ba6704B4b2Da83E;
    address public WAVAX = 0x1D308089a2D1Ced3f1Ce36B1FcaF815b07217be3;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public routerAddress = 0x7E3411B04766089cFaa52DB688855356A12f05D1;
    IDEXRouter public router;

    constructor() {
        router = IDEXRouter(routerAddress);
        owner = msg.sender;
        authorizations[msg.sender] = true;
    }

    /**
     * Set fee function for this contract, to enable syncronization with the parent token,
     * for when fees are reduced in the future.
     */
    function setBuyFees(
        uint256 _reflectionBuyFee,
        uint256 _treasuryBuyFee,
        uint256 _devBuyFee,
        uint256 _liquidityBuyFee,
        uint256 _burnBuyFee
    ) external authorized {
        reflectionBuyFee = _reflectionBuyFee;
        treasuryBuyFee = _treasuryBuyFee;
        devBuyFee = _devBuyFee;
        liquidityBuyFee = _liquidityBuyFee;
        burnBuyFee = _burnBuyFee;
        totalBuyFee = reflectionBuyFee
            .add(treasuryBuyFee)
            .add(devBuyFee)
            .add(liquidityBuyFee)
            .add(burnBuyFee);

        require(totalBuyFee < feeDenominator / 4);
    }

    function setSellFees(
        uint256 _reflectionSellFee,
        uint256 _treasurySellFee,
        uint256 _devSellFee,
        uint256 _liquiditySellFee,
        uint256 _burnSellFee
    ) external authorized {
        reflectionSellFee = _reflectionSellFee;
        treasurySellFee = _treasurySellFee;
        devSellFee = _devSellFee;
        liquiditySellFee = _liquiditySellFee;
        burnSellFee = _burnSellFee;

        totalSellFee = reflectionSellFee
            .add(treasurySellFee)
            .add(devSellFee)
            .add(liquiditySellFee)
            .add(burnSellFee);

        require(totalSellFee < feeDenominator / 4);
    }

    function setOtherFees(uint256 _buybackFee, uint256 _feeDenominator)
        external
        authorized
    {
        buybackFee = _buybackFee;
        feeDenominator = _feeDenominator;

        require(totalBuyFee < feeDenominator / 4);
        require(totalSellFee < feeDenominator / 4);
    }

    function compoundDividend() external {
        emit Holder(msg.sender);
        uint256 before = IBEP20(USDC).balanceOf(msg.sender); //Gets the current balance of USDC

        CoinToken(payable(NITNodes)).transfer(msg.sender, 1); //Workaround to claim dividend contractually.

        uint256 available = IBEP20(USDC).balanceOf(msg.sender) - before; //Gets the new balance of USDC after dividend payout, but subtracts any previously held USDC.

        IBEP20(USDC).transferFrom(msg.sender, address(this), available);

        address[] memory path = new address[](3); //Create the path for the swap. USDC -> WAVAX -> FTMP
        path[0] = USDC;
        path[1] = WAVAX;
        path[2] = NITNodes;

        IBEP20(USDC).approve(routerAddress, available); //Approve the swap.

        emit AmountUSDC(available);

        /**
         * Temporarily set fees to zero for the compounding bonus.
         */
        CoinToken(payable(NITNodes)).setBuyFees(0, 0, 0, 0, 0);
        CoinToken(payable(NITNodes)).setSellFees(0, 0, 0, 0, 0);
        CoinToken(payable(NITNodes)).setOtherFees(0, feeDenominator);

        /**
         * Making the swap, tax free.
         */
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens( //Performs the swap, sending proceeds to the user.
            available,
            0,
            path,
            address(this),
            block.timestamp
        );

        /**
         * Amount of CoinToken swapped, leaving one on the contract for the next user.
         */
        uint256 taxFreeNITAmount = CoinToken(payable(NITNodes)).balanceOf(
            address(this)
        ) - 1; // send all except for 1, for the next user

        emit AmountTaxFree(taxFreeNITAmount);

        /**
         * Sending the tax free CoinToken back to the user.
         */
        CoinToken(payable(NITNodes)).transfer(msg.sender, taxFreeNITAmount);

        /**
         * Resetting the fees back to their normal amount.
         */
        CoinToken(payable(NITNodes)).setBuyFees(
            reflectionBuyFee,
            treasuryBuyFee,
            devBuyFee,
            liquidityBuyFee,
            burnBuyFee
        );
        CoinToken(payable(NITNodes)).setSellFees(
            reflectionSellFee,
            treasurySellFee,
            devSellFee,
            liquiditySellFee,
            burnSellFee
        );
        CoinToken(payable(NITNodes)).setOtherFees(buybackFee, feeDenominator);
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
}