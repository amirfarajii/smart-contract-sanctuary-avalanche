// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import "./interfaces/IBaseLaunchpeg.sol";
import "./interfaces/IBaseLaunchpegV1.sol";
import "./interfaces/IBatchReveal.sol";
import "./interfaces/IFlatLaunchpeg.sol";
import "./interfaces/ILaunchpeg.sol";
import "./interfaces/ILaunchpegFactory.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

error LaunchpegLens__InvalidContract();
error LaunchpegLens__InvalidLaunchpegType();
error LaunchpegLens__InvalidLaunchpegVersion();

/// @title Launchpeg Lens
/// @author Trader Joe
/// @notice Helper contract to fetch launchpegs data
contract LaunchpegLens {
    struct CollectionData {
        string name;
        string symbol;
        uint256 collectionSize;
        uint256 maxPerAddressDuringMint;
        uint256 totalSupply;
        string unrevealedURI;
        string baseURI;
    }

    struct LaunchpegData {
        ILaunchpeg.Phase currentPhase;
        uint256 amountForAuction;
        uint256 amountForAllowlist;
        uint256 amountForDevs;
        uint256 auctionSaleStartTime;
        uint256 preMintStartTime;
        uint256 allowlistStartTime;
        uint256 publicSaleStartTime;
        uint256 publicSaleEndTime;
        uint256 auctionStartPrice;
        uint256 auctionEndPrice;
        uint256 auctionSaleDuration;
        uint256 auctionDropInterval;
        uint256 auctionDropPerStep;
        uint256 allowlistDiscountPercent;
        uint256 publicSaleDiscountPercent;
        uint256 auctionPrice;
        uint256 allowlistPrice;
        uint256 publicSalePrice;
        uint256 lastAuctionPrice;
        uint256 amountMintedDuringAuction;
        uint256 amountMintedDuringPreMint;
        uint256 amountMintedDuringAllowlist;
        uint256 amountMintedDuringPublicSale;
    }

    struct FlatLaunchpegData {
        ILaunchpeg.Phase currentPhase;
        uint256 amountForAllowlist;
        uint256 amountForDevs;
        uint256 preMintStartTime;
        uint256 allowlistStartTime;
        uint256 publicSaleStartTime;
        uint256 publicSaleEndTime;
        uint256 allowlistPrice;
        uint256 salePrice;
        uint256 amountMintedDuringPreMint;
        uint256 amountMintedDuringAllowlist;
        uint256 amountMintedDuringPublicSale;
    }

    struct RevealData {
        uint256 revealBatchSize;
        uint256 lastTokenRevealed;
        uint256 revealStartTime;
        uint256 revealInterval;
    }

    struct UserData {
        uint256 balanceOf;
        uint256 numberMinted;
        uint256 numberMintedWithPreMint;
        uint256 allowanceForAllowlistMint;
    }

    struct ProjectOwnerData {
        address[] projectOwners;
        uint256 amountMintedByDevs;
        uint256 withdrawAVAXStartTime;
        uint256 launchpegBalanceAVAX;
    }

    /// Global struct that is returned by getAllLaunchpegs()
    struct LensData {
        address id;
        LaunchpegType launchType;
        CollectionData collectionData;
        LaunchpegData launchpegData;
        FlatLaunchpegData flatLaunchpegData;
        RevealData revealData;
        UserData userData;
        ProjectOwnerData projectOwnerData;
    }

    enum LaunchpegType {
        Unknown,
        Launchpeg,
        FlatLaunchpeg
    }

    enum LaunchpegVersion {
        Unknown,
        V1,
        V2
    }

    /// @notice LaunchpegFactory V1
    ILaunchpegFactory public immutable launchpegFactoryV1;

    /// @notice LaunchpegFactory V2
    ILaunchpegFactory public immutable launchpegFactoryV2;

    /// @notice BatchReveal address
    address public immutable batchReveal;

    /// @dev LaunchpegLens constructor
    /// @param _launchpegFactoryV1 LaunchpegFactory V1
    /// @param _launchpegFactoryV2 LaunchpegFactory V2
    /// @param _batchReveal BatchReveal address
    constructor(
        ILaunchpegFactory _launchpegFactoryV1,
        ILaunchpegFactory _launchpegFactoryV2,
        address _batchReveal
    ) {
        launchpegFactoryV1 = _launchpegFactoryV1;
        launchpegFactoryV2 = _launchpegFactoryV2;
        batchReveal = _batchReveal;
    }

    /// @notice Gets the type and version of Launchpeg
    /// @param _contract Contract address to consider
    /// @return LaunchpegType Type of Launchpeg implementation (Dutch Auction / Flat / Unknown)
    function getLaunchpegType(address _contract)
        public
        view
        returns (LaunchpegType, LaunchpegVersion)
    {
        if (launchpegFactoryV1.isLaunchpeg(0, _contract)) {
            return (LaunchpegType.Launchpeg, LaunchpegVersion.V1);
        } else if (launchpegFactoryV2.isLaunchpeg(0, _contract)) {
            return (LaunchpegType.Launchpeg, LaunchpegVersion.V2);
        } else if (launchpegFactoryV1.isLaunchpeg(1, _contract)) {
            return (LaunchpegType.FlatLaunchpeg, LaunchpegVersion.V1);
        } else if (launchpegFactoryV2.isLaunchpeg(1, _contract)) {
            return (LaunchpegType.FlatLaunchpeg, LaunchpegVersion.V2);
        } else {
            return (LaunchpegType.Unknown, LaunchpegVersion.Unknown);
        }
    }

    /// @notice Fetch Launchpeg data by type and version
    /// @param _type Type of Launchpeg to consider
    /// @param _version Launchpeg version
    /// @param _number Number of Launchpeg to fetch
    /// @param _limit Last Launchpeg index to fetch
    /// @param _user Address to consider for NFT balances and allowlist allocations
    /// @return LensDataList List of contracts datas, in descending order
    function getLaunchpegsByTypeAndVersion(
        LaunchpegType _type,
        LaunchpegVersion _version,
        uint256 _number,
        uint256 _limit,
        address _user
    ) external view returns (LensData[] memory) {
        if (_type == LaunchpegType.Unknown) {
            revert LaunchpegLens__InvalidLaunchpegType();
        }
        if (_version == LaunchpegVersion.Unknown) {
            revert LaunchpegLens__InvalidLaunchpegVersion();
        }
        // default to v2 unless v1 is specified
        ILaunchpegFactory factory = (_version == LaunchpegVersion.V1)
            ? launchpegFactoryV1
            : launchpegFactoryV2;
        // 0 - Launchpeg, 1 - FlatLaunchpeg
        uint256 lpTypeIdx = uint8(_type) - 1;
        uint256 numLaunchpegs = factory.numLaunchpegs(lpTypeIdx);

        uint256 end = _limit > numLaunchpegs ? numLaunchpegs : _limit;
        uint256 start = _number > end ? 0 : end - _number;

        LensData[] memory LensDatas;
        LensDatas = new LensData[](end - start);

        for (uint256 i = 0; i < LensDatas.length; i++) {
            LensDatas[i] = getLaunchpegData(
                factory.allLaunchpegs(lpTypeIdx, end - 1 - i),
                _user
            );
        }

        return LensDatas;
    }

    /// @notice Fetch Launchpeg data from the provided address
    /// @param _launchpeg Contract address to consider
    /// @param _user Address to consider for NFT balances and allowlist allocations
    /// @return LensData Contract data
    function getLaunchpegData(address _launchpeg, address _user)
        public
        view
        returns (LensData memory)
    {
        (
            LaunchpegType launchType,
            LaunchpegVersion launchVersion
        ) = getLaunchpegType(_launchpeg);
        if (launchType == LaunchpegType.Unknown) {
            revert LaunchpegLens__InvalidContract();
        }

        LensData memory data;
        data.id = _launchpeg;
        data.launchType = launchType;
        data.collectionData = _getCollectionData(_launchpeg);
        data.projectOwnerData = _getProjectOwnerData(_launchpeg, launchVersion);
        data.revealData = _getBatchRevealData(_launchpeg, launchVersion);
        data.userData = _getUserData(_launchpeg, launchVersion, _user);

        if (data.launchType == LaunchpegType.Launchpeg) {
            data.launchpegData = _getLaunchpegData(_launchpeg, launchVersion);
        } else if (data.launchType == LaunchpegType.FlatLaunchpeg) {
            data.flatLaunchpegData = _getFlatLaunchpegData(
                _launchpeg,
                launchVersion
            );
        }

        return data;
    }

    /// @dev Fetches Launchpeg collection data
    /// @param _launchpeg Launchpeg address
    function _getCollectionData(address _launchpeg)
        private
        view
        returns (CollectionData memory data)
    {
        data.name = ERC721AUpgradeable(_launchpeg).name();
        data.symbol = ERC721AUpgradeable(_launchpeg).symbol();
        data.collectionSize = IBaseLaunchpeg(_launchpeg).collectionSize();
        data.maxPerAddressDuringMint = IBaseLaunchpeg(_launchpeg)
            .maxPerAddressDuringMint();
        data.totalSupply = ERC721AUpgradeable(_launchpeg).totalSupply();
        data.unrevealedURI = IBaseLaunchpeg(_launchpeg).unrevealedURI();
        data.baseURI = IBaseLaunchpeg(_launchpeg).baseURI();
    }

    /// @dev Fetches Launchpeg project owner data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getProjectOwnerData(
        address _launchpeg,
        LaunchpegVersion launchVersion
    ) private view returns (ProjectOwnerData memory data) {
        data.amountMintedByDevs = IBaseLaunchpeg(_launchpeg)
            .amountMintedByDevs();
        data.launchpegBalanceAVAX = _launchpeg.balance;
        if (launchVersion == LaunchpegVersion.V1) {
            address[] memory projectOwners = new address[](1);
            projectOwners[0] = IBaseLaunchpegV1(_launchpeg).projectOwner();
            data.projectOwners = projectOwners;
        } else if (launchVersion == LaunchpegVersion.V2) {
            data.projectOwners = _getProjectOwners(_launchpeg);
            data.withdrawAVAXStartTime = IBaseLaunchpeg(_launchpeg)
                .withdrawAVAXStartTime();
        }
    }

    /// @dev Fetches Launchpeg project owners. Only works for Launchpeg V2.
    /// @param _launchpeg Launchpeg address
    function _getProjectOwners(address _launchpeg)
        private
        view
        returns (address[] memory)
    {
        bytes32 role = IBaseLaunchpeg(_launchpeg).PROJECT_OWNER_ROLE();
        uint256 count = IAccessControlEnumerableUpgradeable(_launchpeg)
            .getRoleMemberCount(role);
        address[] memory projectOwners = new address[](count);
        for (uint256 i; i < count; i++) {
            projectOwners[i] = IAccessControlEnumerableUpgradeable(_launchpeg)
                .getRoleMember(role, i);
        }
        return projectOwners;
    }

    /// @dev Fetches Launchpeg data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getLaunchpegData(
        address _launchpeg,
        LaunchpegVersion launchVersion
    ) private view returns (LaunchpegData memory data) {
        ILaunchpeg lp = ILaunchpeg(_launchpeg);
        data.currentPhase = lp.currentPhase();
        data.amountForAuction = lp.amountForAuction();
        data.amountForAllowlist = lp.amountForAllowlist();
        data.amountForDevs = lp.amountForDevs();
        data.auctionSaleStartTime = lp.auctionSaleStartTime();
        data.allowlistStartTime = lp.allowlistStartTime();
        data.publicSaleStartTime = lp.publicSaleStartTime();
        data.auctionStartPrice = lp.auctionStartPrice();
        data.auctionEndPrice = lp.auctionEndPrice();
        data.auctionSaleDuration = lp.auctionSaleDuration();
        data.auctionDropInterval = lp.auctionDropInterval();
        data.auctionDropPerStep = lp.auctionDropPerStep();
        data.allowlistDiscountPercent = lp.allowlistDiscountPercent();
        data.publicSaleDiscountPercent = lp.publicSaleDiscountPercent();
        data.auctionPrice = lp.getAuctionPrice(data.auctionSaleStartTime);
        data.lastAuctionPrice = lp.lastAuctionPrice();
        data.amountMintedDuringAuction = lp.amountMintedDuringAuction();
        data.amountMintedDuringAllowlist = lp.amountMintedDuringAllowlist();
        data.amountMintedDuringPublicSale = lp.amountMintedDuringPublicSale();
        if (launchVersion == LaunchpegVersion.V1) {
            data.allowlistPrice = IBaseLaunchpegV1(_launchpeg)
                .getAllowlistPrice();
            data.publicSalePrice = IBaseLaunchpegV1(_launchpeg)
                .getPublicSalePrice();
        } else if (launchVersion == LaunchpegVersion.V2) {
            data.allowlistPrice = lp.allowlistPrice();
            data.publicSalePrice = lp.salePrice();
            data.preMintStartTime = lp.preMintStartTime();
            data.publicSaleEndTime = lp.publicSaleEndTime();
            data.amountMintedDuringPreMint = lp.amountMintedDuringPreMint();
        }
    }

    /// @dev Fetches FlatLaunchpeg data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getFlatLaunchpegData(
        address _launchpeg,
        LaunchpegVersion launchVersion
    ) private view returns (FlatLaunchpegData memory data) {
        IFlatLaunchpeg lp = IFlatLaunchpeg(_launchpeg);
        data.currentPhase = lp.currentPhase();
        data.amountForAllowlist = lp.amountForAllowlist();
        data.amountForDevs = lp.amountForDevs();
        data.allowlistStartTime = lp.allowlistStartTime();
        data.publicSaleStartTime = lp.publicSaleStartTime();
        data.allowlistPrice = lp.allowlistPrice();
        data.salePrice = lp.salePrice();
        data.amountMintedDuringAllowlist = lp.amountMintedDuringAllowlist();
        data.amountMintedDuringPublicSale = lp.amountMintedDuringPublicSale();
        if (launchVersion == LaunchpegVersion.V2) {
            data.preMintStartTime = lp.preMintStartTime();
            data.publicSaleEndTime = lp.publicSaleEndTime();
            data.amountMintedDuringPreMint = lp.amountMintedDuringPreMint();
        }
    }

    /// @dev Fetches batch reveal data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getBatchRevealData(
        address _launchpeg,
        LaunchpegVersion launchVersion
    ) private view returns (RevealData memory data) {
        if (launchVersion == LaunchpegVersion.V1) {
            IBaseLaunchpegV1 br = IBaseLaunchpegV1(_launchpeg);
            data.revealBatchSize = br.revealBatchSize();
            data.revealStartTime = br.revealStartTime();
            data.revealInterval = br.revealInterval();
            data.lastTokenRevealed = br.lastTokenRevealed();
        } else if (launchVersion == LaunchpegVersion.V2) {
            (
                ,
                ,
                uint256 revealBatchSize,
                uint256 revealStartTime,
                uint256 revealInterval
            ) = IBatchReveal(batchReveal).launchpegToConfig(_launchpeg);
            data.revealBatchSize = revealBatchSize;
            data.revealStartTime = revealStartTime;
            data.revealInterval = revealInterval;
            data.lastTokenRevealed = IBatchReveal(batchReveal)
                .launchpegToLastTokenReveal(_launchpeg);
        }
    }

    /// @dev Fetches Launchpeg user data
    /// @param _launchpeg Launchpeg address
    /// @param launchVersion Launchpeg version
    function _getUserData(
        address _launchpeg,
        LaunchpegVersion launchVersion,
        address _user
    ) private view returns (UserData memory data) {
        if (_user != address(0)) {
            data.balanceOf = ERC721AUpgradeable(_launchpeg).balanceOf(_user);
            data.numberMinted = IBaseLaunchpeg(_launchpeg).numberMinted(_user);
            data.allowanceForAllowlistMint = IBaseLaunchpeg(_launchpeg)
                .allowlist(_user);
            if (launchVersion == LaunchpegVersion.V2) {
                data.numberMintedWithPreMint = IBaseLaunchpeg(_launchpeg)
                    .numberMintedWithPreMint(_user);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @title IBaseLaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of BaseLaunchpeg
interface IBaseLaunchpeg is IERC1155Upgradeable {
    enum Phase {
        NotStarted,
        DutchAuction,
        PreMint,
        Allowlist,
        PublicSale,
        Ended
    }

    /// @notice Collection data to initialize Launchpeg
    /// @param name ERC721 name
    /// @param symbol ERC721 symbol
    /// @param maxPerAddressDuringMint Max amount of NFTs an address can mint in public phases
    /// @param collectionSize The collection size (e.g 10000)
    /// @param amountForDevs Amount of NFTs reserved for `projectOwner` (e.g 200)
    /// @param amountForAuction Amount of NFTs available for the auction (e.g 8000)
    /// @param amountForAllowlist Amount of NFTs available for the allowlist mint (e.g 1000)
    struct CollectionData {
        string name;
        string symbol;
        address batchReveal;
        uint256 maxPerAddressDuringMint;
        uint256 collectionSize;
        uint256 amountForDevs;
        uint256 amountForAuction;
        uint256 amountForAllowlist;
    }

    /// @notice Collection owner data to initialize Launchpeg
    /// @param owner The contract owner
    /// @param projectOwner The project owner
    /// @param royaltyReceiver Royalty fee collector
    /// @param joeFeeCollector The address to which the fees on the sale will be sent
    /// @param joeFeePercent The fees collected by the fee collector on the sale benefits
    struct CollectionOwnerData {
        address owner;
        address projectOwner;
        address royaltyReceiver;
        address joeFeeCollector;
        uint256 joeFeePercent;
    }

    function PROJECT_OWNER_ROLE() external pure returns (bytes32);

    function collectionSize() external view returns (uint256);

    function unrevealedURI() external view returns (string memory);

    function baseURI() external view returns (string memory);

    function amountForDevs() external view returns (uint256);

    function amountForAllowlist() external view returns (uint256);

    function maxPerAddressDuringMint() external view returns (uint256);

    function joeFeePercent() external view returns (uint256);

    function joeFeeCollector() external view returns (address);

    function allowlist(address) external view returns (uint256);

    function amountMintedByDevs() external view returns (uint256);

    function amountMintedDuringPreMint() external view returns (uint256);

    function amountClaimedDuringPreMint() external view returns (uint256);

    function amountMintedDuringAllowlist() external view returns (uint256);

    function amountMintedDuringPublicSale() external view returns (uint256);

    function preMintStartTime() external view returns (uint256);

    function allowlistStartTime() external view returns (uint256);

    function publicSaleStartTime() external view returns (uint256);

    function publicSaleEndTime() external view returns (uint256);

    function withdrawAVAXStartTime() external view returns (uint256);

    function allowlistPrice() external view returns (uint256);

    function salePrice() external view returns (uint256);

    function initializeBatchReveal(address _batchReveal) external;

    function setRoyaltyInfo(address receiver, uint96 feePercent) external;

    function seedAllowlist(
        address[] calldata _addresses,
        uint256[][] calldata stampIds
    ) external;

    function setPreMintStartTime(uint256 _preMintStartTime) external;

    function setAllowlistStartTime(uint256 _allowlistStartTime) external;

    function setPublicSaleStartTime(uint256 _publicSaleStartTime) external;

    function setPublicSaleEndTime(uint256 _publicSaleEndTime) external;

    function setWithdrawAVAXStartTime(uint256 _withdrawAVAXStartTime) external;

    function devMint(uint256 quantity) external;

    function preMint(uint96 _quantity) external payable;

    function claimPreMint() external;

    function batchClaimPreMint(uint96 _maxQuantity) external;

    function allowlistMint(uint256 _quantity) external payable;

    function publicSaleMint(uint256 _quantity) external payable;

    function withdrawAVAX(address to) external;

    function userPendingPreMints(address owner) external view returns (uint256);

    function numberMinted(address owner) external view returns (uint256);

    function numberMintedWithPreMint(address _owner)
        external
        view
        returns (uint256);

    function currentPhase() external view returns (Phase);

    function revealNextBatch() external;

    function hasBatchToReveal() external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBaseLaunchpegV1
/// @author Trader Joe
/// @notice Defines the legacy methods in Launchpeg V1 contracts
interface IBaseLaunchpegV1 {
    /** IBaseLaunchpeg */
    function projectOwner() external view returns (address);

    /** ILaunchpeg */
    function getAllowlistPrice() external view returns (uint256);

    function getPublicSalePrice() external view returns (uint256);

    /** IBatchReveal */
    function revealBatchSize() external view returns (uint256);

    function lastTokenRevealed() external view returns (uint256);

    function revealStartTime() external view returns (uint256);

    function revealInterval() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title IBatchReveal
/// @author Trader Joe
/// @notice Defines the basic interface of BatchReveal
interface IBatchReveal {
    struct BatchRevealConfig {
        uint256 collectionSize;
        int128 intCollectionSize;
        /// @notice Size of the batch reveal
        /// @dev Must divide collectionSize
        uint256 revealBatchSize;
        /// @notice Timestamp for the start of the reveal process
        /// @dev Can be set to zero for immediate reveal after token mint
        uint256 revealStartTime;
        /// @notice Time interval for gradual reveal
        /// @dev Can be set to zero in order to reveal the collection all at once
        uint256 revealInterval;
    }

    function initialize() external;

    function configure(
        address _baseLaunchpeg,
        uint256 _revealBatchSize,
        uint256 _revealStartTime,
        uint256 _revealInterval
    ) external;

    function setRevealBatchSize(
        address _baseLaunchpeg,
        uint256 _revealBatchSize
    ) external;

    function setRevealStartTime(
        address _baseLaunchpeg,
        uint256 _revealStartTime
    ) external;

    function setRevealInterval(address _baseLaunchpeg, uint256 _revealInterval)
        external;

    function setVRF(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    ) external;

    function launchpegToConfig(address)
        external
        view
        returns (
            uint256,
            int128,
            uint256,
            uint256,
            uint256
        );

    function launchpegToBatchToSeed(address, uint256)
        external
        view
        returns (uint256);

    function launchpegToLastTokenReveal(address)
        external
        view
        returns (uint256);

    function useVRF() external view returns (bool);

    function subscriptionId() external view returns (uint64);

    function keyHash() external view returns (bytes32);

    function callbackGasLimit() external view returns (uint32);

    function requestConfirmations() external view returns (uint16);

    function launchpegToNextBatchToReveal(address)
        external
        view
        returns (uint256);

    function launchpegToHasBeenForceRevealed(address)
        external
        view
        returns (bool);

    function launchpegToVrfRequestedForBatch(address, uint256)
        external
        view
        returns (bool);

    function getShuffledTokenId(address _baseLaunchpeg, uint256 _startId)
        external
        view
        returns (uint256);

    function isBatchRevealInitialized(address _baseLaunchpeg)
        external
        view
        returns (bool);

    function revealNextBatch(address _baseLaunchpeg, uint256 _totalSupply)
        external
        returns (bool);

    function hasBatchToReveal(address _baseLaunchpeg, uint256 _totalSupply)
        external
        view
        returns (bool, uint256);

    function forceReveal(address _baseLaunchpeg) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of FlatLaunchpeg
interface IFlatLaunchpeg is IBaseLaunchpeg {
    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external;

    function initializePhases(
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _allowlistPrice,
        uint256 _salePrice
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IBaseLaunchpeg.sol";

/// @title ILaunchpeg
/// @author Trader Joe
/// @notice Defines the basic interface of Launchpeg
interface ILaunchpeg is IBaseLaunchpeg {
    function amountForAuction() external view returns (uint256);

    function auctionSaleStartTime() external view returns (uint256);

    function auctionStartPrice() external view returns (uint256);

    function auctionEndPrice() external view returns (uint256);

    function auctionSaleDuration() external view returns (uint256);

    function auctionDropInterval() external view returns (uint256);

    function auctionDropPerStep() external view returns (uint256);

    function allowlistDiscountPercent() external view returns (uint256);

    function publicSaleDiscountPercent() external view returns (uint256);

    function amountMintedDuringAuction() external view returns (uint256);

    function lastAuctionPrice() external view returns (uint256);

    function getAuctionPrice(uint256 _saleStartTime)
        external
        view
        returns (uint256);

    function initialize(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) external;

    function initializePhases(
        uint256 _auctionSaleStartTime,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionDropInterval,
        uint256 _preMintStartTime,
        uint256 _allowlistStartTime,
        uint256 _allowlistDiscountPercent,
        uint256 _publicSaleStartTime,
        uint256 _publicSaleEndTime,
        uint256 _publicSaleDiscountPercent
    ) external;

    function setAuctionSaleStartTime(uint256 _auctionSaleStartTime) external;

    function auctionMint(uint256 _quantity) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title ILaunchpegFactory
/// @author Trader Joe
/// @notice Defines the basic interface of LaunchpegFactory
interface ILaunchpegFactory {
    function LAUNCHPEG_PAUSER_ROLE() external pure returns (bytes32);

    function launchpegImplementation() external view returns (address);

    function flatLaunchpegImplementation() external view returns (address);

    function batchReveal() external view returns (address);

    function joeFeePercent() external view returns (uint256);

    function joeFeeCollector() external view returns (address);

    function isLaunchpeg(uint256 _type, address _contract)
        external
        view
        returns (bool);

    function allLaunchpegs(uint256 _launchpegType, uint256 _launchpegID)
        external
        view
        returns (address);

    function numLaunchpegs(uint256 _launchpegType)
        external
        view
        returns (uint256);

    function createLaunchpeg(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxPerAddressDuringMint,
        uint256 _collectionSize,
        uint256 _amountForAuction,
        uint256 _amountForAllowlist,
        uint256 _amountForDevs,
        bool _enableBatchReveal
    ) external returns (address);

    function createFlatLaunchpeg(
        string memory _name,
        string memory _symbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint256 _maxPerAddressDuringMint,
        uint256 _collectionSize,
        uint256 _amountForDevs,
        uint256 _amountForAllowlist,
        bool _enableBatchReveal
    ) external returns (address);

    function setLaunchpegImplementation(address _launchpegImplementation)
        external;

    function setFlatLaunchpegImplementation(
        address _flatLaunchpegImplementation
    ) external;

    function setBatchReveal(address _batchReveal) external;

    function setDefaultJoeFeePercent(uint256 _joeFeePercent) external;

    function setDefaultJoeFeeCollector(address _joeFeeCollector) external;

    function addLaunchpegPauser(address _pauser) external;

    function removeLaunchpegPauser(address _pauser) external;

    function pauseLaunchpeg(address _launchpeg) external;
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721AUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __ERC721A_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721A_init_unchained(name_, symbol_);
    }

    function __ERC721A_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721AUpgradeable.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}