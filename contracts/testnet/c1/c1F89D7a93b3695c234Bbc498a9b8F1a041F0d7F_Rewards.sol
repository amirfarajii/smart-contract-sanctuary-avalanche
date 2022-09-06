// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./lib/Claimable.sol";
import "./lib/Math.sol";
import "./lib/InterfacesVaLiFi.sol";

/**
 * @title Rewards Contract / ValiFi Rewards Protocol
 * @dev Implementation of the Rewards NFT ERC721.
 * @custom:a ValiFi
 */
contract Rewards is
    Math,
    Claimable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    struct RewardStruct {
        /** @dev First day maintenance fee */
        uint64 firstDay; // must be change Last Claim
        /** @dev Days of rewards claimed */
        uint256 claimedDays;
        /** @dev Days of minimal rewards (free) claimed */
        uint256 freeDaysClaimed;
    }
    // Mapping of rewards per YieldBox
    mapping(uint256 => RewardStruct) public RewardsClaimed;
    // Days limit of YieldBox Rewards
    uint256 public LIMITS_DAYS;
    // Token Rewards per Day per YieldBox
    uint256 public REWARDS_PER_DAYS;
    // Percentage of the minimal reward per day (when YieldKey is not staked/associated to YieldBox)
    uint8 public MINIMAL_REWARDS;
    // Days limit of YieldBox Minimal Rewards
    uint256 public MINIMAL_REWARDS_DAYS;
    // Pause rewards
    bool private pauseRewards;
    // Instance of the Smart Contract
    IYieldKey private YieldKey;
    IYieldBox private YieldBox;
    IStakedYieldKey private StakedYieldKeyLeg;
    IStakedYieldKey private StakedYieldKeyReg;
    IMaintFee private MaintFee;
    /** @dev Token Address ValiFi */
    address private tokenAddress;
    /** @dev Treasury Address */
    address private rewardsPool;
    uint256 public ADD_PERCENTAGE_FOR_COMPOUND;
    mapping(uint256 => address) public donations;
    IVaLiFiHelpers private VaLiFiHelpers;
    IRouter private router;
    /**
     * @dev Event of Reward
     * @param owner of the YieldBox
     * @param YieldBoxesId ID of the YieldBox
     * @param rewardedDays Amount days claimed
     * @param amountClaimed Amount of VALI token claimed
     */
    event RewardsPaid(
        address indexed owner,
        uint256 YieldBoxesId,
        uint256 rewardedDays,
        uint256 amountClaimed
    );
    /**
     * @dev Event when YieldBox reward per day is updated
     * @param oldRewardPerYieldBox old value of YieldBox reward per day
     * @param newRewardPerYieldBox new value of YieldBox reward per day
     */
    event SetRewardPerYieldBox(
        uint256 oldRewardPerYieldBox,
        uint256 newRewardPerYieldBox
    );
    /**
     * @dev Event when Token Address of ValiFi ERC20 is updated
     * @param tokenAddress new value of ValiFi ERC20 Token Address
     */
    event SetTokenAddress(address tokenAddress);

    /**
     * @dev Event when setting the Rewards Pool wallet (ValiFi ERC20)
     * @param _rewardsPool new value of Rewards Pool wallet (ValiFi ERC20)
     */
    event SetRewardsPool(address _rewardsPool);

    // The User `_wallet` don't have enough rewards (`_amountOdRewards`) pending to claim and create a new YieldBox
    error EnoughRewardsForCompound(address _wallet, uint256 _amountOdRewards);
    // Inconsistence in Rewards Calculate, Rewards Calculate `_amountOdRewardsCalculated` vs Sent `_amountOdRewardsSent`
    error TotalRewardsInconsistence(
        address _wallet,
        uint256 _amountOdRewardsSent,
        uint256 _amountOdRewardsCalculated
    );
    // The Percentage indicated `_percentage` is not valid
    error InvalidPercentage(uint256 _percentage);
    // The Index `index` sent is not valid
    error InvalidIndexDonations(uint256 _index);

    function initialize(
        address _tokenAddress,
        address _rewardsPool,
        address _yieldBox,
        address _yieldKey,
        address _stakedYieldKeyLeg,
        address _stakedYieldKeyReg,
        address _mainFee
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        tokenAddress = _tokenAddress;
        rewardsPool = _rewardsPool;
        YieldBox = IYieldBox(_yieldBox);
        YieldKey = IYieldKey(_yieldKey);
        StakedYieldKeyLeg = IStakedYieldKey(_stakedYieldKeyLeg);
        StakedYieldKeyReg = IStakedYieldKey(_stakedYieldKeyReg);
        MaintFee = IMaintFee(_mainFee);
        LIMITS_DAYS = 432000 minutes;
        MINIMAL_REWARDS_DAYS = 86400 minutes;
        pauseRewards = true;
        ADD_PERCENTAGE_FOR_COMPOUND = 10;
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pause(bool status) public onlyOwner {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @dev Implementation / Instance of paused methods() in the ERC721.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC721Pausable}.
     */
    function pauseReward(bool status) public onlyOwner {
        if (status) {
            pauseRewards = true;
        } else {
            pauseRewards = false;
        }
    }

    /**
     * @dev Calculate Pre-reward per YieldKey
     * @param _wallet Wallet of YieldKey holder
     * @param _yieldKey YieldKey of YieldBox
     * @param _type Type of YieldKey
     */
    function preRewardPerYK(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    )
        public
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        )
    {
        require(!pauseRewards, "The rewards are paused");
        uint256[] memory YieldBoxIds = YieldBox.activeYieldBoxes(_wallet);
        require(YieldBoxIds.length > 0, "No YieldBox currently with rewards");
        require(
            (VaLiFiHelpers.OwnerIsStaked(_wallet, _yieldKey, _type) &&
                (MaintFee.yieldBoxYieldKeyLeg(_yieldKey).length > 0 ||
                    MaintFee.yieldBoxYieldKeyReg(_yieldKey).length > 0)),
            "YieldKey is not associated to YieldBoxes"
        );
        return VaLiFiHelpers.calculateRewardPerYK(_wallet, _yieldKey, _type);
    }

    /**
     * @dev Calculate Pre-minimal rewards per YieldBox
     * @param wallet Wallet of owner of YieldBox
     * @param YieldBoxIds Array of YieldBox Ids
     */
    function preMinimalRewards(address wallet, uint256[] memory YieldBoxIds)
        public
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        )
    {
        require(!pauseRewards, "The rewards are paused");
        return VaLiFiHelpers.calculateMinimalRewards(wallet, YieldBoxIds);
    }

    /**
     * @dev Get total rewards taking into account YieldBoxes with and without associated YieldKeys
     * @param wallet Wallet of YieldBox/YieldKey holder
     */

    function getTotalRewards(address wallet)
        public
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _rewarded,
            uint256[] memory _yieldBoxRewarded,
            uint256[] memory _yieldKey,
            uint256 _time
        )
    {
        require(!pauseRewards, "The rewards are paused");
        return VaLiFiHelpers.TotalRewards(wallet);
    }

    /**
     * @dev Used to calculate and claim rewards for the caller
     * @param _yieldKey Array of YieldKeys
     * @param _type Array of YieldKey types
     * @param _indexDonations Indix of the donations Mapping Address
     * @param _percentageDonations Percentage of the donations
     */
    function rewardPerYK(
        uint256[] memory _yieldKey,
        uint8[] memory _type,
        uint256 _indexDonations,
        uint256 _percentageDonations
    ) external whenNotPaused nonReentrant {
        if (_percentageDonations > 100)
            revert InvalidPercentage(_percentageDonations);
        if (donations[_indexDonations] == address(0))
            revert InvalidIndexDonations(_indexDonations);
        for (uint256 i = 0; i < _yieldKey.length; i++) {
            (
                uint256[] memory amount,
                uint256[] memory rewarded,
                uint256[] memory YieldBoxRewarded,
                uint256 time
            ) = preRewardPerYK(_msgSender(), _yieldKey[i], _type[i]);
            uint256 total;
            for (uint256 j = 0; j < amount.length; j++) {
                total += amount[j];
            }
            IERC20Upgradeable _token = IERC20Upgradeable(tokenAddress);
            require(
                _token.balanceOf(rewardsPool) >= total,
                "Not enough ValiFi tokens in pool"
            );
            if (_percentageDonations > 0) {
                bool success_treasury = _token.transferFrom(
                    rewardsPool,
                    donations[_indexDonations],
                    mulDiv(total.mul(_percentageDonations), 1, 100)
                );
                require(success_treasury, "Rewards Donations failed");
                success_treasury = _token.transferFrom(
                    rewardsPool,
                    _msgSender(),
                    mulDiv(
                        total.mul(uint256(100).sub(_percentageDonations)),
                        1,
                        100
                    )
                );
                require(success_treasury, "Rewards claim failed");
            } else {
                bool success_treasury = _token.transferFrom(
                    rewardsPool,
                    _msgSender(),
                    total
                );
                require(success_treasury, "Rewards claim failed");
            }
            for (uint256 j = 0; j < YieldBoxRewarded.length; j++) {
                if (amount[j] > 0) {
                    emit RewardsPaid(
                        _msgSender(),
                        YieldBoxRewarded[j],
                        rewarded[j],
                        amount[j]
                    );
                    RewardsClaimed[YieldBoxRewarded[j]]
                        .freeDaysClaimed = MINIMAL_REWARDS_DAYS.div(1 minutes);
                    RewardsClaimed[YieldBoxRewarded[j]].claimedDays += rewarded[
                        j
                    ];
                    if (
                        (RewardsClaimed[YieldBoxRewarded[j]].claimedDays >=
                            LIMITS_DAYS.div(1 minutes))
                    ) {
                        YieldBox.setRewardClaimed(
                            false,
                            true,
                            YieldBoxRewarded[j]
                        );
                    } else {
                        YieldBox.setRewardClaimed(
                            true,
                            false,
                            YieldBoxRewarded[j]
                        );
                    }
                }
            }
        }
    }

    /**
     * @dev Used to calculate and claim the minimal rewards for the caller
     * @param _wallet Wallet holder of the YieldBoxes (without associated YieldKeys)
     * @param _YieldBoxIds YieldBox Ids owned (without associated YieldKeys)
     * @param _indexDonations Indix of the donations Mapping Address
     * @param _percentageDonations Percentage of the donations
     */
    function minimalRewardPerYB(
        address _wallet,
        uint256[] memory _YieldBoxIds,
        uint256 _indexDonations,
        uint256 _percentageDonations
    ) external whenNotPaused nonReentrant {
        if (_percentageDonations > 100)
            revert InvalidPercentage(_percentageDonations);
        if (donations[_indexDonations] == address(0))
            revert InvalidIndexDonations(_indexDonations);
        (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        ) = preMinimalRewards(_wallet, _YieldBoxIds);
        uint256 total;
        for (uint256 i = 0; i < amount.length; i++) {
            total += amount[i];
        }
        IERC20Upgradeable _token = IERC20Upgradeable(tokenAddress);
        require(
            _token.balanceOf(rewardsPool) >= total,
            "Not enough ValiFi tokens in pool"
        );
        if (_percentageDonations > 0) {
            bool success_treasury = _token.transferFrom(
                rewardsPool,
                donations[_indexDonations],
                mulDiv(total.mul(_percentageDonations), 1, 100)
            );
            require(success_treasury, "Rewards Donations failed");
            success_treasury = _token.transferFrom(
                rewardsPool,
                _msgSender(),
                mulDiv(
                    total.mul(uint256(100).sub(_percentageDonations)),
                    1,
                    100
                )
            );
            require(success_treasury, "Rewards claim failed");
        } else {
            bool success_treasury = _token.transferFrom(
                rewardsPool,
                _msgSender(),
                total
            );
            require(success_treasury, "Rewards claim failed");
        }
        for (uint256 i = 0; i < YieldBoxRewarded.length; i++) {
            if (amount[i] > 0) {
                emit RewardsPaid(
                    _msgSender(),
                    YieldBoxRewarded[i],
                    rewarded[i],
                    amount[i]
                );
                if (
                    RewardsClaimed[YieldBoxRewarded[i]].freeDaysClaimed >=
                    MINIMAL_REWARDS_DAYS
                ) {
                    RewardsClaimed[YieldBoxRewarded[i]]
                        .freeDaysClaimed = MINIMAL_REWARDS_DAYS;
                } else {
                    RewardsClaimed[YieldBoxRewarded[i]]
                        .freeDaysClaimed += rewarded[i];
                }
            }
        }
    }

    /**
     * @dev Used to calculate and claim rewards for the caller
     * @param _wallet Wallet holder of All YieldBoxes with or without associated YieldKeys
     * @param _indexDonations Indix of the donations Mapping Address
     * @param _percentageDonations Percentage of the donations
     */
    function claimAllRewards(
        address _wallet,
        uint256 _indexDonations,
        uint256 _percentageDonations
    ) external whenNotPaused nonReentrant {
        if (_percentageDonations > 100)
            revert InvalidPercentage(_percentageDonations);
        if (donations[_indexDonations] == address(0))
            revert InvalidIndexDonations(_indexDonations);
        (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256[] memory yieldKey,
            uint256 time
        ) = getTotalRewards(_wallet);
        uint256 total;
        for (uint256 j = 0; j < amount.length; j++) {
            total += amount[j];
        }
        IERC20Upgradeable _token = IERC20Upgradeable(tokenAddress);
        require(
            _token.balanceOf(rewardsPool) >= total,
            "Not enough ValiFi tokens in pool"
        );
        if (_percentageDonations > 0) {
            bool success_treasury = _token.transferFrom(
                rewardsPool,
                donations[_indexDonations],
                mulDiv(total.mul(_percentageDonations), 1, 100)
            );
            require(success_treasury, "Rewards Donations failed");
            success_treasury = _token.transferFrom(
                rewardsPool,
                _msgSender(),
                mulDiv(
                    total.mul(uint256(100).sub(_percentageDonations)),
                    1,
                    100
                )
            );
            require(success_treasury, "Rewards claim failed");
        } else {
            bool success_treasury = _token.transferFrom(
                rewardsPool,
                _msgSender(),
                total
            );
            require(success_treasury, "Rewards claim failed");
        }
        for (uint256 j = 0; j < YieldBoxRewarded.length; j++) {
            if (amount[j] > 0) {
                emit RewardsPaid(
                    _msgSender(),
                    YieldBoxRewarded[j],
                    rewarded[j],
                    amount[j]
                );
                if (yieldKey[j] == 0) {
                    RewardsClaimed[YieldBoxRewarded[j]]
                        .freeDaysClaimed = MINIMAL_REWARDS_DAYS.div(1 minutes);
                    RewardsClaimed[YieldBoxRewarded[j]].claimedDays += rewarded[
                        j
                    ];
                    if (
                        (RewardsClaimed[YieldBoxRewarded[j]].claimedDays >=
                            LIMITS_DAYS.div(1 minutes))
                    ) {
                        YieldBox.setRewardClaimed(
                            false,
                            true,
                            YieldBoxRewarded[j]
                        );
                    } else {
                        YieldBox.setRewardClaimed(
                            true,
                            false,
                            YieldBoxRewarded[j]
                        );
                    }
                } else {
                    RewardsClaimed[YieldBoxRewarded[j]]
                        .freeDaysClaimed = MINIMAL_REWARDS_DAYS.div(1 minutes);
                    RewardsClaimed[YieldBoxRewarded[j]].claimedDays += rewarded[
                        j
                    ];
                    if (
                        (RewardsClaimed[YieldBoxRewarded[j]].claimedDays >=
                            LIMITS_DAYS.div(1 minutes))
                    ) {
                        YieldBox.setRewardClaimed(
                            false,
                            true,
                            YieldBoxRewarded[j]
                        );
                    } else {
                        YieldBox.setRewardClaimed(
                            true,
                            false,
                            YieldBoxRewarded[j]
                        );
                    }
                }
            }
        }
    }

    /**
     * @dev Compound of Yield Box based on VALI Tokens of Rewards pending to claim
     * @dev connecting with TraderJob for getting the USDC
     * @param _wallet Wallet of YieldBox/YieldKey holder
     */
    function compoundOfRewards(address _wallet)
        external
        whenNotPaused
        nonReentrant
    {
        (
            bool status,
            uint256 totalAmount,
            uint256 compoundAmount
        ) = VaLiFiHelpers.CompoundOfRewardsParameters(_wallet);
        require(
            _msgSender() == _wallet,
            "Only the Owner can compound of rewards"
        );
        if (!status) revert EnoughRewardsForCompound(_wallet, totalAmount);
        IERC20MetadataUpgradeable _token = IERC20MetadataUpgradeable(
            YieldBox.tokenAddress()
        );
        IERC20MetadataUpgradeable _usdc = IERC20MetadataUpgradeable(
            YieldBox.usdcAddress()
        );
        // Update Storage of Minutes Claimed
        _updateClaimedRewards(_wallet, totalAmount, compoundAmount);
        bool success = _token.transferFrom(
            rewardsPool,
            address(this),
            compoundAmount
        );
        require(success, "Rewards claim failed");
        // Portion VALI Token in USDC
        (uint256 Sval, uint256 Vval) = YieldBox.getSvalVval();
        uint256 VaLiPerYB = mulDiv(Sval, 1 ether, 100);
        // Additional Portion based on `ADD_PERCENTAGE_FOR_COMPOUND` percentage of VALI Token in USDC to create a YieldBox
        uint256 SwapVaLiPerYB = VaLiPerYB.add(
            mulDiv(VaLiPerYB, 1, ADD_PERCENTAGE_FOR_COMPOUND)
        );
        // Approve the Router for Transfer of VALI Token to Swap USDC
        _token.approve(address(router), SwapVaLiPerYB);
        // Transfer the VALI Token to Swap USDC
        _swapTokensForTokens(SwapVaLiPerYB);
        // Approve The YieldBox for Transfer of USDC to YieldBox Contract
        _usdc.approve(address(YieldBox), _usdc.balanceOf(address(this)));
        // Approve The YieldBox for Transfer of VALI Token to YieldBox Contract
        _token.approve(address(YieldBox), mulDiv(Vval, 1 ether, 100));
        // Create YieldBox
        YieldBox.create(_wallet, YieldBox.usdcAddress());
        // roll back VALI Tokens to the User
        success = _token.transfer(_wallet, _token.balanceOf(address(this)));
        require(success, "Refund VaLiFi claimed failed");
        // roll back USDC Tokens to the User
        success = _usdc.transfer(_wallet, _usdc.balanceOf(address(this)));
        require(success, "Refund USDC claimed failed");
    }

    function isCompoundOfRewards(address _wallet)
        public
        view
        returns (bool response)
    {
        (response, , ) = VaLiFiHelpers.CompoundOfRewardsParameters(_wallet);
    }

    /// @dev Private Method to Swap ERC20 Token WhiteListed in the Issuance Process
    /// @dev and Getting the USDC Equivalent Price of the Token WhiteListed in the Issuance Process
    /// @param _tokenAmount Amount of ERC20Token Swapped top USDC in UniSwapV2 Router
    function _swapTokensForTokens(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(YieldBox.tokenAddress());
        path[1] = address(YieldBox.usdcAddress());
        /// make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tokenAmount,
            1,
            path,
            address(this),
            block.timestamp
        );
    }

    function _updateClaimedRewards(
        address _wallet,
        uint256 _totalAmount,
        uint256 _compoundAmount
    ) private returns (uint256) {
        (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256[] memory yieldKey,

        ) = getTotalRewards(_wallet);
        uint256 totalAmount;
        for (uint256 i = 0; i < amount.length; i++) {
            totalAmount += amount[i];
        }
        if (totalAmount != _totalAmount)
            revert TotalRewardsInconsistence(
                _wallet,
                _totalAmount,
                totalAmount
            );
        if (totalAmount < _compoundAmount)
            revert EnoughRewardsForCompound(_wallet, totalAmount);
        uint256 totalCompoundAmount = _compoundAmount;
        for (
            uint256 i = 0;
            i < amount.length && totalCompoundAmount != 0;
            i++
        ) {
            if ((YieldBoxRewarded[i] != 0) && (yieldKey[i] != 0)) {
                if (rewarded[i].mul(REWARDS_PER_DAYS) > totalCompoundAmount) {
                    for (uint256 j = 0; j < rewarded[i]; j++) {
                        if (j.mul(REWARDS_PER_DAYS) >= totalCompoundAmount) {
                            RewardsClaimed[YieldBoxRewarded[i]]
                                .claimedDays += 1;
                            totalCompoundAmount = 0;
                            break;
                        } else {
                            RewardsClaimed[YieldBoxRewarded[i]]
                                .claimedDays += 1;
                            totalCompoundAmount -= REWARDS_PER_DAYS;
                        }
                    }
                } else {
                    RewardsClaimed[YieldBoxRewarded[i]].claimedDays += rewarded[
                        i
                    ];
                    totalCompoundAmount -= rewarded[i].mul(REWARDS_PER_DAYS);
                }
            } else {
                if (
                    rewarded[i].mul(MINIMAL_REWARDS_DAYS) > totalCompoundAmount
                ) {
                    for (uint256 k = 0; k < rewarded[i]; k++) {
                        if (
                            k.mul(MINIMAL_REWARDS_DAYS) >= totalCompoundAmount
                        ) {
                            RewardsClaimed[YieldBoxRewarded[i]]
                                .freeDaysClaimed += 1;
                            totalCompoundAmount = 0;
                            break;
                        } else {
                            RewardsClaimed[YieldBoxRewarded[i]]
                                .freeDaysClaimed += 1;
                            totalCompoundAmount -= MINIMAL_REWARDS_DAYS;
                        }
                    }
                } else {
                    RewardsClaimed[YieldBoxRewarded[i]]
                        .freeDaysClaimed += rewarded[i];
                    totalCompoundAmount -= rewarded[i].mul(
                        MINIMAL_REWARDS_DAYS
                    );
                }
            }
        }
    }

    /**
     * @dev Allows to set the main variables such as REWARDS_PER_DAYS, MINIMAL_REWARDS, LIMITS_DAYS, MINIMAL_REWARDS_DAYS
     * @param _value Array value of REWARDS_PER_DAYS, MINIMAL_REWARDS, LIMITS_DAYS, MINIMAL_REWARDS_DAYS
     */
    function setValue(uint256[5] memory _value) external onlyOwner {
        require(
            _value[0] > 0 &&
                _value[1] >= 0 &&
                _value[2] >= 30 &&
                _value[3] >= 0 &&
                _value[4] >= 0,
            "Can't set values: incorrect parameter values"
        );
        uint256 oldValue = REWARDS_PER_DAYS;
        REWARDS_PER_DAYS = _value[0];
        MINIMAL_REWARDS = uint8(_value[1]);
        LIMITS_DAYS = _value[2] * 24 * 60 minutes;
        MINIMAL_REWARDS_DAYS = _value[3] * 24 * 60 minutes;
        ADD_PERCENTAGE_FOR_COMPOUND = _value[4];
        emit SetRewardPerYieldBox(oldValue, _value[0]);
    }

    /**
     * @dev Allows to set the Rewards Pool wallet address
     * @param _rewardsPool Rewards Pool address
     */
    function setRewardsPool(address _rewardsPool)
        external
        validAddress(_rewardsPool)
        onlyOwner
    {
        rewardsPool = _rewardsPool;
        emit SetRewardsPool(_rewardsPool);
    }

    /**
     * @dev Allows to set the VaLiFi Helpers Contract Address
     * @param VaLiFiHelpers_ VaLiFi Helpers Contract Address
     */
    function setVaLiFiHelpers(address VaLiFiHelpers_)
        external
        validAddress(VaLiFiHelpers_)
        onlyOwner
    {
        VaLiFiHelpers = IVaLiFiHelpers(VaLiFiHelpers_);
    }

    /**
     * @dev Method to Setting Set Router Address for Swapping VALI to USDC
     * @param _address Router Address
     */
    function setRouterAddress(address _address) external onlyOwner {
        router = IRouter(_address);
    }

    /**
     * @dev Method to Setting Donations Address
     * @param _index Index of Donations Mapping
     * @param _address address where to donate the money
     */
    function setDonationsAddress(uint256 _index, address _address)
        external
        validAddress(_address)
        onlyOwner
    {
        donations[_index] = _address;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./Blacklistable.sol";

/**
 * @title Claimable Methods
 * @dev Implementation of the claiming utils that can be useful for withdrawing accidentally sent tokens that are not used in bridge operations.
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Claimable is OwnableUpgradeable, Blacklistable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // Event when the Smart Contract receive Amount of Native or ERC20 tokens
    /**
     * @dev Event when the Smart Contract receive Amount of Native or ERC20 tokens
     * @param sender The address of the sender
     * @param value The amount of tokens
     */
    event ValueReceived(address indexed sender, uint256 indexed value);
    /**
     * @dev Event when the Smart Contract Send Amount of Native or ERC20 tokens
     * @param receiver The address of the receiver
     * @param value The amount of tokens
     */
    event ValueSent(address indexed receiver, uint256 indexed value);

    /// @notice Handle receive ether
    receive() external payable {
        emit ValueReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Withdraws the erc20 tokens or native coins from this contract.
     * Caller should additionally check that the claimed token is not a part of bridge operations (i.e. that token != erc20token()).
     * @param _token address of the claimed token or address(0) for native coins.
     * @param _to address of the tokens/coins receiver.
     */
    function claimValues(address _token, address _to)
        public
        validAddress(_to)
        notBlacklisted(_to)
        onlyOwner
    {
        if (_token == address(0)) {
            _claimNativeCoins(_to);
        } else {
            _claimErc20Tokens(_token, _to);
        }
    }

    /**
     * @dev Internal function for withdrawing all native coins from the contract.
     * @param _to address of the coins receiver.
     */
    function _claimNativeCoins(address _to) private {
        uint256 amount = address(this).balance;

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = _to.call{value: amount}("");
        require(
            success,
            "ERC20: Address: unable to send value, recipient may have reverted"
        );
        // Event when the Smart Contract Send Amount of Native or ERC20 tokens
        emit ValueSent(_to, amount);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC20 contract from this contract.
     * @param _token address of the claimed ERC20 token.
     * @param _to address of the tokens receiver.
     */
    function _claimErc20Tokens(address _token, address _to) private {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc721Tokens(address _token, address _to)
        public
        validAddress(_to)
        notBlacklisted(_to)
        onlyOwner
    {
        IERC721Upgradeable token = IERC721Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this));
        token.safeTransferFrom(address(this), _to, balance);
    }

    /**
     * @dev Internal function for withdrawing all tokens of some particular ERC721 contract from this contract.
     * @param _token address of the claimed ERC721 token.
     * @param _to address of the tokens receiver.
     */
    function claimErc1155Tokens(
        address _token,
        address _to,
        uint256 _id
    ) public validAddress(_to) notBlacklisted(_to) onlyOwner {
        IERC1155Upgradeable token = IERC1155Upgradeable(_token);
        uint256 balance = token.balanceOf(address(this), _id);
        bytes memory data = "0x00";
        token.safeTransferFrom(address(this), _to, _id, balance, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";


/**
 * @title Math Library
 * @dev Allows handle 512-bit multiply, RoundingUp
 * @custom:a Alfredo Lopez / Marketingcycle / ValiFI
 */
contract Math {
    using SafeMathUpgradeable for uint256;

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = MathUpgradeable.mulDiv(a, b, denominator);
    }

    // function sort_item(uint256 pos, uint256[] memory _array)
    //     internal
    //     pure
    //     returns (uint256 w_min)
    // {
    //     w_min = pos;
    //     for (uint256 i = pos; i < _array.length; i++) {
    //         if (_array[i] < _array[w_min]) {
    //             w_min = i;
    //         }
    //     }
    // }

    // /**
    //  * @dev Sort the array
    //  */
    // function ordered(uint256[] memory _array)
    //     internal
    //     pure
    //     returns (uint256[] memory)
    // {
    //     for (uint256 i = 0; i < _array.length; i++) {
    //         uint256 w_min = sort_item(i, _array);
    //         if (w_min == i) continue;
    //         uint256 tmp = _array[i];
    //         _array[i] = _array[w_min];
    //         _array[w_min] = tmp;
    //     }
    //     return _array;
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

// IYieldKey private constant YieldKey =
// 		// IYieldKey(address(0xD3b35ea829C9FF6e2b8506886ea36f0Ac1A30f7e)); // Testnet
// 		IYieldKey(address(0xFEFeDa5DD1ECe04dECE30CEa027177459F4F53DA)); // Local Testnet
// IYieldBox private constant YieldBox =
// 		// IYieldBox(address(0x57f94693Ae1542AEe6373dd38dD545BfaBD2E91e)); // Testnet
// 		IYieldBox(address(0x7598b1dB111726E5487e850340780Aa1321879eB)); // Local Testnet
// IStakedYieldKey private constant StakedYieldKeyLeg =
// 		// IStakedYieldKey(address(0xB9acF127d5Bb7f79e08930Fd1915B3Aa7c476aDd)); // Testnet
// 		IStakedYieldKey(address(0xA317c14B395755f72E98784523688C396d45BFAb)); // Local Testnet
// IStakedYieldKey private constant StakedYieldKeyReg =
// 		// IStakedYieldKey(address(0xD3b35ea829C9FF6e2b8506886ea36f0Ac1A30f7e)); // Testnet
// 		IStakedYieldKey(address(0x8cf902568A347540eB4b5ef734BB105484a5eEd2)); // Local Testnet
// IMaintFee private constant MaintFee =
// 		// IMaintFee(address(0x3975df9b2bda7ece95Ed7ebb809495c9640a7a00)); // Testnet
// 		IMaintFee(address(0x473B87E5Bb1f66F2Fa16687c07E17DF2c75eC452)); // Local Testnet
// IRewards private constant Rewards =
// 		// IRewards(address(0x4C3cc44ba18070d7e631884f11de8737c431554a)); // Testnet
// 		IRewards(address(0x82d5ff68697d0d389c527b5C8D764a6201E096e5)); // Local Testnet

/** @dev Interface of Maintenance Fee */
interface IMaintFee {
    /**
     * @dev Struct of the YieldBox
     */
    struct MainFeeStruct {
        /** @dev Maintenance fee status */
        bool status;
        /** @dev Maintenance fee owner */
        address lastOwner;
        /** @dev First day maintenance fee */
        uint64 firstDay;
        /** @dev Fee due Date */
        uint64 feeDue;
        /** @dev Unclaimed Days */
        uint256 unClaimedDays;
        /** @dev YieldKey Token Id */
        uint256 yieldKey;
        /** @dev Type of YieldKey */
        uint8 yieldKeyType; // Types: 4,6,8 and 12
    }

    /**@dev Maintenance fee details by Token Id */
    function maintFee(uint256 _tokenId)
        external
        view
        returns (MainFeeStruct memory);

    /** @dev get array of YieldBoxes per Legendary YieldKey */
    function yieldBoxYieldKeyLeg(uint256 _yieldKey)
        external
        view
        returns (uint256[] memory);

    /** @dev get array of YieldBoxes per Regular YieldKey */
    function yieldBoxYieldKeyReg(uint256 _yieldKey)
        external
        view
        returns (uint256[] memory);
}

/** @dev Interface of Legendary YieldKey */
interface IValiFiNFT is IERC721Upgradeable {
    function tokenHoldings(address _owner)
        external
        view
        returns (uint256[] memory);
}

interface IStakedYieldKey is IValiFiNFT {
    /**
     * @dev Struct of Staked YieldKeys
     */
    struct StakeYieldKey {
        bool isStaked;
        uint64[] startstake;
        uint64[] endstake;
    }

    function isStaked(address wallet, uint256 _tokenId)
        external
        view
        returns (bool);

    function getStakedYieldKeyHistory(address wallet, uint256 _tokenId)
        external
        view
        returns (uint64[] memory startstake, uint64[] memory endstake);

    function tokenStaking(address _owner)
        external
        view
        returns (uint256[] memory stakeTokenIds);
}

/** @dev Interface of YieldBox */
interface IYieldBox is IValiFiNFT {
    /**
     * @dev Struct of the YieldBox
     */
    struct YieldBoxStruct {
        /** @dev YieldBox Status */
        bool status;
        /** @dev Dead YieldBox Token */
        bool dead;
        /** @dev Time of Last Claim */
        uint64 rewardClaimed;
        /** @dev YieldBox Owner */
        address owner;
        /** @dev YieldBox Token ID */
        uint256 id;
        /** @dev Time of Creation */
        uint256 createdAt;
    }

    function yieldBox(uint256 _tokenIDs)
        external
        view
        returns (YieldBoxStruct memory);

    function activeYieldBoxes(address _wallet)
        external
        view
        returns (uint256[] memory rewardedTokenIds);

    function setRewardClaimed(
        bool status,
        bool dead,
        uint256 tokenId
    ) external;

    function totalSupply() external view returns (uint256);

    function tokenAddress() external view returns (address);

    function usdcAddress() external view returns (address);

    function getVaLiFiPriceinStable() external view returns (uint256 price);

    function getSvalVval() external view returns (uint256 sval, uint256 vval);

    function create(address _wallet, address _token) external;
}

/** @dev Interface of Regular YieldKey */
interface IYieldKey is IValiFiNFT {
    function capacityAmount(uint256 tokenId) external view returns (uint256);
}

/** @dev Interface of Rewards Smart Contract */
interface IRewards {
    struct RewardStruct {
        /** @dev First day maintenance fee */
        uint64 firstDay; // must be change Last Claim
        /** @dev Days of rewards claimed */
        uint256 claimedDays;
        /** @dev Days of minimal rewards (free) claimed */
        uint256 freeDaysClaimed;
    }

    function RewardsClaimed(uint256 _yieldBoxId)
        external
        view
        returns (RewardStruct memory);

    function preRewardPerYK(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function preMinimalRewards(address wallet, uint256[] memory YieldBoxIds)
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function getTotalRewards(address wallet)
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _rewarded,
            uint256[] memory _yieldBoxRewarded,
            uint256[] memory _yieldKey,
            uint256 time
        );

    function MINIMAL_REWARDS_DAYS() external pure returns (uint256);

    function MINIMAL_REWARDS() external pure returns (uint256);

    function LIMITS_DAYS() external pure returns (uint256);

    function REWARDS_PER_DAYS() external pure returns (uint256);

    function ADD_PERCENTAGE_FOR_COMPOUND() external pure returns (uint256);
}

/** @dev Interface of Router Smart Contract */
interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IVaLiFiHelpers {
    function TotalRewards(address wallet)
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _rewarded,
            uint256[] memory _yieldBoxRewarded,
            uint256[] memory _yieldKey,
            uint256 time
        );

    function OwnerIsStaked(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    ) external view returns (bool);

    /** @dev get array of YieldBoxes without associated YieldKeys */
    function getYieldBoxWithoutYieldKey(address _walletAddress)
        external
        view
        returns (uint256[] memory);

    function getYieldBoxAttached(
        uint256 _yieldKey,
        uint8 _type,
        uint256[] memory _tokenIds
    ) external view returns (uint256 attachYB);

    function isYieldBoxInArray(
        uint256 _tokenId,
        uint256[] memory _yieldKeyArray
    ) external pure returns (bool);

    function getAvailableSlots(uint256 _yieldKey, uint8 _type)
        external
        view
        returns (uint256 result);

    function CompoundOfRewardsParameters(address _wallet)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function calculateMinimalRewards(
        address wallet,
        uint256[] memory YieldBoxIds
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function calculateRewardPerYK(
        address _wallet,
        uint256 _yieldKey,
        uint8 _type
    )
        external
        view
        returns (
            uint256[] memory amount,
            uint256[] memory rewarded,
            uint256[] memory YieldBoxRewarded,
            uint256 time
        );

    function getTotalDays(
        uint256[] calldata _tokenIds,
        uint256[] calldata _paidDays
    ) external pure returns (uint256 totalDays);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Blacklistable Methods
 * @dev Allows accounts to be blacklisted by Owner
 */
contract Blacklistable is OwnableUpgradeable {
    // Index Address
    address[] private wallets;
    // Mapping of blacklisted Addresses
    mapping(address => bool) private blacklisted;
    // Events when wallets are added or dropped from the blacklisted mapping
    event InBlacklisted(address indexed _account);
    event OutBlacklisted(address indexed _account);

    /**
     * @dev Reverts if account is blacklisted
     * @param _account The address to check
     */
    modifier notBlacklisted(address _account) {
        require(
            !blacklisted[_account],
            "ERC721 ValiFi: sender account is blacklisted"
        );
        _;
    }

    /**
     * @dev Reverts if a given address is equal to address(0)
     * @param _to The address to check
     */
    modifier validAddress(address _to) {
        require(_to != address(0), "ERC721 ValiFi: Zero Address not allowed");
        /* solcov ignore next */
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param _account The address to check
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    /**
     * @dev Adds account to blacklist
     * @param _account The address to blacklist
     */
    function addBlacklist(address _account)
        public
        validAddress(_account)
        notBlacklisted(_account)
        onlyOwner
    {
        blacklisted[_account] = true;
        wallets.push(_account);
        emit InBlacklisted(_account);
    }

    /**
     * @dev Removes account from blacklist
     * @param _account The address to remove from the blacklist
     */
    function dropBlacklist(address _account)
        public
        validAddress(_account)
        onlyOwner
    {
        require(
            isBlacklisted(_account),
            "ERC721 ValiFi: Wallet not present in blacklist"
        );
        blacklisted[_account] = false;
        emit OutBlacklisted(_account);
    }

    /**
     * @dev Retrieve the list of Blacklisted Addresses
     */
    function getBlacklist() public view returns (address[] memory) {
        return wallets;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}