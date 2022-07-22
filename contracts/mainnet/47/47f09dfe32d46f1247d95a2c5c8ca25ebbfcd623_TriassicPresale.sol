// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TriassicPresale is Ownable {

  uint16 public maxEggs = 4; 

  mapping (address => uint16[]) public presalersEggs;
  mapping (uint16 => uint256) public eggsPrice;

  bool public whitelistEnabled = true;
  address[] whitelistedPresalers;
  address _foundation;


  constructor(address foundation, address[] memory presalers) {
    for (uint256 i = 0; i < presalers.length; i++) {
      whitelistedPresalers.push(presalers[i]);
    }

    _foundation = foundation;

    eggsPrice[0] = 4.50 * (10**18);
    eggsPrice[1] = 9.00 * (10**18);
    eggsPrice[2] = 18.0 * (10**18);
  }

  function buyPresaleEgg(uint16 id) external payable {
    uint256 price = eggsPrice[id];

    require(msg.value >= price, "[TRIASSIC] Error 4001: Not enough to buy the egg");
    require(msg.sender.balance >= price, "[TRIASSIC] Error 4002: Not enough balance to buy the egg");
    require(!whitelistEnabled || isPresaler(msg.sender), "[TRIASSIC] Error 4003: Not allowed to buy the egg");
    require(presalersEggs[msg.sender].length < maxEggs, "[TRIASSIC] Error 4005: Max eggs reached");

    bool sent = payable(_foundation).send(price);

    require(sent, "[TRIASSIC] Error 4004: Can't tranfer funds");

    presalersEggs[msg.sender].push(id);
  }

  function isPresaler(address sender) public view returns (bool) {
    for (uint256 i = 0; i < whitelistedPresalers.length; i++) {
      if(whitelistedPresalers[i] == sender) return true;
    }

    return false;
  }

  function addPresalers(address[] memory presalers) external onlyOwner {
    for (uint256 i = 0; i < presalers.length; i++) {
      whitelistedPresalers.push(presalers[i]);
    }
  }

  function getPresalerEggs(address presaler) external view returns (uint16[] memory) {
    return presalersEggs[presaler];
  }

  function getPriceEgg(uint16 id) external view returns (uint256) {
    return eggsPrice[id];
  }

  function setPriceEgg(uint16 id, uint256 price) external onlyOwner {
    eggsPrice[id] = price;
  }

  function setMaxEggs(uint16 max) external onlyOwner {
    maxEggs = max;
  }

  function setWhitelistEnabled(bool value) external onlyOwner {
    whitelistEnabled = value;
  }
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