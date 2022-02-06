// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "../Ownable.sol";
import "../Pauseable.sol";
import "../IPoliceAndThief.sol";
import "../IBank.sol";
import "../ITraits.sol";
import "../IPoliceAndThief.sol";

interface IPoliceGame is IPoliceAndThief {
    function mintOldTokens(address oldGame, uint256 id, address owner) external;
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
    function transferFrom(address, address, uint256) external;
}

contract P2Swapper is Ownable {
    IBank public p2bank;
    IPoliceGame public game = IPoliceGame(0x15e6C37CDb635ACc1fF82A8E6f1D25a757949BEC);
    address public oldBank = 0x408634E518D44FFbb6A1fed5faAC6D4AD0B2943b;

    event Registered(uint256 id, address owner, bool isThief, uint256 value);

    struct TokenData {
        uint256 id;
        bool isThief;
        address owner;
        uint256 value;
    }

    function setAddrs(IBank _p2bank) public onlyOwner {
        p2bank = _p2bank;
    }

    function transferFrom(address _from, address _to, uint256 _id) public onlyOwner {
        game.transferFrom(_from, _to, _id);
    }

    function setDataToNewBank(TokenData[] memory _data) public onlyOwner {
        for (uint256 i = 0; i < _data.length; i++) {
            TokenData memory t = _data[i];
            if (game.ownerOf(t.id) != oldBank) continue;

            p2bank.setOldTokenInfo(t.id, t.isThief, t.owner, t.value);
            game.transferFrom(oldBank, t.owner, t.id);
            game.transferFrom(t.owner, address(p2bank), t.id);
            emit Registered(t.id, t.owner, t.isThief, t.value);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be Pauseable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pauseable is Context {
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
     * @dev Initializes the contract in paused state.
     */
    constructor() {
        _paused = true;
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
        require(!paused(), "Pauseable: paused");
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
        require(paused(), "Pauseable: not paused");
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

pragma solidity ^0.8.0;

import "./Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function selectTrait(uint16 seed, uint8 traitType) external view returns(uint8);
    function drawSVG(uint256 tokenId) external view returns (string memory);
    function traitData(uint8, uint8) external view returns (string memory, string memory);
    function traitCountForType(uint8) external view returns (uint8);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IPoliceAndThief {

    // struct to store each token's traits
    struct ThiefPolice {
        bool isThief;
        uint8 uniform;
        uint8 hair;
        uint8 eyes;
        uint8 facialHair;
        uint8 headgear;
        uint8 neckGear;
        uint8 accessory;
        uint8 alphaIndex;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (ThiefPolice memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IBank {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    function claimForUser(uint256[] calldata tokenIds, address _tokenOwner) external;

    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) external;
    function randomPoliceOwner(uint256 seed) external view returns (address);
    function bank(uint256) external view returns(uint16, uint80, address);
    function totalLootEarned() external view returns(uint256);
    function lastClaimTimestamp() external view returns(uint256);
    function setOldTokenInfo(uint256, bool, address, uint256) external;

    function pack(uint256, uint256) external view returns(Stake memory);
    function packIndices(uint256) external view returns(uint256);
    function realOwnerOf(uint256) external view returns(address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}