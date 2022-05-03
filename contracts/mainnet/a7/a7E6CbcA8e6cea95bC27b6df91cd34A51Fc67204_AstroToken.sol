/**
 *Submitted for verification at snowtrace.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
// File: Astro_Contracts/interface/InterfaceLP.sol


pragma solidity ^ 0.8.9;

interface InterfaceLP {
    function sync() external;
}
// File: Astro_Contracts/interface/IDEXRouter.sol

pragma solidity ^ 0.8.9;

interface IJoeRouter01 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

pragma solidity ^ 0.8.9;

interface IDEXRouter is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

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

// File: Astro_Contracts/interface/IDEXFactory.sol


pragma solidity ^ 0.8.0;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: Astro_Contracts/library/ERC20Detailed.sol


pragma solidity ^ 0.8.0;


abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: Astro_Contracts/AstroToken.sol


pragma solidity ^ 0.8.0;


contract AstroToken is ERC20Detailed {

    address owner;

    bool public initialDistributionFinished = true;
    bool public swapEnabled = true;
    bool public autoRebase = true;
    bool public feesOnNormalTransfers = true;
    bool public isLiquidityEnabled = true;

    uint256 public rewardYield = 3944150; // APY: 100,103.36795485453209020930376137, Daily ROI: 1.910846122730853405394701828557
    uint256 public rewardYieldDenominator = 10000000000;
    uint256 public maxSellTransactionAmount = 50000 * 10**6;

    uint256 public rebaseFrequency = 1800;
    uint256 public nextRebase = 1651560540; //block.timestamp + 604800;

    uint256 public rebaseDuration = 604800;

    uint256 public allottedSellInterval;
    uint256 public allottedSellPercentage;
    uint256 public releaseBlock;

    mapping (address => bool) _isFeeExempt;
    address[] public _markerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => uint256) private userInitialAmount;

    uint256 private constant MAX_REBASE_FREQUENCY = 1800;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 10**9 * 10**DECIMALS;
    uint256 private TOTAL_GONS;
    uint256 private constant MAX_SUPPLY = ~uint256(0);

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public liquidityReceiver = 0x151847E314944CAF735770dfD47f5068f275D3fb;
    address public treasuryReceiver = 0x4636b95e76323Eb097D857bE31aF9Ed06322A4a8;
    address public riskFreeValueReceiver = 0x51f0f5AE935Cd173ca3eBd396Bfb36F500470043;
    address public operationsReceiver = 0x8A5882CCd77a889Dd475769566d5135852770361;
    address public xASTROReceiver = 0x882b024d1FC33D58a4872201231808d5bc5F4a17;
    address public futureEcosystemReceiver = 0x2fE107F66c03eE625962C65d8e7924005394fBFB;
    address public burnReceiver = 0xaC13f6517d7841A0499533453b944e2f91AC2B4c;

    IDEXRouter public router;
    address public pair;
    IERC20 public usdcAddress;
    address public convertTo = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    /*
        0: Buy Fee
        1: Sell Fee
        2: Whale Sell Fee 
        3: Invador Fee
    */
    uint256[4] public totalFee          = [1500, 3000, 5000, 8000];
    uint256[4] public liquidityFee      = [495, 750, 1250, 2000];
    uint256[4] public treasuryFee       = [480, 750, 1250, 2000];
    uint256[4] public riskFeeValueFee   = [150, 600, 1000, 1600];
    uint256[4] public ecosystemFee      = [75, 300, 500, 800];
    uint256[4] public operationsFee     = [150, 150, 250, 400];
    uint256[4] public xASTROFee         = [150, 150, 250, 400];
    uint256[4] public burnFee           = [0, 300, 500, 800];
    uint256 public feeDenominator       = 10000;

    uint256 public normalSellLimit      = 1 * 10 ** 4 * 10 ** 6;
    uint256 public whaleSellLimit       = 25 * 10 ** 3 * 10 ** 6;
    uint256 public purchasePeriod       = 60 * 60 * 24;

    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;


    address[] public airdropAddress;
    uint256[] public airdropAmount;


    struct TokenSellInfo {
        uint256 startTime;
        uint256 sellAmount;
    }

    bool pause;

    modifier paused() {
        require(!pause, "Contract is paused");
        _;
    }

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        if(msg.sender != burnReceiver) {
            require(to != address(0x0));
        }
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "AstroToken: Caller is not owner the contract.");
        _;
    }

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    uint256 private gonSwapThreshold;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => TokenSellInfo) private _userSellInfos;
    mapping(address => bool) public _blacklistedUsers;
    mapping(address => uint256) public _allottedSellHistory;

    constructor(address _router, address _usdcAddress) ERC20Detailed("100 Days Ventures", "preASTRO", uint8(DECIMALS)) {
        owner = msg.sender;
        TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
        router = IDEXRouter(_router);
        usdcAddress = IERC20(_usdcAddress);
        gonSwapThreshold = (TOTAL_GONS) / (1000);

        releaseBlock = 1651560540; //block.timestamp;
        allottedSellInterval = 1 weeks;
        allottedSellPercentage = 100;

        pair = IDEXFactory(router.factory()).createPair(address(this), router.WAVAX());
        //address pairUSDC = IDEXFactory(router.factory()).createPair(address(this), address(usdcAddress));

        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _allowedFragments[address(this)][pair] = type(uint256).max;
        _allowedFragments[address(this)][address(this)] = type(uint256).max;
        _allowedFragments[address(this)][convertTo] = type(uint256).max;
        //_allowedFragments[address(this)][pairUSDC] = type(uint256).max;

        usdcAddress.approve(address(router), type(uint256).max);
        //usdcAddress.approve(address(pairUSDC), type(uint256).max);
        usdcAddress.approve(address(this), type(uint256).max);

        setAutomatedMarketMakerPair(pair, true);
        //setAutomatedMarketMakerPair(pairUSDC, true);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS / (_totalSupply);

        _isFeeExempt[liquidityReceiver] = true;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[riskFreeValueReceiver] = true;
        _isFeeExempt[operationsReceiver] = true;
        _isFeeExempt[xASTROReceiver] = true;
        _isFeeExempt[futureEcosystemReceiver] = true;
        _isFeeExempt[burnReceiver] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[msg.sender] = true;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        if (automatedMarketMakerPairs[who])
            return _gonBalances[who];
        else
            return _gonBalances[who] / (_gonsPerFragment);
    }

    function initialBalanceOf(address who) public view returns (uint256) {
        return userInitialAmount[who];
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold / (_gonsPerFragment);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        if (_isFeeExempt[from] || _isFeeExempt[to]) {
            return false;
        } else if (feesOnNormalTransfers) {
            return true;
        } else {
            return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender] &&
        !inSwap &&
        swapEnabled &&
        totalFee[0] + totalFee[1] > 0 &&
        _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
        (TOTAL_GONS - _gonBalances[DEAD] - _gonBalances[ZERO] - _gonBalances[treasuryReceiver]) /
        _gonsPerFragment;
    }

    function isOverLiquified() public view returns (bool) {
        return isLiquidityEnabled;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setRebaseDuration(uint256 _rebaseDuration) external onlyOwner {
        nextRebase = nextRebase - rebaseDuration + _rebaseDuration;
        rebaseDuration = _rebaseDuration;
    }

    function manualSync() public {
        for (uint256 i = 0; i < _markerPairs.length; i++) {
            try InterfaceLP(_markerPairs[i]).sync() {} catch Error(
                string memory reason
            ) {
                emit GenericErrorEvent(
                    'manualSync(): _makerPairs.sync() Failed'
                );
                emit GenericErrorEvent(reason);
            }
        }
    }

    function claimAllottedSell() external {
        require(block.timestamp > releaseBlock + 1 weeks);
        require(block.timestamp > _allottedSellHistory[msg.sender] + allottedSellInterval);
        require(_allottedSellHistory[msg.sender] > 0, 'not eligible yet');

        uint256 claimAmount = balanceOf(msg.sender) / (10000) * (allottedSellPercentage);

        _transferFrom(msg.sender, address(this), claimAmount);
        _swapTokensForUSDC(claimAmount, msg.sender);

        _allottedSellHistory[msg.sender] = block.timestamp;
    }

    function updateAllottedSellTimer() external {
        require(_allottedSellHistory[msg.sender] == 0,  'already done');
        _allottedSellHistory[msg.sender] = block.timestamp;
    }

    function transfer(address to, uint256 value) external override validRecipient(to) paused returns (bool) {
        require(!_blacklistedUsers[msg.sender], "You are a blacklisted user");
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 gonAddAmount = amount * (_gonsPerFragment);
        uint256 gonSubAmount = amount * (_gonsPerFragment);

        if (automatedMarketMakerPairs[from])
            gonSubAmount = amount;

        if (automatedMarketMakerPairs[to])
            gonAddAmount = amount;

        _gonBalances[from] = _gonBalances[from] - (gonSubAmount);
        _gonBalances[to] = _gonBalances[to] + (gonAddAmount);

        emit Transfer(from, to, amount);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        bool excludedAccount = _isFeeExempt[sender] || _isFeeExempt[recipient];

        require(initialDistributionFinished || excludedAccount, "Trading not started");

        if (
            automatedMarketMakerPairs[recipient] &&
            !excludedAccount
        ) {
            if (block.timestamp - _userSellInfos[sender].startTime > purchasePeriod) {
                _userSellInfos[sender].startTime = block.timestamp;
                _userSellInfos[sender].sellAmount = 0;
            }

            bool canSellTokens = true;
            uint256 onceUSC = getUSDCFromASTRO(amount);
            if (_userSellInfos[sender].sellAmount + onceUSC > maxSellTransactionAmount) {
                canSellTokens = false;
            }
            else {
                _userSellInfos[sender].sellAmount += onceUSC;
            }
            require(canSellTokens == true, "Error sell amount");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount * (_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        if (automatedMarketMakerPairs[sender]) {
            _gonBalances[sender] = _gonBalances[sender] - (amount);
        }
        else {
            _gonBalances[sender] = _gonBalances[sender] - (gonAmount);
        }

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, gonAmount) : gonAmount;
        if (automatedMarketMakerPairs[recipient]) {
            _gonBalances[recipient] = _gonBalances[recipient] + (gonAmountReceived / (_gonsPerFragment));
        }
        else {
            _gonBalances[recipient] = _gonBalances[recipient] + (gonAmountReceived);
            userInitialAmount[recipient] = userInitialAmount[recipient] + (gonAmountReceived);
        }

        emit Transfer(sender, recipient, gonAmountReceived / (_gonsPerFragment));

        if (shouldRebase() && autoRebase) {
            _rebase();

            if (!automatedMarketMakerPairs[sender] && !automatedMarketMakerPairs[recipient]) {
                manualSync();
            }
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != ~uint256(0)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender] - (value);
        }

        _transferFrom(from, to, value);
        return true;
    }

//    function _swapAndLiquify(uint256 contractTokenBalance) private {
//        uint256 half = contractTokenBalance / (2);
//        uint256 otherHalf = contractTokenBalance - (half);
//
//        uint256 initialBalance = address(this).balance;
//
//        _swapTokensForAVAX(half, address(this));
//
//        uint256 newBalance = address(this).balance.sub(initialBalance);
//
//        _addLiquidity(otherHalf, newBalance);
//
//        emit SwapAndLiquify(half, newBalance, otherHalf);
//    }

    function _addLiquidity(uint256 tokenAmount, uint256 avaxAmount) private {
        router.addLiquidityAVAX{value: avaxAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }

    function _addLiquidityUSDC(uint256 tokenAmount, uint256 usdcAmount) private {
        router.addLiquidity(
            address(this),
            convertTo,
            tokenAmount,
            usdcAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }

    function _swapTokensForAVAX(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WAVAX();

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function _swapTokensForUSDC(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WAVAX();
        path[2] = address(usdcAddress);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function swapBack() internal swapping {
        uint256 realTotalFee = totalFee[0] + (totalFee[1]) + (totalFee[2]) + (totalFee[3]);

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 balanceBefore = address(this).balance;

        uint256 amountToLiquify = 0;
        if (!isOverLiquified())
            amountToLiquify = contractTokenBalance * (liquidityFee[0] + liquidityFee[1] + liquidityFee[2] + liquidityFee[3]) / (realTotalFee);

        uint256 amountToSwap = contractTokenBalance - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = convertTo;

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance - (balanceBefore);

        uint256 totalAVAXFee = ((realTotalFee) -
        (liquidityFee[0] + liquidityFee[1] + liquidityFee[2] + liquidityFee[3]) /
        (2));

        uint256 amountAVAXLiquidity = (amountAVAX * (liquidityFee[0] + liquidityFee[1] + liquidityFee[2] + liquidityFee[3])) /
        (totalAVAXFee) /
        (2);

        uint256 amountToRFV = amountAVAX * (riskFeeValueFee[0] + riskFeeValueFee[1] + riskFeeValueFee[2] + riskFeeValueFee[3]) / (realTotalFee);
        uint256 amountToTreasury = amountAVAX * (treasuryFee[0] + treasuryFee[1] + treasuryFee[2] + treasuryFee[3]) / (realTotalFee);
        uint256 amountToOperation = amountAVAX * (operationsFee[0] + operationsFee[1] + operationsFee[2] + operationsFee[3]) / (realTotalFee);
        uint256 amountToxASTRO = amountAVAX * (xASTROFee[0] + xASTROFee[1] + xASTROFee[2] + xASTROFee[3]) / (realTotalFee);
        uint256 amountToEcosystem = amountAVAX * (ecosystemFee[0] + ecosystemFee[1] + ecosystemFee[2] + ecosystemFee[3]) / (realTotalFee);


        (bool success,) = payable(treasuryReceiver).call{
        value : amountToTreasury,
        gas : 30000
        }('');
        (success,) = payable(riskFreeValueReceiver).call{
        value : amountToRFV,
        gas : 30000
        }('');
        (success,) = payable(operationsReceiver).call{
        value : amountToOperation,
        gas : 30000
        }('');
        (success,) = payable(xASTROReceiver).call{
        value : amountToxASTRO,
        gas : 30000
        }('');
        (success,) = payable(futureEcosystemReceiver).call{
        value : amountToEcosystem,
        gas : 30000
        }('');

        success = false;

        if (amountToLiquify > 0) {
            router.addLiquidityAVAX{value : amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityReceiver,
                block.timestamp
            );
        }

        emit SwapBack(contractTokenBalance, amountToLiquify, amountToRFV, amountToTreasury);
    }

    function takeFee(address sender, address recipient, uint256 gonAmount) internal returns (uint256) {
        uint256 amount = gonAmount / (_gonsPerFragment);
        uint256 usdcAmount = getUSDCFromASTRO(amount);

        uint256 _realFee = totalFee[0];
        if(automatedMarketMakerPairs[recipient]) {
            _realFee = totalFee[1];
            if (usdcAmount > whaleSellLimit) {
                _realFee = totalFee[3];
            }
            else if (usdcAmount > normalSellLimit) {
                _realFee = totalFee[2];
            }
        }

        uint256 feeAmount = gonAmount / (feeDenominator) * (_realFee);

        _gonBalances[address(this)] = _gonBalances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount / (_gonsPerFragment));
        return gonAmount / (feeAmount);
    }

    function getUSDCFromASTRO(uint256 _amount) public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WAVAX();
        path[2] = address(usdcAddress);

        uint256[] memory price_out = router.getAmountsOut(_amount, path);
        return price_out[2];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];

        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - (subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender] + (addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _rebase() private {
        if (!inSwap) {
            int256 supplyDelta = int256(_totalSupply * (rewardYield) / (rewardYieldDenominator));

            coreRebase(supplyDelta);
        }
    }

    function coreRebase(int256 supplyDelta) private returns (uint256) {
        uint256 epoch = block.timestamp;

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply - (uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply + (uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS / (_totalSupply);

        nextRebase = epoch + rebaseFrequency;

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function manualRebase() external onlyOwner {
        require(!inSwap, "Try again");
        require(nextRebase <= block.timestamp, "Not in time");

        int256 supplyDelta = int256(_totalSupply * (rewardYield) / (rewardYieldDenominator));

        coreRebase(supplyDelta);
        manualSync();
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            _markerPairs.push(_pair);
        } else {
            require(_markerPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == _pair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function setInitialDistributionFinished(bool _value) external onlyOwner {
        require(initialDistributionFinished != _value, "Not changed");
        initialDistributionFinished = _value;
    }

    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        require(_isFeeExempt[_addr] != _value, "Not changed");
        _isFeeExempt[_addr] = _value;
    }

    function setBlacklisted(address _addr, bool _value) external onlyOwner {
        require(_blacklistedUsers[_addr] != _value, "Not changed");
        _blacklistedUsers[_addr] = _value;
    }

    function pauseTrading(bool _pause) external onlyOwner {
        require(_pause != pause, "No change.");
        pause = _pause;
    }

    function adjustAllottedSell(uint256 interval, uint256 percentage) external onlyOwner {
        allottedSellInterval = interval * 1 days;
        allottedSellPercentage = percentage;
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy) external onlyOwner {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
    }

    function setSwapBackSettings(bool _enabled, uint256 _num, uint256 _denom) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS / (_denom) * (_num);
    }

    function setIsLiquidityEnabled(bool _value) external onlyOwner {
        isLiquidityEnabled = _value;
    }

    function setFeeReceivers(address _liquidityReceiver, address _treasuryReceiver, address _riskFreeValueReceiver, address _futureEcosystemReceiver, address _operationReceiver, address _xASTROReceiver, address _burnReceiver) external onlyOwner {
        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        operationsReceiver = _operationReceiver;
        xASTROReceiver = _xASTROReceiver;
        futureEcosystemReceiver = _futureEcosystemReceiver;
        burnReceiver = _burnReceiver;
    }

    function setFees(uint8 _feeKind, uint256 _total, uint256 _liquidityFee, uint256 _riskFreeValue, uint256 _treasuryFee, uint256 _feeFee, uint256 _operationFee, uint256 _xAstroFee, uint256 _burnFee) external onlyOwner {
        require (_liquidityFee + _riskFreeValue + _treasuryFee + _feeFee + _operationFee + _xAstroFee + _burnFee == 100, "subFee is not allowed");

        totalFee[_feeKind] = _total * 100;
        liquidityFee[_feeKind] = _total * _liquidityFee;
        treasuryFee[_feeKind] = _total * _treasuryFee;
        riskFeeValueFee[_feeKind] = _total * _riskFreeValue;
        ecosystemFee[_feeKind] = _total * _feeFee;
        operationsFee[_feeKind] = _total * _operationFee;
        xASTROFee[_feeKind] = _total * _xAstroFee;
        burnFee[_feeKind] = _total * _burnFee;
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function setRouterAddress(address _router) external onlyOwner {
        router = IDEXRouter(_router);
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        require(autoRebase != _autoRebase, "Not changed");
        autoRebase = _autoRebase;
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        require(_rebaseFrequency <= MAX_REBASE_FREQUENCY, "Too high");
        rebaseFrequency = _rebaseFrequency;
    }

    function setRewardYield(uint256 _rewardYield, uint256 _rewardYieldDenominator) external onlyOwner {
        rewardYield = _rewardYield;
        rewardYieldDenominator = _rewardYieldDenominator;
    }

    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        require(feesOnNormalTransfers != _enabled, "Not changed");
        feesOnNormalTransfers = _enabled;
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        maxSellTransactionAmount = _maxTxn;
    }

    function setNormalSellLimit(uint256 _fee) external onlyOwner {
        normalSellLimit = _fee;
    }

    function setWhaleSellLimit(uint256 _fee) external onlyOwner {
        whaleSellLimit = _fee;
    }

    function setPurchasePeriod(uint256 _time) external onlyOwner {
        purchasePeriod = _time;
    }

    function setAirdropAddress(address[] memory _airdropAddress) external onlyOwner {
        airdropAddress = _airdropAddress;
    }

    function setAirdropAmount(uint256[] memory _airdropAmount) external onlyOwner {
        airdropAmount = _airdropAmount;
    }

    function airdrop(address tokenAddress) external onlyOwner {
        for(uint256 i = 0; i < airdropAddress.length ; i ++) {
            IERC20(tokenAddress).transfer(airdropAddress[i], airdropAmount[i]);
        }
    }

    event SwapBack(uint256 contractTokenBalance,uint256 amountToLiquify,uint256 amountToRFV,uint256 amountToTreasury);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 avaxReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyUSDC(uint256 tokensSwapped, uint256 busdReceived, uint256 tokensIntoLiqudity);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GenericErrorEvent(string reason);

    receive() payable external {}

    fallback() payable external {}
}