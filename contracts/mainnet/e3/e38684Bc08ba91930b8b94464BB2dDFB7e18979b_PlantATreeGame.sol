// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*

▀▀█▀▀ █▀▀█ █▀▀ █▀▀ █▀▀ 　 
─░█── █▄▄▀ █▀▀ █▀▀ ▀▀█ 　 
─░█── ▀─▀▀ ▀▀▀ ▀▀▀ ▀▀▀ 　 

░█▀▀█ █▀▀█ █▀▀ █▀▀ 
░█▄▄▀ █▄▄█ █── █▀▀ 
░█─░█ ▀──▀ ▀▀▀ ▀▀▀ 

░█▀▀█ █▀▀█ █▀▄▀█ █▀▀ 
░█─▄▄ █▄▄█ █─▀─█ █▀▀ 
░█▄▄█ ▀──▀ ▀───▀ ▀▀▀

Discord: http://discord.io/PlantATree
Website: https://treegame.live
*/

interface ERC721Interface {
    function ownerOf(uint256) external view returns (address);
}

interface PlantATreeRewardSystem {
    function PlantATree(address ref) external payable;
}

contract PlantATreeGame is VRFConsumerBaseV2, Ownable {
    // [Chainlink VRF config block]
    VRFCoordinatorV2Interface COORDINATOR;
    // subscription ID.
    uint64 s_subscriptionId;

    bytes32 keyHash;

    uint32 callbackGasLimit = 2500000; //100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant numWords = 1;
    // [End of Chainlink VRF config block]

    // Win percentages and Race track values

    enum SORT_TYPE {
        TOTAL_WIN,
        TOTAL_GAMES
    }

    uint256[] private WIN_PERCENTAGES = [0, 25, 50, 75, 100];

    string[] private TRACK_VALUES = [
        "-2",
        "0",
        "2",
        "4",
        "3",
        "-1",
        "-3",
        "1",
        "-4",
        "2",
        " -1",
        "3",
        "-4",
        "1",
        "-3",
        "-2",
        "4",
        "0",
        "1",
        "-1",
        "-3",
        "3",
        "4",
        "-4",
        "2",
        "-2",
        "0",
        "1",
        "3",
        "0",
        "2",
        "-2",
        "-3",
        "-4",
        "-1",
        "4",
        "-1",
        "4",
        "1",
        "3",
        "-4",
        "2",
        "-2",
        "-3",
        "0",
        "-3",
        "2",
        "3",
        "1",
        "-1",
        "4",
        "-2",
        "-4",
        "0",
        "2",
        "0",
        "1",
        "-4",
        "3",
        "-3",
        "-1",
        "4",
        "-2",
        "0",
        "3",
        "-3",
        "2",
        "-1",
        "4",
        "-2",
        "-4",
        "1",
        "-2",
        "3",
        "0",
        "1",
        "-4",
        "-1",
        "-3",
        "2",
        "4"
    ];

    uint256 public constant MAX_NFT_SUPPLY = 600;
    uint256 public constant PLAYERS_COUNT = 4;
    uint256 private pvtIndex;
    uint256 private pvtGamesCount;

    // TressGame Data Structure

    struct Game {
        uint256 id;
        uint256[PLAYERS_COUNT] players;
        uint256[PLAYERS_COUNT] effects;
        string[PLAYERS_COUNT] tracks;
        uint256 timestamp;
        uint256 winnerTokenId;
        uint256 map;
        uint256 text;
        uint256 rndResult;
    }

    struct TreesToken {
        uint256 tokenId;
        uint256 totalGamesPlayed;
        uint8 communityShareQualified;
        uint256 totalWonGames;
        uint256 totalLostGames;
        uint256 balance;
    }

    // Dev addresses
    address artist;
    address dev;
    address public PAT_Address;
    mapping(address => bool) private admins;
    address public ref;

    //for dev claim
    modifier onlyAdmin() {
        require(admins[msg.sender] == true);
        _;
    }

    // Total Games Value
    uint256 public totalGamesValues = 0 ether;

    // Balances & Shares

    uint256 public teamBalance = 0 ether;
    uint256 public communityBalance = 0 ether;

    // Minimum balance to distrubte for community only
    uint256 public constant MINIMUM_COMMUNITY_BALANCE = 1 ether;

    // NFT TressContract . Used to check ownership of a token
    ERC721Interface internal TREES_CONTRACT;
    address public TreesNFTContractAddress;

    //  Minimum Game Value set to 0.4. This means minimum entry fee is 0.1
    uint256 public constant MINIMUM_GAME_VALUE = 0.4 ether;

    // Initial values of total game value and their disturbtions. Initial values don't matter here as it has to be passed in the constructor anyway.
    uint256 public GAME_VALUE = 0.4 ether;
    // disturbtions based on total game value
    uint256 public ENTRY_FEE = 0.1 ether;
    uint256 public WIN_SHARE = 0.2 ether;
    uint256 public LOSS_SHARE = 0.0426 ether;
    uint256 public TEAM_SHARE = 0.024 ether;
    uint256 public COMMUNITY_SHARE = 0.0162 ether;
    uint256 public DynamicRewardsSystem_Share = 0.032 ether;
    uint256 public DynamicRewards_Balance = 0;

    // Minimum games played to be qualified for community shares. On the fifth game the nft holder will be qualified
    uint256 public constant COMMUNITY_MINIMUM_GAMES = 5;

    // Tokens count that are qulaified for getting community shares
    uint256 public qualifiedTokensCount = 0;

    // Players waiting to start the game
    mapping(uint256 => uint256) public pendingPlayers;
    uint256 public pendingPlayersCount;

    // Games & Tokens data
    mapping(uint256 => TreesToken) public treesTokens;
    mapping(uint256 => Game) public games;
    uint256 public gamesCounter;
    bool public GameIsAcive = false;

    // Random range minimum and maximum
    uint256 private constant min = 1;
    uint256 private constant max = 100;

    // VRF Request Id => Games Ids
    mapping(uint256 => uint256) public requestIdToGameId;

    // Limit of top trees
    uint256 public constant TOP_LIMIT = 30;

    // index to tokenId
    mapping(uint256 => uint256) public topTokensBytotalWonGames;
    mapping(uint256 => uint256) public topTokensByTotalGamesPlayed;

    // Game Events
    event GameJoined(uint256 _TreeTokenId);
    event GameStarted(Game _game);
    event GameEnded(uint256 _GameId, uint256 _TreeTokenId);

    // Config Events
    event VRFConfigUpdated(
        uint64 subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    );
    event EntryFeeUpdated(uint256 totalGameValue);
    event TeamAddressesUpdated(address artist, address dev);

    constructor(
        uint256 _pvtGamesCount,
        uint256 _gamesCounter,
        uint64 subscriptionId,
        bytes32 _keyHash,
        address _vrfCoordinator,
        address TreesNFTAddress_,
        address _PAT_Address,
        address _ref,
        address _dev,
        address _artist
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        require(TreesNFTAddress_ != address(0));
        require(_vrfCoordinator != address(0));
        require(_pvtGamesCount > 0);
        pvtGamesCount = _pvtGamesCount;
        TreesNFTContractAddress = TreesNFTAddress_;
        TREES_CONTRACT = ERC721Interface(TreesNFTContractAddress);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        PAT_Address = _PAT_Address;
        ref = _ref;
        setTeamAddresses(_artist, _dev);

        //scores migrated from old contract
        gamesCounter = _gamesCounter;
        totalGamesValues = gamesCounter * GAME_VALUE;
        require( (gamesCounter % pvtGamesCount) == 0 , "err");
    }

    // change VRF config if needed. for example, if subscription Id changed ...etc.
    function setVRFConfig(
        uint64 subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    ) external onlyOwner {
        s_subscriptionId = subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        keyHash = _keyHash;
        emit VRFConfigUpdated(
            subscriptionId,
            _callbackGasLimit,
            _requestConfirmations,
            _keyHash
        );
    }


    // Requets a random number from ChainLink
    function getRandomNumber() internal returns (uint256 requestId) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
    }

    // Receive the requested random number from ChainLink
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 rndWord = randomWords[0];
        pvtIndex = rndWord;
        uint256 gameId = requestIdToGameId[requestId];
        uint256 rnd = getGameRandomNumber(games[gameId].players, rndWord);
        processGame(gameId, rnd);
    }

    function processGame(uint256 gameId, uint256 rnd) internal {
        pickWinner(gameId, rnd);
    }

    // get a track for a Trees token (player)
    function getTrack(uint256 baseNum, uint256 MBTokenId)
        internal
        view
        returns (string memory)
    {
        require(
            TRACK_VALUES.length > 72,
            "TRACK_VALUES length must be greater than 72"
        );
        uint256 startIndex = (baseNum + MBTokenId) % (TRACK_VALUES.length - 72);
        uint256 endIndex = startIndex + 9;
        string memory track = TRACK_VALUES[startIndex];
        for (uint256 i = startIndex + 1; i < endIndex; i++) {
            track = string(abi.encodePacked(track, ",", TRACK_VALUES[i]));
        }
        return track;
    }

    // get game map
    function getMap(uint256 baseNum) internal pure returns (uint256) {
        return ((baseNum * 7) % 4) + 1;
    }

    // get game text
    function getText(uint256 baseNum) internal pure returns (uint256) {
        return (baseNum % 10) + 1;
    }

    // get game effect
    function getEffect(uint256 baseNum, uint256 MBTokenId)
        internal
        pure
        returns (uint256)
    {
        return ((baseNum + MBTokenId) % 6) + 1;
    }

    // Select the winner based on the random result considering total games played for each player
    function pickWinner(uint256 gameId, uint256 randomResult) internal {
        //sortPlayersByTotalGamesPlayed(gameId);
        Game storage game = games[gameId];
        game.winnerTokenId = getWinnerTokenId(gameId, randomResult);
        game.rndResult = randomResult;
        game.timestamp = block.timestamp;
        // randomResult is between 1 and 100
        game.map = getMap(randomResult + gamesCounter);
        game.text = getText(randomResult + gamesCounter + 3);
        setPlayersEffects(gameId, randomResult);
        setPlayersTracks(gameId, randomResult);

        // Winner and Losers shares
        calculateShares(gameId);

        // Keep track of top winners
        bool alreadyAdded = false;
        uint256 smallestTokenIdIndex = 1; //topTokensBytotalWonGames[1];
        if (
            topTokensBytotalWonGames[smallestTokenIdIndex] == game.winnerTokenId
        ) {
            alreadyAdded = true;
        }
        if (!alreadyAdded) {
            for (uint256 k = 2; k <= TOP_LIMIT; k++) {
                if (topTokensBytotalWonGames[k] == game.winnerTokenId) {
                    alreadyAdded = true;
                    break;
                }
                if (
                    treesTokens[topTokensBytotalWonGames[k]].totalWonGames <
                    treesTokens[topTokensBytotalWonGames[smallestTokenIdIndex]]
                        .totalWonGames
                ) {
                    smallestTokenIdIndex = k;
                }
            }
        }
        // update only if it wasn't added before
        if (
            !alreadyAdded &&
            treesTokens[topTokensBytotalWonGames[smallestTokenIdIndex]]
                .totalWonGames <
            treesTokens[game.winnerTokenId].totalWonGames
        ) {
            topTokensBytotalWonGames[smallestTokenIdIndex] = game.winnerTokenId;
        }

        emit GameEnded(gameId, games[gameId].winnerTokenId);
    }

    // set effects for each player except the winner
    function setPlayersEffects(uint256 gameId, uint256 randomResult) internal {
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for (uint256 i = 0; i < l; i++) {
            if (games[gameId].winnerTokenId == game.players[i]) {
                game.effects[i] = 0;
            } else {
                game.effects[i] = getEffect(randomResult, game.players[i]);
            }
        }
    }

    // set the tracks for all players
    function setPlayersTracks(uint256 gameId, uint256 randomResult) internal {
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for (uint256 i = 0; i < l; i++) {
            game.tracks[i] = getTrack(randomResult, game.players[i]);
        }
    }

    // sort players by total games played . index 0 -> lowest . index 3 -> highest
    function sortPlayersByTotalGamesPlayed(uint256 gameId) internal {
        Game storage game = games[gameId];
        uint256 l = game.players.length;
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (
                    treesTokens[game.players[i]].totalGamesPlayed >
                    treesTokens[game.players[j]].totalGamesPlayed
                ) {
                    uint256 temp = game.players[i];
                    game.players[i] = game.players[j];
                    game.players[j] = temp;
                }
            }
        }
    }

    // get the winner token id based on WIN_PERCENTAGES and the random result
    function getWinnerTokenId(uint256 gameId, uint256 randomResult)
        internal
        view
        returns (uint256 winnerTokenId)
    {
        require(
            randomResult >= 1 && randomResult <= 100,
            "Random result is out of range"
        );
        uint256 l = WIN_PERCENTAGES.length;
        for (uint256 i = 1; i < l; i++) {
            if (
                randomResult > WIN_PERCENTAGES[i - 1] &&
                randomResult <= WIN_PERCENTAGES[i]
            ) {
                return games[gameId].players[i - 1];
            }
        }
    }

    // get games as array within the range from-to
    function getGames(uint256 gameIdFrom, uint256 gameIdTo)
        external
        view
        returns (Game[] memory)
    {
        uint256 length = gameIdTo - gameIdFrom;
        Game[] memory gamesArr = new Game[](length + 1);
        uint256 j = 0;
        for (uint256 i = gameIdFrom; i <= gameIdTo; i++) {
            gamesArr[j] = games[i];
            j++;
        }
        return gamesArr;
    }

    // get top Trees by wins or total played games
    function getTopTreesNFT(SORT_TYPE sortType)
        external
        view
        returns (TreesToken[] memory)
    {
        TreesToken[] memory treesArr = new TreesToken[](TOP_LIMIT);
        if (sortType == SORT_TYPE.TOTAL_WIN) {
            for (uint256 i = 1; i <= TOP_LIMIT; i++) {
                treesArr[i - 1] = treesTokens[topTokensBytotalWonGames[i]];
            }
        }
        if (sortType == SORT_TYPE.TOTAL_GAMES) {
            for (uint256 i = 1; i <= TOP_LIMIT; i++) {
                treesArr[i - 1] = treesTokens[topTokensByTotalGamesPlayed[i]];
            }
        }
        return treesArr;
    }

    // get players by game
    function getGamePlayers(uint256 gameId)
        external
        view
        returns (uint256[PLAYERS_COUNT] memory)
    {
        return games[gameId].players;
    }

    // get effects by gamee
    function getGameEffects(uint256 gameId)
        external
        view
        returns (uint256[PLAYERS_COUNT] memory)
    {
        return games[gameId].effects;
    }

    // calculate the players (including the winner), community and dev shares
    function calculateShares(uint256 gameId) internal {
        Game storage game = games[gameId];
        // Winner specific
        // Add the wining share to the winner token
        uint256 winnerTokenId = game.winnerTokenId;
        treesTokens[winnerTokenId].totalWonGames++;
        treesTokens[winnerTokenId].totalGamesPlayed++;
        treesTokens[winnerTokenId].balance += WIN_SHARE;

        // Distribute the losing share to the losers tokens
        uint256 l = game.players.length;
        for (uint256 i = 0; i < l; i++) {
            uint256 tokenId = game.players[i];
            if (tokenId != winnerTokenId) {
                treesTokens[tokenId].totalGamesPlayed++;
                treesTokens[tokenId].totalLostGames++;
                treesTokens[tokenId].balance += LOSS_SHARE;
            }
        }

        // Dev share
        teamBalance += TEAM_SHARE;

        // Community share
        communityBalance += COMMUNITY_SHARE;
    }

    // Distribute Community shares
    // Anyone can call this to distribute the shares to their respective balances
    function distributeCommunityShare() external {
        require(
            communityBalance >= MINIMUM_COMMUNITY_BALANCE,
            "Community balance must be 1 or greater"
        );
        require(qualifiedTokensCount > 0, "There is no qualified tokens yet");
        require(
            communityBalance >= qualifiedTokensCount,
            "Share per token is zero"
        );
        // Distribute the community share to the qualified tokens
        // devide before multiply issue is skipped as it is checked above communityBalance >= qualifiedTokensCount
        // ref: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
        uint256 sharePerToken = communityBalance / qualifiedTokensCount;
        communityBalance = 0;
        for (uint256 j = 1; j <= MAX_NFT_SUPPLY; j++) {
            treesTokens[j].balance += (sharePerToken *
                treesTokens[j].communityShareQualified);
        }
    }

    // Claim the balance of a Trees token
    function claim(uint256 _tokenId) external {
        require(
            _tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY,
            "Tresstoken Id must be between 1 and 600"
        );
        require(
            ownerOfTreesNFT(_tokenId),
            "Please make sure you own this Tresstoken"
        );
        uint256 mbBalance = treesTokens[_tokenId].balance;
        require(mbBalance > 0, "Balance is zero");
        require(
            address(this).balance >= mbBalance,
            "Insufficient contract balance"
        );
        treesTokens[_tokenId].balance = 0;
        payable(msg.sender).transfer(mbBalance);
    }

    // Claim the balance of the dev
    function devClaim() external onlyAdmin {
        require(artist != address(0), "artist address can not be zero");
        require(dev != address(0), "dev address can not be zero");
        require(teamBalance > 0, "team Balance must be greater than zero");
        require(
            address(this).balance >= teamBalance,
            "Insufficient contract balance"
        );
        uint256 _teamBalance = teamBalance;
        teamBalance = 0;
        uint256 _artist = (_teamBalance * 40) / 100;
        uint256 _dev = (_teamBalance * 60) / 100;
        payable(artist).transfer(_artist);
        payable(dev).transfer(_dev);
    }

    // Set addresses of the team
    function setTeamAddresses(address _artist, address _dev) public onlyOwner {
        require(_artist != address(0) && _dev != address(0), "address can not be zero");
        artist = _artist;
        dev = _dev;
        admins[artist] = true;
        admins[dev] = true;

        emit TeamAddressesUpdated(_artist, _dev);
    }

    // Set Entry Fee
    function setEntryFeeWithGameShare(
        uint256 totalGameValue,
        uint256 _WIN_SHARE,
        uint256 _LOSS_SHARE,
        uint256 _COMMUNITY_SHARE,
        uint256 _DyanmicRewardsSystem_Share,
        uint256 _totalGameValue
    ) public onlyOwner {
        require(totalGameValue >= MINIMUM_GAME_VALUE);

        // set the game value
        GAME_VALUE = _totalGameValue;
        WIN_SHARE = _WIN_SHARE;
        LOSS_SHARE = _LOSS_SHARE;
        COMMUNITY_SHARE = _COMMUNITY_SHARE;
        DynamicRewardsSystem_Share = _DyanmicRewardsSystem_Share;

        if (
            WIN_SHARE +
                (LOSS_SHARE * 3) +
                TEAM_SHARE +
                COMMUNITY_SHARE +
                DynamicRewardsSystem_Share !=
            totalGameValue
        ) {
            revert();
        }

        emit EntryFeeUpdated(totalGameValue);
    }

    // Join a new game
    function joinGame(uint256 _tokenId) external payable {
        require(GameIsAcive == true, "Game not Active");

        require(_tokenId > 0 && _tokenId <= MAX_NFT_SUPPLY);
        require(ownerOfTreesNFT(_tokenId));
        require(
            treesTokenIsNotPlaying(_tokenId),
            "This Tress token is already in a game"
        );
        require(
            pendingPlayersCount < PLAYERS_COUNT,
            "Please wait few seconds and try joining again"
        );
        require(msg.value == ENTRY_FEE);

        pendingPlayersCount++;
        pendingPlayers[pendingPlayersCount] = _tokenId;
        treesTokens[_tokenId].tokenId = _tokenId;
        if (
            qualifiedTokensCount < MAX_NFT_SUPPLY &&
            treesTokens[_tokenId].communityShareQualified == 0 &&
            treesTokens[_tokenId].totalGamesPlayed >= COMMUNITY_MINIMUM_GAMES
        ) {
            treesTokens[_tokenId].communityShareQualified = 1;
            qualifiedTokensCount++;
        }

        // Keep track of top by total games played
        // get top of the 4 players
        uint256 playerTokenId = _tokenId;
        bool alreadyAdded = false;
        uint256 smallestTokenIdIndex = 1;
        if (
            topTokensByTotalGamesPlayed[smallestTokenIdIndex] == playerTokenId
        ) {
            alreadyAdded = true;
        }
        if (!alreadyAdded) {
            for (uint256 k = 2; k <= TOP_LIMIT; k++) {
                if (topTokensByTotalGamesPlayed[k] == playerTokenId) {
                    alreadyAdded = true;
                    break;
                }
                if (
                    treesTokens[topTokensByTotalGamesPlayed[k]]
                        .totalGamesPlayed <
                    treesTokens[
                        topTokensByTotalGamesPlayed[smallestTokenIdIndex]
                    ].totalGamesPlayed
                ) {
                    smallestTokenIdIndex = k;
                }
            }
        }
        // update only if it wasn't added before
        if (
            !alreadyAdded &&
            treesTokens[topTokensByTotalGamesPlayed[smallestTokenIdIndex]]
                .totalGamesPlayed <
            treesTokens[playerTokenId].totalGamesPlayed
        ) {
            topTokensByTotalGamesPlayed[smallestTokenIdIndex] = playerTokenId;
        }

        emit GameJoined(_tokenId);

        if (pendingPlayersCount == PLAYERS_COUNT) {
            // Start the game as we have already 4 players
            startGame();
        }
    }

    function setTreeNFTContract(address TreesNFTAddress_) public onlyOwner {
        TreesNFTContractAddress = TreesNFTAddress_;
        TREES_CONTRACT = ERC721Interface(TreesNFTContractAddress);
    }

    function ownerOfTreesNFT(uint256 _tokenId) internal view returns (bool) {
        address tokenOwnerAddress = TREES_CONTRACT.ownerOf(_tokenId);
        return (tokenOwnerAddress == msg.sender);
    }

    function treesTokenIsNotPlaying(uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pendingPlayersCount; i++) {
            if (pendingPlayers[i + 1] == _tokenId) {
                return false;
            }
        }
        return true;
    }

    // Start the game and clear daata including pending players for a new game
    function startGame() private {
        gamesCounter++;
        totalGamesValues += GAME_VALUE;
        uint256[PLAYERS_COUNT] memory _players;
        _players[0] = pendingPlayers[1];
        _players[1] = pendingPlayers[2];
        _players[2] = pendingPlayers[3];
        _players[3] = pendingPlayers[4];

        uint256[PLAYERS_COUNT] memory _effects = [uint256(0), 0, 0, 0];
        string[PLAYERS_COUNT] memory _tracks = ["", "", "", ""];

        games[gamesCounter] = Game(
            gamesCounter,
            _players,
            _effects,
            _tracks,
            0,
            0,
            0,
            0,
            0
        );

        // reset
        pendingPlayers[1] = 0;
        pendingPlayers[2] = 0;
        pendingPlayers[3] = 0;
        pendingPlayers[4] = 0;
        pendingPlayersCount = 0;
        // end

        emit GameStarted(games[gamesCounter]);

        if ((gamesCounter - 1) % pvtGamesCount == 0) {
            uint256 requestId = getRandomNumber();
            requestIdToGameId[requestId] = gamesCounter;
        } else {
            //
            uint256 rnd = getGameRandomNumber(_players, pvtIndex);
            processGame(gamesCounter, rnd);
        }

        // feed the DyanmicRewardsSystem
        DynamicRewards_Balance += DynamicRewardsSystem_Share;
        if (DynamicRewards_Balance >= 0.1 ether) {
            PlantATreeRewardSystem(PAT_Address).PlantATree{
                value: DynamicRewards_Balance
            }(ref);
            DynamicRewards_Balance = 0;
        }
    }

    function getGameRandomNumber(uint256[4] memory _players, uint256 _rndFactor)
        internal 
        view
        returns (uint256)
    {
        uint256 rnd = uint256(
            keccak256(abi.encodePacked(_rndFactor, block.timestamp, _players))
        );
        uint256 randomResult = (rnd % max) + min;
        return randomResult;
    }

    function setGameActive(bool _isActive) public onlyOwner {
        GameIsAcive = _isActive;
    }

    function setConfig(
        uint256 _pvtGamesCount,
        address TreesNFTContractAddress_,
        address PATaddr,
        address _ref
    ) external onlyOwner {
        if (_pvtGamesCount > 0) pvtGamesCount = _pvtGamesCount;
        if (TreesNFTContractAddress_ != address(0))
            TreesNFTContractAddress = TreesNFTContractAddress_;
        if (PATaddr != address(0)) PAT_Address = PATaddr;
        if (_ref != address(0)) ref = _ref;
    }
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