/**
 *Submitted for verification at snowtrace.io on 2022-04-09
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface iPEFI is IERC20 {
    function leave(uint256 share) external;
}

contract OwnableInitialized {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initOwner) {
        require(initOwner != address(0), "Ownable: initOwner is the zero address");
        _owner = initOwner;
        emit OwnershipTransferred(address(0), initOwner);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IPOTIONS is IERC1155 {
    function burnFrom(address from, uint256 id, uint256 amount) external;
    function burnFromBatch(address from, uint256[] memory ids, uint256[] memory amounts) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom( address from, address to, uint256 tokenId) external;
    function transferFrom( address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IPenguinEmperorManager {
    function roll(address) external;
}

contract PenguinDatabase {
    // User profile
    struct Profile {
        uint8 activeAvatarType;                             // Type of avatar: 1 - use "built-in" avatar, 2 - use NFT avatar
        uint32 lastNameChange;                              // UTC timestamp at which player last changed their name
        address avatarNFTContract;                          // NFT contract address in the case of NFT-avatar; otherwise, value = 0x0
        uint256 avatarId;                                   // ID of avatar. In the case of NFT avatar, this is the NFT token ID
        string nickname;                                    // Player nickname
    }

    struct BuiltInStyle {
        uint128 style;
        string color;
    }

    uint8 private constant AVATAR_TYPE_BUILT_IN = 1;
    uint8 private constant AVATAR_TYPE_NFT = 2;

    mapping(address => Profile) public profiles;    // user profiles
    mapping(address => BuiltInStyle) public builtInStyles;
    // Nickname DB
    mapping(string => bool) public nicknameExists;

    modifier onlyRegistered() {
        require(isRegistered(msg.sender), "must be registered");
        _;
    }

    function isRegistered(address penguinAddress) public view returns(bool) {
        return (profiles[penguinAddress].activeAvatarType != 0) && (bytes(profiles[penguinAddress].nickname).length != 0);
    }

    function nickname(address penguinAddress) external view returns(string memory) {
        return profiles[penguinAddress].nickname;
    }

    function color(address penguinAddress) external view returns(string memory) {
        return builtInStyles[penguinAddress].color;
    }

    function style(address penguinAddress) external view returns(uint256) {
        return builtInStyles[penguinAddress].style;
    }
    
    function avatar(address _player) external view returns(uint8 _activeAvatarType, uint256 _avatarId, IERC721 _avatarNFTContract) {
         Profile storage info = profiles[_player];
         (_activeAvatarType, _avatarId, _avatarNFTContract) = 
         (info.activeAvatarType, info.avatarId, IERC721(info.avatarNFTContract));
    }

    function currentProfile(address _player) external view returns(Profile memory, BuiltInStyle memory) {
        return (profiles[_player], builtInStyles[_player]);
    }

    function canChangeName(address penguinAddress) public view returns(bool) {
        if (uint256(profiles[penguinAddress].lastNameChange) + 86400 <= block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function changeStyle(uint128 _newStyle) external {
        builtInStyles[msg.sender].style = _newStyle;
    }

    function changeColor(string memory _newColor) external {
        builtInStyles[msg.sender].color = _newColor;
    }

    function setNickname(string memory _newNickname) external onlyRegistered {
        _setNickname(msg.sender, _newNickname);
    }

    // Set Penguin built-in avatar
    function setAvatarBuiltIn(uint128 _style, string memory _color) external {
        _setAvatarBuiltIn(msg.sender, _style, _color);
    }

    // set NFT avatar
    function setAvatarNFT(IERC721 _nftContract, uint256 _tokenId) external {
        _setAvatarNFT(msg.sender, _nftContract, _tokenId);
    }

    function _setNickname(address _player, string memory _newNickname) internal {
        require(!nicknameExists[_newNickname], "Choose a different nickname, that one is already taken.");
        require(canChangeName(_player), "Can only change name once daily");
        Profile memory currentPenguinInfo = profiles[_player];
        nicknameExists[currentPenguinInfo.nickname] = false;
        nicknameExists[_newNickname] = true;
        currentPenguinInfo.nickname = _newNickname;
        currentPenguinInfo.lastNameChange = uint32(block.timestamp);
        //commit changes to storage
        profiles[_player] = currentPenguinInfo;
    }
    
    function _setAvatarNFT(address _player, IERC721 _nftContract, uint256 _tokenId) internal {
        require(_nftContract.ownerOf(_tokenId) == _player, "NFT token does not belong to user");
        Profile memory currentPenguinInfo = profiles[_player];
        currentPenguinInfo.activeAvatarType = AVATAR_TYPE_NFT;
        currentPenguinInfo.avatarNFTContract = address(_nftContract);
        currentPenguinInfo.avatarId = _tokenId; 
        //commit changes to storage
        profiles[_player] = currentPenguinInfo;
    }

    function _setAvatarBuiltIn(address _player, uint128 _style, string memory _color) internal {
        BuiltInStyle memory currentPenguinStyle = builtInStyles[_player];
        profiles[_player].activeAvatarType = AVATAR_TYPE_BUILT_IN;
        currentPenguinStyle.style = _style;
        currentPenguinStyle.color = _color;
        //commit changes to storage
        builtInStyles[_player] = currentPenguinStyle;
    }

    function registerYourPenguin(string memory _nickname, IERC721 _nftContract, uint256 _tokenId, uint128 _style, string memory _color) external {
        require(address(_nftContract) != address(0) || bytes(_color).length > 0, "must set at least one profile preference");

        // Penguins can only register their nickname once. Each nickname must be unique.
        require(bytes(_nickname).length != 0, "cannot have empty nickname");
        require(!isRegistered(msg.sender), "already registered");
        require(nicknameExists[_nickname] != true, "Choose a different nickname, that one is already taken.");
        nicknameExists[_nickname] = true;

        Profile memory currentPenguinInfo = profiles[msg.sender];
        currentPenguinInfo.nickname = _nickname;
        currentPenguinInfo.lastNameChange = uint32(block.timestamp);
        //commit changes to storage
        profiles[msg.sender] = currentPenguinInfo;

        //if color is not the empty string, set the user's built in style preferences
        if (bytes(_color).length > 0) {
            _setAvatarBuiltIn(msg.sender, _style, _color);
        }
        //if user wishes to set an NFT avatar, do so.
        if (address(_nftContract) != address(0)) {
            _setAvatarNFT(msg.sender, _nftContract, _tokenId);
        }
    }
    
    function updateProfile(string memory _newNickname, uint128 _newStyle, string memory _newColor) external {
        require(isRegistered(msg.sender), "not registered yet");
        //require(profiles[msg.sender].activeAvatarType == AVATAR_TYPE_BUILT_IN, "only for built-in avatar");
        
        bool emptyInputNickname = (bytes(_newNickname).length == 0);
        bool emptyInputStyle = (_newStyle == type(uint128).max);
        bool emptyInputColor = (bytes(_newColor).length == 0);
        require(!emptyInputNickname || !emptyInputStyle || !emptyInputColor, "Nothing to update");
        
        // update nickname if applied
        if(!emptyInputNickname) {
            if (keccak256(abi.encodePacked(_newNickname)) != keccak256(abi.encodePacked(profiles[msg.sender].nickname))){
                _setNickname(msg.sender, _newNickname);   
            }
        }
        
        // update style if applied
        if(!emptyInputStyle){
            if(_newStyle != builtInStyles[msg.sender].style) {
                builtInStyles[msg.sender].style = _newStyle;
            }
        }
        
        // update color if applied
        if(!emptyInputColor) {
            if (keccak256(abi.encodePacked(_newColor)) != keccak256(abi.encodePacked(builtInStyles[msg.sender].color))){
                builtInStyles[msg.sender].color = _newColor;   
            }
        }
    }
}

contract PenguinEmperor is OwnableInitialized {
    //struct packed into two storage slots
    struct PlayerInfo {
        //cumulative time spent as emperor
        uint32 timeAsEmperor;
        //last time at which the player became emperor (default 0)
        uint32 lastCrowningBlockTimestamp;
        //number of times the player has stolen the crown
        uint32 timesCrownStolen;
        //most recent timestamp at which player was poisoned (default 0)
        uint32 lastTimePoisoned;
        //number of times the player has been poisoned by another emperor
        uint32 timesPoisoned;
        //number of times the player has poisoned another emperor
        uint32 emperorsPoisoned;    
        //remaining bits in storage slot 
        uint64 additionalStorage;
    }

    struct PlayerStatus {
        uint32 frozenTimestamp;
        uint8 hailStormsCast;
        //0 = not perplexed, 1 = perplexed w/ 0 failed bids, 2 = perplexed w/ 1 failed bid, 3 = 2 failed, 4 = 3 failed (resets to status 0)
        uint8 perplexedStatus;
        //0 = will not perplex person who steals throne, 1 = will perplex person who steals throne
        uint8 perplexProtectionActive;
        uint8 perplexSpellsCast;
        //0 = not protected, 1 = protected w/ 0 failed bids, 2 = protected w/ 1 failed bid, 3 = 2 failed, 4 = 3 failed (resets to status 0)
        uint8 bananaStatus;
        uint8 bananaSpellsCast;
        uint32 vigorTimestamp;
        uint8 vigorSpellsCast;
        //0 = not effected, 1 = effected w/ 0 failed bids, 2 = effected w/ 1 failed bid, 3 = 2 failed, 4 = 3 failed (resets to status 0)
        uint8 toxinStatus;
        uint32 toxinTimestamp;
        uint8 toxinSpellsCast;

        //8*9 + 2*32 = 136 bits used
    }

    //packs address and bid into a single storage slot
    //bids must be less than 2^96-1 = 7.922...e28, i.e. trillions of a token with 18 decimals
    struct PlayerAndBid {
        address playerAddress;
        uint96 bidAmount;
    }

    //packs address and reign into a single storage slot
    struct PlayerAndReign {
        address playerAddress;
        uint32 reign;
    }

    //STORAGE
    //token used for play
    address public immutable TOKEN_TO_PLAY;
    //used for intermediate token management if not playing with PEFI or iPEFI
    address public immutable NEST_ALLOCATOR;
    //database for users to register their penguins
    address public immutable PENGUIN_DATABASE;

    //PEFI token
    address internal constant PEFI = 0xe896CDeaAC9615145c0cA09C8Cd5C25bced6384c;
    //iPEFI token
    address internal constant NEST = 0xE9476e16FE488B90ada9Ab5C7c2ADa81014Ba9Ee;
    //see usage in poisonCost() function
    uint256 internal constant MAX_POISON_BIPS_FEE = 1000;
    //constant for calculations that use BIPS
    uint256 internal constant MAX_BIPS = 10000;

    //address and bid amount of current emperor
    PlayerAndBid public currentEmperorAndBid;

    //amount of each bid that goes to the jackpot & nest, in BIPS
    uint256 public immutable JACKPOT_FEE_BIPS;
    uint256 public immutable NEST_FEE_BIPS;
    //current jackpot size in TOKEN_TO_PLAY
    uint256 public jackpot;
    //total TOKEN_TO_PLAY sent to NEST
    uint256 public totalNestDistribution;

    uint32 internal constant MAX_DURATION = 7 days;
    //game settings. times in (UTC) seconds, bid + fee amounts in wei
    uint32 public immutable startDate;
    //consult the 'finalDate()' function for the true final date, as the optional 'addTimeOnSteal' mechanic may modify it
    uint32 internal immutable finalDateInternal;
    uint256 public immutable openingBid;
    uint256 public immutable minBidIncrease;
    uint256 public immutable maxBidIncrease;
    uint256 public immutable poisonFixedFee;
    uint256 public immutable poisonBipsFee;
    uint256 public immutable poisonDuration;
    uint256 public immutable poisonCooldown;
    uint256 public immutable poisonSplitToNest;
    uint256 public immutable poisonSplitToJackpot;

    //total number of times the crown was stolen this game
    uint32 public totalTimesCrownStolen;
    //whether or not the game's jackpot has been distributed yet
    bool public jackpotClaimed;

    //variables for top emperors
    uint256 public immutable NUMBER_TOP_EMPERORS;
    mapping(uint256 => PlayerAndReign) public topEmperorsAndReigns;
    uint256[] public JACKPOT_SPLIT;

    //optional extra mechanic to ocassionally distribute tokens
    bool public immutable randomDistributorEnabled;

    //optional extra mechanic to add to the game's duration each time the crown is stolen
    uint256 constant internal MAX_TIME_TO_ADD_ON_STEAL = 120;
    uint32 public immutable timeToAddOnSteal;
    bool public immutable addTimeOnStealEnabled;

    //stores info for each player
    mapping(address => PlayerInfo) public playerDB;

    //POTION STORAGE
    mapping(address => PlayerStatus) public statuses;
    //last player to poison the player (default 0 address)
    mapping(address => address) public lastPoisonedBy;

    IPOTIONS public immutable POTIONS;
    //tokenId in the 'POTIONS' contract for different potions
    uint256 internal constant FROST_POTION_SLOT = 1;
    uint256 internal constant PERPLEX_POTION_SLOT = 2;
    uint256 internal constant BANANA_POTION_SLOT = 3;
    uint256 internal constant VIGOR_POTION_SLOT = 4;
    uint256 internal constant TOXIN_POTION_SLOT = 5;

    //max number of casts of various spells
    uint8 internal constant MAX_HAIL_STORMS_PER_USER = 2;
    uint8 internal constant MAX_PERPLEX_PER_USER = 2;
    uint8 internal constant MAX_BANANA_PER_USER = 5;
    uint8 internal constant MAX_VIGOR_PER_USER = 3;
    uint8 internal constant MAX_TOXIN_PER_USER = 5;

    //duration in seconds
    uint16 internal constant FREEZE_DURATION = 600;
    uint16 internal constant VIGOR_DURATION = 600;
    uint16 internal constant TOXIN_DURATION = 120;

    //EVENTS
    event CrownStolen(address indexed newEmperor);
    event SentToNest(uint256 amountTokens);
    event JackpotClaimed(uint256 jackpotSize);
    event EmperorPoisoned(address indexed poisonedEmperor, address indexed poisoner, uint256 timePoisoned);
    
    event HailStormCast(address indexed caster);
    event HitByHailStorm(address indexed caster, address indexed effected);
    event PerplexCast(address indexed caster);
    event HitByPerplexed(address indexed caster, address indexed effected);
    event FailedBecausePerplexed(address indexed effected);
    event BananaCast(address indexed caster);
    event FailedBecauseBanana(address indexed effected);
    event VigorCast(address indexed caster);
    event ToxinCast(address indexed caster);
    event HitByToxin(address indexed caster, address indexed effected);
    event FailedBecauseToxin(address indexed effected);

    modifier stealCrownCheck() {
        /*Checks for the following conditions:
        A. Check to see that the competiton is ongoing
        B. The msg.sender registered their Penguin.
        C. The msg.sender isn't the current Emperor.
        D. The bid is enough to dethrone the currentEmperor.
        E. Sender is not a contract
        F. Sender was not recently poisoned.
        */
        require(isGameRunning(), "Competition is not ongoing.");
        //checking if the player has stolen the crown before here means the database only has to be checked on the user's first crown steal
        require(playerDB[msg.sender].timesCrownStolen > 0 || PenguinDatabase(PENGUIN_DATABASE).isRegistered(msg.sender), "Please register your Penguin first.");
        require(msg.sender != currentEmperorAndBid.playerAddress, "You are already the King of Penguins.");
        require(msg.sender == tx.origin, "EOAs only");
        require(block.timestamp >= (playerDB[msg.sender].lastTimePoisoned + poisonDuration), "You were poisoned too recently");
        _;
    } 

    //see below for how the variables are assigned to the arrays
    //uint32[3] memory _times = [_startDate, _comptitionDuration, _timeToAddOnSteal]
    //address[4] memory _addressParameters = [TOKEN_TO_PLAY, NEST_ALLOCATOR, PENGUIN_DATABASE, owner]
    //uint256[3] memory _bidParameters = [openingBid, minBidIncrease, maxBidIncrease]
    //uint256[6] memory _poisonParameter = [poisonFixedFee, poisonBipsFee, poisonDuration, poisonCooldown, poisonSplitToNest, poisonSplitToJackpot]
    //bool[2] memory _optionalMechanics = [randomDistributorEnabled, addTimeOnStealEnabled]
    //uint256[] memory _JACKPOT_SPLIT = bips that each top emperor gets (beginning with the one with the longest reign)
    constructor (
        uint256 _JACKPOT_FEE_BIPS,
        uint256 _NEST_FEE_BIPS,
        uint256 _NUMBER_TOP_EMPERORS,
        IPOTIONS _POTIONS,
        uint32[3] memory _times,
        address[4] memory _addressParameters,
        uint256[3] memory _bidParameters,
        uint256[6] memory _poisonParameters,
        bool[2] memory _optionalMechanics,
        uint256[] memory _JACKPOT_SPLIT)
        OwnableInitialized(_addressParameters[3]) {
        require(_NUMBER_TOP_EMPERORS > 0, "must have at least 1 top emperor");
        require(_JACKPOT_SPLIT.length == _NUMBER_TOP_EMPERORS, "wrong length of _JACKPOT_SPLIT input");
        //local parameter since immutable variables can't be read inside the constructor
        uint256 numTopEmperors = _NUMBER_TOP_EMPERORS;
        NUMBER_TOP_EMPERORS = _NUMBER_TOP_EMPERORS;
        uint256 jackpotTotal;
        uint256 i;
        while (i < numTopEmperors) {
            jackpotTotal += _JACKPOT_SPLIT[i];
            unchecked {
                ++i;
            }
        }
        require(_times[0] > block.timestamp, "game must start in future");
        require(_times[1] <= MAX_DURATION, "cannot exceed max duration");
        require(jackpotTotal == MAX_BIPS, "bad JACKPOT_SPLIT input");
        require(_poisonParameters[4] + _poisonParameters[5] == MAX_BIPS, "bad poisonSplit inputs");
        require(_poisonParameters[1] <= MAX_POISON_BIPS_FEE, "bad poisonBipsFee inpupt");
        require(_bidParameters[1] <= _bidParameters[2], "invalid bidIncrease values"); 
        require(_addressParameters[0] != address(0) && _addressParameters[1] != address(0)
            && _addressParameters[2] != address(0) && _addressParameters[3] != address(0), "bad address input");
        require(_times[2] <= MAX_TIME_TO_ADD_ON_STEAL, "timeToAddOnSteal too large");
        TOKEN_TO_PLAY = _addressParameters[0];
        NEST_ALLOCATOR = _addressParameters[1];
        PENGUIN_DATABASE = _addressParameters[2];
        startDate = _times[0];
        finalDateInternal = _times[0] + _times[1];
        JACKPOT_FEE_BIPS = _JACKPOT_FEE_BIPS;
        JACKPOT_SPLIT = _JACKPOT_SPLIT;
        NEST_FEE_BIPS = _NEST_FEE_BIPS;
        openingBid = _bidParameters[0];
        minBidIncrease = _bidParameters[1];
        maxBidIncrease = _bidParameters[2];
        poisonFixedFee = _poisonParameters[0];
        poisonBipsFee = _poisonParameters[1];
        poisonDuration = _poisonParameters[2];
        poisonCooldown = _poisonParameters[3];
        poisonSplitToNest = _poisonParameters[4];
        poisonSplitToJackpot = _poisonParameters[5];
        randomDistributorEnabled = _optionalMechanics[0];
        timeToAddOnSteal = _times[2];
        addTimeOnStealEnabled = _optionalMechanics[1];
        POTIONS = _POTIONS;
    }

    //PUBLIC VIEW FUNCTIONS
    //gets contract AVAX balance, to be split amongst winners
    function avaxJackpot() public view returns(uint256) {
        return address(this).balance;
    }

    //returns the current cost of poisoning the emperor
    function poisonCost() public view returns(uint256) {
        return ((currentEmperorAndBid.bidAmount * poisonBipsFee) / MAX_BIPS) + poisonFixedFee;
    }

    //returns nickname of the current emperor
    function getCurrentEmperorNickname() view public returns (string memory) {
        return PenguinDatabase(PENGUIN_DATABASE).nickname(currentEmperorAndBid.playerAddress);
    }

    //whether or not 'penguinAddress' can be poisoned at the present moment
    function canBePoisoned(address penguinAddress) public view returns(bool) {
        if (block.timestamp >= (playerDB[penguinAddress].lastTimePoisoned + poisonCooldown)) {
            return true;
        } else {
            return false;
        }
    }

    //remaining time until 'penguinAddress' can be poisoned again
    function timeLeftForPoison(address penguinAddress) public view returns(uint256) {
        if (block.timestamp >= (playerDB[penguinAddress].lastTimePoisoned + poisonCooldown)) {
            return 0;
        } else {
            return ((playerDB[penguinAddress].lastTimePoisoned + poisonCooldown) - block.timestamp);
        }
    }   

    //remaining time that 'penguinAddress' is poisoned
    function timePoisonedRemaining(address penguinAddress) public view returns(uint256) {
        if (block.timestamp >= (playerDB[penguinAddress].lastTimePoisoned + poisonDuration)) {
            return 0;
        } else {
            return ((playerDB[penguinAddress].lastTimePoisoned + poisonDuration) - block.timestamp);
        }
    }

    function finalDate() public view returns(uint32) {
        if (!addTimeOnStealEnabled) {
            return finalDateInternal;
        } else {
            return finalDateInternal + (totalTimesCrownStolen * timeToAddOnSteal);
        }
    }

    //returns 'true' only if the game is open for play
    function isGameRunning() public view returns(bool) {
        return(block.timestamp >= startDate && block.timestamp <= finalDate());
    }

    //returns 0 if game is not running, otherwise returns the amount of seconds left to play
    function timeUntilEnd() public view returns(uint256) {
        if (!isGameRunning()) {
            return 0;
        } else {
            return(finalDate() - block.timestamp);
        }
    }

    //returns 0 if the game start has passed, otherwise returns the amount of seconds left until the game starts
    function timeUntilStart() public view returns(uint256) {
        if (block.timestamp >= startDate) {
            return 0;
        } else {
            return (startDate - block.timestamp);
        }
    }

    //includes the time that the current emperor has held the throne
    function timeAsEmperor(address penguinAddress) public view returns(uint256) {
        if (penguinAddress != currentEmperorAndBid.playerAddress || jackpotClaimed) {
            return playerDB[penguinAddress].timeAsEmperor;
        } else if (!isGameRunning()) {
            return (playerDB[penguinAddress].timeAsEmperor + (finalDate() - playerDB[penguinAddress].lastCrowningBlockTimestamp));
        } else {
            return (playerDB[penguinAddress].timeAsEmperor + (uint32(block.timestamp) - playerDB[penguinAddress].lastCrowningBlockTimestamp));
        }
    }

    function topEmperors(uint256 index) public view returns(address) {
        return topEmperorsAndReigns[index].playerAddress;
    }

    function longestReigns(uint256 index) public view returns(uint32) {
        return topEmperorsAndReigns[index].reign;
    }

    //EXTERNAL FUNCTIONS
    function stealCrown(uint256 amount) external stealCrownCheck() returns (bool bidFailed) {
        //copy current emperor to memory for savings on repeatedly checking storage slot
        PlayerAndBid memory emperor = currentEmperorAndBid;

        //get current emperor's status for checking potions
        PlayerStatus memory emperorStatus = statuses[emperor.playerAddress];
        //check if current emperor has vigor active
        require(emperorStatus.vigorTimestamp < (uint32(block.timestamp) - VIGOR_DURATION), "emperor has vigor active!");
        //get the msg.sender's status for checking potions
        PlayerStatus memory callerStatus = statuses[msg.sender];
        //check if msg.sender has hail storm active
        require(callerStatus.frozenTimestamp < (uint32(block.timestamp) - FREEZE_DURATION), "caller is frozen!");

        //transfer TOKEN_TO_PLAY from the new emperor to this contract
        IERC20(TOKEN_TO_PLAY).transferFrom(msg.sender, address(this), amount);

        bidFailed = _stealCrown(amount, emperor, emperorStatus, callerStatus);
        return bidFailed;
    }

    function stealCrownAndPoison(uint256 amount) external stealCrownCheck()  returns (bool bidFailed) {
        //copy current emperor to memory for savings on repeatedly checking storage slot
        PlayerAndBid memory emperor = currentEmperorAndBid;
        require(canBePoisoned(emperor.playerAddress), "This emperor was already recently poisoned");

        //get current emperor's status for checking potions
        PlayerStatus memory emperorStatus = statuses[emperor.playerAddress];
        //check if current emperor has vigor active
        require(emperorStatus.vigorTimestamp < (uint32(block.timestamp) - VIGOR_DURATION), "emperor has vigor active!");
        //get the msg.sender's status for checking potions
        PlayerStatus memory callerStatus = statuses[msg.sender];
        //check if msg.sender has hail storm active
        require(callerStatus.frozenTimestamp < (uint32(block.timestamp) - FREEZE_DURATION), "caller is frozen!");

        uint256 currentPoisonCost = poisonCost();
        //transfer TOKEN_TO_PLAY from the new emperor to this contract
        IERC20(TOKEN_TO_PLAY).transferFrom(msg.sender, address(this), (amount + currentPoisonCost));
        playerDB[emperor.playerAddress].lastTimePoisoned = uint32(block.timestamp);
        playerDB[emperor.playerAddress].timesPoisoned += 1;
        playerDB[msg.sender].emperorsPoisoned += 1;
        lastPoisonedBy[emperor.playerAddress] = msg.sender;
        emit EmperorPoisoned(emperor.playerAddress, msg.sender, block.timestamp);
        totalNestDistribution += ((currentPoisonCost * poisonSplitToNest) / MAX_BIPS);
        jackpot += ((currentPoisonCost * poisonSplitToJackpot) / MAX_BIPS);

        bidFailed = _stealCrown(amount, emperor, emperorStatus, callerStatus);
        return bidFailed;
    }

    function claimJackpot() external {
        require(block.timestamp > finalDate(), "Competition still running");
        require(!jackpotClaimed, "Jackpot already claimed");
        jackpotClaimed = true;
        emit JackpotClaimed(jackpot);

        //copy current emperor to memory for savings on repeatedly checking storage slot
        PlayerAndBid memory emperor = currentEmperorAndBid;

        //Keeps track of the time (in seconds) for which the lastEmperor held the crown.
        //nearly identical to logic above, but uses finalDate() instead of block.timestamp
        playerDB[emperor.playerAddress].timeAsEmperor += (finalDate() - playerDB[emperor.playerAddress].lastCrowningBlockTimestamp);    

        //Checks to see if the final Emperor is within the top NUMBER_TOP_EMPERORS (in terms of total time as Emperor)
        _updateTopEmperors(emperor.playerAddress);

        //update AVAX jackpot, to handle if any simple transfers have been made to the contract
        uint256 avaxJackpotSize = avaxJackpot();

        //distribute funds to nest
        _sendToNest(totalNestDistribution);

        //split jackpot among top NUMBER_TOP_EMPERORS emperors
        uint256 i;
        while (i < NUMBER_TOP_EMPERORS) {
            address recipient = topEmperorsAndReigns[i].playerAddress;
            //deal with edge case present in testing where less than NUMBER_TOP_EMPERORS addresses have played
            if (recipient == address(0)) {
                recipient = owner();
            }
            _safeTokenTransfer(TOKEN_TO_PLAY, recipient, ((jackpot * JACKPOT_SPLIT[i]) / MAX_BIPS));
            _transferAVAX(recipient, ((avaxJackpotSize * JACKPOT_SPLIT[i]) / MAX_BIPS));
            unchecked {
                ++i;
            }
        }   

        //refund last bid
        _safeTokenTransfer(TOKEN_TO_PLAY, emperor.playerAddress, emperor.bidAmount);
    }

    //simple function for accepting AVAX transfers directly to the contract -- allows increasing avaxJackpot
    receive() external payable {}

    //SPELLS / POTIONS
    function castHailStorm() external {
        require(statuses[msg.sender].hailStormsCast < MAX_HAIL_STORMS_PER_USER, "max spell usage");
        POTIONS.burnFrom(msg.sender, FROST_POTION_SLOT, 1);
        statuses[msg.sender].hailStormsCast += 1;
        uint256 i;
        address emperor;
        while (i < NUMBER_TOP_EMPERORS) {
            emperor = topEmperorsAndReigns[i].playerAddress; 
            //if emperor does not have vigor active and is not the caster of the spell, then freeze them
            if (statuses[emperor].vigorTimestamp < (uint32(block.timestamp) - VIGOR_DURATION) && (emperor != msg.sender)) {
                statuses[emperor].frozenTimestamp = uint32(block.timestamp);
                emit HitByHailStorm(msg.sender, emperor);
            }
            unchecked {
                ++i;
            }
        }
        emit HailStormCast(msg.sender);
    }

    function castPerplex() external {
        require(statuses[msg.sender].perplexSpellsCast < MAX_PERPLEX_PER_USER, "max spell usage");
        require(statuses[msg.sender].perplexProtectionActive == 0, "cannot stack perplex spells");
        POTIONS.burnFrom(msg.sender, PERPLEX_POTION_SLOT, 1);
        statuses[msg.sender].perplexSpellsCast += 1;        
        statuses[msg.sender].perplexProtectionActive = 1;
        emit PerplexCast(msg.sender);
    }

    function castBanana() external {
        require(statuses[msg.sender].bananaSpellsCast < MAX_BANANA_PER_USER, "max spell usage");
        require(statuses[msg.sender].bananaStatus == 0, "cannot stack banana spells");
        POTIONS.burnFrom(msg.sender, BANANA_POTION_SLOT, 1);
        statuses[msg.sender].bananaSpellsCast += 1;        
        statuses[msg.sender].bananaStatus = 1;
        emit BananaCast(msg.sender);
    }

    function castVigor() external {
        require(statuses[msg.sender].vigorSpellsCast < MAX_VIGOR_PER_USER, "max spell usage");
        POTIONS.burnFrom(msg.sender, VIGOR_POTION_SLOT, 1);
        statuses[msg.sender].vigorSpellsCast += 1;        
        statuses[msg.sender].vigorTimestamp = uint32(block.timestamp);
        emit VigorCast(msg.sender);
    }

    function castToxin() external {
        require(statuses[msg.sender].toxinSpellsCast < MAX_TOXIN_PER_USER, "max spell usage");
        address emperor = currentEmperorAndBid.playerAddress;
        require(statuses[emperor].vigorTimestamp < (uint32(block.timestamp) - VIGOR_DURATION), "emperor has vigor active!");
        POTIONS.burnFrom(msg.sender, TOXIN_POTION_SLOT, 1);
        statuses[msg.sender].toxinSpellsCast += 1;
        statuses[emperor].toxinTimestamp = uint32(block.timestamp);
        statuses[emperor].toxinStatus = 1;
        emit HitByToxin(msg.sender, emperor);
        emit ToxinCast(msg.sender);
    }

    //OWNER-ONLY FUNCTIONS
    function stuckTokenRetrieval(address token, uint256 amount, address dest) external onlyOwner {
        require(block.timestamp > finalDate() + 10800, "The competiton must be over");
        _safeTokenTransfer(token, dest, amount);
    }   

    //INTERNAL FUNCTIONS
    function _stealCrown(uint256 _amount, PlayerAndBid memory emperor, PlayerStatus memory emperorStatus, PlayerStatus memory callerStatus) internal returns (bool) {
        //return variable. false if bid succeeds, true if it fails.
        bool bidFails;

        if (emperor.playerAddress == address(0)) {
            require(_amount == openingBid, "must match openingBid");
            //update currentEmperor, bid amount, and last crowning time
            emperor.playerAddress = msg.sender;
            emperor.bidAmount = uint96(_amount);
            currentEmperorAndBid = emperor;
            playerDB[msg.sender].lastCrowningBlockTimestamp = uint32(block.timestamp);
            //first bid doesn't count for these  two
            //playerDB[msg.sender].timesCrownStolen += 1;
            //emit CrownStolen(msg.sender);

        } else {
            require(_amount >= (emperor.bidAmount + minBidIncrease) && _amount <= (emperor.bidAmount + maxBidIncrease), "Bad bid"); 
            //in the event the caller is perplexed
            if (callerStatus.perplexedStatus != 0) {
                bidFails = true;
                statuses[msg.sender].perplexedStatus = (callerStatus.perplexedStatus + 1) % 4;
                emit FailedBecausePerplexed(msg.sender);
            //in the event the caller has toxin active
            } else if (callerStatus.toxinStatus != 0 && callerStatus.toxinTimestamp < (uint32(block.timestamp) - TOXIN_DURATION)) {
                bidFails = true;
                statuses[msg.sender].toxinStatus = (callerStatus.toxinStatus + 1) % 4;  
                emit FailedBecauseToxin(msg.sender);
            //in the event the current emperor has banana active              
            } else if (emperorStatus.bananaStatus != 0) {
                bidFails = true;
                statuses[emperor.playerAddress].bananaStatus = (emperorStatus.bananaStatus + 1) % 4;  
                emit FailedBecauseBanana(msg.sender);                
            //i.e. if the current emperor has cast perplex, so that the person who dethrones them gets perplexed (as long as they don't have vigor protection)
            } else if (emperorStatus.perplexProtectionActive != 0 && callerStatus.vigorTimestamp < (uint32(block.timestamp) - VIGOR_DURATION)) {
                callerStatus.perplexedStatus = 1;
                emperorStatus.perplexProtectionActive = 0;
                emit HitByPerplexed(emperor.playerAddress, msg.sender);
            }

            uint256 lastEmperorBidMinusFees = (emperor.bidAmount * (MAX_BIPS - (JACKPOT_FEE_BIPS + NEST_FEE_BIPS))) / MAX_BIPS;
            uint256 lastEmperorBidFeeForJackpot = (emperor.bidAmount * JACKPOT_FEE_BIPS) / MAX_BIPS;
            uint256 lastEmperorBidFeeForNests = (emperor.bidAmount * NEST_FEE_BIPS) / MAX_BIPS;    

            //track NEST distribution
            totalNestDistribution += lastEmperorBidFeeForNests; 

            //transfer TOKEN_TO_PLAY to the previous emperor
            _safeTokenTransfer(TOKEN_TO_PLAY, emperor.playerAddress, lastEmperorBidMinusFees);
            jackpot += lastEmperorBidFeeForJackpot; 

            //i.e. if bid succeeds
            if (!bidFails) {
                //Keeps track of the time (in seconds) for which the lastEmperor held the crown.
                playerDB[emperor.playerAddress].timeAsEmperor += (uint32(block.timestamp) - playerDB[emperor.playerAddress].lastCrowningBlockTimestamp);    

                //Checks to see if the last Emperor is within the top NUMBER_TOP_EMPERORS (in terms of total time as Emperor)
                _updateTopEmperors(emperor.playerAddress);  

                //tracking for stats
                totalTimesCrownStolen += 1;

                //update currentEmperor, bid amount, and last crowning time
                emperor.playerAddress = msg.sender;
                emperor.bidAmount = uint96(_amount);
                currentEmperorAndBid = emperor;
                playerDB[msg.sender].lastCrowningBlockTimestamp = uint32(block.timestamp);
                playerDB[msg.sender].timesCrownStolen += 1;
                emit CrownStolen(msg.sender);
            }
        }

        //trigger random roll, if mechanic is enabled
        if (randomDistributorEnabled) {
            IPenguinEmperorManager(payable(owner())).roll(msg.sender);
        }

        return bidFails;
    }

    function _updateTopEmperors(address lastEmperor) internal {
        uint32 newReign = playerDB[lastEmperor].timeAsEmperor; 

        //short-circuit logic to skip steps if user will not be in top emperors array
        if (topEmperorsAndReigns[(NUMBER_TOP_EMPERORS - 1)].reign >= newReign) {
            return;
        }

        //check if emperor already in list -- fetch index if they are
        uint256 i;
        bool alreadyInList;
        while (i < NUMBER_TOP_EMPERORS) {
            if (topEmperorsAndReigns[i].playerAddress == lastEmperor) {
                alreadyInList = true;
                break;
            }
            unchecked {
                ++i;
            }
        }   

        //get the index of the new element
        uint256 j;
        while (j < NUMBER_TOP_EMPERORS) {
            if (topEmperorsAndReigns[j].reign < newReign) {
                break;
            }
            unchecked {
                ++j;
            }
        }

        PlayerAndReign memory newTopEmperorAndReign = PlayerAndReign({playerAddress: lastEmperor, reign: newReign});

        if (!alreadyInList) {
            //shift the array down by one position, as necessary
            uint256 k = (NUMBER_TOP_EMPERORS - 1);
            while (k > j) {
                topEmperorsAndReigns[k] = topEmperorsAndReigns[k - 1];
                unchecked {
                    --k;
                }
            //add in the new element, but only if it belongs in the array
            } if (j < (NUMBER_TOP_EMPERORS - 1)) {
                topEmperorsAndReigns[j] = newTopEmperorAndReign;
            //update last array item in edge case where new newReign is only larger than the smallest stored value
            } else if (topEmperorsAndReigns[(NUMBER_TOP_EMPERORS - 1)].reign < newReign) {
                topEmperorsAndReigns[j] = newTopEmperorAndReign;
            }   

        //case handling for when emperor already holds a spot
        //check i>=j for the edge case of updates to tied positions
        } else if (i >= j) {
            //shift the array by one position, until the emperor's previous spot is overwritten
            uint256 m = i;
            while (m > j) {
                topEmperorsAndReigns[m] = topEmperorsAndReigns[m - 1];
                unchecked {
                    --m;
                }
            }
            //add emperor back into array, in appropriate position
            topEmperorsAndReigns[j] = newTopEmperorAndReign;

        //handle tie edge cases
        } else {
            //just need to update emperor's reign in this case
            topEmperorsAndReigns[i].reign = newReign;
        }
    }

    function _sendToNest(uint256 amount) internal {
        if (TOKEN_TO_PLAY == NEST) {
            iPEFI(NEST).leave(amount);
            uint256 pefiToSend = IERC20(PEFI).balanceOf(address(this));
            IERC20(PEFI).transfer(NEST, pefiToSend);
            emit SentToNest(pefiToSend);
        } else if (TOKEN_TO_PLAY == PEFI) {
            _safeTokenTransfer(PEFI, NEST, amount);
            emit SentToNest(amount);
        } else {
            _safeTokenTransfer(TOKEN_TO_PLAY, NEST_ALLOCATOR, amount);
            emit SentToNest(amount);
        }
    }   

    function _safeTokenTransfer(address token, address _to, uint256 _amount) internal {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            _transferAVAX(_to, _amount);
        } else if (_amount != 0) {
            uint256 tokenBal =  IERC20(token).balanceOf(address(this));
            bool transferSuccess = false;
            if (_amount > tokenBal) {
                if (tokenBal > 0) {
                    transferSuccess = IERC20(token).transfer(_to, tokenBal);
                } else {
                    transferSuccess = true;
                }
            } else {
                transferSuccess = IERC20(token).transfer(_to, _amount);
            }
            require(transferSuccess, "_safeTokenTransfer: transfer failed");            
        }
    }

    function _transferAVAX(address _to, uint256 _amount) internal {
        //skip transfer if amount is zero
        if (_amount != 0) {
            uint256 avaxBal = address(this).balance;
            if (_amount > avaxBal) {
                payable(_to).transfer(avaxBal);
            } else {
                payable(_to).transfer(_amount);
            }
        }
    }
}