/**
 *Submitted for verification at snowtrace.io on 2022-04-19
*/

/**
 *Submitted for verification at FtmScan.com on 2022-01-31
 */

/**
 *Submitted for verification at FtmScan.com on 2022-01-19
 */

/**
 *Submitted for verification at snowtrace.io on 2021-12-31
 */

/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-23
 */

/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-09
 */

/**
 *Submitted for verification at snowtrace.io on 2021-11-30
 */

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
pragma solidity 0.7.5;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol
pragma solidity 0.7.5;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol
pragma solidity 0.7.5;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol
pragma solidity 0.7.5;

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.7.5;

/**
 * @dev String operations.
 */
library Strings {
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity 0.7.5;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

pragma solidity 0.7.5;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity 0.7.5;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Context.sol
pragma solidity 0.7.5;

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol
pragma solidity 0.7.5;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol

pragma solidity 0.7.5;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // mapping from token id to address. public
    mapping(uint256 => address) internal _tokenToAddressMap;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Original minter details
    mapping(uint256 => address) internal _originalMinter;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            // mint
            _addTokenToAllTokensEnumeration(tokenId);
            _updateTokenAddressMap(tokenId, to);
            _insertOriginalMinter(to, tokenId);
        } else if (from != to) {
            // transfer - remove token from 'from' enum
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to == address(0)) {
            // burn
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            // transfer - add token to 'to' enum
            _addTokenToOwnerEnumeration(to, tokenId);
            _updateTokenAddressMap(tokenId, to);
        }
    }

    function _insertOriginalMinter(address addr, uint256 tokenId) private {
        _originalMinter[tokenId] = addr;
    }

    /**
     * @dev Private function to update the token=>address map. Will be called on
     *      mint and transfer of token so that lottery winnings are always paid to
     *      the current owner. Non-standard function created by DeFi Degen.
     *
     */
    function _updateTokenAddressMap(uint256 tokenId, address to) private {
        _tokenToAddressMap[tokenId] = to;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity 0.7.5;

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

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity 0.7.5;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.7.5;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

pragma solidity 0.7.5;

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties {
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");

        _royalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_)
        internal
        pure
        returns (uint256 percentAmount_)
    {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_)
        internal
        pure
        returns (uint256 result_)
    {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_)
        internal
        pure
        returns (uint256 percent_)
    {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return mul(multiplier_, supply_);
    }
}


pragma solidity 0.7.5;

contract AvaxFrogs is ERC721Enumerable, Ownable, ERC2981PerTokenRoyalties {
    using Strings for uint256;
    using SafeMath for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 private epochDay = 86400; // 1 day
    uint256 public costSpawn = 100000000000; // 100
    uint256 public costAvax = 1000000000000000000; // 1
    uint256 public stakingReward = 1000000000; // spawn 1
    uint256 public maxSupply = 5000;
    uint256 public maxMintForTx = 10;
    uint256 public maxMintsForAddress = 50;
    uint256 private contractRoyalties = 1000; // 10%

    bool public paused = true;
    bool public airDropActive = false;
    bool private whiteListOnly = false;

    mapping(address => bool) public whiteListAddresses;
    mapping(address => uint256) private addressMints;
    mapping(uint256 => address) private stakedFrogOwners;
    mapping(uint256 => uint256) private stakedFrogLastClaimDate;
    mapping(address => uint256[]) private stakedFrogsByAddress;
    mapping(uint256 => uint256) public stakedFrogsByAddressIndex;
    mapping(address => bool) public stakers;
    mapping(uint256 => uint256) private rewardPayouts;
    mapping(uint256 => bool) private ogClaims;

    uint256 public liquidityPercentage = 100000; // 400000 == 10%
    uint256 public rewardsPercentage = 800000; // 400000 == 80%
    uint256 public burnPercentage = 100000; // 200000 == 10%

    uint256 private tier1BonusDays = 14;
    uint256 private tier2BonusDays = 21;
    uint256 private tier3BonusDays = 36;

    uint256 private tier1Bonus = 50000000; // 5%
    uint256 private tier2Bonus = 100000000; // 10%
    uint256 private tier3Bonus = 150000000; // 15%

    bool public bonusActive = true;
    bool private ogClaimActive = false;

    address public liquidityWallet =
        address(0);
    address public burnWallet =
        address(0);
    address public rewardsWallet;
    address private timeFrogsNFTAddress_ =
        address(0xA1B46ff2a3394b9460B4004F2e7401DeC7f7A023);


    IERC20 public spawn;

    constructor(string memory _initBaseURI, address _spawnAddress)
        ERC721("Avax Frogs FPC", "AVAXFROGS")
    {
        setBaseURI(_initBaseURI);
        rewardsWallet = address(this);
        spawn = IERC20(_spawnAddress);
    }

    function setBonusActive(bool _value) external onlyOwner {
        bonusActive = _value;
    }

    function ownerMint(uint _amount) external onlyOwner {
         for (uint i = 0; i <= _amount; i++) {
            uint tokenId = totalSupply() + 1;
            _safeMint(owner(), tokenId);
            _setTokenRoyalty(tokenId, owner(), contractRoyalties);
        }
    }

    function setWallet(address _wallet, uint256 id) external onlyOwner {
        if (id == 1) {
            liquidityWallet = _wallet;
        } else if (id == 2) {
            burnWallet = _wallet;
        } else if (id == 3) {
            rewardsWallet = _wallet;
        }
    }

    /*
    @function _baseURI()
    @description - Gets the current base URI for nft metadata
    @returns <string>
  */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
    @function mint(_mintAmount)
    @description - Mints _mintAmount of NFTs for sender address.
    @param <uint256> _mintAmount - The number of NFTs to mint.
  */
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        uint256 ownerCanMintCount = maxMintsForAddress -
            addressMints[msg.sender];

        require(
            ownerCanMintCount >= _mintAmount,
            "ERROR: You cant mint that many frogs"
        );

        require(!paused, "ERROR: Contract paused. Please check discord.");

        require(
            _mintAmount <= maxMintForTx,
            "ERROR: The max no mints per transaction exceeded"
        );

        require(
            supply + _mintAmount <= maxSupply,
            "ERROR: Not enough Frogs left to mint!"
        );

        require(
            spawn.allowance(msg.sender, address(this)) >=
                (costSpawn * _mintAmount),
            "ERROR: Not approved to spend enough token"
        );

        // Check that their is enough balance
        require(
            spawn.balanceOf(address(msg.sender)) >= (costSpawn * _mintAmount),
            "ERROR: Not enough spawn balance"
        );

        require(
            msg.value >= (costAvax * _mintAmount),
            "ERROR: Not not enought AVAX"
        );

        require(
            address(liquidityWallet) != address(0),
            "ERROR: Treasury wallet not set"
        );

        require(address(burnWallet) != address(0), "ERROR: Wallet not set");

        if (whiteListOnly) {
            require(
                whiteListAddresses[msg.sender] == true,
                "ERROR: You are not part of the white list."
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 tokenId = supply + 1;
            _safeMint(msg.sender, tokenId);
            _setTokenRoyalty(tokenId, owner(), contractRoyalties);

            uint256 liquidityFee = costSpawn.mul(liquidityPercentage).div(
                1000000
            );
            spawn.transferFrom(msg.sender, liquidityWallet, liquidityFee);

            uint256 rewardsFee = costSpawn.mul(rewardsPercentage).div(1000000);
            spawn.transferFrom(msg.sender, rewardsWallet, rewardsFee);

            uint256 burnFee = costSpawn.mul(burnPercentage).div(1000000);
            spawn.transferFrom(msg.sender, burnWallet, burnFee);

            addressMints[msg.sender]++;

            // This will have changes after a mint, so re-asign it
            supply = totalSupply();
        }
    }

    /*
    @function claimFreeAvaxFrogsAndSpawn(_frogs)
    @description - Claim the rewards for a users TimeFrogs
    @param <uint256[]> _frogs - The list of frogs to claim
  */
    function claimFreeAvaxFrogsAndSpawn(uint256[] calldata _frogs) external {
        // Make sure the claim is active
        require(ogClaimActive, "ERROR: TF claim not available yet");    

        // make sure some frogs are passed in
        require(
            _frogs.length > 0,
            "ERROR: Nothing to claim!"
        );

        for (uint i = 0; i < _frogs.length; i++) {

            uint256 tokenId = _frogs[i];

            // make sure this frog hasn't already been claimed
            require(
                !ogClaims[tokenId],
                "ERROR: Already claimed for this frog!"
            );

            // Check for owner of TF
            if(msg.sender != IERC721(timeFrogsNFTAddress_).ownerOf(tokenId)) {
                // if this is not the owner, move to next. Don't abandon tx completely
                continue;
            } else {
                // otherwise, mint and drop tokens

                // Get a new tokenId from supply
                uint256 newTokenId = totalSupply() + 1;

                // Mint the token to the sender
                _safeMint(msg.sender, newTokenId);

                uint amountSpawn = 10000000000;
                spawn.transfer(msg.sender, amountSpawn);
                ogClaims[tokenId] = true;
            }           
        }

    }

    /*
    @function toggleOgClaim(_value)
    @description - Set Tf claim
    @param <bool> _value - true/false
  */
    function toggleOgClaim(bool _value) external onlyOwner {
        ogClaimActive = _value;
    }


    /*
    @function ogClaimed(_value)
    @description - Check if token has been claimed
    @param <bool> _tokenId - The tokenId
  */
    function ogClaimed(uint256 _tokenId) external view returns (bool) {
        bool claimed = ogClaims[_tokenId];
        return claimed;
    }

    /*
    @function walletOfOwner(_owner)
    @description - Gets the list ok NFT tokenIds that owner has.
  */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /*
    @function tokenURL(tokenId)
    @description - Gets the metadata URI for a NFT tokenId
    @param <uint256> tokenId - The id ok the NFT token
    @returns <string> - The URI for the NFT metadata file
  */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /*
    @function setPercentage(_newCost)
    @description - Sets % allocation of SPAWN
    @param <uint256> _newPercentage - The %
  */
    function setPercentage(uint256 _newPercentage, uint256 _id)
        external
        onlyOwner
    {
        if (_id == 1) {
            liquidityPercentage = _newPercentage;
        } else if (_id == 2) {
            rewardsPercentage = _newPercentage;
        } else if (_id == 3) {
            burnPercentage = _newPercentage;
        }
    }

    /*
    @function setCost(_newCost)
    @description - Sets the cost of a single NFT
    @param <uint256> _newCost - The cost of a single nft
  */
    function setCost(uint256 _newCost, uint256 _id) external onlyOwner {
        if (_id == 1) {
            costSpawn = _newCost;
        } else if (_id == 2) {
            costAvax = _newCost;
        }
    }

    /*
    @function setMaxMintForTx
    @description - Sets the maximum mintable amount in 1 tx
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForTx(uint256 amount) external onlyOwner {
        maxMintForTx = amount;
    }

    /*
    @function setMaxMintForAddress
    @description - Sets the maximum mintable amount for an address
    @param <uint256> amount - The number of mintable tokens in 1 tx
  */
    function setMaxMintForAddress(uint256 amount) external onlyOwner {
        maxMintsForAddress = amount;
    }

    /*
    @function setBaseURI(_newBaseURI)
    @description - Sets the base URI for the meta data files
    @param <string> _newBaseURI - The new base URI for the metadata files
  */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /*
    @function setBaseExtension(_newBaseExtension)
    @description - Sets the extension for the meta data file (default .json)
    @param <string> _newBaseExtension - The new file extension to use.
  */
    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /*
    @function pause(_state)
    @description - Pauses the contract.
    @param <bool> _state - true/false
  */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /*
    @function stakeToTime()
    @description - Sends contract balance to wallet for staking. Kept manual to prevent hacks.
    */
    function withdrawSpawn() public onlyOwner {
        spawn.transfer(owner(), spawn.balanceOf(address(this)));
    }

    function withdrawAvax() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        require(success);
    }

    /*
    @function setMaxSupply()
    @description - Sets the max supply that can be minted.
                   This will be useful if the project sells out super fast and
                   we want to add more mintable nfts.
    */
    function setMaxSupply(uint256 amount) external onlyOwner {
        require(
            amount > maxSupply,
            "ERROR: Max supply is currently smaller than new supply"
        );
        maxSupply = amount;
    }

    /*
    @function airDrop(to, amount)
    @description - Air drop an nft to address
    @param <address> to - The address to airdrop nft
    */
    function airDrop(address to) external onlyOwner {
        require(airDropActive, "ERROR: Air drop is not active");

        uint256 supply = totalSupply();
        uint256 tokenId = supply + 1;

        _setTokenRoyalty(tokenId, owner(), contractRoyalties);
        _safeMint(to, tokenId);
    }

    /*
    @function setAirDropStatus(value)
    @description - Sets the status of airdrop to true/false
    @param <bool> value - true/false
    */
    function setAirDropStatus(bool value) external onlyOwner {
        airDropActive = value;
    }

    /*
    @function addWhiteListAddresses()
    @description - Adds a batch of addresses to white list
    */
    function addWhiteListAddresses(address[] calldata _addresses)
        public
        onlyOwner
    {
        require(_addresses.length < 500, "ERROR: Too many in one tx");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteListAddresses[_addresses[i]] = true;
        }
    }

    /*
    @function setWhiteList()
    @description - Sets contract to whitelist only addresses true/false
    */
    function setWhiteList(bool _value) public onlyOwner {
        whiteListOnly = _value;
    }

    /*
    @function stake()
    @description - custodial staking. Transfers the users NFT to this contract and 
                   keeps track of that owner for this token
    */
    function stake(uint256 _tokenId) public {
        // Get the token owner
        address tokenOwner = ownerOf(_tokenId);

        // Get the latest block timestamp
        uint256 timeStampNow = block.timestamp;

        // Check the token owner is the sender (also double checks that frog isnt already staked)
        require(
            tokenOwner == msg.sender,
            "ERROR: You are not the owner of this frog"
        );

        // idx for staked frogs
        uint256 idx;

        // All ok, transder the NFT from the sender to this contract
        transferFrom(msg.sender, address(this), _tokenId);

        // Keep track of who owns this NFT
        stakedFrogOwners[_tokenId] = msg.sender;

        // Set the last claim date to now
        stakedFrogLastClaimDate[_tokenId] = timeStampNow;

        // Get the next index value that will be used
        if (stakers[tokenOwner] == true) {
            idx = stakedFrogsByAddress[tokenOwner].length;
        } else {
            idx = 0;
        }

        // Set the token against this new index
        stakedFrogsByAddress[tokenOwner].push(_tokenId);

        // Keep a reference to the index for this token, for when it needs to be del'd
        stakedFrogsByAddressIndex[_tokenId] = idx;

        stakers[tokenOwner] = true;
    }

    /*
    @function stakeMultiple()
    @description - stakes multiple frogs
    */
    function stakeMultiple(uint256[] calldata _tokenIds) external {
         for(uint i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i]);
        }
    }

    /*
    @function unstake()
    @description - transfers the NFT back to the original owner who staked.
    */
    function unstake(uint256 _tokenId) public {
        // Get the token owner from the staked frog owner array
        address tokenOwner = stakedFrogOwners[_tokenId];

        // Check the owner is the sender
        require(
            tokenOwner == msg.sender,
            "ERROR: You are not the owner of this frog"
        );

        // All good so far, transfer the NFT from the contract to the owner
        IERC721(address(this)).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );

        // Reset the address against this staked from (it is no longer staked)
        stakedFrogOwners[_tokenId] = address(0);

        // Reset the last claim date to anything really, 0 is fine
        stakedFrogLastClaimDate[_tokenId] = 0;

        // get the index of the frog that was staked
        uint256 idxForDeletion = stakedFrogsByAddressIndex[_tokenId];

        // delete the item in the array, but leave its position so that the
        // stakedFrogsByAddressIndex map is still correct
        delete stakedFrogsByAddress[tokenOwner][idxForDeletion];

        // If this is the last frog being unstaked, de-mark the user as a staker
        if (stakedFrogsByAddress[tokenOwner].length == 0) {
            stakers[tokenOwner] = false;
        }
    }

    /*
    @function stakeMultiple()
    @description - stakes multiple frogs
    */
    function unstakeMultiple(uint256[] calldata _tokenIds) external {
         for(uint i = 0; i < _tokenIds.length; i++) {
            unstake(_tokenIds[i]);
        }
    }

    /*
    @function stakedWalletOfOwner()
    @description - Gets the list of tokens that the sender has staked.
    */
    function stakedWalletOfOwner() public view returns (uint256[] memory) {
        uint256[] memory stakedFrogs = stakedFrogsByAddress[msg.sender];
        return stakedFrogs;
    }

    /*
    @function claim()
    @description - Claims the daily reward for a token, if enough time has elapsed (1 day)
    */
    function claim(uint256 _tokenId) public {
        // The last time this token claimed
        uint256 lastClaimDate = stakedFrogLastClaimDate[_tokenId];

        // Get the token owner from the staked frog array
        address tokenOwner = stakedFrogOwners[_tokenId];

        // Get the latest timestamp
        uint256 timeStampNow = block.timestamp;

        // Message sender must be the owner
        require(
            tokenOwner == msg.sender,
            "ERROR: You are not the owner of this frog"
        );

        // Ensure there is at least 1 day between claims
        require(
            (timeStampNow - lastClaimDate) > 1 days,
            "ERROR: Please wait 24 hourts between claims"
        );

        // Find out how many whole days have elapsed since last claim
        uint256 daysSinceClaim = (block.timestamp - lastClaimDate) / epochDay;

        // Get the epoch value for the number of days being claimed
        uint256 epochSinceLastClaim = (daysSinceClaim * epochDay);

        // Calculate how much spawn is owed
        uint256 currentReward = (stakingReward * daysSinceClaim);
        uint256 bonus = 0;


        // Add any bonus
        if (daysSinceClaim >= tier3BonusDays) {
            bonus = daysSinceClaim * tier3Bonus;            
        } else if (daysSinceClaim >= tier2BonusDays) {
            bonus = daysSinceClaim * tier2Bonus;
        } else if (daysSinceClaim >= tier1BonusDays) {
            bonus = daysSinceClaim * tier1Bonus;
        }

        //eg. 7000000000 + (50000000 * 7) = 7350000000 (7.35 spawn)
        currentReward = currentReward.add(bonus);

        // Transfer the spawn to the owner
        spawn.transfer(tokenOwner, currentReward);

        // Update the total rewards for this token
        rewardPayouts[_tokenId] = rewardPayouts[_tokenId] + currentReward;

        // Upodate the last claim date to the last claim date + the claimed epoch
        stakedFrogLastClaimDate[_tokenId] = lastClaimDate + epochSinceLastClaim;
    }

    /*
    @function setTierBonus()
    @description - Update the bonus amounts for staking
    */
    function setTierBonus(uint256 _bonus, uint256 _id) external onlyOwner {
        if (_id == 1) {
            tier1Bonus = _bonus;
        } else if (_id == 2) {
            tier2Bonus = _bonus;
        } else if (_id == 3) {
            tier3Bonus = _bonus;
        }
    }

        /*
    @function setTierBonusDays()
    @description - Update the bonus periods
    */
    function setTierBonusDays(uint256 _days, uint256 _id) external onlyOwner {
        if (_id == 1) {
            tier1BonusDays = _days;
        } else if (_id == 2) {
            tier2BonusDays = _days;
        } else if (_id == 3) {
            tier3BonusDays = _days;
        }
    }

    /*
    @function claimAll()
    @description - Claim all frogs sent in
    */
    function claimAll(uint256[] calldata _tokenIds) external {
        for(uint i = 0; i < _tokenIds.length; i++) {
            claim(_tokenIds[i]);
        }
    }

    /*
    @function setStakingReward()
    @description - Sets the daily reward rate
    */
    function setStakingReward(uint256 _amount) external onlyOwner {
        stakingReward = _amount;
    }

    /*
    @function getLastClaimDate()
    @description - Gets the last claim date of a frog
    */
    function getLastClaimDate(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return stakedFrogLastClaimDate[_tokenId];
    }

    /*
    @function getNextClaimDate()
    @description - Gets the last claim date of a frog
    */
    function getNextClaimDate(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 lastClaimDate = stakedFrogLastClaimDate[_tokenId];
        return (lastClaimDate + epochDay);
    }

    /*
    @function getDaysSinceLastClaim()
    @description - Gets the number of whole days since the last claim
    */
    function getDaysSinceLastClaim(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        // Find out how many whole days have elapsed since last claim
        uint256 daysSinceClaim = (block.timestamp -
            stakedFrogLastClaimDate[_tokenId]) / epochDay;
        return daysSinceClaim;
    }

    /*
    @function getClaimedAmount()
    @description - Gets the amount of rewards claimed for a frog
    */
    function getClaimedAmount(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 total = rewardPayouts[_tokenId];
        return total;
    }
}