// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "clouds/contracts/LDiamond.sol";
import "../libraries/AppStorage.sol";
import "../libraries/LAuthorizable.sol";

/// @title AuthorizationFacet
/// @author mektigboy
/// @notice Facet in charge of displaying and setting the authorization variables
/// @dev Utilizes 'LDiamond', 'AppStorage' and 'LAuthorizable'
contract AuthorizationFacet {
    ///////////////////
    /// APP STORAGE ///
    ///////////////////

    AppStorage s;

    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Get if address is authorized
    /// @param _address Address
    /// @return True or false
    function authorized(address _address) external view returns (bool) {
        return s.authorized[_address];
    }

    /// @notice Authorize address
    /// @param _address Address to authorize
    function authorize(address _address) external {
        LDiamond.enforceIsOwner();

        s.authorized[_address] = true;
    }

    /// @notice Unauthorize address
    /// @param _address Address to unauthorize
    function unauthorize(address _address) external {
        LDiamond.enforceIsOwner();

        s.authorized[_address] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/AppStorage.sol";

error LAuthorizable__OnlyAuthorized();

/// @title LAuthorizable
/// @author mektigboy
library LAuthorizable {
    /////////////
    /// LOGIC ///
    /////////////

    /// @notice Enforce only authorized address can call a certain function
    /// @param s AppStorage
    /// @param _address Address
    function enforceIsAuthorized(AppStorage storage s, address _address) internal view {
        if (!s.authorized[_address]) revert LAuthorizable__OnlyAuthorized();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

////////////
/// NODE ///
////////////

struct Node {
    string name;
    ///
    uint256 creation;
    uint256 lastClaimTime;
    ///
    uint256 amount;
    uint256 rewardPaid;
    ///
    bool active;
}

///////////////
/// ROYALTY ///
///////////////

struct RoyaltyInfo {
    address recipient;
    uint256 bps;
}

////////////
/// MATH ///
////////////

enum Rounding {
    Down,
    Up,
    Zero
}

///////////////////
/// APP STORAGE ///
///////////////////

struct AppStorage {
    ////////////////////
    /// AUTHORIZABLE ///
    ////////////////////
    mapping(address => bool) authorized;
    ////////////////
    /// PAUSABLE ///
    ////////////////
    bool paused;
    ///////////////
    /// REWARDS ///
    ///////////////
    uint256 accumulatedRewardPerShare;
    uint256 ACCUMULATED_REWARD_PER_SHARE_PRECISION;
    uint256 lastRewardBalance;
    ///////////////
    /// GENERAL ///
    ///////////////
    address vpnd;
    address wavax;
    address stratosphere;
    address rewardsPool;
    address nodeStorage;
    address treasury;
    address referralController;
    ///
    uint256 deployedAt;
    uint256 tvl;
    uint256 balance; // TODO: Do we need this? Seems duplicated of 'lastRewardBalance'
    uint256 dailyReception;
    uint256 txCounter;
    mapping(uint256 => uint256) balances;
    mapping(uint256 => uint256) dailyReceptions;
    /////////////
    /// NODES ///
    /////////////
    uint256 minNodeAmount;
    uint256 maxNodesPerWallet;
    mapping(uint256 => Node) nodeByTokenId;
    /////////////////
    /// MIGRATION ///
    /////////////////
    uint256 totalNodesCreated;
    uint256 totalNodesMigrated;
    mapping(address => bool) alreadyMigrated;
    /////////////
    /// TAXES ///
    /////////////
    uint256 claimFee;
    uint256 compoundFee;
    uint256 depositFee;
    uint256 quoteSlippagePct;
    address dexRouter;
    //////////////
    /// ERC721 ///
    //////////////
    string baseURI;
    string name;
    string symbol;
    bool isTransferable;
    mapping(address => uint256) tokenBalances;
    mapping(uint256 => address) tokenOwners;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    /////////////////////////
    /// ERC721 ENUMERABLE ///
    /////////////////////////
    mapping(address => mapping(uint256 => uint256)) ownedTokens;
    mapping(uint256 => uint256) ownedTokensIndex;
    uint256[] allTokens;
    mapping(uint256 => uint256) allTokensIndex;
    /////////////////
    /// ROYALTIES ///
    /////////////////
    address royaltyRecipient;
    uint16 royaltyBps;
    mapping(uint256 => RoyaltyInfo) royaltyInfoForToken;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IDiamondCut.sol";

error IDiamondCut__AddressMustBeZero();
error IDiamondCut__FunctionAlreadyExists();
error IDiamondCut__ImmutableFunction();
error IDiamondCut__IncorrectAction();
error IDiamondCut__InexistentFacetCode();
error IDiamondCut__InexistentFunction();
error IDiamondCut__InvalidAddressZero();
error IDiamondCut__InvalidReplacementWithSameFunction();
error IDiamondCut__NoSelectors();

error LDiamond__InitializationFailed(
  address _initializationContractAddress,
  bytes _data
);
error LDiamond__OnlyOwner();

/// @title LDiamond
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @notice Diamond library
/// @dev EIP-2535 "Diamond" standard
library LDiamond {
  //////////////
  /// EVENTS ///
  //////////////

  event DiamondCut(IDiamondCut.FacetCut[] _cut, address _init, bytes _data);

  event OwnershipTransferred(
    address indexed pastOwner,
    address indexed newOwner
  );

  ///////////////
  /// STORAGE ///
  ///////////////

  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    /// @notice Facet address
    address facetAddress;
    /// @notice Facet position in 'facetFunctionSelectors.functionSelectors' array
    uint96 functionSelectorPosition;
  }

  struct FacetFunctionSelectors {
    /// @notice Function selectors
    bytes4[] functionSelectors;
    /// @notice Position of 'facetAddress' in 'facetAddresses' array
    uint256 facetAddressPosition;
  }

  struct DiamondStorage {
    /// @notice Position of selector in 'facetFunctionSelectors.selectors' array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    /// @notice Facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    /// @notice Facet addresses
    address[] facetAddresses;
    /// @notice Query if contract implements an interface
    mapping(bytes4 => bool) supportedInterfaces;
    /// @notice Owner of contract
    address owner;
  }

  /////////////
  /// LOGIC ///
  /////////////

  /// @notice ...
  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;

    assembly {
      ds.slot := position
    }
  }

  /// @notice ...
  /// @param _owner New owner
  function updateContractOwner(address _owner) internal {
    DiamondStorage storage ds = diamondStorage();

    address oldOwner = ds.owner;

    ds.owner = _owner;

    emit OwnershipTransferred(oldOwner, _owner);
  }

  /// @notice ...
  function contractOwner() internal view returns (address owner_) {
    owner_ = diamondStorage().owner;
  }

  /// @notice ...
  function enforceIsOwner() internal view {
    if (diamondStorage().owner != msg.sender) revert LDiamond__OnlyOwner();
  }

  /// @notice ...
  /// @param _cut ...
  /// @param _init ...
  /// @param _data ...
  function diamondCut(
    IDiamondCut.FacetCut[] memory _cut,
    address _init,
    bytes memory _data
  ) internal {
    for (uint256 facetIndex; facetIndex < _cut.length; ++facetIndex) {
      IDiamondCut.FacetCutAction action = _cut[facetIndex].action;

      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(
          _cut[facetIndex].facetAddress,
          _cut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(
          _cut[facetIndex].facetAddress,
          _cut[facetIndex].functionSelectors
        );
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(
          _cut[facetIndex].facetAddress,
          _cut[facetIndex].functionSelectors
        );
      } else {
        revert IDiamondCut__IncorrectAction();
      }
    }

    emit DiamondCut(_cut, _init, _data);

    initializeDiamondCut(_init, _data);
  }

  /// @notice ...
  /// @param _facet Facet address
  /// @param _selectors Facet selectors
  function addFunctions(address _facet, bytes4[] memory _selectors) internal {
    if (_selectors.length == 0) revert IDiamondCut__NoSelectors();

    DiamondStorage storage ds = diamondStorage();

    if (_facet == address(0)) revert IDiamondCut__InvalidAddressZero();

    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facet].functionSelectors.length
    );

    /// @notice Add new facet address if it does not exists already

    if (selectorPosition == 0) {
      addFacet(ds, _facet);
    }

    for (
      uint256 selectorIndex;
      selectorIndex < _selectors.length;
      ++selectorIndex
    ) {
      bytes4 selector = _selectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      if (oldFacetAddress != address(0))
        revert IDiamondCut__FunctionAlreadyExists();

      addFunction(ds, selector, selectorPosition, _facet);

      ++selectorPosition;
    }
  }

  /// @notice ...
  /// @param _facet Facet address
  /// @param _selectors Facet selectors
  function replaceFunctions(address _facet, bytes4[] memory _selectors)
    internal
  {
    if (_selectors.length == 0) revert IDiamondCut__NoSelectors();

    DiamondStorage storage ds = diamondStorage();

    if (_facet == address(0)) revert IDiamondCut__InvalidAddressZero();

    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facet].functionSelectors.length
    );

    /// @notice Add new facet address if it does not exists already

    if (selectorPosition == 0) {
      addFacet(ds, _facet);
    }
    for (
      uint256 selectorIndex;
      selectorIndex < _selectors.length;
      ++selectorIndex
    ) {
      bytes4 selector = _selectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      if (oldFacetAddress == _facet)
        revert IDiamondCut__InvalidReplacementWithSameFunction();

      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facet);

      ++selectorPosition;
    }
  }

  /// @notice ...
  /// @param _facet Facet address
  /// @param _selectors Facet selectors
  function removeFunctions(address _facet, bytes4[] memory _selectors)
    internal
  {
    if (_selectors.length == 0) revert IDiamondCut__NoSelectors();

    DiamondStorage storage ds = diamondStorage();

    if (_facet != address(0)) revert IDiamondCut__AddressMustBeZero();

    for (
      uint256 selectorIndex;
      selectorIndex < _selectors.length;
      ++selectorIndex
    ) {
      bytes4 selector = _selectors[selectorIndex];
      address oldFacetAddress = ds
        .selectorToFacetAndPosition[selector]
        .facetAddress;

      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  /// @notice ...
  /// @param ds DiamondStorage
  /// @param _facet Facet address
  function addFacet(DiamondStorage storage ds, address _facet) internal {
    enforceHasContractCode(_facet);

    ds.facetFunctionSelectors[_facet].facetAddressPosition = ds
      .facetAddresses
      .length;
    ds.facetAddresses.push(_facet);
  }

  /// @notice ...
  /// @param ds DiamondStorage
  /// @param _selector Facet selector
  /// @param _positon Selector position
  /// @param _facet Facet address
  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _positon,
    address _facet
  ) internal {
    ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition = _positon;
    ds.facetFunctionSelectors[_facet].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facet;
  }

  /// @notice ...
  /// @param ds DiamondStorage
  /// @param _facet Facet address
  /// @param _selector Facet address
  function removeFunction(
    DiamondStorage storage ds,
    address _facet,
    bytes4 _selector
  ) internal {
    if (_facet == address(0)) revert IDiamondCut__InexistentFunction();

    /// @notice An immutable function is defined directly in diamond
    if (_facet == address(this)) revert IDiamondCut__ImmutableFunction();

    /// @notice Replaces selector with last selector, then deletes last selector
    uint256 selectorPosition = ds
      .selectorToFacetAndPosition[_selector]
      .functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[_facet]
      .functionSelectors
      .length - 1;

    /// @notice Replaces '_selector' with 'lastSelector' if not they are not the same
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facet].functionSelectors[
        lastSelectorPosition
      ];
      ds.facetFunctionSelectors[_facet].functionSelectors[
        selectorPosition
      ] = lastSelector;
      ds
        .selectorToFacetAndPosition[lastSelector]
        .functionSelectorPosition = uint96(selectorPosition);
    }

    /// @notice Deletes last selector

    ds.facetFunctionSelectors[_facet].functionSelectors.pop();

    delete ds.selectorToFacetAndPosition[_selector];

    /// @notice Deletes facet address if there are no more selectors for facet address
    if (lastSelectorPosition == 0) {
      /// @notice Replaces facet address with last facet address, deletes last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds
        .facetFunctionSelectors[_facet]
        .facetAddressPosition;

      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds
          .facetFunctionSelectors[lastFacetAddress]
          .facetAddressPosition = facetAddressPosition;
      }

      ds.facetAddresses.pop();

      delete ds.facetFunctionSelectors[_facet].facetAddressPosition;
    }
  }

  /// @notice ...
  /// @param _init ...
  /// @param _data ...
  function initializeDiamondCut(address _init, bytes memory _data) internal {
    if (_init == address(0)) {
      return;
    }

    enforceHasContractCode(_init);

    (bool success, bytes memory error) = _init.delegatecall(_data);

    if (!success) {
      if (error.length > 0) {
        /// @solidity memory-safe-assembly
        assembly {
          let dataSize := mload(error)

          revert(add(32, error), dataSize)
        }
      } else {
        revert LDiamond__InitializationFailed(_init, _data);
      }
    }
  }

  /// @notice ...
  /// @param _contract Contract address
  function enforceHasContractCode(address _contract) internal view {
    uint256 contractSize;

    assembly {
      contractSize := extcodesize(_contract)
    }

    if (contractSize == 0) revert IDiamondCut__InexistentFacetCode();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title IDiamondCut
/// @author mektigboy
/// @author Modified from Nick Mudge: https://github.com/mudgen/diamond-3-hardhat
/// @dev EIP-2535 "Diamond" standard
interface IDiamondCut {
    //////////////
    /// EVENTS ///
    //////////////

    event DiamondCut(FacetCut[] _cut, address _init, bytes _data);

    ///////////////
    /// STORAGE ///
    ///////////////

    /// ACTIONS

    /// Add     - 0
    /// Replace - 1
    /// Remove  - 2

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @param _cut Facet addreses and function selectors
    /// @param _init Address of contract or facet to execute _data
    /// @param _data Function call, includes function selector and arguments
    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _data
    ) external;
}