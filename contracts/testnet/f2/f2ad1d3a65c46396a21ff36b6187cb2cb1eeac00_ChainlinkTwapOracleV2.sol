/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-09
*/

// File: contracts/interfaces/ITwapOracle.sol

// contracts/core/ITwapOracle.sol


pragma solidity 0.8.4;

interface ITwapOracle {
    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK, UNISWAP_V2}

    function getTwap(uint256 timestamp) external view returns (uint256);
}

// File: contracts/interfaces/ITwapOracleV2.sol

// contracts/core/ITwapOracleV2.sol


pragma solidity 0.8.4;


interface ITwapOracleV2 is ITwapOracle {
    function getLatest() external view returns (uint256);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/oracle/ChainlinkTwapOracleV2.sol

// contracts/oracle/ChainlinkTwapOracleV2.sol


pragma solidity 0.8.4;





/// @title Time-weighted average price oracle
/// @notice This contract extends the Chainlink Oracle, computes 30-minute
///         time-weighted average price (TWAP).
/// @author Tranchess
/// @dev This contract relies on the following assumptions on the Chainlink aggregator:
///      1. Round ID returned by `latestRoundData()` is monotonically increasing over time.
///      2. Round ID is continuous in the same phase. Formally speaking, let `x` and `y` be two
///         round IDs returned by `latestRoundData` in different blocks and they satisfy `x < y`
///         and `x >> 64 == y >> 64`. Then every integer between `x` and `y` is a valid round ID.
///      3. Phase change is rare.
///      4. Each round is updated only once and `updatedAt` returned by `getRoundData()` is
///         timestamp of the block in which the round is updated. Therefore, a transaction is
///         guaranteed to see all rounds whose `updatedAt` is less than the current block timestamp.
contract ChainlinkTwapOracleV2 is ITwapOracleV2, Ownable {
    using SafeMath for uint256;

    uint256 private constant EPOCH = 30 minutes;
    uint256 private constant MAX_ITERATION = 500;

    event Update(uint256 timestamp, uint256 price, UpdateType updateType);

    /// @notice Chainlink aggregator used as the data source.
    address public immutable chainlinkAggregator;

    /// @notice Minimum number of Chainlink rounds required in an epoch.
    uint256 public immutable chainlinkMinMessageCount;

    /// @notice Maximum gap between an epoch start and a previous Chainlink round for the round
    ///         to be used in TWAP calculation.
    uint256 public immutable chainlinkMessageExpiration;

    /// @dev A multipler that normalizes price from the Chainlink aggregator to 18 decimal places.
    uint256 private immutable _chainlinkPriceMultiplier;

    string public symbol;

    /// @dev Mapping of epoch end timestamp => TWAP
    mapping(uint256 => uint256) private _ownerUpdatedPrices;

    constructor(
        address chainlinkAggregator_,
        uint256 chainlinkMinMessageCount_,
        uint256 chainlinkMessageExpiration_,
        string memory symbol_
    ) {
        chainlinkAggregator = chainlinkAggregator_;
        require(chainlinkMinMessageCount_ > 0);
        chainlinkMinMessageCount = chainlinkMinMessageCount_;
        chainlinkMessageExpiration = chainlinkMessageExpiration_;
        uint256 decimal = AggregatorV3Interface(chainlinkAggregator_).decimals();
        _chainlinkPriceMultiplier = 10**(uint256(18).sub(decimal));
        symbol = symbol_;
    }

    /// @notice Return the latest price with 18 decimal places.
    function getLatest() external view override returns (uint256) {
        (, int256 answer, , uint256 updatedAt, ) =
            AggregatorV3Interface(chainlinkAggregator).latestRoundData();
        require(updatedAt >= block.timestamp - chainlinkMessageExpiration, "Stale price oracle");
        return uint256(answer).mul(_chainlinkPriceMultiplier);
    }

    /// @notice Return TWAP with 18 decimal places in the epoch ending at the specified timestamp.
    ///         Zero is returned if TWAP in the epoch is not available.
    /// @param timestamp End Timestamp in seconds of the epoch
    /// @return TWAP (18 decimal places) in the epoch, or zero if not available
    function getTwap(uint256 timestamp) external view override returns (uint256) {
        uint256 twap = _getTwapFromChainlink(timestamp);
        if (twap == 0) {
            twap = _ownerUpdatedPrices[timestamp];
        }
        return twap;
    }

    /// @notice Search for the last round before the given timestamp. Zeros are returned
    ///         if the search fails.
    function findLastRoundBefore(uint256 timestamp)
        public
        view
        returns (
            uint80 roundID,
            int256 answer,
            uint256 updatedAt
        )
    {
        (roundID, answer, , updatedAt, ) = AggregatorV3Interface(chainlinkAggregator)
            .latestRoundData();
        if (updatedAt < timestamp + EPOCH) {
            // Fast path: sequentially check each round when the target epoch is in the near past.
            for (uint256 i = 0; i < MAX_ITERATION && updatedAt >= timestamp && answer != 0; i++) {
                roundID--;
                (, answer, , updatedAt, ) = _getChainlinkRoundData(roundID);
            }
        } else {
            // Slow path: binary search. During the search, the `roundID` round is always updated
            // at or after the given timestamp, and the `leftRoundID` round is either invalid or
            // updated before the given timestamp.
            uint80 step = 1;
            uint80 leftRoundID = 0;
            while (step <= roundID) {
                leftRoundID = roundID - step;
                (, answer, , updatedAt, ) = _getChainlinkRoundData(leftRoundID);
                if (updatedAt < timestamp || answer == 0) {
                    break;
                }
                step <<= 1;
                roundID = leftRoundID;
            }
            while (leftRoundID + 1 < roundID) {
                uint80 midRoundID = (leftRoundID + roundID) / 2;
                (, answer, , updatedAt, ) = _getChainlinkRoundData(midRoundID);
                if (updatedAt < timestamp || answer == 0) {
                    leftRoundID = midRoundID;
                } else {
                    roundID = midRoundID;
                }
            }
            roundID = leftRoundID;
            (, answer, , updatedAt, ) = _getChainlinkRoundData(roundID);
        }
        if (updatedAt >= timestamp || answer == 0) {
            // The last round before the epoch end is not found, due to either incontinuous
            // round IDs caused by a phase change or abnormal `updatedAt` timestamps.
            return (0, 0, 0);
        }
    }

    /// @dev Calculate TWAP of the given epoch from the Chainlink oracle.
    /// @param timestamp End timestamp of the epoch to be updated
    /// @return TWAP of the epoch calculated from Chainlink, or zero if there's no sufficient data
    function _getTwapFromChainlink(uint256 timestamp) private view returns (uint256) {
        require(block.timestamp > timestamp, "Too soon");
        (uint80 roundID, int256 answer, uint256 updatedAt) = findLastRoundBefore(timestamp);
        if (answer == 0) {
            return 0;
        }
        uint256 sum = 0;
        uint256 sumTimestamp = timestamp;
        uint256 messageCount = 1;
        for (uint256 i = 0; i < MAX_ITERATION && updatedAt >= timestamp - EPOCH; i++) {
            sum = sum.add(uint256(answer).mul(sumTimestamp - updatedAt));
            sumTimestamp = updatedAt;
            if (roundID == 0) {
                break;
            }
            roundID--;
            (, int256 newAnswer, , uint256 newUpdatedAt, ) = _getChainlinkRoundData(roundID);
            if (
                newAnswer == 0 ||
                newUpdatedAt > updatedAt ||
                newUpdatedAt < timestamp - EPOCH - chainlinkMessageExpiration
            ) {
                break; // Stop if the previous round is invalid
            }
            answer = newAnswer;
            updatedAt = newUpdatedAt;
            messageCount++;
        }
        if (messageCount >= chainlinkMinMessageCount) {
            sum = sum.add(uint256(answer).mul(sumTimestamp - (timestamp - EPOCH)));
            return sum.mul(_chainlinkPriceMultiplier) / EPOCH;
        } else {
            return 0;
        }
    }

    /// @dev Call `chainlinkAggregator.getRoundData(roundID)`. Return zero if the call reverts.
    function _getChainlinkRoundData(uint80 roundID)
        private
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        (bool success, bytes memory returnData) =
            chainlinkAggregator.staticcall(
                abi.encodePacked(AggregatorV3Interface.getRoundData.selector, abi.encode(roundID))
            );
        if (success) {
            return abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));
        } else {
            return (roundID, 0, 0, 0, roundID);
        }
    }

    /// @notice Submit a TWAP with 18 decimal places by the owner.
    ///         This is allowed only when a epoch cannot be updated by either Chainlink or Uniswap.
    function updateTwapFromOwner(uint256 timestamp, uint256 price) external onlyOwner {
        require(timestamp % EPOCH == 0, "Unaligned timestamp");
        require(timestamp <= block.timestamp - EPOCH * 2, "Not ready for owner");
        require(_ownerUpdatedPrices[timestamp] == 0, "Owner cannot update an existing epoch");

        uint256 chainlinkTwap = _getTwapFromChainlink(timestamp);
        require(chainlinkTwap == 0, "Owner cannot overwrite Chainlink result");

        _ownerUpdatedPrices[timestamp] = price;
        emit Update(timestamp, price, UpdateType.OWNER);
    }
}