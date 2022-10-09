// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./chainlink/VRFConsumerBaseV2.sol";
import "./chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "./chainlink-vrf.sol";
import "./claw-prize.sol";
import "./tiered sales.sol";

/* jiggypuff                                                                                                                                           
                   .....                                                                                                            
                  .....  ...                                                                                                        
                 ...:**+=:. ....                                                                                                    
                ....*######+:. ....                                                                                                 
                ...+#########*=. .....                                                                                              
               ...:#############-   .....          .................                                                                
               ...-##############*: .......     .......................                                                             
               ...=################=.....................................                                                           
               ...-#################+:..................................:.                                                          
               ...-############*=-:.......::............................::.                                                         
               ....*########+-:..........::.........     ...............:::.                                                        
               ... +#####*=:.............:........       ..............:::::..                                                      
               .....*##+-:..............::........      ..............::::::::................                                      
               :....:=:.................:........       ..........:::::::::::::.........           ....                             
               .:...:..................:::.......      .....:::::::::::::::.............:::-----:::.... ...                         
               .:::::..................:::.......      ..:::::::::::::::..........:..-################*+=-.  ...                    
                :::....................::::.......    ..:::..:::::::..................:+###################+-.....                  
               .:::.....................::::.......   ..:......:......................:.-###################+....                   
              .::..................... .:::::............................................=#################=..::                    
             .:::.......    ..::. ... ...:::::.................::.....................:::.+##############*-..:.                     
            .:::.....    :=+*++=::::..   .::::::..............:::.......................:::=###########*-..::.                      
           .::::....   .++++++-    :*-.   .:::::::::......::::::........................:::.+########+-...:.                        
           :.:...:.   :*++++++-    =+*-   ...::::::::::::::::::..........................::::#####*=....::.                         
          .::::...   .*++++++++===++++=   .. ..:::::::::::::::.    ......................::::+##=:....::.                           
          :::::.:.   =*+++++++++++++++=    .   ....::::::::..   .........................::::::.....:::                             
         .:::::::    =*++++++++++++++*:                  ... ...       .:::..............:::::...:::.                               
         ::::::::.   :*+++++++++++++*-.                  . ...      :=+*++++-:::.......::::::::::::                                 
        .::::::::.    :**+++++++++*=:...                  ..      :+*+++++=    ==:.....::::::::::                                   
        .:::::::::...  .-++**+*+=-::.....                 :      .*+++++++=.   -*+....:::::::::.                                    
        :::::::::.::.      ...   ::.......               ..      =++++++++++--=++*:...:::::::::.                                    
  .........:::......::..     ..::........................:.      ++++++++++++++++*-...:::::::::.                                    
 .....     ...........::::::::...........................:.      +++++++++++++++**:.:::::::::::                                     
 .:....          ..........................................      :*+++++++++++++*-:::::::::::::                                     
  .:........  .......................:-:..................:       -**+++++++++*+::::::::::::::.                                     
   .:::................................-=-:................:.       -+***++**+-.::::::::::::::                                      
     .:::::...............................:--=-----:........::        .:---:..:::::::::::::::.                                      
       .:::::::::::::::.......................................::..    .....:::::::::::::::::.                                       
          .::::::::::::::::......................................:::::::::::::::::::::::::::                                        
            :::::::::::::::::::.............................................:::::::::::::::                                         
             .::::::::::::::::::::::.........................................:::::::::::::                                          
              ::::::::::::::::::::::::::......................................:::::::::::                                           
               .::::::::::::::::::::::::::::::::::::::::::::::::::.....    ....:::::::::                                            
                 :::::::::::::::::::::::::::::::::::::::::::::::::.....     ...:::::::.                                             
                  .::::::::::::::::::::::::::::::::::::::::::::::::.....    ...:::::.                                               
                    .::::::::::::::::::::::::::::::::::::::::::::::::....   ...::::                                                 
                  ..:::::::::::::::::::::::::::::::::::::::::::::::::..... ....::.                                                  
                .:::::::::::::::::::::::::::::::::::::::::::::::::::::.........:                                                    
              .::::::::::----::::::::::::::::::::::::::::::::::::::::::.......:.                                                    
            .......:::::::--------:::::::::::::::::::::::::::::::::::::::....::                                                     
           ..........::::::------------:::::::::::::::::::::::::::------::::::-::                                                   
          ...........::::::------=--:.     .....:::::::::-----------------::::::::.                                                 
         ...........:::::------:.                        :--------------::::::::::::.                                               
          ........::::::-:::.                              :----------::::::::.....::.                                              
           ............                                      .:------:::::::..........                                              
                                                                 .:--::::::............                                             
                                                                    ..:::::::.........                                              
                                                                         ...::::::..                                                
                                                                                                                                                      

lol hi feel free to read and learn from my bad/copied code 
check my twitter too @miphguy
*/

contract clawMachine is ConfirmedOwner, VRF {
    uint256 private _price;
    uint256 private _maxPerTx = 10;
    uint256 public maxPlays = 100;
    bool public paused;
    uint256 public avaxWon;
    bool public avaSharkWon = false;
    address private avashark = 0xBAe25062E3684DDD951488A9EC304E7e58F13780;
    uint256 private avasharkToken = 790;
    prize contract1;
    prize contract2;
    bbb contractBBB;
    event win(string prize, address user);
    event Transfer(address from, address to, uint256 tokenId);

    constructor(address[3] memory prizes) VRF(431, 100) {
        contract1 = prize(prizes[0]);
        contract2 = prize(prizes[1]);
        contractBBB = bbb(prizes[2]);
    }

    function setPrice(uint256 priceInMilli) external onlyOwner {
        _price = priceInMilli;
    }

    function minted1() public view returns (uint256) {
        return contract1.totalSupply();
    }

    function minted2() public view returns (uint256) {
        return contract2.totalSupply();
    }

    function mintedBBB() public view returns (uint256) {
        return contractBBB.totalSupply();
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function refillPlays(uint256 plays) external onlyOwner {
        maxPlays = plays;
    }

    function withdraw(uint256 amountInMilli) external onlyOwner {
        payable(msg.sender).transfer(amountInMilli * 10**15);
    }

    function withdrawErc20(address addy) external onlyOwner {
        IERC20 erc = IERC20(addy);
        erc.transfer(msg.sender, erc.balanceOf(address(this)));
    }

    function deposit() external payable {}

    function play() external payable {
        require(!paused, "game is paused");
        require(msg.value >= (_price), "incorrect amount of AVAX sent");
        //require(address(this).balance > 1 ether, "not enough avax in the contract");
        internalMint(msg.sender);
    }

    function internalMint(address to) internal {
        bool hasRemaining1 = minted1() < contract1.maxMintable();
        bool hasRemaining2 = minted2() < contract2.maxMintable();
        bool hasRemainingBBB = mintedBBB() < contractBBB.maxMintable();
        require(
            hasRemaining1 ||
                hasRemaining2 ||
                hasRemainingBBB ||
                !avaSharkWon ||
                avaxWon < 100,
            "no more prizes"
        );
        require(maxPlays > 0, "no more plays, ask owner to refill the machine");
        bool exit = false;
        while (!exit){
        uint256 randomNum = (getRandomness() % 200) + 1;
        if (randomNum <= 10 && hasRemainingBBB) {
    
            contractBBB.clawMint(to);
            maxPlays--;
            emit win("bbb", to);
        } else if (10 < randomNum && randomNum <= 35 && hasRemaining1) {
            contract1.mint(to);
            maxPlays--;
            emit win("prize 1", to);
        } else if (35 < randomNum && randomNum <= 80 && hasRemaining2) {
            contract2.mint(to);
            maxPlays--;
            emit win("prize 2", to);
        } else if (85 < randomNum && randomNum <= 95 && !avaSharkWon) {
            IERC721(avashark).safeTransferFrom(owner(), to, avasharkToken);
            avaSharkWon = true;
            maxPlays--;
            emit win("an avashark", to);
        } else if (95 < randomNum && randomNum <= 100 && avaxWon < 100) {
            payable(to).transfer(0.01 ether);
            avaxWon++;
            maxPlays--;
            emit win("1 AVAX", to);
        } else {
            if (randomNum > 100) {
                exit = true;
                }
            maxPlays--;
            emit win("nothing", to);
        }
        }
    }
}
/*  
░░░░░░░░░░░▄▀▀░░▀▀▄  jigglypuff 
▌▄▄▄░▀▀░▄▄▀░░░░░░░░█▄▄░▀▀░▄▄▄▀
▌▐█████░░▀░░░░░░░░░▐░░░█████▌▐
▐░███▀░░░▄░░░░░░░▀▀▄░░░░▀███░▌
░█░▀▀░░░░░█░░░░░░░░▌░░░░░▀▀░█
░░█▀░░▄▐██░▀▄░░░░▄█▄▐█▌▄░░░█
░░▄░░░██▄██░░░▀▀▀░▄███▄█░░░▐
░░▌░░▀█████▐░░░░░░▀█████▀░░▀
░░▌░░▀▀▀▀▀▀▀░░░░░░▀▄▀▀▀▀█░░▐
░░█░░░░▀▀░░░▀█▄▄▄▀░░░▀▀░░░░█
░░▀▄░░░░█░░░░▀▀▀▀░░░░▄░░░░▄▀
░░░▀▄░▄░░▌░░░░░░░░░░▐░░▄░▄▀
░░░░░▀▄▀▀░░░░░░░░░░░░▀▀▄▀
░░░▄▀░░▀▀▄▄░░░░░░░░▄▄▀▀░░▀▄
░░░▐▄░▄▄▄▄░▀▀▀▀▀▀▀▀░▄▄▄▄░▄▄
*/

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.4;

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
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
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

// SPDX-License-Identifier: MIT
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./chainlink/VRFConsumerBaseV2.sol";
import "./chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "./chainlink/ConfirmedOwner.sol";

/* jiggypuff                                                                                                                                           
                   .....                                                                                                            
                  .....  ...                                                                                                        
                 ...:**+=:. ....                                                                                                    
                ....*######+:. ....                                                                                                 
                ...+#########*=. .....                                                                                              
               ...:#############-   .....          .................                                                                
               ...-##############*: .......     .......................                                                             
               ...=################=.....................................                                                           
               ...-#################+:..................................:.                                                          
               ...-############*=-:.......::............................::.                                                         
               ....*########+-:..........::.........     ...............:::.                                                        
               ... +#####*=:.............:........       ..............:::::..                                                      
               .....*##+-:..............::........      ..............::::::::................                                      
               :....:=:.................:........       ..........:::::::::::::.........           ....                             
               .:...:..................:::.......      .....:::::::::::::::.............:::-----:::.... ...                         
               .:::::..................:::.......      ..:::::::::::::::..........:..-################*+=-.  ...                    
                :::....................::::.......    ..:::..:::::::..................:+###################+-.....                  
               .:::.....................::::.......   ..:......:......................:.-###################+....                   
              .::..................... .:::::............................................=#################=..::                    
             .:::.......    ..::. ... ...:::::.................::.....................:::.+##############*-..:.                     
            .:::.....    :=+*++=::::..   .::::::..............:::.......................:::=###########*-..::.                      
           .::::....   .++++++-    :*-.   .:::::::::......::::::........................:::.+########+-...:.                        
           :.:...:.   :*++++++-    =+*-   ...::::::::::::::::::..........................::::#####*=....::.                         
          .::::...   .*++++++++===++++=   .. ..:::::::::::::::.    ......................::::+##=:....::.                           
          :::::.:.   =*+++++++++++++++=    .   ....::::::::..   .........................::::::.....:::                             
         .:::::::    =*++++++++++++++*:                  ... ...       .:::..............:::::...:::.                               
         ::::::::.   :*+++++++++++++*-.                  . ...      :=+*++++-:::.......::::::::::::                                 
        .::::::::.    :**+++++++++*=:...                  ..      :+*+++++=    ==:.....::::::::::                                   
        .:::::::::...  .-++**+*+=-::.....                 :      .*+++++++=.   -*+....:::::::::.                                    
        :::::::::.::.      ...   ::.......               ..      =++++++++++--=++*:...:::::::::.                                    
  .........:::......::..     ..::........................:.      ++++++++++++++++*-...:::::::::.                                    
 .....     ...........::::::::...........................:.      +++++++++++++++**:.:::::::::::                                     
 .:....          ..........................................      :*+++++++++++++*-:::::::::::::                                     
  .:........  .......................:-:..................:       -**+++++++++*+::::::::::::::.                                     
   .:::................................-=-:................:.       -+***++**+-.::::::::::::::                                      
     .:::::...............................:--=-----:........::        .:---:..:::::::::::::::.                                      
       .:::::::::::::::.......................................::..    .....:::::::::::::::::.                                       
          .::::::::::::::::......................................:::::::::::::::::::::::::::                                        
            :::::::::::::::::::.............................................:::::::::::::::                                         
             .::::::::::::::::::::::.........................................:::::::::::::                                          
              ::::::::::::::::::::::::::......................................:::::::::::                                           
               .::::::::::::::::::::::::::::::::::::::::::::::::::.....    ....:::::::::                                            
                 :::::::::::::::::::::::::::::::::::::::::::::::::.....     ...:::::::.                                             
                  .::::::::::::::::::::::::::::::::::::::::::::::::.....    ...:::::.                                               
                    .::::::::::::::::::::::::::::::::::::::::::::::::....   ...::::                                                 
                  ..:::::::::::::::::::::::::::::::::::::::::::::::::..... ....::.                                                  
                .:::::::::::::::::::::::::::::::::::::::::::::::::::::.........:                                                    
              .::::::::::----::::::::::::::::::::::::::::::::::::::::::.......:.                                                    
            .......:::::::--------:::::::::::::::::::::::::::::::::::::::....::                                                     
           ..........::::::------------:::::::::::::::::::::::::::------::::::-::                                                   
          ...........::::::------=--:.     .....:::::::::-----------------::::::::.                                                 
         ...........:::::------:.                        :--------------::::::::::::.                                               
          ........::::::-:::.                              :----------::::::::.....::.                                              
           ............                                      .:------:::::::..........                                              
                                                                 .:--::::::............                                             
                                                                    ..:::::::.........                                              
                                                                         ...::::::..                                                
                                                                                                                                                      

lol hi feel free to read and learn from my bad/copied code 
check my twitter too @miphguy
*/

contract VRF is ConfirmedOwner, VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId);
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) private requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint256 private currentRngIndex = 0;
    uint256 private currentRequestIndex;
    bytes32 keyHash =
        0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords;

    constructor(
        uint64 subscriptionId,
        uint32 _numWords
    )
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        ConfirmedOwner(msg.sender)
    {
        numWords = _numWords;
        COORDINATOR = VRFCoordinatorV2Interface(
            0x2eD832Ba664535e5886b75D64C46EB9a228C2610
        );
        s_subscriptionId = subscriptionId;



    }
    


    function setWordsAndGas(uint32 num, uint32 gas) external onlyOwner {
        numWords = num;
        callbackGasLimit = gas;
    }

    function requestRandomWords()
        public
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(requests[_requestId].exists, "request not found");
        requests[_requestId].fulfilled = true;
        requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled)
    {
        require(requests[_requestId].exists, "request not found");
        RequestStatus memory request = requests[_requestId];
        return (request.fulfilled);
    }

    function getRandomness() internal returns (uint256 randomWord) {
        require(
            requests[requestIds[currentRequestIndex]].exists,
            "request not found"
        );
        RequestStatus memory request = requests[
            requestIds[currentRequestIndex]
        ];
        randomWord = request.randomWords[currentRngIndex];
        if (currentRngIndex < numWords - 1) {
            currentRngIndex++;
        } else {
            currentRngIndex = 0;
            currentRequestIndex++;
        }
        return randomWord;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "./chainlink/ConfirmedOwner.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./chainlink-vrf.sol";
import "./BatchRevealPrize.sol";
import "./Authorizable.sol";

/* jiggypuff                                                                                                                                           
                   .....                                                                                                            
                  .....  ...                                                                                                        
                 ...:**+=:. ....                                                                                                    
                ....*######+:. ....                                                                                                 
                ...+#########*=. .....                                                                                              
               ...:#############-   .....          .................                                                                
               ...-##############*: .......     .......................                                                             
               ...=################=.....................................                                                           
               ...-#################+:..................................:.                                                          
               ...-############*=-:.......::............................::.                                                         
               ....*########+-:..........::.........     ...............:::.                                                        
               ... +#####*=:.............:........       ..............:::::..                                                      
               .....*##+-:..............::........      ..............::::::::................                                      
               :....:=:.................:........       ..........:::::::::::::.........           ....                             
               .:...:..................:::.......      .....:::::::::::::::.............:::-----:::.... ...                         
               .:::::..................:::.......      ..:::::::::::::::..........:..-################*+=-.  ...                    
                :::....................::::.......    ..:::..:::::::..................:+###################+-.....                  
               .:::.....................::::.......   ..:......:......................:.-###################+....                   
              .::..................... .:::::............................................=#################=..::                    
             .:::.......    ..::. ... ...:::::.................::.....................:::.+##############*-..:.                     
            .:::.....    :=+*++=::::..   .::::::..............:::.......................:::=###########*-..::.                      
           .::::....   .++++++-    :*-.   .:::::::::......::::::........................:::.+########+-...:.                        
           :.:...:.   :*++++++-    =+*-   ...::::::::::::::::::..........................::::#####*=....::.                         
          .::::...   .*++++++++===++++=   .. ..:::::::::::::::.    ......................::::+##=:....::.                           
          :::::.:.   =*+++++++++++++++=    .   ....::::::::..   .........................::::::.....:::                             
         .:::::::    =*++++++++++++++*:                  ... ...       .:::..............:::::...:::.                               
         ::::::::.   :*+++++++++++++*-.                  . ...      :=+*++++-:::.......::::::::::::                                 
        .::::::::.    :**+++++++++*=:...                  ..      :+*+++++=    ==:.....::::::::::                                   
        .:::::::::...  .-++**+*+=-::.....                 :      .*+++++++=.   -*+....:::::::::.                                    
        :::::::::.::.      ...   ::.......               ..      =++++++++++--=++*:...:::::::::.                                    
  .........:::......::..     ..::........................:.      ++++++++++++++++*-...:::::::::.                                    
 .....     ...........::::::::...........................:.      +++++++++++++++**:.:::::::::::                                     
 .:....          ..........................................      :*+++++++++++++*-:::::::::::::                                     
  .:........  .......................:-:..................:       -**+++++++++*+::::::::::::::.                                     
   .:::................................-=-:................:.       -+***++**+-.::::::::::::::                                      
     .:::::...............................:--=-----:........::        .:---:..:::::::::::::::.                                      
       .:::::::::::::::.......................................::..    .....:::::::::::::::::.                                       
          .::::::::::::::::......................................:::::::::::::::::::::::::::                                        
            :::::::::::::::::::.............................................:::::::::::::::                                         
             .::::::::::::::::::::::.........................................:::::::::::::                                          
              ::::::::::::::::::::::::::......................................:::::::::::                                           
               .::::::::::::::::::::::::::::::::::::::::::::::::::.....    ....:::::::::                                            
                 :::::::::::::::::::::::::::::::::::::::::::::::::.....     ...:::::::.                                             
                  .::::::::::::::::::::::::::::::::::::::::::::::::.....    ...:::::.                                               
                    .::::::::::::::::::::::::::::::::::::::::::::::::....   ...::::                                                 
                  ..:::::::::::::::::::::::::::::::::::::::::::::::::..... ....::.                                                  
                .:::::::::::::::::::::::::::::::::::::::::::::::::::::.........:                                                    
              .::::::::::----::::::::::::::::::::::::::::::::::::::::::.......:.                                                    
            .......:::::::--------:::::::::::::::::::::::::::::::::::::::....::                                                     
           ..........::::::------------:::::::::::::::::::::::::::------::::::-::                                                   
          ...........::::::------=--:.     .....:::::::::-----------------::::::::.                                                 
         ...........:::::------:.                        :--------------::::::::::::.                                               
          ........::::::-:::.                              :----------::::::::.....::.                                              
           ............                                      .:------:::::::..........                                              
                                                                 .:--::::::............                                             
                                                                    ..:::::::.........                                              
                                                                         ...::::::..                                                
                                                                                                                                                      

lol hi feel free to read and learn from my bad/copied code 
check my twitter too @miphguy
*/

contract prize is ERC721A, ERC721AQueryable, ConfirmedOwner, BatchRevealPrize, Authorizable {
    using Strings for uint256;

    uint256 public maxMintable;
    string private _customBaseURI;
    string private _URISuffix = ".json";
    uint256 private _royaltyAmount;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bool public paused;
    string public unrevealedURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 max,
        string memory baseUri,
        string memory unrevealedURI_,
        bool paused_
    )
        ERC721A(name, symbol)
        ConfirmedOwner(msg.sender)
    {
        _customBaseURI = baseUri;
        unrevealedURI = unrevealedURI_;
        paused = paused_;
        maxMintable = max;
    }

    function mintByOwner(address to) public onlyOwner {
        _mint(to, 1);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(uint256(keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1),block.difficulty))));
        }
    }

    function maxValues(uint256 maxMintable_) public onlyOwner {
        maxMintable = maxMintable_;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawErc20(address addy) external onlyOwner {
        IERC20 erc = IERC20(addy);
        erc.transfer(msg.sender, erc.balanceOf(address(this)));
    }

    function mint(address to) public onlyAuthorized {
        require(totalSupply() < maxMintable, "minting more than max supply");
        _mint(to, 1);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(uint256(keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1),block.difficulty))));
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (tokenId >= lastTokenRevealed) {
            return unrevealedURI;
        } else {
            return
                string.concat(
                    _customBaseURI,
                    getShuffledTokenId(tokenId).toString(),
                    _URISuffix
                );
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), ((_salePrice * _royaltyAmount) / 10000));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}

/*  
░░░░░░░░░░░▄▀▀░░▀▀▄  jigglypuff 
▌▄▄▄░▀▀░▄▄▀░░░░░░░░█▄▄░▀▀░▄▄▄▀
▌▐█████░░▀░░░░░░░░░▐░░░█████▌▐
▐░███▀░░░▄░░░░░░░▀▀▄░░░░▀███░▌
░█░▀▀░░░░░█░░░░░░░░▌░░░░░▀▀░█
░░█▀░░▄▐██░▀▄░░░░▄█▄▐█▌▄░░░█
░░▄░░░██▄██░░░▀▀▀░▄███▄█░░░▐
░░▌░░▀█████▐░░░░░░▀█████▀░░▀
░░▌░░▀▀▀▀▀▀▀░░░░░░▀▄▀▀▀▀█░░▐
░░█░░░░▀▀░░░▀█▄▄▄▀░░░▀▀░░░░█
░░▀▄░░░░█░░░░▀▀▀▀░░░░▄░░░░▄▀
░░░▀▄░▄░░▌░░░░░░░░░░▐░░▄░▄▀
░░░░░▀▄▀▀░░░░░░░░░░░░▀▀▄▀
░░░▄▀░░▀▀▄▄░░░░░░░░▄▄▀▀░░▀▄
░░░▐▄░▄▄▄▄░▀▀▀▀▀▀▀▀░▄▄▄▄░▄▄
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "./chainlink-vrf.sol";
import "./BatchReveal.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Authorizable.sol";

/* jiggypuff                                                                                                                                           
                   .....                                                                                                            
                  .....  ...                                                                                                        
                 ...:**+=:. ....                                                                                                    
                ....*######+:. ....                                                                                                 
                ...+#########*=. .....                                                                                              
               ...:#############-   .....          .................                                                                
               ...-##############*: .......     .......................                                                             
               ...=################=.....................................                                                           
               ...-#################+:..................................:.                                                          
               ...-############*=-:.......::............................::.                                                         
               ....*########+-:..........::.........     ...............:::.                                                        
               ... +#####*=:.............:........       ..............:::::..                                                      
               .....*##+-:..............::........      ..............::::::::................                                      
               :....:=:.................:........       ..........:::::::::::::.........           ....                             
               .:...:..................:::.......      .....:::::::::::::::.............:::-----:::.... ...                         
               .:::::..................:::.......      ..:::::::::::::::..........:..-################*+=-.  ...                    
                :::....................::::.......    ..:::..:::::::..................:+###################+-.....                  
               .:::.....................::::.......   ..:......:......................:.-###################+....                   
              .::..................... .:::::............................................=#################=..::                    
             .:::.......    ..::. ... ...:::::.................::.....................:::.+##############*-..:.                     
            .:::.....    :=+*++=::::..   .::::::..............:::.......................:::=###########*-..::.                      
           .::::....   .++++++-    :*-.   .:::::::::......::::::........................:::.+########+-...:.                        
           :.:...:.   :*++++++-    =+*-   ...::::::::::::::::::..........................::::#####*=....::.                         
          .::::...   .*++++++++===++++=   .. ..:::::::::::::::.    ......................::::+##=:....::.                           
          :::::.:.   =*+++++++++++++++=    .   ....::::::::..   .........................::::::.....:::                             
         .:::::::    =*++++++++++++++*:                  ... ...       .:::..............:::::...:::.                               
         ::::::::.   :*+++++++++++++*-.                  . ...      :=+*++++-:::.......::::::::::::                                 
        .::::::::.    :**+++++++++*=:...                  ..      :+*+++++=    ==:.....::::::::::                                   
        .:::::::::...  .-++**+*+=-::.....                 :      .*+++++++=.   -*+....:::::::::.                                    
        :::::::::.::.      ...   ::.......               ..      =++++++++++--=++*:...:::::::::.                                    
  .........:::......::..     ..::........................:.      ++++++++++++++++*-...:::::::::.                                    
 .....     ...........::::::::...........................:.      +++++++++++++++**:.:::::::::::                                     
 .:....          ..........................................      :*+++++++++++++*-:::::::::::::                                     
  .:........  .......................:-:..................:       -**+++++++++*+::::::::::::::.                                     
   .:::................................-=-:................:.       -+***++**+-.::::::::::::::                                      
     .:::::...............................:--=-----:........::        .:---:..:::::::::::::::.                                      
       .:::::::::::::::.......................................::..    .....:::::::::::::::::.                                       
          .::::::::::::::::......................................:::::::::::::::::::::::::::                                        
            :::::::::::::::::::.............................................:::::::::::::::                                         
             .::::::::::::::::::::::.........................................:::::::::::::                                          
              ::::::::::::::::::::::::::......................................:::::::::::                                           
               .::::::::::::::::::::::::::::::::::::::::::::::::::.....    ....:::::::::                                            
                 :::::::::::::::::::::::::::::::::::::::::::::::::.....     ...:::::::.                                             
                  .::::::::::::::::::::::::::::::::::::::::::::::::.....    ...:::::.                                               
                    .::::::::::::::::::::::::::::::::::::::::::::::::....   ...::::                                                 
                  ..:::::::::::::::::::::::::::::::::::::::::::::::::..... ....::.                                                  
                .:::::::::::::::::::::::::::::::::::::::::::::::::::::.........:                                                    
              .::::::::::----::::::::::::::::::::::::::::::::::::::::::.......:.                                                    
            .......:::::::--------:::::::::::::::::::::::::::::::::::::::....::                                                     
           ..........::::::------------:::::::::::::::::::::::::::------::::::-::                                                   
          ...........::::::------=--:.     .....:::::::::-----------------::::::::.                                                 
         ...........:::::------:.                        :--------------::::::::::::.                                               
          ........::::::-:::.                              :----------::::::::.....::.                                              
           ............                                      .:------:::::::..........                                              
                                                                 .:--::::::............                                             
                                                                    ..:::::::.........                                              
                                                                         ...::::::..                                                
                                                                                                                                                      

lol hi feel free to read and learn from my bad/copied code 
check my twitter too @miphguy
*/

contract bbb is
    ERC721A,
    ERC721AQueryable,
    ERC721ABurnable,
    VRF,
    BatchReveal,
    Authorizable
{
    using Strings for uint256;
    uint256 private price;
    uint256 public maxMintable = 3060;
    string private customBaseURI;
    string private unrevealedURI;
    string private URISuffix = ".json";
    uint256 private royaltyAmount;
    uint256[4] private tierMints;
    uint256[4] private tierPrice;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public wlTime;
    uint256 public publicTime;
    bool public paused;
    bytes32 public immutable merkleRootT1;
    bytes32 public immutable merkleRootT2;
    bytes32 public immutable merkleRootT3;

    constructor(
        bytes32 _merkleRootT1,
        bytes32 _merkleRootT2,
        bytes32 _merkleRootT3
    ) ERC721A("Bad Biz Bones", "BBB") VRF(431, 102) {
        customBaseURI = "revealed";
        unrevealedURI = "unrevealed";
        price = 0.01 ether;
        royaltyAmount = 500;
        tierMints = [0, 10, 5, 2]; //don't mind my stupid use of arrays i like having the indexes start from 1
        tierPrice = [999 ether, 0.15 ether, 0.1 ether, 0]; //same as previous array
        paused = true;
        wlTime = 0;
        publicTime = 1;
        merkleRootT1 = _merkleRootT1;
        merkleRootT2 = _merkleRootT2;
        merkleRootT3 = _merkleRootT3;
    }

    mapping(address => uint256) public publicMints;
    mapping(address => bool) public claimed1;
    mapping(address => bool) public claimed2;
    mapping(address => bool) public claimed3;
    mapping(uint256 => address) royaltyReceiver; //to give royalties to minters

    function setTierMints(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3
    ) public onlyOwner {
        tierMints = [0, tier1, tier2, tier3];
    }

    function setTierPrice(
        uint256 tier1,
        uint256 tier2,
        uint256 tier3
    ) public onlyOwner {
        tierPrice = [999 * 10**18, tier1, tier2, tier3];
    }

    function isWhitelisted(
        bytes32[] memory proof,
        bytes32 leaf,
        address user
    ) public view returns (uint256) {
        if (MerkleProof.verify(proof, merkleRootT3, leaf) && !claimed3[user]) {
            return 3;
        } else if (
            MerkleProof.verify(proof, merkleRootT2, leaf) && !claimed2[user]
        ) {
            return 2;
        } else if (
            MerkleProof.verify(proof, merkleRootT1, leaf) && !claimed1[user]
        ) {
            return 1;
        } else return 0;
    }

    function setBaseURI(string memory customBaseURI_) public onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function mintByOwner(address[] calldata to, uint256[] calldata counts) public onlyOwner {
        require(to.length == counts.length && to.length != 0, "mismatched array lengths or 0 length array");
        for (uint256 j = 0; j < to.length; j++) {
            require(
                counts[j] < REVEAL_BATCH_SIZE,
                "this is gonna break the internet"
            );
            royaltyReceiver[totalSupply()]= to[j];
            _safeMint(to[j], counts[j]);
            if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
                setBatchSeed(getRandomness());
            }
        }
    }

    function maxValues(uint256 maxMintable_) public onlyOwner {
        maxMintable = maxMintable_;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function setPrivateAndPublicSale(uint256 privateTime_, uint256 publicTime_)
        public
        onlyOwner
    {
        wlTime = privateTime_;
        publicTime = publicTime_;
    }

    function publicSale() public view returns (bool) {
        bool publicS = false;
        publicS = (block.timestamp > publicTime);
        return publicS;
    }

    function privateSale() public view returns (bool) {
        bool privateS = false;
        privateS = (block.timestamp > wlTime);
        return privateS;
    }

    function revealNextBatch() external onlyOwner {
        setBatchSeed(getRandomness());
    }

    function toBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function mint(uint256 quantity) external payable {
        require(publicSale(), "public sale hasn't started yet");
        require(!paused, "minting is paused");
        require(msg.value >= price * quantity, "incorrect amount of avax sent");
        require(
            quantity < REVEAL_BATCH_SIZE,
            "this is gonna break the internet"
        );
 
        royaltyReceiver[totalSupply()] = msg.sender;

        _safeMint(msg.sender, quantity);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(getRandomness());
        }
    }

    function tier1Mint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(privateSale(), "private sale hasn't started yet");
        require(!paused, "minting is paused");
        require(
            msg.value >= tierPrice[1] * quantity,
            "incorrect amount of avax sent"
        );
        require(
            quantity < REVEAL_BATCH_SIZE,
            "this is gonna break the internet"
        );
        require(
            isWhitelisted(
                merkleProof,
                keccak256(abi.encodePacked(msg.sender)),
                msg.sender
            ) == 1,
            "invalid merkle proof or already claimed"
        );
        claimed1[msg.sender] = true;
        royaltyReceiver[totalSupply()] = msg.sender;
        _safeMint(msg.sender, quantity);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(getRandomness());
        }
    }

    function tier2Mint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(privateSale(), "private sale hasn't started yet");
        require(!paused, "minting is paused");
        require(
            msg.value >= tierPrice[2] * quantity,
            "incorrect amount of avax sent"
        );
        require(
            quantity < REVEAL_BATCH_SIZE,
            "this is gonna break the internet"
        );
        require(
            isWhitelisted(
                merkleProof,
                keccak256(abi.encodePacked(msg.sender)),
                msg.sender
            ) == 2,
            "invalid merkle proof or already claimed"
        );
        claimed2[msg.sender] = true;
        royaltyReceiver[totalSupply()] = msg.sender;
        _safeMint(msg.sender, quantity);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(getRandomness());
        }
    }

    function tier3Mint(uint256 quantity, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(privateSale(), "private sale hasn't started yet");
        require(!paused, "minting is paused");
        require(
            msg.value >= tierPrice[3] * quantity,
            "incorrect amount of avax sent"
        );
        require(
            quantity < REVEAL_BATCH_SIZE,
            "this is gonna break the internet"
        );
        require(
            isWhitelisted(
                merkleProof,
                keccak256(abi.encodePacked(msg.sender)),
                msg.sender
            ) == 3,
            "invalid merkle proof or already claimed"
        );
        claimed3[msg.sender] = true;
        royaltyReceiver[totalSupply()] = msg.sender;
        _safeMint(msg.sender, quantity);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(getRandomness());
        }
    }

    function clawMint(address to) external onlyAuthorized {
        require(privateSale(), "sale hasn't started yet");
        require(!paused, "minting is paused");
        royaltyReceiver[totalSupply()] = to;
        _safeMint(to, 1);
        if (totalSupply() >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            setBatchSeed(getRandomness());
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function withdrawERC20(address addy) public onlyOwner {
        IERC20 erc = IERC20(addy);
        erc.transfer(owner(), erc.balanceOf(address(this)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (tokenId >= lastTokenRevealed) {
            return unrevealedURI;
        } else {
            return
                string.concat(
                    customBaseURI,
                    getShuffledTokenId(tokenId).toString(),
                    URISuffix
                );
        }
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 _royaltyAmount)
    {
        uint256 index = _tokenId;
        while (royaltyReceiver[index] == address(0)){
            index -= 1;
        }
        return (
            royaltyReceiver[index],
            ((_salePrice * royaltyAmount) / 10000)
        );
        

    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index)
        public
        view
        returns (TokenOwnership memory)
    {
        return _ownershipAt(index);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}

/*  
░░░░░░░░░░░▄▀▀░░▀▀▄  jigglypuff 
▌▄▄▄░▀▀░▄▄▀░░░░░░░░█▄▄░▀▀░▄▄▄▀
▌▐█████░░▀░░░░░░░░░▐░░░█████▌▐
▐░███▀░░░▄░░░░░░░▀▀▄░░░░▀███░▌
░█░▀▀░░░░░█░░░░░░░░▌░░░░░▀▀░█
░░█▀░░▄▐██░▀▄░░░░▄█▄▐█▌▄░░░█
░░▄░░░██▄██░░░▀▀▀░▄███▄█░░░▐
░░▌░░▀█████▐░░░░░░▀█████▀░░▀
░░▌░░▀▀▀▀▀▀▀░░░░░░▀▄▀▀▀▀█░░▐
░░█░░░░▀▀░░░▀█▄▄▄▀░░░▀▀░░░░█
░░▀▄░░░░█░░░░▀▀▀▀░░░░▄░░░░▄▀
░░░▀▄░▄░░▌░░░░░░░░░░▐░░▄░▄▀
░░░░░▀▄▀▀░░░░░░░░░░░░▀▀▄▀
░░░▄▀░░▀▀▄▄░░░░░░░░▄▄▀▀░░▀▄
░░░▐▄░▄▄▄▄░▀▀▀▀▀▀▀▀░▄▄▄▄░▄▄
*/

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
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
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
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721AQueryable.
 *
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) public view virtual override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] calldata tokenIds)
        external
        view
        virtual
        override
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view virtual override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

//SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

/*
  See ../../randomness.md
*/
abstract contract BatchRevealPrize {
    uint constant public TOKEN_LIMIT = 100;
    uint constant public REVEAL_BATCH_SIZE = 1;
    mapping(uint => uint) public batchToSeed;
    uint public lastTokenRevealed = 0;

    struct Range{
        int128 start;
        int128 end;
    }
    // Forked from openzeppelin
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(int128 a, int128 b) internal pure returns (int128) {
        return a < b ? a : b;
    }

    uint constant RANGE_LENGTH = (TOKEN_LIMIT/REVEAL_BATCH_SIZE)*2;
    int128 constant intTOKEN_LIMIT = int128(int(TOKEN_LIMIT));

    // ranges include the start but not the end [start, end)
    function addRange(Range[RANGE_LENGTH] memory ranges, int128 start, int128 end, uint lastIndex) pure private returns (uint) {
        uint positionToAssume = lastIndex;
        for(uint j=0; j<lastIndex; j++){
            int128 rangeStart = ranges[j].start;
            int128 rangeEnd = ranges[j].end;
            if(start < rangeStart && positionToAssume == lastIndex){
                positionToAssume = j;
            }
            if(
                (start < rangeStart && end > rangeStart) ||
                (rangeStart <= start &&  end <= rangeEnd) ||
                (start < rangeEnd && end > rangeEnd)
            ){
                int128 length = end-start;
                start = min(start, rangeStart);
                end = start + length + (rangeEnd-rangeStart);
                ranges[j] = Range(-1,-1); // Delete
            }
        }
        for(uint pos = lastIndex; pos > positionToAssume; pos--){
            ranges[pos] = ranges[pos-1];
        }
        ranges[positionToAssume] = Range(start, min(end, intTOKEN_LIMIT));
        lastIndex++;
        if(end > intTOKEN_LIMIT){
            addRange(ranges, 0, end - intTOKEN_LIMIT, lastIndex);
            lastIndex++;
        }
        return lastIndex;
    }

    function buildJumps(uint lastBatch) view private returns (Range[RANGE_LENGTH] memory) {
        Range[RANGE_LENGTH] memory ranges;
        uint lastIndex = 0;
        for(uint i=0; i<lastBatch; i++){
            int128 start = int128(int(getFreeTokenId(batchToSeed[i], ranges)));
            int128 end = start + int128(int(REVEAL_BATCH_SIZE));
            lastIndex = addRange(ranges, start, end, lastIndex);
        }
        return ranges;
    }

    function getShuffledTokenId(uint startId) view internal returns (uint) {
        uint batch = startId/REVEAL_BATCH_SIZE;
        Range[RANGE_LENGTH] memory ranges = buildJumps(batch);
        uint positionsToMove = (startId % REVEAL_BATCH_SIZE) + batchToSeed[batch];
        return getFreeTokenId(positionsToMove, ranges);
    }

    function getFreeTokenId(uint positionsToMoveStart, Range[RANGE_LENGTH] memory ranges) pure private returns (uint) {
        int128 positionsToMove = int128(int(positionsToMoveStart));
        int128 id = 0;

        for(uint round = 0; round<2; round++){
            for(uint i=0; i<RANGE_LENGTH; i++){
                int128 start = ranges[i].start;
                int128 end = ranges[i].end;
                if(id < start){
                    int128 finalId = id + positionsToMove;
                    if(finalId < start){
                        return uint(uint128(finalId));
                    } else {
                        positionsToMove -= start - id;
                        id = end;
                    }
                } else if(id < end){
                    id = end;
                }
            }
            if((id + positionsToMove) >= intTOKEN_LIMIT){
                positionsToMove -= intTOKEN_LIMIT - id;
                id = 0;
            }
        }
        return uint(uint128(id + positionsToMove));
    }

    function setBatchSeed(uint randomness) internal {
        uint batchNumber;
        unchecked {
            batchNumber = lastTokenRevealed/REVEAL_BATCH_SIZE;
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        batchToSeed[batchNumber] = randomness % (TOKEN_LIMIT - (batchNumber*REVEAL_BATCH_SIZE));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./chainlink/ConfirmedOwner.sol";

abstract contract Authorizable is ConfirmedOwner {

    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(authorized[msg.sender] || owner() == msg.sender, "caller is not authorized");
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721ABurnable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721ABurnable.
 *
 * @dev ERC721A token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is ERC721A, IERC721ABurnable {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual override {
        _burn(tokenId, true);
    }
}

//SPDX-License-Identifier: CC0
pragma solidity ^0.8.0;

/*
  See ../../randomness.md
*/
abstract contract BatchReveal {
    uint constant public TOKEN_LIMIT = 3060;
    uint constant public REVEAL_BATCH_SIZE = 30;
    mapping(uint => uint) public batchToSeed;
    uint public lastTokenRevealed = 0;

    struct Range{
        int128 start;
        int128 end;
    }
    // Forked from openzeppelin
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(int128 a, int128 b) internal pure returns (int128) {
        return a < b ? a : b;
    }

    uint constant RANGE_LENGTH = (TOKEN_LIMIT/REVEAL_BATCH_SIZE)*2;
    int128 constant intTOKEN_LIMIT = int128(int(TOKEN_LIMIT));

    // ranges include the start but not the end [start, end)
    function addRange(Range[RANGE_LENGTH] memory ranges, int128 start, int128 end, uint lastIndex) pure private returns (uint) {
        uint positionToAssume = lastIndex;
        for(uint j=0; j<lastIndex; j++){
            int128 rangeStart = ranges[j].start;
            int128 rangeEnd = ranges[j].end;
            if(start < rangeStart && positionToAssume == lastIndex){
                positionToAssume = j;
            }
            if(
                (start < rangeStart && end > rangeStart) ||
                (rangeStart <= start &&  end <= rangeEnd) ||
                (start < rangeEnd && end > rangeEnd)
            ){
                int128 length = end-start;
                start = min(start, rangeStart);
                end = start + length + (rangeEnd-rangeStart);
                ranges[j] = Range(-1,-1); // Delete
            }
        }
        for(uint pos = lastIndex; pos > positionToAssume; pos--){
            ranges[pos] = ranges[pos-1];
        }
        ranges[positionToAssume] = Range(start, min(end, intTOKEN_LIMIT));
        lastIndex++;
        if(end > intTOKEN_LIMIT){
            addRange(ranges, 0, end - intTOKEN_LIMIT, lastIndex);
            lastIndex++;
        }
        return lastIndex;
    }

    function buildJumps(uint lastBatch) view private returns (Range[RANGE_LENGTH] memory) {
        Range[RANGE_LENGTH] memory ranges;
        uint lastIndex = 0;
        for(uint i=0; i<lastBatch; i++){
            int128 start = int128(int(getFreeTokenId(batchToSeed[i], ranges)));
            int128 end = start + int128(int(REVEAL_BATCH_SIZE));
            lastIndex = addRange(ranges, start, end, lastIndex);
        }
        return ranges;
    }

    function getShuffledTokenId(uint startId) view internal returns (uint) {
        uint batch = startId/REVEAL_BATCH_SIZE;
        Range[RANGE_LENGTH] memory ranges = buildJumps(batch);
        uint positionsToMove = (startId % REVEAL_BATCH_SIZE) + batchToSeed[batch];
        return getFreeTokenId(positionsToMove, ranges);
    }

    function getFreeTokenId(uint positionsToMoveStart, Range[RANGE_LENGTH] memory ranges) pure private returns (uint) {
        int128 positionsToMove = int128(int(positionsToMoveStart));
        int128 id = 0;

        for(uint round = 0; round<2; round++){
            for(uint i=0; i<RANGE_LENGTH; i++){
                int128 start = ranges[i].start;
                int128 end = ranges[i].end;
                if(id < start){
                    int128 finalId = id + positionsToMove;
                    if(finalId < start){
                        return uint(uint128(finalId));
                    } else {
                        positionsToMove -= start - id;
                        id = end;
                    }
                } else if(id < end){
                    id = end;
                }
            }
            if((id + positionsToMove) >= intTOKEN_LIMIT){
                positionsToMove -= intTOKEN_LIMIT - id;
                id = 0;
            }
        }
        return uint(uint128(id + positionsToMove));
    }

    function setBatchSeed(uint randomness) internal {
        uint batchNumber;
        unchecked {
            batchNumber = lastTokenRevealed/REVEAL_BATCH_SIZE;
            lastTokenRevealed += REVEAL_BATCH_SIZE;
        }
        // not perfectly random since the folding doesn't match bounds perfectly, but difference is small
        batchToSeed[batchNumber] = randomness % (TOKEN_LIMIT - (batchNumber*REVEAL_BATCH_SIZE));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721ABurnable.
 */
interface IERC721ABurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}