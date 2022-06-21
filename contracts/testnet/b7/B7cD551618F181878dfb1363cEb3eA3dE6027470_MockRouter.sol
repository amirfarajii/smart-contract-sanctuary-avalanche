// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Counter.sol";
import "../interfaces/IERC677.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Router contract
 * @author Applicature
 * @dev Contract for register AdditionalLottery contract as Keeper to track is game started and get winners
 */
contract MockRouter {
    event Registered(
        string name,
        bytes encryptedEmail,
        address indexed keeperRegistry,
        uint32 gasLimit,
        address indexed counter,
        bytes checkData,
        uint96 amount,
        uint8 source
    );

    uint8 private constant DECIMALS = 18;
    uint8 private constant MIN_LINK = 5;
    uint96 private constant MIN_GAS_LIMIT = 2300;

    IERC677 public immutable linkToken;
    address public upkeepRegistration;
    address public keeperRegistry;
    address public counter;

    //check the balance with Link tokens before each round

    constructor(
        address linkToken_,
        address upkeepRegistration_,
        address counter_,
        address keeperRegistry_
    ) {
        require(
            linkToken_ != address(0) &&
                upkeepRegistration_ != address(0) &&
                counter_ != address(0),
            "ZERO_ADDRESS"
        );
        linkToken = IERC677(linkToken_);
        upkeepRegistration = upkeepRegistration_;
        counter = counter_;
        keeperRegistry = keeperRegistry_;
    }

    function registerAdditionalLottery(
        string memory name,
        bytes memory encryptedEmail,
        uint32 gasLimit,
        bytes memory checkData,
        uint96 amount,
        uint8 source
    ) external {
        require(gasLimit >= MIN_GAS_LIMIT, "LOW_GAS_LIMIT");
        // require(amount >= MIN_LINK * DECIMALS, "LOW_AMOUNT");

        linkToken.transferFrom(msg.sender, counter, amount);

        // transferLinkTokens(counter, amount);

        // register as upkeep additional lottery
        linkToken.transferAndCall(
            upkeepRegistration,
            amount,
            abi.encodeWithSignature(
                "register(string memory name,bytes calldata encryptedEmail,address upkeepContract,uint32 gasLimit,address adminAddress,bytes calldata checkData,uint96 amount,uint8 source)",
                name,
                encryptedEmail,
                keeperRegistry,
                gasLimit,
                address(this),
                checkData,
                amount,
                source
            )
        );

        emit Registered(
            name,
            encryptedEmail,
            keeperRegistry,
            gasLimit,
            counter,
            checkData,
            amount,
            source
        );
    }

    function cancelUpkeep(uint256 id_) external {
        (bool success1, bytes memory returnData1) = keeperRegistry.call(
            abi.encodeWithSignature("function cancelUpkeep(uint256 id))", id_)
        );
        require(success1, "INVALID_CALL_CANCEL");

        //withdraw tokens
    }

    // function transferLinkTokens(address counter_, uint96 amount_) private {
    // // check the balance of user with Link tokens
    // (bool success, bytes memory returnData) = linkToken.delegatecall(
    //     abi.encodeWithSignature("balanceOf(address _owner)", msg.sender)
    // );
    // require(success, "INVALID_DELEGATECALL_BALANCEOF");

    // (uint256 userBalance) = abi.decode(returnData, (uint256));
    // require(userBalance >= amount_, "INVALID_BALANCE");

    // // approve transfer tokens from msg.sender to AdditionalGame contract
    // (bool success1, bytes memory returnData1) = linkToken.delegatecall(
    //     abi.encodeWithSignature(
    //         "approve(address _spender, uint256 _value)",
    //         address(counter_),
    //         amount_
    //     )
    // );
    // require(success1, "INVALID_DELEGATECALL_APPROVE");

    // transfer tokens from msg.sender to AdditionalGame contract
    //     (bool success2, bytes memory returnData2) = linkToken.delegatecall(
    //         abi.encodeWithSignature(
    //             "transferFrom(address _from, address _to, uint256 _value)",
    //             msg.sender,
    //             counter_,
    //             amount_
    //         )
    //     );
    //     require(success2, "INVALID_DELEGATECALL_TRANSFER");
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Counter is KeeperCompatibleInterface {
    /**
    * Public counter variable
    */
    uint public counter;

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public lastTimeStamp;

    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;

      counter = 0;
    }

    function checkUpkeep(bytes calldata  checkData ) external view override returns (bool upkeepNeeded, bytes memory  performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata  performData ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            counter = counter++;
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC677 is IERC20 {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}