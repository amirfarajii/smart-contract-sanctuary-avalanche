// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {EnumerableSet} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";

/**
 * @title CurrencyManager
 * @notice It allows adding/removing currencies for trading on the Joepeg exchange.
 */
contract CurrencyManager is
    ICurrencyManager,
    Ownable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedCurrencies;

    event CurrencyRemoved(address indexed currency);
    event CurrencyWhitelisted(address indexed currency);

    /**
     * @notice Add a currency in the system
     * @param currency address of the currency to add
     */
    function addCurrency(address currency) external override onlyOwner {
        require(
            !_whitelistedCurrencies.contains(currency),
            "Currency: Already whitelisted"
        );
        _whitelistedCurrencies.add(currency);

        emit CurrencyWhitelisted(currency);
    }

    /**
     * @notice Remove a currency from the system
     * @param currency address of the currency to remove
     */
    function removeCurrency(address currency) external override onlyOwner {
        require(
            _whitelistedCurrencies.contains(currency),
            "Currency: Not whitelisted"
        );
        _whitelistedCurrencies.remove(currency);

        emit CurrencyRemoved(currency);
    }

    /**
     * @notice Returns if a currency is in the system
     * @param currency address of the currency
     */
    function isCurrencyWhitelisted(address currency)
        external
        view
        override
        returns (bool)
    {
        return _whitelistedCurrencies.contains(currency);
    }

    /**
     * @notice View number of whitelisted currencies
     */
    function viewCountWhitelistedCurrencies()
        external
        view
        override
        returns (uint256)
    {
        return _whitelistedCurrencies.length();
    }

    /**
     * @notice See whitelisted currencies in the system
     * @param cursor cursor (should start at 0 for first request)
     * @param size size of the response (e.g., 50)
     */
    function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedCurrencies.length() - cursor) {
            length = _whitelistedCurrencies.length() - cursor;
        }

        address[] memory whitelistedCurrencies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedCurrencies[i] = _whitelistedCurrencies.at(cursor + i);
        }

        return (whitelistedCurrencies, cursor + length);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency)
        external
        view
        returns (bool);

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// ⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⢸⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⣸⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠋⣠⣾⣿⡿⠀⢠⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⢠⣿⡇⠀⠀⠀⣠⠀⠀⠀⠀⢸⣿⠀⠉⠉⠁⠀⠀⣼⠀⠀⠀⠀
// ⠀⠀⢀⡀⠀⠀⣾⣿⠀⠀⢠⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀⠀
// ⠀⢠⣿⡀⠀⠀⠹⣿⠀⠀⣾⣿⣿⣿⣿⣿⣶⣤⣄⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀
// ⠀⠈⢻⣧⠀⠀⠀⠘⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⣿⡇⠀⠀
// ⠀⠀⠀⢻⡄⠀⠀⢀⣀⣤⣤⣽⣛⣿⣿⣿⣿⣿⣿⣧⣤⣀⡀⠀⠀⠀⢸⡇⠀⠀
// ⠀⠀⠀⠸⠁⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀⢸⠃⠀⠀
// ⠀⠀⠀⠀⠀⠀⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠈⠀⠀⠀
// ⠀⠀⠀⣠⣴⣶⣶⣶⣿⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣦⣄⠀⠀⠀
// ⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀
// ⠀⢺⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀
// ⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠀⠀
// ⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠁⠀
//                contract by: primata 🐵

// TurdDAOAuctionOuthouse.sol is a modified version of Joepegs's AuctionHouse.sol:
// https://github.com/traderjoe-xyz/joepegs/blob/acf0ecf70577b9ad3a7969168f0f00e7ea375434/contracts/JoepegAuctionHouse.sol

import {SafeCast} from "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import {ERC165} from "lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {IERC20, SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "./Errors.sol";
import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
import {IProtocolFeeManager} from "./interfaces/IProtocolFeeManager.sol";
import {IWAVAX} from "./interfaces/IWAVAX.sol";

/**
 * @title TurdDAOAuctionOuthouse
 * @notice An auction house that supports running English and Dutch auctions on ERC721 tokens
 */
contract TurdDAOAuctionOuthouse is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    struct DutchAuction {
        address creator;
        uint96 startTime;
        address currency;
        uint96 endTime;
        uint256 nonce;
        uint256 startPrice;
        uint256 endPrice;
        uint256 dropInterval;
    }

    struct EnglishAuction {
        address creator;
        address currency;
        uint96 startTime;
        address lastBidder;
        uint96 endTime;
        uint256 nonce;
        uint256 lastBidPrice;
        uint256 startPrice;
    }

    uint256 public constant PERCENTAGE_PRECISION = 10000;

    address public immutable WAVAX;

    ICurrencyManager public currencyManager;
    mapping(address => bool) public approved;

    address public turds;

    /// @notice Stores latest auction nonce per user
    /// @dev (user address => latest nonce)
    mapping(address => uint256) public userLatestAuctionNonce;

    /// @notice Stores Dutch Auction data for NFTs
    /// @dev (collection address => token id => dutch auction)
    mapping(address => mapping(uint256 => DutchAuction)) public dutchAuctions;

    /// @notice Stores English Auction data for NFTs
    /// @dev (collection address => token id => english auction)
    mapping(address => mapping(uint256 => EnglishAuction)) public englishAuctions;

    /// @notice Required minimum percent increase from last bid in order to
    /// place a new bid on an English Auction
    uint256 public englishAuctionMinBidIncrementPct;

    /// @notice Represents both:
    /// - Number of seconds before an English Auction ends where any new
    ///   bid will extend the auction's end time
    /// - Number of seconds to extend an English Auction's end time by
    uint96 public englishAuctionRefreshTime;

    event DutchAuctionStart(
        address indexed creator,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 startPrice,
        uint256 endPrice,
        uint96 startTime,
        uint96 endTime,
        uint256 dropInterval
    );
    event DutchAuctionSettle(
        address indexed creator,
        address buyer,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 price
    );
    event DutchAuctionCancel(
        address indexed caller,
        address creator,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce
    );

    event EnglishAuctionStart(
        address indexed creator,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 startPrice,
        uint96 startTime,
        uint96 endTime
    );
    event EnglishAuctionPlaceBid(
        address indexed creator,
        address bidder,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 bidAmount,
        uint96 endTimeExtension
    );
    event EnglishAuctionSettle(
        address indexed creator,
        address buyer,
        address currency,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce,
        uint256 price
    );
    event EnglishAuctionCancel(
        address indexed caller,
        address creator,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 nonce
    );

    event CurrencyManagerSet(
        address indexed oldCurrencyManager,
        address indexed newCurrencyManager
    );
    event EnglishAuctionMinBidIncrementPctSet(
        uint256 indexed oldEnglishAuctionMinBidIncrementPct,
        uint256 indexed newEnglishAuctionMinBidIncrementPct
    );
    event EnglishAuctionRefreshTimeSet(
        uint96 indexed oldEnglishAuctionRefreshTime,
        uint96 indexed newEnglishAuctionRefreshTime
    );
    event ProtocolFeeManagerSet(
        address indexed oldProtocolFeeManager,
        address indexed newProtocolFeeManager
    );
    event turdsSet(address indexed oldTurds, address indexed newTurds);
    event ApprovalSet(address indexed oldAuctionManager, bool state);

    event FlushedPayment(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );

    modifier isSupportedCurrency(IERC20 _currency) {
        if (!currencyManager.isCurrencyWhitelisted(address(_currency))) {
            revert TurdDAOAuctionOuthouse__UnsupportedCurrency();
        } else {
            _;
        }
    }

    modifier isValidStartTime(uint256 _startTime) {
        if (_startTime < block.timestamp) {
            revert TurdDAOAuctionOuthouse__InvalidStartTime();
        } else {
            _;
        }
    }

    modifier onlyApproved() {
        if (!approved[msg.sender]) {
            revert TurdDAOAuctionOuthouse__OnlyApproved();
        } else {
            _;
        }
    }


    ///  @notice Constructor
    ///  @param _wavax address of WAVAX
    ///  @param _englishAuctionMinBidIncrementPct minimum bid increment percentage for English Auctions
    ///  @param _englishAuctionRefreshTime refresh time for English auctions
    ///  @param _currencyManager currency manager address
    ///  @param _auctionManager auction manager address
    ///  @param _turds protocol fee recipient
    constructor(
        address _wavax,
        uint256 _englishAuctionMinBidIncrementPct,
        uint96 _englishAuctionRefreshTime,
        address _currencyManager,
        address _auctionManager,
        address _turds
    ) {
        WAVAX = _wavax;
        _updateEnglishAuctionMinBidIncrementPct(_englishAuctionMinBidIncrementPct);
        _updateEnglishAuctionRefreshTime(_englishAuctionRefreshTime);
        _updateCurrencyManager(_currencyManager);
        _updateApproved(_auctionManager, true);
        _updateTurds(_turds);
    }

    /// @notice Required implementation for IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Starts an English Auction for an ERC721 token
    /// @dev Note this requires the auction house to hold the ERC721 token in escrow
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _duration number of seconds for English Auction to run
    /// @param _startPrice minimum starting bid price
    function startEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _startPrice
    ) external whenNotPaused isSupportedCurrency(_currency) nonReentrant {
        _addEnglishAuction(
            _collection,
            _tokenId,
            _currency,
            block.timestamp.toUint96(),
            _duration,
            _startPrice
        );
    }

    /// @notice Schedules an English Auction for an ERC721 token
    /// @dev Note this requires the auction house to hold the ERC721 token in escrow
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _startTime time to start the auction
    /// @param _duration number of seconds for English Auction to run
    /// @param _startPrice minimum starting bid price
    function scheduleEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _startPrice
    )
        external
        whenNotPaused
        isSupportedCurrency(_currency)
        isValidStartTime(_startTime)
        nonReentrant
    {
        _addEnglishAuction(_collection, _tokenId, _currency, _startTime, _duration, _startPrice);
    }

    function _addEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _startPrice
    ) internal onlyApproved {
        if (_duration == 0) {
            revert TurdDAOAuctionOuthouse__InvalidDuration();
        }
        address collectionAddress = address(_collection);
        if (englishAuctions[collectionAddress][_tokenId].creator != address(0)) {
            revert TurdDAOAuctionOuthouse__AuctionAlreadyExists();
        }

        uint256 nonce = userLatestAuctionNonce[msg.sender];
        EnglishAuction memory auction = EnglishAuction({
            creator: msg.sender,
            nonce: nonce,
            currency: address(_currency),
            lastBidder: address(0),
            lastBidPrice: 0,
            startTime: _startTime,
            endTime: _startTime + _duration,
            startPrice: _startPrice
        });
        englishAuctions[collectionAddress][_tokenId] = auction;
        userLatestAuctionNonce[msg.sender] = nonce + 1;

        // Hold ERC721 token in escrow
        _collection.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit EnglishAuctionStart(
            auction.creator,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.startPrice,
            _startTime,
            auction.endTime
        );
    }

    /// @notice Place bid on a running English Auction
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _amount amount of currency to bid
    function placeEnglishAuctionBid(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
        EnglishAuction memory auction = englishAuctions[address(_collection)][_tokenId];
        address currency = auction.currency;
        if (currency == address(0)) {
            revert TurdDAOAuctionOuthouse__NoAuctionExists();
        }

        IERC20(currency).safeTransferFrom(msg.sender, address(this), _amount);
        _placeEnglishAuctionBid(_collection, _tokenId, _amount, auction);
    }

    /// @notice Place bid on a running English Auction using AVAX and/or WAVAX
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _wavaxAmount amount of WAVAX to bid
    function placeEnglishAuctionBidWithAVAXAndWAVAX(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _wavaxAmount
    ) external payable whenNotPaused nonReentrant {
        EnglishAuction memory auction = englishAuctions[address(_collection)][_tokenId];
        address currency = auction.currency;
        if (currency != WAVAX) {
            revert TurdDAOAuctionOuthouse__CurrencyMismatch();
        }

        if (msg.value > 0) {
            // Wrap AVAX into WAVAX
            IWAVAX(WAVAX).deposit{value: msg.value}();
        }
        if (_wavaxAmount > 0) {
            IERC20(WAVAX).safeTransferFrom(msg.sender, address(this), _wavaxAmount);
        }
        _placeEnglishAuctionBid(_collection, _tokenId, msg.value + _wavaxAmount, auction);
    }

    /// @notice Settles an English Auction
    /// @dev Note:
    /// - Can be called by creator at any time (including before the auction's end time to accept the
    ///   current latest bid)
    /// - Can be called by anyone after the auction ends
    /// - Transfers funds and fees appropriately to seller, royalty receiver, and protocol fee recipient
    /// - Transfers ERC721 token to last highest bidder
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function settleEnglishAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        address collectionAddress = address(_collection);
        EnglishAuction memory auction = englishAuctions[collectionAddress][_tokenId];
        if (auction.creator == address(0)) {
            revert TurdDAOAuctionOuthouse__NoAuctionExists();
        }
        if (auction.lastBidPrice == 0) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionCannotSettleWithoutBid();
        }
        if (block.timestamp < auction.startTime) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionCannotSettleUnstartedAuction();
        }
        if (msg.sender != auction.creator && block.timestamp < auction.endTime) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionOnlyCreatorCanSettleBeforeEndTime();
        }

        delete englishAuctions[collectionAddress][_tokenId];

        // Settle auction using latest bid
        _transferFeesAndFunds(
            collectionAddress,
            _tokenId,
            IERC20(auction.currency),
            address(this),
            auction.creator,
            auction.lastBidPrice
        );

        _collection.safeTransferFrom(address(this), auction.lastBidder, _tokenId);

        emit EnglishAuctionSettle(
            auction.creator,
            auction.lastBidder,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.lastBidPrice
        );
    }

    /// @notice Cancels an English Auction
    /// @dev Note:
    /// - Can only be called by auction creator
    /// - Can only be cancelled if no bids have been placed
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function cancelEnglishAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        address collectionAddress = address(_collection);
        EnglishAuction memory auction = englishAuctions[collectionAddress][_tokenId];
        if (msg.sender != auction.creator) {
            revert TurdDAOAuctionOuthouse__OnlyAuctionCreatorCanCancel();
        }
        if (auction.lastBidder != address(0)) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionCannotCancelWithExistingBid();
        }

        delete englishAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        emit EnglishAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Only owner function to cancel an English Auction in case of emergencies
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function emergencyCancelEnglishAuction(IERC721 _collection, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        address collectionAddress = address(_collection);
        EnglishAuction memory auction = englishAuctions[collectionAddress][_tokenId];
        if (auction.creator == address(0)) {
            revert TurdDAOAuctionOuthouse__NoAuctionExists();
        }

        address lastBidder = auction.lastBidder;
        uint256 lastBidPrice = auction.lastBidPrice;

        delete englishAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        if (lastBidPrice > 0) {
            IERC20(auction.currency).safeTransfer(lastBidder, lastBidPrice);
        }

        emit EnglishAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Starts a Dutch Auction for an ERC721 token
    /// @dev Note:
    /// - Requires the auction house to hold the ERC721 token in escrow
    /// - Drops in price every `dutchAuctionDropInterval` seconds in equal
    ///   amounts
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _duration number of seconds for Dutch Auction to run
    /// @param _dropInterval number of seconds between each drop in price
    /// @param _startPrice starting sell price
    /// @param _endPrice ending sell price
    function startDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice
    ) external whenNotPaused isSupportedCurrency(_currency) nonReentrant {
        _addDutchAuction(
            _collection,
            _tokenId,
            _currency,
            block.timestamp.toUint96(),
            _duration,
            _dropInterval,
            _startPrice,
            _endPrice
        );
    }

    /// @notice Schedules a Dutch Auction for an ERC721 token
    /// @dev Note:
    /// - Requires the auction house to hold the ERC721 token in escrow
    /// - Drops in price every `dutchAuctionDropInterval` seconds in equal
    ///   amounts
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of currency to sell ERC721 token for
    /// @param _startTime time to start the auction
    /// @param _duration number of seconds for Dutch Auction to run
    /// @param _dropInterval number of seconds between each drop in price
    /// @param _startPrice starting sell price
    /// @param _endPrice ending sell price
    function scheduleDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice
    )
        external
        whenNotPaused
        isSupportedCurrency(_currency)
        isValidStartTime(_startTime)
        nonReentrant
    {
        _addDutchAuction(
            _collection,
            _tokenId,
            _currency,
            _startTime,
            _duration,
            _dropInterval,
            _startPrice,
            _endPrice
        );
    }

    function _addDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice
    ) internal onlyApproved {
        if (_duration == 0 || _duration < _dropInterval) {
            revert TurdDAOAuctionOuthouse__InvalidDuration();
        }
        if (_dropInterval == 0) {
            revert TurdDAOAuctionOuthouse__InvalidDropInterval();
        }
        address collectionAddress = address(_collection);
        if (dutchAuctions[collectionAddress][_tokenId].creator != address(0)) {
            revert TurdDAOAuctionOuthouse__AuctionAlreadyExists();
        }
        if (_startPrice <= _endPrice || _endPrice == 0) {
            revert TurdDAOAuctionOuthouse__DutchAuctionInvalidStartEndPrice();
        }

        DutchAuction memory auction = DutchAuction({
            creator: msg.sender,
            nonce: userLatestAuctionNonce[msg.sender],
            currency: address(_currency),
            startPrice: _startPrice,
            endPrice: _endPrice,
            startTime: _startTime,
            endTime: _startTime + _duration,
            dropInterval: _dropInterval
        });
        dutchAuctions[collectionAddress][_tokenId] = auction;
        userLatestAuctionNonce[msg.sender] += 1;

        _collection.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit DutchAuctionStart(
            auction.creator,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.startPrice,
            auction.endPrice,
            auction.startTime,
            auction.endTime,
            auction.dropInterval
        );
    }

    /// @notice Settles a Dutch Auction
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function settleDutchAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        DutchAuction memory auction = dutchAuctions[address(_collection)][_tokenId];
        _settleDutchAuction(_collection, _tokenId, auction);
    }

    /// @notice Settles a Dutch Auction with AVAX and/or WAVAX
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function settleDutchAuctionWithAVAXAndWAVAX(IERC721 _collection, uint256 _tokenId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        DutchAuction memory auction = dutchAuctions[address(_collection)][_tokenId];
        address currency = auction.currency;
        if (currency != WAVAX) {
            revert TurdDAOAuctionOuthouse__CurrencyMismatch();
        }

        _settleDutchAuction(_collection, _tokenId, auction);
    }

    /// @notice Calculates current Dutch Auction sale price for an ERC721 token.
    /// Returns 0 if the auction hasn't started yet.
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @return current Dutch Auction sale price for specified ERC721 token
    function getDutchAuctionSalePrice(address _collection, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        DutchAuction memory auction = dutchAuctions[_collection][_tokenId];
        if (block.timestamp < auction.startTime) {
            return 0;
        }
        if (block.timestamp >= auction.endTime) {
            return auction.endPrice;
        }
        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 elapsedSteps = timeElapsed / auction.dropInterval;
        uint256 totalPossibleSteps = (auction.endTime - auction.startTime) / auction.dropInterval;

        uint256 priceDifference = auction.startPrice - auction.endPrice;

        return auction.startPrice - (elapsedSteps * priceDifference) / totalPossibleSteps;
    }

    /// @notice Cancels a running Dutch Auction
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function cancelDutchAuction(IERC721 _collection, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        address collectionAddress = address(_collection);
        DutchAuction memory auction = dutchAuctions[collectionAddress][_tokenId];
        if (msg.sender != auction.creator) {
            revert TurdDAOAuctionOuthouse__OnlyAuctionCreatorCanCancel();
        }

        delete dutchAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        emit DutchAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Only owner function to cancel a Dutch Auction in case of emergencies
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function emergencyCancelDutchAuction(IERC721 _collection, uint256 _tokenId)
        external
        nonReentrant
        onlyOwner
    {
        address collectionAddress = address(_collection);
        DutchAuction memory auction = dutchAuctions[collectionAddress][_tokenId];
        if (auction.creator == address(0)) {
            revert TurdDAOAuctionOuthouse__NoAuctionExists();
        }

        delete dutchAuctions[collectionAddress][_tokenId];

        _collection.safeTransferFrom(address(this), auction.creator, _tokenId);

        emit DutchAuctionCancel(
            msg.sender,
            auction.creator,
            collectionAddress,
            _tokenId,
            auction.nonce
        );
    }

    /// @notice Update `englishAuctionMinBidIncrementPct`
    /// @param _englishAuctionMinBidIncrementPct new minimum bid increment percetange for English auctions
    function updateEnglishAuctionMinBidIncrementPct(uint256 _englishAuctionMinBidIncrementPct)
        external
        onlyOwner
    {
        _updateEnglishAuctionMinBidIncrementPct(_englishAuctionMinBidIncrementPct);
    }

    /// @notice Update `englishAuctionMinBidIncrementPct`
    /// @param _englishAuctionMinBidIncrementPct new minimum bid increment percetange for English auctions
    function _updateEnglishAuctionMinBidIncrementPct(uint256 _englishAuctionMinBidIncrementPct)
        internal
    {
        if (
            _englishAuctionMinBidIncrementPct == 0 ||
            _englishAuctionMinBidIncrementPct > PERCENTAGE_PRECISION
        ) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionInvalidMinBidIncrementPct();
        }

        uint256 oldEnglishAuctionMinBidIncrementPct = englishAuctionMinBidIncrementPct;
        englishAuctionMinBidIncrementPct = _englishAuctionMinBidIncrementPct;
        emit EnglishAuctionMinBidIncrementPctSet(
            oldEnglishAuctionMinBidIncrementPct,
            _englishAuctionMinBidIncrementPct
        );
    }

    /// @notice Update `englishAuctionRefreshTime`
    /// @param _englishAuctionRefreshTime new refresh time for English auctions
    function updateEnglishAuctionRefreshTime(uint96 _englishAuctionRefreshTime) external onlyOwner {
        _updateEnglishAuctionRefreshTime(_englishAuctionRefreshTime);
    }

    /// @notice Update `englishAuctionRefreshTime`
    /// @param _englishAuctionRefreshTime new refresh time for English auctions
    function _updateEnglishAuctionRefreshTime(uint96 _englishAuctionRefreshTime) internal {
        if (_englishAuctionRefreshTime == 0) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionInvalidRefreshTime();
        }
        uint96 oldEnglishAuctionRefreshTime = englishAuctionRefreshTime;
        englishAuctionRefreshTime = _englishAuctionRefreshTime;
        emit EnglishAuctionRefreshTimeSet(oldEnglishAuctionRefreshTime, englishAuctionRefreshTime);
    }

    /// @notice Update currency manager
    /// @param _currencyManager new currency manager address
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        _updateCurrencyManager(_currencyManager);
    }

    /// @notice Update currency manager
    /// @param _currencyManager new currency manager address
    function _updateCurrencyManager(address _currencyManager) internal {
        if (_currencyManager == address(0)) {
            revert TurdDAOAuctionOuthouse__ExpectedNonNullAddress();
        }
        address oldCurrencyManagerAddress = address(currencyManager);
        currencyManager = ICurrencyManager(_currencyManager);
        emit CurrencyManagerSet(oldCurrencyManagerAddress, _currencyManager);
    }

    /// @notice Update protocol fee recipient
    /// @param _turds new recipient for protocol fees
    function updateTurds(address _turds) external onlyOwner {
        _updateTurds(_turds);
    }

    /// @notice Update protocol fee recipient
    /// @param _turds new recipient for protocol fees
    function _updateTurds(address _turds) internal {
        if (_turds == address(0)) {
            revert TurdDAOAuctionOuthouse__ExpectedNonNullAddress();
        }
        address oldturds = turds;
        turds = _turds;
        emit turdsSet(oldturds, _turds);
    }

    /// @notice Update royalty fee manager
    /// @param _approved new fee manager address
    function addApproved(address _approved) external onlyOwner {
        _updateApproved(_approved, true);
    }

    /// @notice Update royalty fee manager
    /// @param _approved new fee manager address
    function removeApproved(address _approved) external onlyOwner {
        _updateApproved(_approved, false);
    }

    /// @notice Update auction manager
    /// @param _approved new auction manager address
    function _updateApproved(address _approved, bool _state) internal {
        if (_approved == address(0)) {
            revert TurdDAOAuctionOuthouse__ExpectedNonNullAddress();
        }

        approved[_approved] = _state;
        emit ApprovalSet(_approved, _state);
    }


    /// @notice Place bid on a running English Auction
    /// @dev Note:
    /// - Requires holding the bid in escrow until either a higher bid is placed
    ///   or the auction is settled
    /// - If a bid already exists, only bids at least `englishAuctionMinBidIncrementPct`
    ///   percent higher can be placed
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _bidAmount amount of currency to bid
    function _placeEnglishAuctionBid(
        IERC721 _collection,
        uint256 _tokenId,
        uint256 _bidAmount,
        EnglishAuction memory auction
    ) internal {
        if (auction.creator == address(0)) {
            revert TurdDAOAuctionOuthouse__NoAuctionExists();
        }
        if (_bidAmount == 0) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionInsufficientBidAmount();
        }
        if (msg.sender == auction.creator) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionCreatorCannotPlaceBid();
        }
        if (block.timestamp < auction.startTime) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionCannotBidOnUnstartedAuction();
        }
        if (block.timestamp >= auction.endTime) {
            revert TurdDAOAuctionOuthouse__EnglishAuctionCannotBidOnEndedAuction();
        }

        uint96 endTimeExtension;
        if (auction.endTime - block.timestamp <= englishAuctionRefreshTime) {
            endTimeExtension = englishAuctionRefreshTime;
            auction.endTime += endTimeExtension;
        }

        if (auction.lastBidPrice == 0) {
            if (_bidAmount < auction.startPrice) {
                revert TurdDAOAuctionOuthouse__EnglishAuctionInsufficientBidAmount();
            }
            auction.lastBidder = msg.sender;
            auction.lastBidPrice = _bidAmount;
        } else {
            if (msg.sender == auction.lastBidder) {
                // If bidder is same as last bidder, ensure their bid is at least
                // `englishAuctionMinBidIncrementPct` percent of their previous bid
                if (
                    _bidAmount * PERCENTAGE_PRECISION <
                    auction.lastBidPrice * englishAuctionMinBidIncrementPct
                ) {
                    revert TurdDAOAuctionOuthouse__EnglishAuctionInsufficientBidAmount();
                }
                auction.lastBidPrice += _bidAmount;
            } else {
                // Ensure bid is at least `englishAuctionMinBidIncrementPct` percent greater
                // than last bid
                if (
                    _bidAmount * PERCENTAGE_PRECISION <
                    auction.lastBidPrice * (PERCENTAGE_PRECISION + englishAuctionMinBidIncrementPct)
                ) {
                    revert TurdDAOAuctionOuthouse__EnglishAuctionInsufficientBidAmount();
                }

                address previousBidder = auction.lastBidder;
                uint256 previousBidPrice = auction.lastBidPrice;

                auction.lastBidder = msg.sender;
                auction.lastBidPrice = _bidAmount;

                // Transfer previous bid back to bidder
                IERC20(auction.currency).safeTransfer(previousBidder, previousBidPrice);
            }
        }

        address collectionAddress = address(_collection);
        englishAuctions[collectionAddress][_tokenId] = auction;

        emit EnglishAuctionPlaceBid(
            auction.creator,
            auction.lastBidder,
            auction.currency,
            collectionAddress,
            _tokenId,
            auction.nonce,
            auction.lastBidPrice,
            endTimeExtension
        );
    }

    /// @notice Settles a Dutch Auction
    /// @dev Note:
    /// - Transfers funds and fees appropriately to seller, royalty receiver, and protocol fee recipient
    /// - Transfers ERC721 token to buyer
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    function _settleDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        DutchAuction memory _auction
    ) internal {
        if (_auction.creator == address(0)) {
            revert TurdDAOAuctionOuthouse__NoAuctionExists();
        }
        if (msg.sender == _auction.creator) {
            revert TurdDAOAuctionOuthouse__DutchAuctionCreatorCannotSettle();
        }
        if (block.timestamp < _auction.startTime) {
            revert TurdDAOAuctionOuthouse__DutchAuctionCannotSettleUnstartedAuction();
        }

        // Get auction sale price
        address collectionAddress = address(_collection);
        uint256 salePrice = getDutchAuctionSalePrice(collectionAddress, _tokenId);

        delete dutchAuctions[collectionAddress][_tokenId];

        if (_auction.currency == WAVAX) {
            // Transfer WAVAX if needed
            if (salePrice > msg.value) {
                IERC20(WAVAX).safeTransferFrom(msg.sender, address(this), salePrice - msg.value);
            }

            // Wrap AVAX if needed
            if (msg.value > 0) {
                IWAVAX(WAVAX).deposit{value: msg.value}();
            }

            // Refund excess AVAX if needed
            if (salePrice < msg.value) {
                IERC20(WAVAX).safeTransfer(msg.sender, msg.value - salePrice);
            }

            _transferFeesAndFunds(
                collectionAddress,
                _tokenId,
                IERC20(WAVAX),
                address(this),
                _auction.creator,
                salePrice
            );
        } else {
            _transferFeesAndFunds(
                collectionAddress,
                _tokenId,
                IERC20(_auction.currency),
                msg.sender,
                _auction.creator,
                salePrice
            );
        }

        _collection.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit DutchAuctionSettle(
            _auction.creator,
            msg.sender,
            _auction.currency,
            collectionAddress,
            _tokenId,
            _auction.nonce,
            salePrice
        );
    }

    /// @notice Transfer fees and funds to royalty recipient, protocol, and seller
    /// @param _collection address of ERC721 token
    /// @param _tokenId token id of ERC721 token
    /// @param _currency address of token being used for the purchase (e.g. USDC)
    /// @param _from sender of the funds
    /// @param _to seller's recipient
    /// @param _amount amount being transferred (in currency)
    function _transferFeesAndFunds(
        address _collection,
        uint256 _tokenId,
        IERC20 _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // Initialize the final amount that is transferred to seller

        _currency.safeTransferFrom(_from, turds, _amount);

        emit FlushedPayment(_collection, _tokenId, turds, address(_currency), _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TurdDAOAuctionOuthouse
error TurdDAOAuctionOuthouse__AuctionAlreadyExists();
error TurdDAOAuctionOuthouse__CurrencyMismatch();
error TurdDAOAuctionOuthouse__ExpectedNonNullAddress();
error TurdDAOAuctionOuthouse__ExpectedNonZeroFinalSellerAmount();
error TurdDAOAuctionOuthouse__FeesHigherThanExpected();
error TurdDAOAuctionOuthouse__InvalidDropInterval();
error TurdDAOAuctionOuthouse__InvalidDuration();
error TurdDAOAuctionOuthouse__InvalidMinPercentageToAsk();
error TurdDAOAuctionOuthouse__InvalidStartTime();
error TurdDAOAuctionOuthouse__NoAuctionExists();
error TurdDAOAuctionOuthouse__OnlyAuctionCreatorCanCancel();
error TurdDAOAuctionOuthouse__OnlyManager();
error TurdDAOAuctionOuthouse__UnsupportedCurrency();
error TurdDAOAuctionOuthouse__OnlyApproved();

error TurdDAOAuctionOuthouse__EnglishAuctionCannotBidOnUnstartedAuction();
error TurdDAOAuctionOuthouse__EnglishAuctionCannotBidOnEndedAuction();
error TurdDAOAuctionOuthouse__EnglishAuctionCannotCancelWithExistingBid();
error TurdDAOAuctionOuthouse__EnglishAuctionCannotSettleUnstartedAuction();
error TurdDAOAuctionOuthouse__EnglishAuctionCannotSettleWithoutBid();
error TurdDAOAuctionOuthouse__EnglishAuctionCreatorCannotPlaceBid();
error TurdDAOAuctionOuthouse__EnglishAuctionInsufficientBidAmount();
error TurdDAOAuctionOuthouse__EnglishAuctionInvalidMinBidIncrementPct();
error TurdDAOAuctionOuthouse__EnglishAuctionInvalidRefreshTime();
error TurdDAOAuctionOuthouse__EnglishAuctionOnlyCreatorCanSettleBeforeEndTime();

error TurdDAOAuctionOuthouse__DutchAuctionCannotSettleUnstartedAuction();
error TurdDAOAuctionOuthouse__DutchAuctionCreatorCannotSettle();
error TurdDAOAuctionOuthouse__DutchAuctionInsufficientAmountToSettle();
error TurdDAOAuctionOuthouse__DutchAuctionInvalidStartEndPrice();

// RoyaltyFeeManager
error RoyaltyFeeManager__InvalidRoyaltyFeeRegistryV2();
error RoyaltyFeeManager__RoyaltyFeeRegistryV2AlreadyInitialized();

// RoyaltyFeeRegistryV2
error RoyaltyFeeRegistryV2__InvalidMaxNumRecipients();
error RoyaltyFeeRegistryV2__RoyaltyFeeCannotBeZero();
error RoyaltyFeeRegistryV2__RoyaltyFeeLimitTooHigh();
error RoyaltyFeeRegistryV2__RoyaltyFeeRecipientCannotBeNullAddr();
error RoyaltyFeeRegistryV2__RoyaltyFeeSetterCannotBeNullAddr();
error RoyaltyFeeRegistryV2__RoyaltyFeeTooHigh();
error RoyaltyFeeRegistryV2__TooManyFeeRecipients();

// RoyaltyFeeSetterV2
error RoyaltyFeeSetterV2__CollectionCannotSupportERC2981();
error RoyaltyFeeSetterV2__CollectionIsNotNFT();
error RoyaltyFeeSetterV2__NotCollectionAdmin();
error RoyaltyFeeSetterV2__NotCollectionOwner();
error RoyaltyFeeSetterV2__NotCollectionSetter();
error RoyaltyFeeSetterV2__SetterAlreadySet();

// PendingOwnable
error PendingOwnable__NotOwner();
error PendingOwnable__AddressZero();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();

// PendingOwnableUpgradeable
error PendingOwnableUpgradeable__NotOwner();
error PendingOwnableUpgradeable__AddressZero();
error PendingOwnableUpgradeable__NotPendingOwner();
error PendingOwnableUpgradeable__PendingOwnerAlreadySet();
error PendingOwnableUpgradeable__NoPendingOwner();

// SafeAccessControlEnumerable
error SafeAccessControlEnumerable__SenderMissingRoleAndIsNotOwner(
    bytes32 role,
    address sender
);
error SafeAccessControlEnumerable__RoleIsDefaultAdmin();

// SafeAccessControlEnumerableUpgradeable
error SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner(
    bytes32 role,
    address sender
);
error SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin();

// SafePausable
error SafePausable__AlreadyPaused();
error SafePausable__AlreadyUnpaused();

// SafePausableUpgradeable
error SafePausableUpgradeable__AlreadyPaused();
error SafePausableUpgradeable__AlreadyUnpaused();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProtocolFeeManager {
    function setDefaultProtocolFee(uint256 _defaultProtocolFee) external;

    function setProtocolFeeForCollection(
        address _collection,
        uint256 _protocolFee
    ) external;

    function unsetProtocolFeeForCollection(address _collection) external;

    function protocolFeeForCollection(address _collection)
        external
        view
        returns (uint256);

    function defaultProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IAuctionHouse {
    function startEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _startPrice
    ) external;

    function scheduleEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _startPrice
    ) external;

    function startDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice
    ) external;

    function scheduleDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _startTime,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice
    ) external;
}