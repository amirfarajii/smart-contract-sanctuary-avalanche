// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/security/PausableUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/ProxyCheckerUpgradeable.sol";
import "oz-custom/contracts/internal-upgradeable/BlacklistableUpgradeable.sol";
import "oz-custom/contracts/oz-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./libraries/Roles.sol";
import "./interfaces/IAuthority.sol";

contract Authority is
    IAuthority,
    UUPSUpgradeable,
    PausableUpgradeable,
    ProxyCheckerUpgradeable,
    BlacklistableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    /// @dev value is equal to keccak256("Authority_v1")
    bytes32 public constant VERSION =
        0x095dd5e04e0f3f5bce98e4ee904d9f7209827187c4201f036596b2f7fdd602e7;

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function init() external initializer {
        __Pausable_init_unchained();

        address sender = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);

        _grantRole(Roles.SIGNER_ROLE, sender);
        _grantRole(Roles.PAUSER_ROLE, sender);
        _grantRole(Roles.MINTER_ROLE, sender);
        _grantRole(Roles.OPERATOR_ROLE, sender);
        _grantRole(Roles.UPGRADER_ROLE, sender);

        _setRoleAdmin(Roles.PAUSER_ROLE, Roles.OPERATOR_ROLE);
        _setRoleAdmin(Roles.MINTER_ROLE, Roles.OPERATOR_ROLE);
    }

    function setRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    function requestAccess(bytes32 role) external whenNotPaused {
        address origin = _txOrigin();
        _checkRole(Roles.OPERATOR_ROLE, origin);

        address sender = _msgSender();
        _onlyProxy(sender, origin);

        _grantRole(Roles.PROXY_ROLE, sender);
        if (role != 0) _grantRole(role, sender);

        emit ProxyAccessGranted(sender);
    }

    function pause() external onlyRole(Roles.PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(Roles.PAUSER_ROLE) {
        _unpause();
    }

    function paused()
        public
        view
        override(IAuthority, PausableUpgradeable)
        returns (bool)
    {
        return PausableUpgradeable.paused();
    }

    function setUserStatus(
        address account_,
        bool status_
    )
        external
        override(BlacklistableUpgradeable, IBlacklistableUpgradeable)
        whenPaused
        onlyRole(Roles.PAUSER_ROLE)
    {
        _setUserStatus(account_, status_);
        if (status_) emit Blacklisted(account_);
        else emit Whitelisted(account_);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(Roles.UPGRADER_ROLE) {}

    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "oz-custom/contracts/oz-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

import "oz-custom/contracts/internal-upgradeable/interfaces/IBlacklistableUpgradeable.sol";

interface IAuthority is
    IBlacklistableUpgradeable,
    IAccessControlEnumerableUpgradeable
{
    event ProxyAccessGranted(address indexed proxy);

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool isPaused);

    function requestAccess(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Roles {
    bytes32 public constant PROXY_ROLE =
        0x77d72916e966418e6dc58a19999ae9934bef3f749f1547cde0a86e809f19c89b;
    bytes32 public constant SIGNER_ROLE =
        0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70;
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    bytes32 public constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    bytes32 public constant TREASURER_ROLE =
        0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07;
    bytes32 public constant FACTORY_ROLE =
        0xdfbefbf47cfe66b701d8cfdbce1de81c821590819cb07e71cb01b6602fb0ee27;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/utils/ContextUpgradeable.sol";
import "../oz-upgradeable/utils/structs/BitMapsUpgradeable.sol";

import "../libraries/Bytes32Address.sol";

import "./interfaces/IBlacklistableUpgradeable.sol";

abstract contract BlacklistableUpgradeable is
    ContextUpgradeable,
    IBlacklistableUpgradeable
{
    using Bytes32Address for address;
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    BitMapsUpgradeable.BitMap private _blacklisted;

    function __Blacklistable_init() internal onlyInitializing {}

    function __Blacklistable_init_unchained() internal onlyInitializing {}

    function setUserStatus(address account_, bool status) external virtual;

    function isBlacklisted(address account_) public view returns (bool) {
        return _blacklisted.get(account_.fillLast96Bits());
    }

    function _setUserStatus(address account_, bool status_) internal {
        _blacklisted.setTo(account_.fillFirst96Bits(), status_);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBlacklistableUpgradeable {
    event Blacklisted(address indexed account);
    event Whitelisted(address indexed account);

    function setUserStatus(address account_, bool status) external;

    function isBlacklisted(address account_) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../oz-upgradeable/proxy/utils/Initializable.sol";

error ProxyChecker__EOAUnallowed();
error ProxyChecker__ProxyUnallowed();

abstract contract ProxyCheckerUpgradeable is Initializable {
    modifier onlyEOA() {
        _onlyEOA(msg.sender);
        _;
    }

    function __ProxyChecker_init() internal onlyInitializing {}

    function __ProxyChecker_init_unchained() internal onlyInitializing {}

    function _onlyEOA(address sender_) internal view {
        _onlyEOA(sender_, _txOrigin());
    }

    function _onlyEOA(address msgSender_, address txOrigin_) internal view {
        if (_isProxyCall(msgSender_, txOrigin_) || _isProxy(msgSender_))
            revert ProxyChecker__ProxyUnallowed();
    }

    function _onlyProxy(address sender_) internal view {
        if (!_isProxyCall(sender_, _txOrigin()) && !_isProxy(sender_))
            revert ProxyChecker__EOAUnallowed();
    }

    function _onlyProxy(address msgSender_, address txOrigin_) internal view {
        if (!_isProxyCall(msgSender_, txOrigin_) && !_isProxy(msgSender_))
            revert ProxyChecker__EOAUnallowed();
    }

    function _isProxyCall(address msgSender_, address txOrigin_)
        internal
        pure
        returns (bool)
    {
        return msgSender_ != txOrigin_;
    }

    function _isProxy(address caller_) internal view returns (bool) {
        return caller_.code.length != 0;
    }

    function _txOrigin() internal view returns (address) {
        return tx.origin;
    }

    uint256[50] private _gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BitMap256.sol";

library Array {
    using BitMap256 for uint256;

    // 100 record ~= 60k gas
    function buildSet(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 length = arr_.length;
        {
            uint256 val;
            uint256 bitmap;
            for (uint256 i; i < length; ) {
                unchecked {
                    val = arr_[i];
                    while (length > i && bitmap.get(val)) val = arr_[--length];
                    bitmap = bitmap.set(arr_[i] = val);
                    ++i;
                }
            }
        }
        assembly {
            mstore(arr_, length)
        }
        return arr_;
    }

    function trimZero(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory res)
    {
        res = arr_;
        uint256 length = res.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
        assembly {
            mstore(res, counter)
        }
    }

    function trimZero(uint256[256] memory arr_, uint256 size_)
        internal
        pure
        returns (uint256[] memory res)
    {
        res = new uint256[](size_);
        uint256 length = arr_.length;
        uint256 counter;
        for (uint256 i; i < length; ) {
            unchecked {
                if (arr_[i] != 0) res[counter++] = arr_[i];
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///@dev can store up to 256 slots
library BitMap256 {
    struct BitMap {
        uint256 data;
    }

    function index(uint256 value_) internal pure returns (uint256) {
        return value_ & 0xff;
    }

    function indexHash(uint256 value) internal pure returns (uint256 idx) {
        assembly {
            mstore(0x00, value)
            idx := keccak256(0x00, 32)
        }
    }

    function unsafeGet(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            isSet := and(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
        }
    }

    function unsafeGet(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (bool isSet)
    {
        assembly {
            isSet := and(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function get(BitMap storage bitmap_, uint256 value_)
        internal
        view
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, value_)
            isSet := and(
                sload(bitmap_.slot),
                shl(and(keccak256(0x00, 32), 0xff), 1)
            )
        }
    }

    function get(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (bool isSet)
    {
        assembly {
            mstore(0x00, value_)
            isSet := and(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
        }
    }

    function setData(BitMap storage bitmap_, uint256 value) internal {
        assembly {
            sstore(bitmap_.slot, value)
        }
    }

    function setTo(
        BitMap storage bitmap_,
        uint256 value_,
        bool status_
    ) internal {
        if (status_) set(bitmap_, value_);
        else unset(bitmap_, value_);
    }

    function unsafeSet(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(value_, 0xff), 1))
            )
        }
    }

    function unsafeSet(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            bitmap := or(bitmap_, shl(and(value_, 0xff), 1))
        }
    }

    function set(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            sstore(
                bitmap_.slot,
                or(sload(bitmap_.slot), shl(and(keccak256(0x00, 32), 0xff), 1))
            )
        }
    }

    function set(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            mstore(0x00, value_)
            bitmap := or(bitmap_, shl(and(keccak256(0x00, 32), 0xff), 1))
        }
    }

    function unsafeUnset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            sstore(
                bitmap_.slot,
                and(sload(bitmap_.slot), not(shl(and(value_, 0xff), 1)))
            )
        }
    }

    function unsafeUnset(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            bitmap := and(bitmap_, not(shl(and(value_, 0xff), 1)))
        }
    }

    function unset(BitMap storage bitmap_, uint256 value_) internal {
        assembly {
            mstore(0x00, value_)
            sstore(
                bitmap_.slot,
                and(
                    sload(bitmap_.slot),
                    not(shl(and(keccak256(0x00, 32), 0xff), 1))
                )
            )
        }
    }

    function unset(uint256 bitmap_, uint256 value_)
        internal
        pure
        returns (uint256 bitmap)
    {
        assembly {
            mstore(0x00, value_)
            bitmap := and(bitmap_, not(shl(and(keccak256(0x00, 32), 0xff), 1)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(bytes32 bytesValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(address addressValue)
        internal
        pure
        returns (bytes32 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(uint256 uintValue)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(address addressValue)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.17;

import "./Array.sol";
import "./BitMap256.sol";

library EnumerableSet256 {
    using Array for uint256[256];
    using BitMap256 for uint256;
    using BitMap256 for BitMap256.BitMap;

    struct Set {
        uint256 length;
        // Storage of set values
        uint256[256] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        BitMap256.BitMap _indexes;
    }

    function _add(Set storage set, uint256 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values[value.index()] = value;
            unchecked {
                ++set.length;
            }
            return true;
        } else return false;
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, uint256 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._values[value.index()] == value
            ? value.index()
            : 0;

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            //uint256 toDeleteIndex;
            // uint256 lastIndex;
            // unchecked {
            //     //toDeleteIndex = valueIndex - 1;
            //     lastIndex = --set.length;
            // }

            set._values[valueIndex] = 0;

            // if (valueIndex != lastIndex) {
            //     uint256 lastValue = set._values[lastIndex];

            //     // Move the last value to the index where the value to delete is
            //     set._values[valueIndex] = lastValue;
            //     // Update the index for the moved value
            //     //set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            // }

            // Delete the slot where the moved value was stored
            //set._values.pop();

            // Delete the index for the deleted slot
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, uint256 value)
        private
        view
        returns (bool)
    {
        //return set._indexes[value] != 0;
        return set._values[value.index()] == value;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set.length;
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (uint256)
    {
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
    function _values(Set storage set) private view returns (uint256[] memory) {
        uint256[256] memory val = set._values;
        return val.trimZero(set.length);
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        uint256 val;
        assembly {
            val := value
        }
        return _add(set._inner, val);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        uint256 val;
        assembly {
            val := value
        }
        return _remove(set._inner, val);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        uint256 val;
        assembly {
            val := value
        }
        return _contains(set._inner, val);
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        uint256 val = _at(set._inner, index);
        bytes32 val_;
        assembly {
            val_ := val
        }
        return val_;
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory res)
    {
        uint256[] memory val = _values(set._inner);
        res = new bytes32[](val.length);
        assembly {
            res := val
        }
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _add(set._inner, store);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _remove(set._inner, store);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        uint256 store;
        assembly {
            store := value
        }
        return _contains(set._inner, store);
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address addr)
    {
        uint256 value = _at(set._inner, index);
        assembly {
            addr := value
        }
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256[] memory store = _values(set._inner);
        address[] memory result = new address[](store.length);

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
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
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
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        return _values(set._inner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../../libraries/EnumerableSet256.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is
    IAccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
{
    function __AccessControlEnumerable_init() internal onlyInitializing {}

    function __AccessControlEnumerable_init_unchained()
        internal
        onlyInitializing
    {}

    using EnumerableSet256 for EnumerableSet256.AddressSet;

    mapping(bytes32 => EnumerableSet256.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId ==
            type(IAccessControlEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getAllRoleMembers(bytes32 role_)
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return _roleMembers[role_].values();
    }

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
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";

import "../../libraries/BitMap256.sol";
import "../../libraries/Bytes32Address.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    using Bytes32Address for address;
    using BitMap256 for BitMap256.BitMap;

    function __AccessControl_init() internal onlyInitializing {}

    function __AccessControl_init_unchained() internal onlyInitializing {}

    mapping(bytes32 => bytes32) private _adminRoles;
    mapping(bytes32 => BitMap256.BitMap) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _hasRole(uint256(role), account.fillLast12Bytes());
    }

    function _hasRole(uint256 role, bytes32 bytes32Addr)
        internal
        view
        virtual
        returns (bool)
    {
        return _roles[bytes32Addr].unsafeGet(role);
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account))
            revert AccessControl__RoleMissing(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _adminRoles[role];
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        if (account != _msgSender()) revert AccessControl__Unauthorized();
        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _adminRoles[role] = adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (_grantRole(uint256(role), account.fillLast12Bytes()))
            emit RoleGranted(role, account, _msgSender());
    }

    function _grantRole(uint256 role, bytes32 account)
        internal
        virtual
        returns (bool)
    {
        if (!_hasRole(role, account)) {
            _roles[account].unsafeSet(role);
            return true;
        }
        return false;
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (_revokeRole(uint256(role), account.fillLast12Bytes())) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _revokeRole(uint256 role, bytes32 account)
        internal
        virtual
        returns (bool)
    {
        if (_hasRole(role, account)) {
            _roles[account].unsafeUnset(role);
            return true;
        }
        return false;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
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
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getAllRoleMembers(bytes32 role_)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    error AccessControl__Unauthorized();
    error AccessControl__RoleMissing(bytes32 role, address account);
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

    function DEFAULT_ADMIN_ROLE() external pure returns (bytes32);
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
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

error ERC1967UpgradeUpgradeable__NonZeroAddress();
error ERC1967UpgradeUpgradeable__ExecutionFailed();
error ERC1967UpgradeUpgradeable__TargetIsNotContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
error ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
error ERC1967UpgradeUpgradeable__DelegateCallToNonContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotContract();

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!_isContract(newImplementation))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT)
                    revert ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
            } catch {
                revert ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
            }

            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
        if (newAdmin == address(0))
            revert ERC1967UpgradeUpgradeable__NonZeroAddress();
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        if (!_isContract(newBeacon))
            revert ERC1967UpgradeUpgradeable__TargetIsNotContract();
        if (!_isContract(IBeaconUpgradeable(newBeacon).implementation()))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
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
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        if (!_isContract(target))
            revert ERC1967UpgradeUpgradeable__DelegateCallToNonContract();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata);
    }

    function _isContract(address addr_) internal view returns (bool) {
        return addr_.code.length != 0;
    }

    function _verifyCallResult(bool success, bytes memory returndata)
        internal
        pure
        returns (bytes memory)
    {
        if (success) return returndata;
        else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            } else revert ERC1967UpgradeUpgradeable__ExecutionFailed();
        }
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

//import "../../utils/AddressUpgradeable.sol";
error Initializable__Initializing();
error Initializable__NotInitializing();
error Initializable__AlreadyInitialized();

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
    uint256 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    uint256 private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint256 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _initializing != 2;
        uint256 initialized = _initialized;
        if (
            !((isTopLevelCall && initialized == 0) ||
                (initialized == 1 && address(this).code.length == 0))
        ) revert Initializable__AlreadyInitialized();

        _initialized = 1;
        if (isTopLevelCall) _initializing = 2;
        _;
        if (isTopLevelCall) {
            _initializing = 1;
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
    modifier reinitializer(uint256 version) {
        if (_initializing != 1 || _initialized >= version)
            revert Initializable__AlreadyInitialized();
        _initialized = version & ~uint8(0);
        _initializing = 2;
        _;
        _initializing = 1;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        if (_initializing != 2) revert Initializable__NotInitializing();
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        if (_initializing != 1) revert Initializable__Initializing();
        if (_initialized < ~uint8(0)) {
            _initialized = ~uint8(0);
            emit Initialized(~uint8(0));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

error UUPSUpgradeable__OnlyCall();
error UUPSUpgradeable__OnlyDelegateCall();
error UUPSUpgradeable__OnlyActiveProxy();

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
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

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
        if (address(this) == __self) revert UUPSUpgradeable__OnlyDelegateCall();
        if (_getImplementation() != __self)
            revert UUPSUpgradeable__OnlyActiveProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        if (address(this) != __self) revert UUPSUpgradeable__OnlyCall();
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
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
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
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";

error Pausable__Paused();
error Pausable__NotPaused();

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    uint256 private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = 1;
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
    function paused() public view virtual returns (bool isPaused) {
        assembly {
            isPaused := eq(2, sload(_paused.slot))
        }
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) revert Pausable__Paused();
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) revert Pausable__NotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = 2;
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
        _paused = 1;
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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
    function getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot)
        internal
        pure
        returns (BooleanSlot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot)
        internal
        pure
        returns (Bytes32Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot)
        internal
        pure
        returns (Uint256Slot storage r)
    {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        return bitmap._data[index >> 8] & (1 << (index & 0xff)) != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) set(bitmap, index);
        else unset(bitmap, index);
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap._data[index >> 8] |= 1 << (index & 0xff);
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap._data[index >> 8] &= ~(1 << (index & 0xff));
    }
}