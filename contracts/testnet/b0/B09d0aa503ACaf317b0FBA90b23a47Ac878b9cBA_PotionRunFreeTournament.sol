// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// OpenZeppelin
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";

// FrensProtocl
import "./FrensProtocolClient.sol";

/// @title Potion Run Free Tournament (Plague Game).
/// @author Memepanze
/** @notice Free Tournament contract for Potion Run (Plague Game).
* Player Mint ERC1155 if the requested score from the server is higher than a target score.
* The request to the off-chain server is done with @ FrensProtocol Oracle.
*/

contract PotionRunFreeTournament is FrensProtocolClient, ReentrancyGuard, Ownable {
    using Strings for uint256;

    constructor(address _badge) {
        setFrensProtocolToken(address(0x5E20E033d579091888b276C885eEB76cAB2a0A55));
        potionRunBadgesContract = _badge;
        startDate = 1673546400;
        sessionDuration = 86400;
    }

    /// @notice The contract could receive gas tokens.
    receive() external payable {
        emit ReceivedEth(msg.value);
    }

    /// @notice Badge contract
    address public potionRunBadgesContract;

    /// @notice startDate
    uint public startDate;

    /// @notice session Duration 86400 = 24h
    uint public sessionDuration;

    /**
    * @notice Player is a struct that contains the state data of a player.
    * @param id is the unique id of a player.
    * @param playerAddress is the wallet address of the player.
    * @param score is the score of the player requested from the game server.
    */
    struct Player {
        uint id;
        address playerAddress;
        bool isPlaying;
        uint score;
        bool isRewarded;
        bool isOracle;
    }

    //@var players is a mapping list of the object Player related to an address.
    mapping(address => Player) public players;

    // sessionPlayer mapping sessions => Player
    mapping (uint => mapping(address => Player)) public sessionPlayers;
    
    //@var addr 
    address private addr;

    // session Struct: startDate, endDate, nbPlayers, prizePool
    struct Session {
        uint id;
        uint startDate;
        uint endDate;
        uint nbPlayers;
    }

    // sessions mapping uint => session
    mapping (uint => Session) public sessions;

    // mapping 
    struct RequestState {
        uint sessionId;
        address playerAddress;
    }

    mapping(bytes32 => RequestState) public requestsSent;

    // E V E N T

    /// @notice Emitted on the receive()
    /// @param amount The amount of received Eth
    event ReceivedEth(uint amount);

    /// @notice Emitted on withdrawBalance() 
    event BalanceWithdraw(address to, uint amount);

    // E R R O R S

    error PR__Unauthorized();

    error PR__NotInTheMitingPeriod();

    error PR__TransferFailed();

    // M O D I F I E R S
    
    /// @notice Check if the minter is an externally owned account
    modifier isEOA() {
        if (tx.origin != msg.sender) {
            revert PR__Unauthorized();
        }
        _;
    }

     // enter the session

    function enter(uint _sessionId) external {
        require(block.timestamp>startDate+sessionDuration*(_sessionId), "Session not started");
        require(block.timestamp<startDate+sessionDuration*(_sessionId+1), "Session finished");
        sessions[_sessionId].nbPlayers++;
        sessionPlayers[_sessionId][msg.sender].playerAddress = msg.sender;
        sessionPlayers[_sessionId][msg.sender].isPlaying = true;
    }

    /// @notice call the game server through FrensProtocol to get the player rank for the sessionId
    function requestPlayerRank(
        address _oracle,
        string memory _queryId,
        string memory _apiBaseUrl,
        string memory _sessionType,
        uint _sessionId,
        string memory _addressPlayer,
        string memory _pathUint
    ) public nonReentrant isEOA {
        require(sessionPlayers[_sessionId][msg.sender].isPlaying, "Player must enter the session");
        require(!sessionPlayers[_sessionId][msg.sender].isRewarded, "Player already rewarded for that session");
        require(block.timestamp>startDate+sessionDuration*(_sessionId+1), "Session not finished");
        string memory _apiUrlSessionType = concatenate(_apiBaseUrl, _sessionType, "/");
        string memory _apiUrlSessionId = concatenate(_apiUrlSessionType, Strings.toString(_sessionId), "/");
        string memory _urlToFetch = concatenate(_apiUrlSessionId, _addressPlayer, "");
        bytes32 _requestId = getUintRequest(
            _oracle, //FrensProtocol Oracle Address
            _queryId, // The specific queryId to retrieve Uint & String data from your API
            _urlToFetch, // The base url of the API to fetch
            _pathUint, // The API path of the uint data
            this.achievedRequest.selector // The string signature of the achievedRequest function: achevied(bytes32,uint256,string)
        );
        requestsSent[_requestId].sessionId =  _sessionId;
        requestsSent[_requestId].playerAddress = msg.sender;
    }

    // M I N T

    /// @notice The callback function that will be triggered by the Oracle
    /// @param _requestId.
    /// @param _uint.
    function achievedRequest(bytes32 _requestId, uint256 _uint) external recordAchievedRequest(_requestId)
    {
        addr = requestsSent[_requestId].playerAddress;
        uint _sessionId = requestsSent[_requestId].sessionId;
        players[addr].score = _uint;

        // @notice Set the bool isOracle to true after the oracle request.
        players[addr].isOracle = true;
        if(_uint < sessions[_sessionId].nbPlayers/5){
            (bool success, ) = potionRunBadgesContract.call(abi.encodeWithSignature("mint(address,uint256)", addr, 0));
            require(success, "Call potionRunBadgeContract failed!");
        }
        if(_uint == 1 ){
            (bool success, ) = potionRunBadgesContract.call(abi.encodeWithSignature("mint(address,uint256)", addr, 1));
            require(success, "Call potionRunBadgeContract failed!");
        } else if (_uint == 2) {
            (bool success, ) = potionRunBadgesContract.call(abi.encodeWithSignature("mint(address,uint256)", addr, 2));
            require(success, "Call potionRunBadgeContract failed!");
        } else if (_uint == 3) {
            (bool success, ) = potionRunBadgesContract.call(abi.encodeWithSignature("mint(address,uint256)", addr, 3));
            require(success, "Call potionRunBadgeContract failed!");
        }
        sessionPlayers[_sessionId][addr].isRewarded = true;
        
    }

    function setBadgeContract(address _address) external onlyOwner {
        potionRunBadgesContract = _address;
    }
    

    /// @notice Withdraw the contract balance to the contract owner
    /// @param _to Recipient of the withdrawal
    function withdrawBalance(address _to) external onlyOwner nonReentrant {
        uint amount = address(this).balance;
        bool sent;

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert PR__TransferFailed();
        }

        emit BalanceWithdraw(_to, amount);
    }

    /// @notice withdraw ERC20
    function withdrawToken(address _tokenContract, address _to) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint amount = tokenContract.balanceOf(address(this));
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(_to, amount);
    }
}