// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ILendingPoolConfig.sol";

contract LendingPoolConfig is ILendingPoolConfig, Ownable {
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  // Base interest rate which is the y-intercept when utilization rate is 0; expressed in 1e18
  uint256 public baseRate;
  // Multiplier of utilization rate that gives the slope of the interest rate; expressed in 1e18
  uint256 public multiplier;
  // Multiplier after hitting a specified utilization point (kink2); expressed in 1e18
  uint256 public jumpMultiplier;
  // Utilization point at which the interest rate is fixed; expressed in 1e18
  uint256 public kink1;
  // Utilization point at which the jump multiplier is applied; expressed in 1e18
  uint256 public kink2;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant SECONDS_PER_YEAR = 365 days;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _baseRate // Base interest rate when utilization rate is 0; expressed in 1e18
    * @param _multiplier // Multiplier of utilization rate that gives the slope of the interest rate; expressed in 1e18
    * @param _jumpMultiplier // Multiplier after hitting a specified utilization point (kink2); expressed in 1e18
    * @param _kink1 // Utilization point at which the interest rate is fixed; expressed in 1e18
    * @param _kink2 // Utilization point at which the jump multiplier is applied; expressed in 1e18
  */
  constructor(
    uint256 _baseRate,
    uint256 _multiplier,
    uint256 _jumpMultiplier,
    uint256 _kink1,
    uint256 _kink2
  ) {
      baseRate = _baseRate;
      multiplier = _multiplier;
      jumpMultiplier = _jumpMultiplier;
      kink1 = _kink1;
      kink2 = _kink2;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Returns the interest rate per second
    * @param _debt Total borrowed amount
    * @param _floating Total available liquidity
    * @return rate Interest rate per second; expressed in 1e18
  */
  function getInterestRate(uint256 _debt, uint256 _floating) external view returns (uint256) {
    if (_debt == 0 && _floating == 0) return 0;

    uint256 total = _debt.add(_floating);
    // TODO div by safe multiplier or 1e16
    uint256 utilizationRate = _debt.mul(SAFE_MULTIPLIER).div(total);
    // calculate borrow rate for slope up to kink 1
    uint256 rate = baseRate.add(utilizationRate.mul(multiplier)
                                               .div(SAFE_MULTIPLIER)
                                               .div(SECONDS_PER_YEAR));

    // if utilization above kink2 return a high interest rate
    // (base + rate + excess utilization above kink 2 * jumpMultiplier)
    if (utilizationRate > kink2) {
       return baseRate.add(rate)
                      .add(jumpMultiplier)
                      .mul(utilizationRate.sub(kink2))
                      .div(SECONDS_PER_YEAR);
    }
    // if utilization between kink1 and kink2, rates are flat
    if (kink1 < utilizationRate && utilizationRate < kink2) {
      return baseRate.add(kink1.mul(multiplier))
                     .div(SECONDS_PER_YEAR);
    }
    // if utilization below kink1, return rate
    return rate;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
    * Updates lending pool interest rate model variables, callable only by owner
    @param _baseRate // Base interest rate when utilization rate is 0; expressed in 1e18
    @param _multiplier // Multiplier of utilization rate that gives the slope of the interest rate; expressed in 1e18
    @param _jumpMultiplier // Multiplier after hitting a specified utilization point (kink2); expressed in 1e18
    @param _kink1 // Utilization point at which the interest rate is fixed; expressed in 1e18
    @param _kink2 // Utilization point at which the jump multiplier is applied; expressed in 1e18
  */
  function updateInterestRateModel(
    uint256 _baseRate,
    uint256 _multiplier,
    uint256 _jumpMultiplier,
    uint256 _kink1,
    uint256 _kink2
  ) external onlyOwner {
    baseRate = _baseRate;
    multiplier = _multiplier;
    jumpMultiplier = _jumpMultiplier;
    kink1 = _kink1;
    kink2 = _kink2;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILendingPoolConfig {
  /**
    * Returns the interest rate per second
    * @param _debt total borrowed amount
    * @param _floating total available liquidity
  */
  function getInterestRate(uint256 _debt, uint256 _floating) external view returns (uint256);

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
library SafeMath {
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