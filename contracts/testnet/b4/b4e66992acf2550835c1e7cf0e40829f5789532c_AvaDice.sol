/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-30
*/

// File: VRF_Dice.sol



/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/


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









/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

////// -License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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









/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

////// -License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



pragma solidity ^0.8.0;



////import "../../utils/introspection/IERC165.sol";



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

    function getApproved(uint256 tokenId) external view returns (address operator);



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

    function isApprovedForAll(address owner, address operator) external view returns (bool);



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









/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

////// -License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;



/** ****************************************************************************

 * @notice Interface for contracts using VRF randomness

 * *****************************************************************************

 * @dev PURPOSE

 *

 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness

 * @dev to Vera the verifier in such a way that Vera can be sure he's not

 * @dev making his output up to suit himself. Reggie provides Vera a public key

 * @dev to which he knows the secret key. Each time Vera provides a seed to

 * @dev Reggie, he gives back a value which is computed completely

 * @dev deterministically from the seed and the secret key.

 *

 * @dev Reggie provides a proof by which Vera can verify that the output was

 * @dev correctly computed once Reggie tells it to her, but without that proof,

 * @dev the output is indistinguishable to her from a uniform random sample

 * @dev from the output space.

 *

 * @dev The purpose of this contract is to make it easy for unrelated contracts

 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide

 * @dev simple access to a verifiable source of randomness. It ensures 2 things:

 * @dev 1. The fulfillment came from the VRFCoordinator

 * @dev 2. The consumer contract implements fulfillRandomWords.

 * *****************************************************************************

 * @dev USAGE

 *

 * @dev Calling contracts must inherit from VRFConsumerBase, and can

 * @dev initialize VRFConsumerBase's attributes in their constructor as

 * @dev shown:

 *

 * @dev   contract VRFConsumer {

 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)

 * @dev       VRFConsumerBase(_vrfCoordinator) public {

 * @dev         <initialization with other arguments goes here>

 * @dev       }

 * @dev   }

 *

 * @dev The oracle will have given you an ID for the VRF keypair they have

 * @dev committed to (let's call it keyHash). Create subscription, fund it

 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface

 * @dev subscription management functions).

 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,

 * @dev callbackGasLimit, numWords),

 * @dev see (VRFCoordinatorInterface for a description of the arguments).

 *

 * @dev Once the VRFCoordinator has received and validated the oracle's response

 * @dev to your request, it will call your contract's fulfillRandomWords method.

 *

 * @dev The randomness argument to fulfillRandomWords is a set of random words

 * @dev generated from your requestId and the blockHash of the request.

 *

 * @dev If your contract could have concurrent requests open, you can use the

 * @dev requestId returned from requestRandomWords to track which response is associated

 * @dev with which randomness request.

 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,

 * @dev if your contract could have multiple requests in flight simultaneously.

 *

 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds

 * @dev differ.

 *

 * *****************************************************************************

 * @dev SECURITY CONSIDERATIONS

 *

 * @dev A method with the ability to call your fulfillRandomness method directly

 * @dev could spoof a VRF response with any random value, so it's critical that

 * @dev it cannot be directly called by anything other than this base contract

 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).

 *

 * @dev For your users to trust that your contract's random behavior is free

 * @dev from malicious interference, it's best if you can write it so that all

 * @dev behaviors implied by a VRF response are executed *during* your

 * @dev fulfillRandomness method. If your contract must store the response (or

 * @dev anything derived from it) and use it later, you must ensure that any

 * @dev user-significant behavior which depends on that stored value cannot be

 * @dev manipulated by a subsequent VRF request.

 *

 * @dev Similarly, both miners and the VRF oracle itself have some influence

 * @dev over the order in which VRF responses appear on the blockchain, so if

 * @dev your contract could have multiple VRF requests in flight simultaneously,

 * @dev you must ensure that the order in which the VRF responses arrive cannot

 * @dev be used to manipulate your contract's user-significant behavior.

 *

 * @dev Since the block hash of the block which contains the requestRandomness

 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful

 * @dev miner could, in principle, fork the blockchain to evict the block

 * @dev containing the request, forcing the request to be included in a

 * @dev different block with a different hash, and therefore a different input

 * @dev to the VRF. However, such an attack would incur a substantial economic

 * @dev cost. This cost scales with the number of blocks the VRF oracle waits

 * @dev until it calls responds to a request. It is for this reason that

 * @dev that you can signal to an oracle you'd like them to wait longer before

 * @dev responding to the request (however this is not enforced in the contract

 * @dev and so remains effective only in the case of unmodified oracle software).

 */

abstract contract VRFConsumerBaseV2 {

  error OnlyCoordinatorCanFulfill(address have, address want);

  address private immutable vrfCoordinator;



  /**

   * @param _vrfCoordinator address of VRFCoordinator contract

   */

  constructor(address _vrfCoordinator) {

    vrfCoordinator = _vrfCoordinator;

  }



  /**

   * @notice fulfillRandomness handles the VRF response. Your contract must

   * @notice implement it. See "SECURITY CONSIDERATIONS" above for ////important

   * @notice principles to keep in mind when implementing your fulfillRandomness

   * @notice method.

   *

   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this

   * @dev signature, and will call it once it has verified the proof

   * @dev associated with the randomness. (It is triggered via a call to

   * @dev rawFulfillRandomness, below.)

   *

   * @param requestId The Id initially returned by requestRandomness

   * @param randomWords the VRF output expanded to the requested number of words

   */

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;



  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF

  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating

  // the origin of the call

  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {

    if (msg.sender != vrfCoordinator) {

      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);

    }

    fulfillRandomWords(requestId, randomWords);

  }

}









/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

////// -License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;



interface VRFCoordinatorV2Interface {

  /**

   * @notice Get configuration relevant for making requests

   * @return minimumRequestConfirmations global min for request confirmations

   * @return maxGasLimit global max for request gas limit

   * @return s_provingKeyHashes list of registered key hashes

   */

  function getRequestConfig()

    external

    view

    returns (

      uint16,

      uint32,

      bytes32[] memory

    );



  /**

   * @notice Request a set of random words.

   * @param keyHash - Corresponds to a particular oracle job which uses

   * that key for generating the VRF proof. Different keyHash's have different gas price

   * ceilings, so you can select a specific one to bound your maximum per request cost.

   * @param subId  - The ID of the VRF subscription. Must be funded

   * with the minimum subscription balance required for the selected keyHash.

   * @param minimumRequestConfirmations - How many blocks you'd like the

   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS

   * for why you may want to request more. The acceptable range is

   * [minimumRequestBlockConfirmations, 200].

   * @param callbackGasLimit - How much gas you'd like to receive in your

   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords

   * may be slightly less than this amount because of gas used calling the function

   * (argument decoding etc.), so you may need to request slightly more than you expect

   * to have inside fulfillRandomWords. The acceptable range is

   * [0, maxGasLimit]

   * @param numWords - The number of uint256 random values you'd like to receive

   * in your fulfillRandomWords callback. Note these numbers are expanded in a

   * secure way by the VRFCoordinator from a single random value supplied by the oracle.

   * @return requestId - A unique identifier of the request. Can be used to match

   * a request to a response in fulfillRandomWords.

   */

  function requestRandomWords(

    bytes32 keyHash,

    uint64 subId,

    uint16 minimumRequestConfirmations,

    uint32 callbackGasLimit,

    uint32 numWords

  ) external returns (uint256 requestId);



  /**

   * @notice Create a VRF subscription.

   * @return subId - A unique subscription id.

   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.

   * @dev Note to fund the subscription, use transferAndCall. For example

   * @dev  LINKTOKEN.transferAndCall(

   * @dev    address(COORDINATOR),

   * @dev    amount,

   * @dev    abi.encode(subId));

   */

  function createSubscription() external returns (uint64 subId);



  /**

   * @notice Get a VRF subscription.

   * @param subId - ID of the subscription

   * @return balance - LINK balance of the subscription in juels.

   * @return reqCount - number of requests for this subscription, determines fee tier.

   * @return owner - owner of the subscription.

   * @return consumers - list of consumer address which are able to use this subscription.

   */

  function getSubscription(uint64 subId)

    external

    view

    returns (

      uint96 balance,

      uint64 reqCount,

      address owner,

      address[] memory consumers

    );



  /**

   * @notice Request subscription owner transfer.

   * @param subId - ID of the subscription

   * @param newOwner - proposed new owner of the subscription

   */

  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;



  /**

   * @notice Request subscription owner transfer.

   * @param subId - ID of the subscription

   * @dev will revert if original owner of subId has

   * not requested that msg.sender become the new owner.

   */

  function acceptSubscriptionOwnerTransfer(uint64 subId) external;



  /**

   * @notice Add a consumer to a VRF subscription.

   * @param subId - ID of the subscription

   * @param consumer - New consumer which can use the subscription

   */

  function addConsumer(uint64 subId, address consumer) external;



  /**

   * @notice Remove a consumer from a VRF subscription.

   * @param subId - ID of the subscription

   * @param consumer - Consumer to remove from the subscription

   */

  function removeConsumer(uint64 subId, address consumer) external;



  /**

   * @notice Cancel a subscription

   * @param subId - ID of the subscription

   * @param to - Where to send the remaining LINK to

   */

  function cancelSubscription(uint64 subId, address to) external;

}









/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

//-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IAvaDatabase {





    function addGame(address _gameAddress) external;



    function removeGame(address _gameAddress) external;



    function updateStatistics(address player, bool isWin, uint _playedAmount, uint _wonAmount) external;



    function getInfoOfUser(address player, uint roundID) external view returns (uint gameNo, uint wonNo, uint lostNo, uint playedAmn,uint wonAmn,uint lostAmn);



    function getTotalInfo(uint roundID) external view returns (uint gameNo, uint wonNo, uint lostNo, uint playedAmn,uint wonAmn,uint lostAmn);



    function startNewRound() external;

}







/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

//-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IStrongbox {

    function depositAVAX() external payable;



    function depositAVAD(uint _value) external;



    function executePaymentAVAX(uint256 amount, address _to) external;



    function executePaymentAVAD(uint256 amount, address _to) external;

}







/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

////// -License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



pragma solidity ^0.8.0;



////import "../utils/Context.sol";



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









/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/

            

////// -License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)



pragma solidity ^0.8.0;



////import "../IERC721.sol";



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

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);



    /**

     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.

     * Use along with {totalSupply} to enumerate all tokens.

     */

    function tokenByIndex(uint256 index) external view returns (uint256);

}





/** 

 *  SourceUnit: d:\GitHub\AvaDice\AvaDice_DiceGame\contracts\AVAX\AvaDice_VRF.sol

*/



//-License-Identifier: MIT

pragma solidity ^0.8.0;



////import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

////import "@openzeppelin/contracts/access/Ownable.sol";

////import "./IStrongbox.sol";

////import "./IAvaDatabase.sol";



////import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

////import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";



contract AvaDice is Ownable, VRFConsumerBaseV2 {

    event GameResult(

        address player,

        uint playedAmount,

        uint wonAmount,

        bool result,

        uint winningNumber

    );



    uint256 public maxLimit = 2 ether;

    uint256 public minLimit = 0.1 ether;

    uint256 public publicHouseEdge = 20;

    uint256 public nftOwnerHouseEdgeMultip = 2;



    address private treasuryAddress;

    IStrongbox treasury;



    bool public isPaused;



    IERC721Enumerable AvaDiceNFT;

    IAvaDatabase database;



    /** VRF VARIABLES */

    VRFCoordinatorV2Interface COORDINATOR;



    // Your subscription ID.

    uint64 s_subscriptionId;



    // Rinkeby coordinator. For other networks,

    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;



    // The gas lane to use, which specifies the maximum gas price to bump to.

    // For a list of available gas lanes on each network,

    // see https://docs.chain.link/docs/vrf-contracts/#configurations

    bytes32 immutable keyHash =

        0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;



    uint32 callbackGasLimit = 25000;



    // The default is 3, but you can set this higher.

    uint16 immutable requestConfirmations = 1;



    // For this example, retrieve 2 random values in one request.

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.

    uint32 numWords = 1;



    uint256 public s_randomWords;

    uint256 public s_requestId;



    mapping(address => bool) isPlaying;

    mapping(address => uint[]) selectedRoll;

    mapping(address => uint) payedAmount;

    mapping(address => uint) playedBlock;



    bool private pending;



    constructor(

        address _treasuryAddress,

        address _nftAddress,

        address _database,

        uint64 subscriptionId

    ) VRFConsumerBaseV2(vrfCoordinator) {

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        setTresury(_treasuryAddress);

        AvaDiceNFT = IERC721Enumerable(_nftAddress);

        database = IAvaDatabase(_database);

        s_subscriptionId = subscriptionId;

    }



    function setTresury(address _treasuryAddress) public onlyOwner {

        treasuryAddress = _treasuryAddress;

        treasury = IStrongbox(treasuryAddress);

    }



    function setNFT(address _nftAddress) external onlyOwner {

        AvaDiceNFT = IERC721Enumerable(_nftAddress);

    }



    function setDataBase(address _database) external onlyOwner {

        database = IAvaDatabase(_database);

    }



    function setMaxLimit(uint256 _maxLimit) external onlyOwner {

        maxLimit = _maxLimit;

    }



    function setMinLimit(uint256 _minLimit) external onlyOwner {

        minLimit = _minLimit;

    }



    function setPublicHouseEdge(uint256 _houseEdge) external onlyOwner {

        publicHouseEdge = _houseEdge;

    }



    function setNFTOwnerHouseEdge(uint256 _nftOwnerHouseEdgeMultip)

        external

        onlyOwner

    {

        nftOwnerHouseEdgeMultip = _nftOwnerHouseEdgeMultip;

    }



    function setPause() external onlyOwner {

        isPaused = !isPaused;

    }



    function requestRandomWords() internal {

        // Will revert if subscription is not set and funded.

        s_requestId = COORDINATOR.requestRandomWords(

            keyHash,

            s_subscriptionId,

            requestConfirmations,

            callbackGasLimit,

            numWords

        );

    }



    function fulfillRandomWords(

        uint256, /* requestId */

        uint256[] memory randomWords

    ) internal override {

        pending = false;

        s_randomWords = (randomWords[0] % 6) + 1;

    }



    function playDice(

        uint dice1,

        uint dice2,

        uint dice3

    ) external payable {

        require(tx.origin == msg.sender);

        require(msg.value >= minLimit);

        require(msg.value <= maxLimit);

        require(!isPaused);

        require(!isPlaying[msg.sender]);

        selectedRoll[msg.sender] = [dice1, dice2, dice3];

        if(!pending) {

            pending = true;

            requestRandomWords();

        }

        payedAmount[msg.sender] = msg.value;

        playedBlock[msg.sender] = block.number;

        treasury.depositAVAX{value: msg.value}();

        isPlaying[msg.sender] = true;

    }



    function getResult() external {

        require(

            (playedBlock[msg.sender] + 4) <= block.number,

            "Please wait for VRF confirmation!"

        );

        isPlaying[msg.sender] = false;

        uint houseEdge = houseEdgeCalculator(msg.sender);

        uint amount = payedAmount[msg.sender];

        if (

            selectedRoll[msg.sender][0] == s_randomWords ||

            selectedRoll[msg.sender][1] == s_randomWords ||

            selectedRoll[msg.sender][2] == s_randomWords

        ) {

            uint pay = ((amount * 1000) / (houseEdge + 1000)) * 2;

            treasury.executePaymentAVAX(pay, msg.sender);

            emit GameResult(msg.sender, amount, pay, true, s_randomWords);

            database.updateStatistics(msg.sender, true, amount, pay);

        } else {

            emit GameResult(msg.sender, amount, 0, false, s_randomWords);

            database.updateStatistics(msg.sender, false, amount, 0);

        }

    }



    function houseEdgeCalculator(address player)

        public

        view

        returns (uint houseEdge)

    {

        uint balanceOfUser = AvaDiceNFT.balanceOf(player);

        bool isLegendaryOwner;

        for (uint i = 0; i < balanceOfUser; i++) {

            uint tokenId = AvaDiceNFT.tokenOfOwnerByIndex(player, i);

            if (tokenId >= 4431) {

                isLegendaryOwner = true;

            }

        }

        if (balanceOfUser >= 5 || isLegendaryOwner) {

            houseEdge = ((publicHouseEdge) - (5 * nftOwnerHouseEdgeMultip));

        } else {

            houseEdge = ((publicHouseEdge) -

                (balanceOfUser * nftOwnerHouseEdgeMultip));

        }

    }



    function withdraw() external onlyOwner {

        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");

        require(sent, "0x08");

    }



    function destroy() external onlyOwner {

        selfdestruct(payable(owner()));

    }

}