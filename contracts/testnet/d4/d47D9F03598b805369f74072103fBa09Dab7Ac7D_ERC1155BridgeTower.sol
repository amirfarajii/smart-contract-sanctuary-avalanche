// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../../securitize/WhitelistableUpgradeable.sol";

import "../access/PartnerAccessControl.sol";
import "../access/MinterAccessControl.sol";

import "../IsPrivateCollection.sol";

import "./ERC1155Base.sol";

contract ERC1155BridgeTower is
    ERC1155Base,
    IsPrivateCollection,
    MinterAccessControl,
    PartnerAccessControl,
    WhitelistableUpgradeable
{
    event CreateERC1155BridgeTower(address owner, string name, string symbol);
    event CreateERC1155BridgeTowerUser(
        address owner,
        string name,
        string symbol
    );

    function __ERC1155BridgeTowerUser_init(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI,
        address[] memory operators,
        address transferProxy,
        address lazyTransferProxy,
        address securitizeRegistryProxy,
        address contractsRegistryProxy,
        uint256 lockPeriod
    ) external virtual {
        __ERC1155BridgeTower_init_unchained(
            _name,
            _symbol,
            baseURI,
            contractURI,
            transferProxy,
            lazyTransferProxy,
            securitizeRegistryProxy,
            contractsRegistryProxy,
            lockPeriod
        );

        for (uint256 i = 0; i < operators.length; i++) {
            setApprovalForAll(operators[i], true);
        }

        isPrivate = true;

        emit CreateERC1155BridgeTowerUser(_msgSender(), _name, _symbol);
    }

    function __ERC1155BridgeTower_init(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI,
        address transferProxy,
        address lazyTransferProxy,
        address securitizeRegistryProxy,
        address contractsRegistryProxy,
        uint256 lockPeriod
    ) external virtual {
        __ERC1155BridgeTower_init_unchained(
            _name,
            _symbol,
            baseURI,
            contractURI,
            transferProxy,
            lazyTransferProxy,
            securitizeRegistryProxy,
            contractsRegistryProxy,
            lockPeriod
        );

        isPrivate = false;

        emit CreateERC1155BridgeTower(_msgSender(), _name, _symbol);
    }

    function __ERC1155BridgeTower_init_unchained(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory contractURI,
        address transferProxy,
        address lazyTransferProxy,
        address securitizeRegistryProxy,
        address contractsRegistryProxy,
        uint256 lockPeriod
    ) internal initializer {
        __Ownable_init_unchained();
        __ERC1155Lazy_init_unchained();
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Mint1155Validator_init_unchained();
        __ERC1155_init_unchained("", transferProxy);
        __HasContractURI_init_unchained(contractURI);
        __RoyaltiesUpgradeable_init_unchained();
        __ERC1155Base_init_unchained(_name, _symbol);
        __ERC1155Lockable_init_unchained(lockPeriod);
        __MinterAccessControl_init_unchained();
        __PartnerAccessControl_init_unchained();
        __Whitelistable_init_unchained(
            securitizeRegistryProxy,
            contractsRegistryProxy
        );

        _setBaseURI(baseURI);

        // Setting default approve for transfer proxies
        _setDefaultApproval(transferProxy, true);
        _setDefaultApproval(lazyTransferProxy, true);
    }

    function transferFromOrMint(
        LibERC1155LazyMint.Mint1155Data memory data,
        address from,
        address to,
        uint256 amount
    ) external override onlyPartner(_msgSender()) {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(from);
        onlyWhitelistedAddress(to);

        super._transferFromOrMint(data, from, to, amount);
    }

    function mintAndTransfer(
        LibERC1155LazyMint.Mint1155Data memory data,
        address to,
        uint256 amount
    ) public override onlyPartner(_msgSender()) {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(to);

        if (isPrivate) {
            require(
                owner() == data.creators[0].account ||
                    isMinter(data.creators[0].account),
                "ERC1155BridgeTower: not owner nor minter"
            );
        }

        super.mintAndTransfer(data, to, amount);
    }

    function updateAccount(
        uint256 id,
        address from,
        address to
    ) external {
        onlyWhitelistedAddress(_msgSender());

        super._updateAccount(id, from, to);
    }

    function setBaseURI(string memory newBaseURI) external {
        onlyWhitelistedAddress(_msgSender());

        super._setBaseURI(newBaseURI);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155Upgradeable)
    {
        onlyWhitelistedAddress(_msgSender());

        super.setApprovalForAll(operator, approved);
    }

    function addMinter(address minter) public override {
        onlyWhitelistedAddress(_msgSender());

        super.addMinter(minter);
    }

    function removeMinter(address minter) public override {
        onlyWhitelistedAddress(_msgSender());

        super.removeMinter(minter);
    }

    function addPartner(address partner) public override {
        onlyWhitelistedAddress(_msgSender());

        super.addPartner(partner);
    }

    function removePartner(address partner) public override {
        onlyWhitelistedAddress(_msgSender());

        super.removePartner(partner);
    }

    function transferOwnership(address newOwner) public override {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(newOwner);

        super.transferOwnership(newOwner);
    }

    function renounceOwnership() public override {
        onlyWhitelistedAddress(_msgSender());

        super.renounceOwnership();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Upgradeable) {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(from);
        onlyWhitelistedAddress(to);

        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155Upgradeable) {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(from);
        onlyWhitelistedAddress(to);

        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function unlock(address user, uint256 id) public override(ERC1155Lockable) {
        onlyWhitelistedAddress(_msgSender());
        onlyWhitelistedAddress(user);

        super.unlock(user, id);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import "../openzeppelin-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ISecuritizeRegistryProxy.sol";
import "./interfaces/IContractsRegistryProxy.sol";

abstract contract WhitelistableUpgradeable is OwnableUpgradeable {
    using AddressUpgradeable for address;

    address public securitizeRegistryProxy;
    address public contractsRegistryProxy;

    modifier onlyContract(address addr) {
        require(addr.isContract(), "Whitelistable: not contract address");
        _;
    }

    function __Whitelistable_init(
        address initialSecuritizeRegistryProxy,
        address initialContractsRegistryProxy
    ) internal {
        __Ownable_init_unchained();
        __Whitelistable_init_unchained(
            initialSecuritizeRegistryProxy,
            initialContractsRegistryProxy
        );
    }

    function __Whitelistable_init_unchained(
        address initialSecuritizeRegistryProxy,
        address initialContractsRegistryProxy
    )
        internal
        onlyContract(initialSecuritizeRegistryProxy)
        onlyContract(initialContractsRegistryProxy)
    {
        securitizeRegistryProxy = initialSecuritizeRegistryProxy;
        contractsRegistryProxy = initialContractsRegistryProxy;
    }

    function setSecuritizeRegistryProxy(address newSecuritizeRegistryProxy)
        external
        onlyOwner
        onlyContract(newSecuritizeRegistryProxy)
    {
        onlyWhitelistedAddress(_msgSender());

        securitizeRegistryProxy = newSecuritizeRegistryProxy;
    }

    function setContractsRegistryProxy(address newContractsRegistryProxy)
        external
        onlyOwner
        onlyContract(newContractsRegistryProxy)
    {
        onlyWhitelistedAddress(_msgSender());

        contractsRegistryProxy = newContractsRegistryProxy;
    }

    function onlyWhitelistedAddress(address addr) public view {
        require(
            ISecuritizeRegistryProxy(securitizeRegistryProxy)
                .isWhitelistedWallet(addr) ||
                IContractsRegistryProxy(contractsRegistryProxy)
                    .isWhitelistedContract(addr),
            "Whitelistable: address is not whitelisted"
        );
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

abstract contract PartnerAccessControl is OwnableUpgradeable {
    mapping(address => bool) private _partners;

    event PartnerStatusChanged(address indexed partner, bool indexed status);

    modifier onlyPartner(address account) {
        require(
            isPartner(account),
            "PartnerAccessControl: caller is not a partner"
        );
        _;
    }

    function __PartnerAccessControl_init() internal initializer {
        __Ownable_init_unchained();
        __PartnerAccessControl_init_unchained();
    }

    function __PartnerAccessControl_init_unchained() internal initializer {}

    /**
     * @dev Add `partner` to the list of allowed partners.
     */
    function addPartner(address partner) public virtual onlyOwner {
        _partners[partner] = true;

        emit PartnerStatusChanged(partner, true);
    }

    /**
     * @dev Revoke `partner` from the list of allowed partners.
     */
    function removePartner(address partner) public virtual onlyOwner {
        _partners[partner] = false;

        emit PartnerStatusChanged(partner, false);
    }

    /**
     * @dev Returns `true` if `account` has been granted to partners.
     */
    function isPartner(address account) public view returns (bool) {
        return _partners[account];
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

abstract contract MinterAccessControl is OwnableUpgradeable {
    mapping(address => bool) private _minters;

    event MinterStatusChanged(address indexed minter, bool indexed status);

    function __MinterAccessControl_init() internal initializer {
        __Ownable_init_unchained();
        __MinterAccessControl_init_unchained();
    }

    function __MinterAccessControl_init_unchained() internal initializer {}

    /**
     * @dev Add `_minter` to the list of allowed minters.
     */
    function addMinter(address _minter) public virtual onlyOwner {
        _minters[_minter] = true;

        emit MinterStatusChanged(_minter, true);
    }

    /**
     * @dev Revoke `_minter` from the list of allowed minters.
     */
    function removeMinter(address _minter) public virtual onlyOwner {
        _minters[_minter] = false;

        emit MinterStatusChanged(_minter, false);
    }

    /**
     * @dev Returns `true` if `account` has been granted to minters.
     */
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IsPrivateCollection {
    /// @dev true if collection is private, false if public
    bool internal isPrivate;

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../../openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

import "./ERC1155DefaultApproval.sol";
import "./ERC1155Lazy.sol";

import "../HasContractURI.sol";

abstract contract ERC1155Base is
    OwnableUpgradeable,
    ERC1155DefaultApproval,
    ERC1155Lazy,
    HasContractURI
{
    string public name;
    string public symbol;

    event BaseUriChanged(string newBaseURI);

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC1155DefaultApproval, IERC1155Upgradeable)
        returns (bool)
    {
        return ERC1155DefaultApproval.isApprovedForAll(_owner, _operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Lazy, ERC165StorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155Lazy) {
        ERC1155Lazy._mint(account, id, amount, data);
    }

    function __ERC1155Base_init_unchained(
        string memory _name,
        string memory _symbol
    ) internal initializer {
        name = _name;
        symbol = _symbol;
    }

    function uri(uint256 id)
        external
        view
        virtual
        override(ERC1155BaseURI, ERC1155Upgradeable)
        returns (string memory)
    {
        return _tokenURI(id);
    }

    function _setBaseURI(string memory newBaseURI)
        internal
        virtual
        override
        onlyOwner
    {
        super._setBaseURI(newBaseURI);

        emit BaseUriChanged(newBaseURI);
    }

    uint256[50] private __gap;
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

pragma solidity ^0.8.0;

interface ISecuritizeRegistryProxy {
    function setSecuritizeRegistry(address newSecuritizeRegistry) external;

    function isWhitelistedWallet(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IContractsRegistryProxy {
    function setContractsRegistry(address newContractsRegistry) external;

    function setSecuritizeRegistryProxy(address newSecuritizeRegistryProxy)
        external;

    function isWhitelistedContract(address addr) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
            require(
                _initialized < version,
                "Initializable: contract is already initialized"
            );
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";

abstract contract ERC1155DefaultApproval is ERC1155Upgradeable {
    mapping(address => bool) private defaultApprovals;

    event DefaultApproval(address indexed operator, bool hasApproval);

    function _setDefaultApproval(address operator, bool hasApproval) internal {
        defaultApprovals[operator] = hasApproval;

        emit DefaultApproval(operator, hasApproval);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            defaultApprovals[_operator] ||
            super.isApprovedForAll(_owner, _operator);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../../royalties-upgradeable/RoyaltiesUpgradeable.sol";

import "../../lazy-mint/erc-1155/IERC1155LazyMint.sol";

import "../../royalties/impl/RoyaltiesImpl.sol";

import "./ERC1155Upgradeable.sol";
import "./Mint1155Validator.sol";
import "./ERC1155BaseURI.sol";

abstract contract ERC1155Lazy is
    IERC1155LazyMint,
    ERC1155BaseURI,
    Mint1155Validator,
    RoyaltiesUpgradeable,
    RoyaltiesImpl
{
    using SafeMathUpgradeable for uint256;

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    mapping(uint256 => LibPart.Part[]) private creators;
    mapping(uint256 => uint256) private supply;
    mapping(uint256 => uint256) private minted;

    function __ERC1155Lazy_init_unchained() internal initializer {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165StorageUpgradeable)
        returns (bool)
    {
        return
            interfaceId == LibERC1155LazyMint._INTERFACE_ID_MINT_AND_TRANSFER ||
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ||
            interfaceId == LibRoyalties2981._INTERFACE_ID_ROYALTIES ||
            interfaceId == _INTERFACE_ID_ERC165 ||
            interfaceId == _INTERFACE_ID_ERC1155 ||
            interfaceId == _INTERFACE_ID_ERC1155_METADATA_URI;
    }

    function _transferFromOrMint(
        LibERC1155LazyMint.Mint1155Data memory data,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 balance = balanceOf(from, data.tokenId);
        uint256 left = amount;

        if (balance != 0) {
            uint256 transfer = amount;

            if (balance < amount) {
                transfer = balance;
            }

            safeTransferFrom(from, to, data.tokenId, transfer, "");

            left = amount - transfer;
        }

        if (left > 0) {
            mintAndTransfer(data, to, left);
        }
    }

    function mintAndTransfer(
        LibERC1155LazyMint.Mint1155Data memory data,
        address to,
        uint256 amount
    ) public virtual override {
        address minter = address(uint160(data.tokenId >> 96));
        address sender = _msgSender();

        require(
            minter == sender || isApprovedForAll(minter, sender),
            "ERC1155Lazy: transfer caller is not approved"
        );
        require(amount > 0, "ERC1155Lazy: incorrect amount");

        if (supply[data.tokenId] == 0) {
            require(
                minter == data.creators[0].account,
                "ERC1155Lazy: incorrect tokenId"
            );
            require(data.supply > 0, "ERC1155Lazy: incorrect supply");
            require(
                data.creators.length == data.signatures.length,
                "ERC1155Lazy: creators and signatures length mismatch"
            );

            bytes32 hash = LibERC1155LazyMint.hash(data);

            for (uint256 i = 0; i < data.creators.length; i++) {
                address creator = data.creators[i].account;

                if (creator != sender) {
                    validate(creator, hash, data.signatures[i]);
                }
            }

            _saveSupply(data.tokenId, data.supply);
            _saveRoyalties(data.tokenId, data.royalties);
            _saveCreators(data.tokenId, data.creators);
            _setTokenURI(data.tokenId, data.tokenURI);
        }

        _mint(to, data.tokenId, amount, "");

        if (minter != to) {
            emit TransferSingle(
                sender,
                address(0),
                minter,
                data.tokenId,
                amount
            );
            emit TransferSingle(sender, minter, to, data.tokenId, amount);
        } else {
            emit TransferSingle(sender, address(0), to, data.tokenId, amount);
        }
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        uint256 newMinted = amount.add(minted[id]);

        require(newMinted <= supply[id], "ERC1155Lazy: more than supply");

        minted[id] = newMinted;

        require(account != address(0), "ERC1155Lazy: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    function _saveSupply(uint256 tokenId, uint256 _supply) internal {
        require(supply[tokenId] == 0, "ERC1155Lazy: supply must be zero");

        supply[tokenId] = _supply;

        emit Supply(tokenId, _supply);
    }

    function _saveCreators(uint256 tokenId, LibPart.Part[] memory _creators)
        internal
    {
        LibPart.Part[] storage creatorsOfToken = creators[tokenId];
        uint256 total = 0;

        for (uint256 i = 0; i < _creators.length; i++) {
            require(
                _creators[i].account != address(0),
                "ERC1155Lazy: account should be present"
            );
            require(
                _creators[i].value != 0,
                "ERC1155Lazy: creator share should be positive"
            );

            creatorsOfToken.push(_creators[i]);
            total = total.add(_creators[i].value);
        }

        require(
            total == 10000,
            "ERC1155Lazy: total amount of creators share should be 10000"
        );

        emit Creators(tokenId, _creators);
    }

    function _updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) internal override {
        require(_msgSender() == _from, "ERC1155Lazy: not allowed");

        super._updateAccount(_id, _from, _to);
    }

    function getCreators(uint256 _id)
        external
        view
        returns (LibPart.Part[] memory)
    {
        return creators[_id];
    }

    function _addMinted(uint256 tokenId, uint256 amount) internal {
        minted[tokenId] += amount;
    }

    function _getMinted(uint256 tokenId) internal view returns (uint256) {
        return minted[tokenId];
    }

    function _getSupply(uint256 tokenId) internal view returns (uint256) {
        return supply[tokenId];
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

abstract contract HasContractURI is ERC165StorageUpgradeable {
    string public contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    function __HasContractURI_init_unchained(string memory _contractURI)
        internal
        initializer
    {
        contractURI = _contractURI;

        _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    }

    /**
     * @dev Internal function to set the contract URI
     * @param _contractURI string URI prefix to assign
     */
    function _setContractURI(string memory _contractURI) internal {
        contractURI = _contractURI;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../openzeppelin-upgradeable/token/ERC1155/ERC1155ReceiverUpgradeable.sol";
import "../../openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "../../openzeppelin-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "../../openzeppelin-upgradeable/utils/AddressUpgradeable.sol";
import "../../openzeppelin-upgradeable/utils/ContextUpgradeable.sol";

import "./ERC1155Lockable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is
    ERC165StorageUpgradeable,
    IERC1155Upgradeable,
    ContextUpgradeable,
    ERC1155Lockable,
    IERC1155MetadataURIUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    address private transferProxy;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     * bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     * bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     * bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     * bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     * bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     * => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^ 0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /**
     * bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_, address initialTransferProxy)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_, initialTransferProxy);
    }

    function __ERC1155_init_unchained(
        string memory uri_,
        address initialTransferProxy
    ) internal initializer {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);

        transferProxy = initialTransferProxy;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );

        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;

        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        ERC1155Lockable.unlock(from, id);

        uint256 unlockedAmount = balanceOf(from, id).sub(
            ERC1155Lockable.getLockedAmount(from, id)
        );

        require(
            unlockedAmount >= amount,
            "ERC1155BridgeTower: not enough unlocked tokens"
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "ERC1155: insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        if (_msgSender() == transferProxy && lockPeriod != 0) {
            ERC1155Lockable.lock(to, id, amount);
        }

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            ERC1155Lockable.unlock(from, id);

            uint256 unlockedAmount = balanceOf(from, id).sub(
                ERC1155Lockable.getLockedAmount(from, id)
            );

            require(
                unlockedAmount >= amount,
                "ERC1155BridgeTower: not enough unlocked tokens"
            );

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);

            if (_msgSender() == transferProxy && lockPeriod != 0) {
                ERC1155Lockable.lock(to, id, amount);
            }
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newURI) internal virtual {
        _uri = newURI;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);

        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable(to)
                        .onERC1155BatchReceived
                        .selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);

        array[0] = element;

        return array;
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "../../proxy/utils/Initializable.sol";

import "./ERC165Upgradeable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {}

    function __ERC165Storage_init_unchained() internal onlyInitializing {}

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

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
            super.supportsInterface(interfaceId) ||
            _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "../../openzeppelin-upgradeable/proxy/utils/Initializable.sol";

abstract contract ERC1155Lockable is Initializable {
    using SafeMathUpgradeable for uint256;

    struct LocksInfo {
        uint256 totalLockedAmount;
        uint256 indexToCheck;
        Lock[] locks;
    }

    struct Lock {
        uint256 amount;
        uint256 start;
        uint256 end;
    }

    uint256 public lockPeriod;

    mapping(address => mapping(uint256 => LocksInfo)) internal locksInfo;

    event Locked(address indexed user, uint256 indexed id, uint256 amount);
    event Unlocked(address indexed user, uint256 indexed id, uint256 amount);

    function __ERC1155Lockable_init_unchained(uint256 initialLockPeriod)
        internal
        initializer
    {
        lockPeriod = initialLockPeriod;
    }

    function lock(
        address user,
        uint256 id,
        uint256 amount
    ) internal {
        Lock memory newLock = Lock({
            amount: amount,
            start: block.timestamp,
            end: block.timestamp.add(lockPeriod)
        });

        locksInfo[user][id].locks.push(newLock);
        locksInfo[user][id].totalLockedAmount = locksInfo[user][id]
            .totalLockedAmount
            .add(amount);

        emit Locked(user, id, amount);
    }

    function unlock(address user, uint256 id) public virtual {
        for (
            uint256 i = locksInfo[user][id].indexToCheck;
            i < locksInfo[user][id].locks.length;
            i++
        ) {
            if (locksInfo[user][id].locks[i].end <= block.timestamp) {
                locksInfo[user][id].indexToCheck = i + 1;
                locksInfo[user][id].totalLockedAmount = locksInfo[user][id]
                    .totalLockedAmount
                    .sub(locksInfo[user][id].locks[i].amount);

                emit Unlocked(user, id, locksInfo[user][id].locks[i].amount);

                delete locksInfo[user][id].locks[i];
            } else {
                break;
            }
        }
    }

    function getLockedAmount(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return locksInfo[user][id].totalLockedAmount;
    }

    function getUnlockableAmount(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        uint256 unlockableAmount = 0;

        for (
            uint256 i = locksInfo[user][id].indexToCheck;
            i < locksInfo[user][id].locks.length;
            i++
        ) {
            if (locksInfo[user][id].locks[i].end <= block.timestamp) {
                unlockableAmount = unlockableAmount.add(
                    locksInfo[user][id].locks[i].amount
                );
            } else {
                break;
            }
        }

        return unlockableAmount;
    }

    function getLocksInfo(address user, uint256 id)
        public
        view
        returns (uint256, Lock[] memory)
    {
        return (locksInfo[user][id].indexToCheck, locksInfo[user][id].locks);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "../../proxy/utils/Initializable.sol";

import "./IERC165Upgradeable.sol";

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

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
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

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../openzeppelin-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

import "../royalties/LibRoyaltiesV2.sol";
import "../royalties/IRoyalties.sol";

abstract contract RoyaltiesUpgradeable is ERC165StorageUpgradeable, IRoyalties {
    function __RoyaltiesUpgradeable_init_unchained() internal initializer {
        _registerInterface(LibRoyaltiesV2._INTERFACE_ID_ROYALTIES);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "../../openzeppelin-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "../../royalties/LibPart.sol";

import "./LibERC1155LazyMint.sol";

interface IERC1155LazyMint is IERC1155Upgradeable {
    event Supply(uint256 tokenId, uint256 value);
    event Creators(uint256 tokenId, LibPart.Part[] creators);

    function mintAndTransfer(
        LibERC1155LazyMint.Mint1155Data memory data,
        address to,
        uint256 _amount
    ) external;

    function transferFromOrMint(
        LibERC1155LazyMint.Mint1155Data memory data,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "./AbstractRoyalties.sol";

import "../LibRoyalties2981.sol";
import "../IRoyalties.sol";
import "../IERC2981.sol";

contract RoyaltiesImpl is AbstractRoyalties, IRoyalties, IERC2981 {
    function getBridgeTowerRoyalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties)
        internal
        override
    {
        emit RoyaltiesSet(id, _royalties);
    }

    /*
     * Token (ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155) can have a number of different royalties beneficiaries
     * calculate sum all royalties, but royalties beneficiary will be only one royalties[0].account, according to rules of IERC2981
     */
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (royalties[id].length == 0) {
            receiver = address(0);
            royaltyAmount = 0;

            return (receiver, royaltyAmount);
        }

        LibPart.Part[] memory _royalties = royalties[id];

        receiver = _royalties[0].account;

        uint256 percent;

        for (uint256 i = 0; i < _royalties.length; i++) {
            percent += _royalties[i].value;
        }

        royaltyAmount = (percent * _salePrice) / 10000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../lazy-mint/erc-1155/LibERC1155LazyMint.sol";

import "../erc-1271/ERC1271Validator.sol";

contract Mint1155Validator is ERC1271Validator {
    function __Mint1155Validator_init_unchained() internal initializer {
        __EIP712_init_unchained("Mint1155", "1");
    }

    function validate(
        address account,
        bytes32 hash,
        bytes memory signature
    ) internal view {
        validate1271(account, hash, signature);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin-upgradeable/utils/StringsUpgradeable.sol";

import "./ERC1155Upgradeable.sol";

import "../LibURI.sol";

contract ERC1155BaseURI is ERC1155Upgradeable {
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function uri(uint256 id)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURI(id);
    }

    function _tokenURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        string memory __tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return __tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(__tokenURI).length > 0) {
            return LibURI.checkPrefix(base, __tokenURI);
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _uri)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _uri;

        emit URI(_tokenURI(tokenId), tokenId);
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyaltiesV2 {
    /**
     * bytes4(keccak256('getBridgeTowerV2Royalties(uint256)')) == 0x2182ba32
     */
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0x2182ba32;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

pragma abicoder v2;

import "./LibPart.sol";

interface IRoyalties {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getBridgeTowerRoyalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    /**
     * keccak256("Part(address account,uint96 value)") == 0x397e04204c1e1a60ee8724b71f8244e10ab5f2e9009854d80f602bda21b59ebb
     */
    bytes32 public constant TYPE_HASH =
        0x397e04204c1e1a60ee8724b71f8244e10ab5f2e9009854d80f602bda21b59ebb;

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../royalties/LibPart.sol";

library LibERC1155LazyMint {
    /**
     * keccak256("Mint1155(uint256 tokenId,uint256 supply,string tokenURI,Part[] creators,Part[] royalties)Part(address account,uint96 value)")
     */
    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH =
        0xfb988707ebb338694f318760b0fd5cfe756d00a2ade251fda110b80c336a3c7f;

    /**
     * bytes4(keccak256("ERC1155_LAZY")) == 0x1cdfaa40
     */
    bytes4 public constant ERC1155_LAZY_ASSET_CLASS = 0x1cdfaa40;
    bytes4 internal constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

    struct Mint1155Data {
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {
        bytes32[] memory royaltiesBytes = new bytes32[](data.royalties.length);

        for (uint256 i = 0; i < data.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(data.royalties[i]);
        }

        bytes32[] memory creatorsBytes = new bytes32[](data.creators.length);

        for (uint256 i = 0; i < data.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(data.creators[i]);
        }

        return
            keccak256(
                abi.encode(
                    MINT_AND_TRANSFER_TYPEHASH,
                    data.tokenId,
                    data.supply,
                    keccak256(bytes(data.tokenURI)),
                    keccak256(abi.encodePacked(creatorsBytes)),
                    keccak256(abi.encodePacked(royaltiesBytes))
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../LibPart.sol";

abstract contract AbstractRoyalties {
    mapping(uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties)
        internal
    {
        uint256 totalValue;

        for (uint256 i = 0; i < _royalties.length; i++) {
            require(
                _royalties[i].account != address(0),
                "Royalties: recipient should be present"
            );
            require(
                _royalties[i].value != 0,
                "Royalties: royalty value should be positive"
            );

            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }

        require(
            totalValue < 10000,
            "Royalties: royalty total value should be < 10000"
        );

        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) internal virtual {
        uint256 length = royalties[_id].length;

        for (uint256 i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

library LibRoyalties2981 {
    /*
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     */
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0x2a55205a;
    uint96 internal constant _WEIGHT_VALUE = 1000000;

    /**
     * Method for converting amount to percent and forming LibPart
     */
    function calculateRoyalties(address to, uint256 amount)
        internal
        pure
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory result;

        if (amount == 0) {
            return result;
        }

        uint256 percent = ((amount * 100) / _WEIGHT_VALUE) * 100;

        require(percent < 10000, "Royalties2981: value more than 100%");

        result = new LibPart.Part[](1);
        result[0].account = payable(to);
        result[0].value = uint96(percent);

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 {
    /**
     * @notice Called with the sale price to determine how much royalty is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import "../../libraries/LibSignature.sol";

import "./ERC1271.sol";

abstract contract ERC1271Validator is EIP712Upgradeable {
    using AddressUpgradeable for address;
    using LibSignature for bytes32;

    string internal constant SIGNATURE_ERROR = "signature verification error";

    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function validate1271(
        address signer,
        bytes32 structHash,
        bytes memory signature
    ) internal view {
        bytes32 hash = _hashTypedDataV4(structHash);
        address signerFromSig;

        if (signature.length == 65) {
            signerFromSig = hash.recover(signature);
        }

        if (signerFromSig != signer) {
            if (signer.isContract()) {
                require(
                    ERC1271(signer).isValidSignature(hash, signature) ==
                        MAGICVALUE,
                    SIGNATURE_ERROR
                );
            } else {
                revert(SIGNATURE_ERROR);
            }
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "../../proxy/utils/Initializable.sol";

import "./ECDSAUpgradeable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version)
        internal
        onlyInitializing
    {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version)
        internal
        onlyInitializing
    {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return
            _buildDomainSeparator(
                _TYPE_HASH,
                _EIP712NameHash(),
                _EIP712VersionHash()
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibSignature {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;

        if (v > 30) {
            require(
                v - 4 == 27 || v - 4 == 28,
                "ECDSA: invalid signature 'v' value"
            );

            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ERC1271 {
    bytes4 public constant ERC1271_INTERFACE_ID = 0xfb855dc9;
    bytes4 public constant ERC1271_RETURN_VALID_SIGNATURE = 0x1626ba7e;
    bytes4 public constant ERC1271_RETURN_INVALID_SIGNATURE = 0x00000000;

    /**
     * @dev Function must be implemented by deriving contract
     * @param _hash Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     * @return A bytes4 magic value 0x1626ba7e if the signature check passes, 0x00000000 if not
     *
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        public
        view
        virtual
        returns (bytes4);

    function returnIsValidSignatureMagicNumber(bool isValid)
        internal
        pure
        returns (bytes4)
    {
        return
            isValid
                ? ERC1271_RETURN_VALID_SIGNATURE
                : ERC1271_RETURN_INVALID_SIGNATURE;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address, RecoverError)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    StringsUpgradeable.toString(s.length),
                    s
                )
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

pragma solidity ^0.8.0;

library LibURI {
    /// @dev checks if _tokenURI starts with base. if true returns _tokenURI, else base + _tokenURI
    function checkPrefix(string memory base, string memory _tokenURI)
        internal
        pure
        returns (string memory)
    {
        bytes memory whatBytes = bytes(base);
        bytes memory whereBytes = bytes(_tokenURI);

        if (whatBytes.length > whereBytes.length) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        for (uint256 j = 0; j < whatBytes.length; j++) {
            if (whereBytes[j] != whatBytes[j]) {
                return string(abi.encodePacked(base, _tokenURI));
            }
        }

        return _tokenURI;
    }
}