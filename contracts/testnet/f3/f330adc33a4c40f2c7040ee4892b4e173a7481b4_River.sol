/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-27
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
}

// File: contracts/River.sol


pragma solidity ^0.8.4;

contract River is ERC20, ERC20Burnable, ERC721Holder, Ownable {
    IERC721 public nft;

    bool public paused;
    uint256 public epochNum;
    uint256 public lastEpochTime;

    int256 public supply; 
    uint256 public totalPeacefulStaked;
    uint256 public totalHungryStaked;
    uint256 public totalFrenzyStaked;

    struct Bear {
        address owner;
        uint256 epochStakedAt;
        // 0 = Peaceful, 1 = Hungry, 2 = Frenzy
        uint256 poolType;
    }

    struct Holder {
        uint256 lastClaimedEpoch;
        uint256[] bearsStaked;
        uint256 tokensUnclaimed;
    }

    // wallet address paired with info for claiming purposes
    mapping(address => Holder) public holderInfo;

    // mapping keeping track of relevant Bear Info
    mapping(uint256 => Bear) public tokenIdInfo;


    constructor(address _nft) ERC20("FISH", "FISH") {
        nft = IERC721(_nft);
        // Inital supply / Carrying Capacity of the River
        supply = 271828;
        epochNum = 0;
        lastEpochTime = block.timestamp;
        paused = true;
    }

    function startExperiment () public onlyOwner {
        paused = false;
    }

    function pauseExperiment () public onlyOwner {
        paused = true;
    }

    function stakeLoop (uint256[] calldata _tokenIds, uint256 _poolType) external {
        require(_poolType >= 0 && _poolType <= 2, "Not a valid Pool Type");
        if (_poolType == 0){
            totalPeacefulStaked += _tokenIds.length;
            for (uint256 i; i < _tokenIds.length; i++) {
                
                nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
                tokenIdInfo[_tokenIds[i]] = Bear(msg.sender, epochNum, 0);
                holderInfo[msg.sender].bearsStaked.push(_tokenIds[i]);
            }
        } else if (_poolType == 1) {
            totalHungryStaked += _tokenIds.length;
            for (uint256 i; i < _tokenIds.length; i++) {
                nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
                tokenIdInfo[_tokenIds[i]] = Bear(msg.sender, epochNum, 1);
                holderInfo[msg.sender].bearsStaked.push(_tokenIds[i]);      
            }
        } else {
            totalFrenzyStaked += _tokenIds.length;
            for (uint256 i; i < _tokenIds.length; i++) {
                nft.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
                tokenIdInfo[_tokenIds[i]] = Bear(msg.sender, epochNum, 2);
                holderInfo[msg.sender].bearsStaked.push(_tokenIds[i]);
            }
        }   
    }

    function unstakeAll () external {
        require(holderInfo[msg.sender].bearsStaked.length > 0, "No Bears Staked");
        require(paused == true, "Can't Unstake Until Experiment Is Over");
        for (uint256 i; i < holderInfo[msg.sender].bearsStaked.length; i++) {
            nft.safeTransferFrom(address(this), msg.sender, holderInfo[msg.sender].bearsStaked[i]);
        }
    }

    function unstakeSelected (uint256[] calldata tokenIds) external {
        for (uint8 i; i < tokenIds.length; i++){
            require(tokenIdInfo[tokenIds[i]].owner == msg.sender, "Not Your Bear");
            
            uint256 fishRatePrev;
            if (tokenIdInfo[tokenIds[i]].poolType == 0){
                totalPeacefulStaked -= 1;
                fishRatePrev = 5;
            } else if (tokenIdInfo[tokenIds[i]].poolType == 1){
                totalHungryStaked -= 1;
                fishRatePrev = 7;
            } else if (tokenIdInfo[tokenIds[i]].poolType == 2){
                totalFrenzyStaked -= 1;
                fishRatePrev = 10;
            }
            
            // updating unclaimed tokens, deleting tokenId from mapping, removing tokenId from list
            if (tokenIdInfo[tokenIds[i]].epochStakedAt < holderInfo[msg.sender].lastClaimedEpoch) {
                holderInfo[msg.sender].tokensUnclaimed += (fishRatePrev * (epochNum - tokenIdInfo[tokenIds[i]].epochStakedAt));
                nft.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                delete tokenIdInfo[tokenIds[i]];
                removeNFT(tokenIds[i], msg.sender);
            } else {
                holderInfo[msg.sender].tokensUnclaimed += (fishRatePrev * (epochNum - holderInfo[msg.sender].lastClaimedEpoch));
                nft.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                delete tokenIdInfo[tokenIds[i]];
                removeNFT(tokenIds[i], msg.sender);
            }
        }
    }

    function remove(uint256 index, address _sender) internal {
        holderInfo[_sender].bearsStaked[index] = holderInfo[_sender].bearsStaked[holderInfo[_sender].bearsStaked.length - 1];
        holderInfo[_sender].bearsStaked.pop();
    }

    function removeNFT(uint256 tokenId, address sender) internal {
        for (uint256 i; i < holderInfo[sender].bearsStaked.length; i++){
            if (holderInfo[sender].bearsStaked[i] == tokenId) {
                remove(i, sender);
                return;
            }
        }
    }

    function changePoolLoop (uint256[] calldata tokenIds, uint8 poolNum) external {
        for (uint8 i; i < tokenIds.length; i++) {
            require(tokenIdInfo[tokenIds[i]].owner == msg.sender, "Not Your Bear");
            changePool(tokenIds[i], poolNum);
        }
    }

    function changePool (uint256 _tokenId, uint8 _poolNum) internal {
        require(_poolNum >= 0 && _poolNum <= 2, "Not A Valid Pool Type");
        
        uint256 fishRatePrev;

        if (_poolNum == 0){
            totalPeacefulStaked += 1;
        } else if (_poolNum == 1){
            totalHungryStaked += 1;
        } else if (_poolNum == 2) {
            totalFrenzyStaked += 1;
        }

        if (tokenIdInfo[_tokenId].poolType == 0){
            totalPeacefulStaked -= 1;
            fishRatePrev = 5;
        } else if (tokenIdInfo[_tokenId].poolType == 1){
            totalHungryStaked -= 1;
            fishRatePrev = 7;
        } else if (tokenIdInfo[_tokenId].poolType == 2){
            totalFrenzyStaked -= 1;
            fishRatePrev = 10;
        }

        // Change poolType, change unclaimed wallet, change epochStakedAt
        tokenIdInfo[_tokenId].poolType = _poolNum;
        if (tokenIdInfo[_tokenId].epochStakedAt < holderInfo[msg.sender].lastClaimedEpoch) {
            holderInfo[msg.sender].tokensUnclaimed += (fishRatePrev * (epochNum - tokenIdInfo[_tokenId].epochStakedAt));
            tokenIdInfo[_tokenId].epochStakedAt = epochNum;
        } else {
            holderInfo[msg.sender].tokensUnclaimed += (fishRatePrev * (epochNum - holderInfo[msg.sender].lastClaimedEpoch));
            tokenIdInfo[_tokenId].epochStakedAt = epochNum;
        }
    }

    function claimRewards () external {
        uint256 tokensClaimable = calculateRewards(msg.sender);
        holderInfo[msg.sender].lastClaimedEpoch = epochNum;
        _mint(msg.sender, tokensClaimable * 10 ** 18);
    }

    function calculateRewards(address _owner) public view returns(uint256) {
        uint256 tokensClaimable = 0;
        for (uint256 i; i < holderInfo[_owner].bearsStaked.length; i++){
            if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].epochStakedAt <= holderInfo[_owner].lastClaimedEpoch) {
                if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].poolType == 0) {
                    tokensClaimable += (5 * (epochNum - holderInfo[_owner].lastClaimedEpoch));
                } else if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].poolType == 1) {
                    tokensClaimable += (7 * (epochNum - holderInfo[_owner].lastClaimedEpoch));
                } else if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].poolType == 2) {
                    tokensClaimable += (10 * (epochNum - holderInfo[_owner].lastClaimedEpoch));
                }
            } else {
                if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].poolType == 0) {
                    tokensClaimable += (5 * (epochNum - tokenIdInfo[holderInfo[_owner].bearsStaked[i]].epochStakedAt));
                } else if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].poolType == 1) {
                    tokensClaimable += (7 * (epochNum - tokenIdInfo[holderInfo[_owner].bearsStaked[i]].epochStakedAt));
                } else if (tokenIdInfo[holderInfo[_owner].bearsStaked[i]].poolType == 2) {
                    tokensClaimable += (10 * (epochNum - tokenIdInfo[holderInfo[_owner].bearsStaked[i]].epochStakedAt));
                }
            }
        }

        tokensClaimable += holderInfo[_owner].tokensUnclaimed;
        return tokensClaimable;
    }

    function changeEpoch() external {
        require(block.timestamp > lastEpochTime + 180 seconds, "Epoch Not Finished Yet");
        require(paused == false, "Please wait for the experiment to begin");
      
        uint256 fishBurned = calculateFishBurned();
        if (supply - int256(fishBurned) < 0){
            paused = true;
            supply = 1;
        } else {
            epochNum += 1;
            lastEpochTime = block.timestamp;
            if ((supply - int256(fishBurned)) * 2 >= 271828){
                supply = 271828;
            } else {
                supply = (supply - int256(fishBurned)) * 2;
            }
        }
    }

    function calculateFishBurned () public view returns(uint256){
        return (totalFrenzyStaked * 15) + (totalHungryStaked * 10) + (totalPeacefulStaked * 5);
    }

    function getListOfTotalStaked(address _sender) public view returns(uint256[] memory) {
        return holderInfo[_sender].bearsStaked;
    }

    function getPeacefulList(address _sender) public view returns(uint256[] memory) {
        uint16 nftCount = 0;
        for (uint8 i; i < holderInfo[_sender].bearsStaked.length; i++){
            uint256 tokenId = holderInfo[_sender].bearsStaked[i];
            if (tokenIdInfo[tokenId].poolType == 0){
                nftCount++;
            }
        }
        
        uint16 index = 0;
        uint256[] memory tokenIds = new uint256[](nftCount);
        for (uint8 i; i < holderInfo[_sender].bearsStaked.length; i++){
            uint256 tokenId = holderInfo[_sender].bearsStaked[i];
            if (tokenIdInfo[tokenId].poolType == 0){
                tokenIds[index] = tokenId;
                index++;
            }
        }

        return tokenIds;
    }
    function getHungryList(address _sender) public view returns(uint256[] memory) {
        uint16 nftCount = 0;
        for (uint8 i; i < holderInfo[_sender].bearsStaked.length; i++){
            uint256 tokenId = holderInfo[_sender].bearsStaked[i];
            if (tokenIdInfo[tokenId].poolType == 1){
                nftCount++;
            }
        }
        
        uint16 index = 0;
        uint256[] memory tokenIds = new uint256[](nftCount);
        for (uint8 i; i < holderInfo[_sender].bearsStaked.length; i++){
            uint256 tokenId = holderInfo[_sender].bearsStaked[i];
            if (tokenIdInfo[tokenId].poolType == 1){
                tokenIds[index] = tokenId;
                index++;
            }
        }

        return tokenIds;
    }
    function getFrenzyList(address _sender) public view returns(uint256[] memory) {
        uint16 nftCount = 0;
        for (uint8 i; i < holderInfo[_sender].bearsStaked.length; i++){
            uint256 tokenId = holderInfo[_sender].bearsStaked[i];
            if (tokenIdInfo[tokenId].poolType == 2){
                nftCount++;
            }
        }
        
        uint16 index = 0;
        uint256[] memory tokenIds = new uint256[](nftCount);
        for (uint8 i; i < holderInfo[_sender].bearsStaked.length; i++){
            uint256 tokenId = holderInfo[_sender].bearsStaked[i];
            if (tokenIdInfo[tokenId].poolType == 2){
                tokenIds[index] = tokenId;
                index++;
            }
        }

        return tokenIds;
    }
}