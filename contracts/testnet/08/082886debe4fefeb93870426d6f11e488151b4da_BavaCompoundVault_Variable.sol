// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./BRTERC20Upgradeable.sol";
import "./interface/IMiniChef.sol";
import "./interface/IRouter.sol";
import "./interface/IPair.sol";
import "./interface/IBavaMasterFarm.sol";
import "./interface/IBavaToken.sol";

// BavaCompoundVault is the compoundVault of BavaMasterFarmer. It will autocompound user LP.
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Bava is sufficiently
// distributed and the community can show to govern itself.

contract BavaCompoundVault_Variable is Initializable, UUPSUpgradeable, BRTERC20Upgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable private WAVAX;     // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
    IERC20Upgradeable private USDCE;     // 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664
    uint256 public MIN_TOKENS_TO_REINVEST;
    uint256 public DEV_FEE_BIPS;
    uint256 public REINVEST_REWARD_BIPS;
    uint256 internal BIPS_DIVISOR;

    IRouter public router;                      // Router
    IBAVAMasterFarm public BavaMasterFarm;      // MasterFarm to mint BAVA token.
    IBavaToken public Bava;                     // The Bava TOKEN!
    uint256 public bavaPid;                     // BAVA Master Farm Vault Id
    address public devaddr;                     // Developer/Employee address.
    address public liqaddr;                     // Liquidate address

    IERC20Upgradeable public rewardToken;
    IERC20Upgradeable[] public bonusRewardTokens;
    uint256[] public blockDeltaStartStage;
    uint256[] public blockDeltaEndStage;
    uint256[] public userFeeStage;
    uint256 public userDepFee;
    uint256 public PERCENT_LOCK_BONUS_REWARD;           // lock xx% of bounus reward in 3 year

    VaultInfo public vaultInfo;                         // Info of vault.
    mapping (address => UserInfo) public userInfo;      // Info of each user that stakes LP tokens. pid => user address => info
    mapping(address => bool) public authorized;

    // Info of each user.
    struct UserInfo {
        uint256 receiptAmount;      // user receipt tokens.
        uint256 rewardDebt;         // Reward debt. See explanation below.
		uint128 blockdelta;         // time passed since withdrawals
		uint128 lastDepositBlock;   // the last block a user deposited at.
    }

    // Info of Vault.
    struct VaultInfo {
        IERC20Upgradeable lpToken;          // Address of LP token contract.
        IMiniChef pglStakingContract;       // Panglin LP Staking contract
        uint256 depositAmount;              // Total deposit amount
        uint256 restakingFarmID;            // RestakingFarm ID
        bool deposits_enabled;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 devAmount);
    event SendBavaReward(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockAmount);
    event DepositsEnabled(bool newValue);
    event Liquidate(address indexed userAccount, uint256 amount);

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender,"!Owner");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /********************************* INITIAL SETUP *********************************/
    // Init the vault. Support LP from pangolin miniChef.
    function initVault(IERC20Upgradeable _lpToken, IMiniChef _stakingPglContract, uint256 _restakingFarmID, IERC20Upgradeable _rewardToken, IERC20Upgradeable[] memory _bonusRewardTokens, IRouter _router, uint256 _MIN_TOKENS_TO_REINVEST, uint256 _DEV_FEE_BIPS, uint256 _REINVEST_REWARD_BIPS) external onlyOwner {        
        require(address(_lpToken) != address(0), "0Add");
        require(address(_stakingPglContract) != address(0), "0Add");

        vaultInfo.lpToken = _lpToken;
        vaultInfo.depositAmount = 0;
        vaultInfo.deposits_enabled = true;
        vaultInfo.pglStakingContract = _stakingPglContract;
        vaultInfo.restakingFarmID = _restakingFarmID;
        
        rewardToken = _rewardToken;
        bonusRewardTokens = _bonusRewardTokens;
        router = _router;
        MIN_TOKENS_TO_REINVEST = _MIN_TOKENS_TO_REINVEST;
        DEV_FEE_BIPS = _DEV_FEE_BIPS;
        REINVEST_REWARD_BIPS = _REINVEST_REWARD_BIPS;
    }

    /**
     * @notice Approve tokens for use in Strategy, Restricted to avoid griefing attacks
     */
    function setAllowances(uint256 _amount) external onlyOwner {
        if (address(vaultInfo.pglStakingContract) != address(0)) {
            vaultInfo.lpToken.approve(address(vaultInfo.pglStakingContract), _amount);
        }

        if (address(router) != address(0)) {
            WAVAX.approve(address(router), _amount);
            IERC20Upgradeable(IPair(address(vaultInfo.lpToken)).token0()).approve(address(router), _amount);
            IERC20Upgradeable(IPair(address(vaultInfo.lpToken)).token1()).approve(address(router), _amount);
            IERC20Upgradeable(address(vaultInfo.lpToken)).approve(address(router), _amount);

            IERC20Upgradeable(rewardToken).approve(address(router), _amount);
            uint256 rewardLength = bonusRewardTokens.length;
            uint i = 0;
            for (i; i < rewardLength; i++) {
                IERC20Upgradeable(bonusRewardTokens[i]).approve(address(router), _amount);
            }
        }
    }

    /****************************************** FARMING CORE FUNCTION ******************************************/
    // Update reward variables of the given vault to be up-to-date.
    function updatePool() public {
        ( , , , uint256 lastRewardBlock, ) = BavaMasterFarm.poolInfo(bavaPid);
        if (block.number <= lastRewardBlock) {
            return;
        }
        BavaMasterFarm.updatePool(bavaPid);
    }

    function claimReward() external {
        updatePool();
        _harvest(msg.sender);
    }

    // lock 95% of reward
    function _harvest(address account) private {
        UserInfo storage user = userInfo[account];
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
        if (user.receiptAmount > 0) {
            uint256 pending = user.receiptAmount*(accBavaPerShare)/(1e12)-(user.rewardDebt);
            uint256 masterBal = Bava.balanceOf(address(this));

            if (pending > masterBal) {
                pending = masterBal;
            }
            
            if(pending > 0) {
                Bava.transfer(account, pending);
                uint256 lockAmount = pending*(PERCENT_LOCK_BONUS_REWARD)/(100);
                Bava.lock(account, lockAmount);

                emit SendBavaReward(account, bavaPid, pending, lockAmount);
            }
            user.rewardDebt = user.receiptAmount*(accBavaPerShare)/(1e12);
        }
    }
    
    // Deposit LP tokens to BavaMasterFarmer for $Bava allocation.
    function deposit(uint256 _amount, bool restake) external {
        require(_amount > 0, "#<0");
        require(vaultInfo.deposits_enabled == true, "False");

        UserInfo storage user = userInfo[msg.sender];
        UserInfo storage devr = userInfo[devaddr];

        (uint256 estimatedTotalReward ) = checkReward();
        if (estimatedTotalReward > MIN_TOKENS_TO_REINVEST) {
            _reinvest(restake);
        }

        updatePool();
        _harvest(msg.sender);
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
        
        vaultInfo.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint vaultReceiptAmount = getSharesForDepositTokens(_amount);
        vaultInfo.depositAmount += _amount;

        uint userReceiptAmount = vaultReceiptAmount - (vaultReceiptAmount * userDepFee / 10000);  
        uint devrReceiptAmount = vaultReceiptAmount - userReceiptAmount;

        user.receiptAmount += userReceiptAmount;
        user.rewardDebt = user.receiptAmount * (accBavaPerShare) / (1e12);
        devr.receiptAmount += devrReceiptAmount;
        devr.rewardDebt = devr.receiptAmount * (accBavaPerShare) / (1e12);
        _mint(msg.sender, userReceiptAmount);
        _mint(devaddr, devrReceiptAmount);

        if(restake == true) {
            _stakeDepositTokens(_amount);
        }
        
        emit Deposit(msg.sender, bavaPid, _amount);
		user.lastDepositBlock = uint128(block.number);
    }

    // Withdraw LP tokens from BavaMasterFarmer. argument "_amount" is receipt amount.
    function withdraw(uint256 _amount, bool harvestReinvestReward) external {
        UserInfo storage user = userInfo[msg.sender];
        uint depositTokenAmount = getDepositTokensForShares(_amount);
        require(vaultInfo.depositAmount >= depositTokenAmount, "#>Bal");
        require(user.receiptAmount >= _amount, "#>Stake");
        updatePool();
        _harvest(msg.sender);
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);

        if(depositTokenAmount > 0) {
            _withdrawDepositTokens(depositTokenAmount);
            if(harvestReinvestReward == true) {
                _getReinvestReward();
            }
            user.receiptAmount = user.receiptAmount-(_amount);
            _burn(msg.sender, _amount);

            user.blockdelta = uint128(block.number - user.lastDepositBlock);
            vaultInfo.depositAmount -= depositTokenAmount;
            user.rewardDebt = user.receiptAmount*(accBavaPerShare)/(1e12);

			if(user.blockdelta == blockDeltaStartStage[0] || block.number == user.lastDepositBlock) {
				//25% fee for withdrawals of LP tokens in the same block this is to prevent abuse from flashloans
                _withdrawLPTokens(depositTokenAmount, userFeeStage[0]);
			} else if (user.blockdelta >= blockDeltaStartStage[1] && user.blockdelta <= blockDeltaEndStage[0]) {
				//8% fee if a user deposits and withdraws in under between same block and 59 minutes.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[1]);
			} else if (user.blockdelta >= blockDeltaStartStage[2] && user.blockdelta <= blockDeltaEndStage[1]) {
				//4% fee if a user deposits and withdraws after 1 hour but before 1 day.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[2]);
			} else if (user.blockdelta >= blockDeltaStartStage[3] && user.blockdelta <= blockDeltaEndStage[2]) {
				//2% fee if a user deposits and withdraws between after 1 day but before 3 days.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[3]);
			} else if (user.blockdelta >= blockDeltaStartStage[4] && user.blockdelta <= blockDeltaEndStage[3]) {
				//1% fee if a user deposits and withdraws after 3 days but before 5 days.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[4]);
			}  else if (user.blockdelta >= blockDeltaStartStage[5] && user.blockdelta <= blockDeltaEndStage[4]) {
				//0.5% fee if a user deposits and withdraws after 5 days but before 2 weeks.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[5]);
			} else if (user.blockdelta >= blockDeltaStartStage[6] && user.blockdelta <= blockDeltaEndStage[5]) {
				//0.25% fee if a user deposits and withdraws after 2 weeks.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[6]);
			} else if (user.blockdelta > blockDeltaStartStage[7]) {
				//0.1% fee if a user deposits and withdraws after 4 weeks.
                _withdrawLPTokens(depositTokenAmount, userFeeStage[7]);
			}
            emit Withdraw(msg.sender, bavaPid, depositTokenAmount);
		}
    }

    // EMERGENCY ONLY. Withdraw without caring about rewards.  
    // This has the same 25% fee as same block withdrawals and ucer receipt record set to 0 to prevent abuse of thisfunction.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 userBRTAmount = balanceOf(msg.sender);
        uint depositTokenAmount = getDepositTokensForShares(userBRTAmount);

        require(vaultInfo.depositAmount >= depositTokenAmount, "#>Bal");      //  vault.lpToken.balanceOf(address(this))
        _withdrawDepositTokens(depositTokenAmount);
        _burn(msg.sender, userBRTAmount);
        // Reordered from Sushi function to prevent risk of reentrancy
        uint256 amountToSend = depositTokenAmount*(75)/(100);
        uint256 devToSend = depositTokenAmount - amountToSend;  //25% penalty
        user.receiptAmount = 0;
        user.rewardDebt = 0;
        vaultInfo.depositAmount -= depositTokenAmount;
        vaultInfo.lpToken.safeTransfer(address(msg.sender), amountToSend);
        vaultInfo.lpToken.safeTransfer(address(devaddr), devToSend);

        emit EmergencyWithdraw(msg.sender, bavaPid, amountToSend, devToSend);
    }

    function reinvest(bool restake) external {
        (uint256 estimatedTotalReward ) = checkReward();
        require(estimatedTotalReward >= MIN_TOKENS_TO_REINVEST, "#<MinInvest");

        _reinvest(restake);
    }

    function liquidateCollateral(address userAccount, uint256 amount) external onlyAuthorized {
        _liquidateCollateral(userAccount, amount);
    }

    // Withdraw LP token from this farm
    function _withdrawLPTokens(uint _depositTokenAmount, uint _userFeeStage) private {
        uint256 userWithdrawFee = _depositTokenAmount * _userFeeStage / BIPS_DIVISOR;
        vaultInfo.lpToken.safeTransfer(address(msg.sender), userWithdrawFee);
        vaultInfo.lpToken.safeTransfer(address(devaddr), _depositTokenAmount - userWithdrawFee);
    }

    /**************************************** Internal restaking FUNCTIONS ****************************************/

    // Stake LP token to 3rd party restaking farm
    function _stakeDepositTokens(uint amount) internal {
        require(amount > 0, "#<0");
        vaultInfo.pglStakingContract.deposit(vaultInfo.restakingFarmID, amount, address(this));
    }

    // Withdraw LP token to 3rd party restaking farm
    function _withdrawDepositTokens(uint amount) internal {
        require(amount > 0, "#<0");
        (uint256 depositAmount,) = vaultInfo.pglStakingContract.userInfo(vaultInfo.restakingFarmID, address(this));
        if (depositAmount > 0) {
            if(depositAmount >= amount) {
                vaultInfo.pglStakingContract.withdraw(vaultInfo.restakingFarmID, amount, address(this));
            } else {
                vaultInfo.pglStakingContract.withdraw(vaultInfo.restakingFarmID, depositAmount, address(this));
            }
        }
    }

    // Claim LP restaking reward from 3rd party restaking contract
    function _getReinvestReward() internal {
        uint256 pendingRewardAmount = vaultInfo.pglStakingContract.pendingReward(vaultInfo.restakingFarmID, address(this));
        if(pendingRewardAmount > 0) {
            vaultInfo.pglStakingContract.harvest(vaultInfo.restakingFarmID, address(this));
        }
    }

    /**************************************** VIEW FUNCTIONS ****************************************/
    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     */
    function getSharesForDepositTokens(uint amount) public view returns (uint) {
        if (totalSupply() * vaultInfo.depositAmount == 0) {
            return amount;
        }
        return (amount*totalSupply() / vaultInfo.depositAmount);
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     */
    function getDepositTokensForShares(uint amount) public view returns (uint) {
        if (totalSupply() * vaultInfo.depositAmount == 0) {
            return 0;
        }
        return (amount * vaultInfo.depositAmount / totalSupply());
    }

    // View function to see pending Bavas on frontend.
    function pendingReward(address _user) external view returns (uint) {
        UserInfo storage user = userInfo[_user];
        (, , uint256 allocPoint, uint256 lastRewardBlock, uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
        uint256 lpSupply = totalSupply();

        if (block.number > lastRewardBlock && lpSupply > 0) {
            uint256 BavaForFarmer;
            (, BavaForFarmer, , ,) = BavaMasterFarm.getPoolReward(lastRewardBlock, block.number, allocPoint);
            accBavaPerShare = accBavaPerShare+(BavaForFarmer*(1e12)/(lpSupply));
        }
        return user.receiptAmount*(accBavaPerShare)/(1e12)-(user.rewardDebt);
    }

    // View function to see pending 3rd party reward. Ignore bonus reward view to reduce code size and gas
    function checkReward() public view returns (uint) {
        uint256 pendingRewardAmount = vaultInfo.pglStakingContract.pendingReward(vaultInfo.restakingFarmID, address(this));
        uint256 rewardBalance = rewardToken.balanceOf(address(this));

        return (pendingRewardAmount+rewardBalance);
    }

    /**************************************** ONLY OWNER FUNCTIONS ****************************************/
    // Rescue any token function, just in case if any user not able to withdraw token from the smart contract.
    function rescueDeployedFunds(address token, uint256 amount, address _to) external onlyOwner {
        require(_to != address(0), "0Addr");
        IERC20Upgradeable(token).safeTransfer(_to, amount);
    }

    // Emergency withdraw LP token from 3rd party restaking contract
    function emergencyWithdrawDepositTokens(bool disableDeposits) external onlyOwner {
        vaultInfo.pglStakingContract.emergencyWithdraw(vaultInfo.restakingFarmID, address(this));
        if (vaultInfo.deposits_enabled == true && disableDeposits == true) {
            updateDepositsEnabled(false);
        }
    }

    // Update the given vault's Bava restaking contract. Can only be called by the owner.
    function setVaultInfo(IMiniChef _stakingPglContract, uint256 _restakingFarmID, IERC20Upgradeable _rewardToken, IERC20Upgradeable[] memory _bonusRewardTokens, bool _withUpdate) external onlyOwner {
        require(address(_stakingPglContract) != address(0) , "0Addr");        
        if (_withUpdate) {
            updatePool();
        }
        vaultInfo.pglStakingContract = _stakingPglContract;
        vaultInfo.restakingFarmID = _restakingFarmID;
        rewardToken = _rewardToken;
        bonusRewardTokens = _bonusRewardTokens;
    }

    function setBavaMasterFarm(IBAVAMasterFarm _BavaMasterFarm, uint256 _bavaPid) external onlyOwner {
        BavaMasterFarm = _BavaMasterFarm;
        bavaPid = _bavaPid;
    }

    function addrUpdate(address _devaddr, address _liqaddr) public onlyOwner {
        devaddr = _devaddr;
        liqaddr = _liqaddr;
    }

    function addAuthorized(address _toAdd) onlyOwner public {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) onlyOwner public {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(vaultInfo.deposits_enabled != newValue);
        vaultInfo.deposits_enabled = newValue;
        emit DepositsEnabled(newValue);
    }

    /**************************************** ONLY AUTHORIZED FUNCTIONS ****************************************/
    // Update % lock for general users & percent for other roles
    function percentUpdate(uint _newlock) public onlyAuthorized {
       PERCENT_LOCK_BONUS_REWARD = _newlock;
    }

	function setStageStarts(uint[] memory _blockStarts) public onlyAuthorized {
        blockDeltaStartStage = _blockStarts;
    }
    
    function setStageEnds(uint[] memory _blockEnds) public onlyAuthorized {
        blockDeltaEndStage = _blockEnds;
    }
    
    function setUserFeeStage(uint[] memory _userFees) public onlyAuthorized {
        userFeeStage = _userFees;
    }

    function setDepositFee(uint _usrDepFees) public onlyAuthorized {
        userDepFee = _usrDepFees;
    }

    function setMinReinvestToken(uint _MIN_TOKENS_TO_REINVEST) public onlyAuthorized {
        MIN_TOKENS_TO_REINVEST = _MIN_TOKENS_TO_REINVEST;
    }

    function setFeeBips(uint _DEV_FEE_BIPS, uint _REINVEST_REWARD_BIPS) public onlyAuthorized {
        DEV_FEE_BIPS = _DEV_FEE_BIPS;
        REINVEST_REWARD_BIPS = _REINVEST_REWARD_BIPS;
    }

    /*********************** Autocompound Strategy ******************
    * Swap all reward tokens to WAVAX and swap half/half WAVAX token to both LP token0 & token1, Add liquidity to LP token
    ****************************************/
    function _reinvest(bool restake) private {
        _getReinvestReward();
        uint wavaxAmount = _convertRewardIntoWAVAX();
        uint liquidity = _convertWAVAXTokenToDepositToken(wavaxAmount);
        if(restake == true) {
            vaultInfo.pglStakingContract.deposit(vaultInfo.restakingFarmID, liquidity, address(this));
        }
        vaultInfo.depositAmount += liquidity;
    }

    function _convertRewardIntoWAVAX() private returns (uint) {
        uint pathLength = 2;
        address[] memory path = new address[](pathLength);
        uint256 avaxAmount;

        path[0] = address(rewardToken);
        path[1] = address(WAVAX);
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (rewardBal > 0) {
            _convertExactTokentoToken(path, rewardBal);
        }

        // Variable reward Super farm strategy
        uint256 rewardLength = bonusRewardTokens.length;
        for (uint i; i < rewardLength; i++) {
            if (address(bonusRewardTokens[i]) != address(WAVAX)) {
                path[0] = address(bonusRewardTokens[i]);
                path[1] = address(WAVAX);
                rewardBal = bonusRewardTokens[i].balanceOf(address(this));
                if (rewardBal > 0) {
                    _convertExactTokentoToken(path, rewardBal);
                }
            }
        }
        
        avaxAmount = WAVAX.balanceOf(address(this));
        uint256 devFee = avaxAmount*(DEV_FEE_BIPS)/(BIPS_DIVISOR);
        uint256 reinvestFee = avaxAmount*(REINVEST_REWARD_BIPS)/(BIPS_DIVISOR);
        WAVAX.safeTransfer(devaddr, devFee);
        WAVAX.safeTransfer(msg.sender, reinvestFee);
        
        return (avaxAmount-reinvestFee-devFee);
    }

    function _convertWAVAXTokenToDepositToken(uint256 amount) private returns (uint) {
        require(amount > 0, "#<0");
        uint amountIn = amount / 2;

        // swap to token0
        uint path0Length = 2;
        address[] memory path0 = new address[](path0Length);
        path0[0] = address(WAVAX);
        path0[1] = IPair(address(vaultInfo.lpToken)).token0();

        uint amountOutToken0 = amountIn;
        // Check if path0[1] equal to WAVAX 
        if (path0[0] != path0[path0Length - 1]) {
            amountOutToken0 = _convertExactTokentoToken(path0, amountIn);
        }

        // swap to token1
        uint path1Length = 2;
        address[] memory path1 = new address[](path1Length);
        path1[0] = path0[0];
        path1[1] = IPair(address(vaultInfo.lpToken)).token1();

        uint amountOutToken1 = amountIn;
        if (path1[0] != path1[path1Length - 1]) {
            amountOutToken1 = _convertExactTokentoToken(path1, amountIn);
        }

        // swap to deposit(LP) Token
        (,,uint liquidity) = router.addLiquidity(
            path0[path0Length - 1], path1[path1Length - 1],
            amountOutToken0, amountOutToken1,
            0, 0,
            address(this),
            block.timestamp+600
        );
        return liquidity;
    }

    // Liquidate user collateral when user LP token value lower than user borrowed fund.
    function _liquidateCollateral(address userAccount, uint256 amount) private {
        UserInfo storage user = userInfo[userAccount];
        uint depositTokenAmount = getDepositTokensForShares(amount);
        updatePool();
        _harvest(userAccount);
        (, , , , uint256 accBavaPerShare) = BavaMasterFarm.poolInfo(bavaPid);
       
        require(vaultInfo.depositAmount >= depositTokenAmount, "#>Bal");
        _burn(msg.sender, amount);
        _withdrawDepositTokens(depositTokenAmount);
        // Reordered from Sushi function to prevent risk of reentrancy
        user.receiptAmount -= amount;
        user.rewardDebt = user.receiptAmount * (accBavaPerShare) / (1e12);
        vaultInfo.depositAmount -= depositTokenAmount;
        vaultInfo.lpToken.safeTransfer(address(liqaddr), depositTokenAmount);

        emit Liquidate(userAccount, amount);
    }

    function _convertExactTokentoToken(address[] memory path, uint amount) private returns (uint) {
        uint[] memory amountsOutToken = router.getAmountsOut(amount, path);
        uint amountOutToken = amountsOutToken[amountsOutToken.length - 1];
        uint[] memory amountOut = router.swapExactTokensForTokens(amount, amountOutToken, path, address(this), block.timestamp+600);
        uint swapAmount = amountOut[amountOut.length - 1];

        return swapAmount;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**************************************************************
     * @dev Initialize smart contract functions - only called once
     * @param symbol: BRT2LPSYMBOL
     *************************************************************/
    function initialize(
        string memory name_, 
        string memory symbol_, 
        IBavaToken _IBava,
        IBAVAMasterFarm _BavaMasterFarm,
        uint256 _bavaPid,
        address _devaddr,
        address _liqaddr,
        uint256 _userDepFee,
        uint256 _newlock,
        uint256[] memory _blockDeltaStartStage,
        uint256[] memory _blockDeltaEndStage,
        uint256[] memory _userFeeStage 
    ) public initializer {
        Bava = _IBava;
        BavaMasterFarm = _BavaMasterFarm;
        bavaPid = _bavaPid;
        devaddr = _devaddr;
        liqaddr = _liqaddr;
        userDepFee = _userDepFee;
        PERCENT_LOCK_BONUS_REWARD = _newlock; 
        blockDeltaStartStage = _blockDeltaStartStage;
        blockDeltaEndStage = _blockDeltaEndStage;
        userFeeStage = _userFeeStage;
        
        WAVAX = IERC20Upgradeable(0x52B654763F016dAF087d163c9EB6c7F486261019);     // 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7
        USDCE = IERC20Upgradeable(0x3800955b7A4233A2a4f2344a43362D9126E9FC81);     // 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664
        BIPS_DIVISOR = 10000;

        __ERC20_init(name_, symbol_);
        __ERC20Burnable_init();
        // __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRouter {
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(address token, uint amountTokenDesired, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountAVAXMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountAVAX);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens( uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMiniChef {
    function userInfo(uint pid, address user) external view returns (
        uint256 amount,
        uint256 rewardDebt
    );

    function poolInfo(uint pid) external view returns (
        uint accRewardPerShare,
        uint allocPoint,
        uint lastRewardTime
    );

    function rewarder(uint pid) external view returns (address);
    function lpToken(uint pid) external view returns (address);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBavaToken {
    function transfer(address to, uint tokens) external returns (bool success);

    function mint(address to, uint tokens) external;

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function cap() external view returns (uint capSuppply);

    function totalSupply() external view returns (uint _totalSupply);

    function lock(address _holder, uint256 _amount) external;

    function lockFromBlock() external view returns (uint lockToBlock);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBAVAMasterFarm {
    function updatePool(uint256 _pid) external;

    function poolInfo(uint256 _pid) external view returns (
        address lpToken,
        address poolContract,
        uint256 allocPoint,
        uint256 lastRewardBlock,
        uint256 accBavaPerShare
    );

    function getPoolReward(uint256 _from, uint256 _to, uint256 _allocPoint) external view returns (
        uint256 forDev, 
        uint256 forFarmer, 
        uint256 forFT, 
        uint256 forAdr, 
        uint256 forFounders
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract BRTERC20Upgradeable is ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {

    // function pause() public onlyOwner {
    //     _pause();
    // }

    // function unpause() public onlyOwner {
    //     _unpause();
    // }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
        // whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
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