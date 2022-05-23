// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

contract GoldPot is ERC721ABurnable, ERC721AQueryable, Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public cost = 400 ether;
    uint256 public maxSupply = 500;
    uint256 public maxMintAmountForTX = 20;
    uint256 public MintCap = 3;
    uint256 public MintCapPlatinumMember = 2;
    bool public paused = false;
    bool public MintCapState = false;
    bool public onlyWhitelisted = false;
    bool public onlyPlatinumMember = false;
    bool public TransferActive = true;
    bytes32 public PlatinumMerkleRoot;
    bytes32 public WhitelistMerkleRoot;
    address[] public whitelistedAddresses;
    address[] public blacklistedAddresses;
    address[] public PlatinumMemberAddresses;
    address[] public addressofAddressMintedBalance;
    address public Treasury;


    struct TokenUri{
        string TokenUri;
        string BatchType;
    }

    struct TokenInfo {
        IERC20 Address;
        string Token;
    }

    TokenUri[] public GoldPotTokenUri;
    TokenInfo[] public AllowedCrypto;

    mapping(address => uint256) public addressMintedBalance;
    mapping(uint256 => uint256) public typeofbaseuri;

    constructor()
        ERC721A("Lucky Leo Gold Pots", "LLGP")
    {_startTokenId();
    }
    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // public
    /**
     * Mint Of a GoldPot
     * @param _mintAmount how many Clovers to mint
     * @param _pid the currency to pay for the mint
     */
    function mint(uint256 _mintAmount,uint256 _batch, uint256 _pid) public nonReentrant() {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        uint256 supply = totalSupply();
        uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
        uint256 price = cost * _mintAmount;
        IERC20 paytoken;
        paytoken = tokens.Address;
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(paytoken.balanceOf(_msgSender()) >= (price), "insufficient funds");
        require(_mintAmount <= maxMintAmountForTX,"max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply,"max NFT limit exceeded");
        
        if(MintCapState != false) {
            require( ownerMintedCount + _mintAmount <= MintCap,"max NFT per address exceeded");
        }
        
       if (onlyPlatinumMember != false) {
            require(_isPlatinumMember(_msgSender()), "user is not whitelisted");
            require( ownerMintedCount + _mintAmount <= MintCapPlatinumMember,"max NFT per address exceeded");

        }
        
        if (onlyWhitelisted != false) {
            require(_isWhitelisted(_msgSender()), "user is not whitelisted"); 
        }

        if(paytoken.allowance(_msgSender(), address(this)) <= price){
            uint256 approveAmount = price ;
            paytoken.approve(address(this), approveAmount );
        }

        paytoken.transferFrom(_msgSender(), Treasury, price);
        addressofAddressMintedBalance.push(_msgSender());
        addressMintedBalance[_msgSender()] += _mintAmount;

        uint256 StratingID = _nextTokenId();
        uint256 EndingID = StratingID + _mintAmount;

        for (uint256 i = StratingID; i <= EndingID; i++) {
            
            typeofbaseuri[(i)] = _batch;
            
        }

        _safeMint(_msgSender(), _mintAmount);
    }

    /**
     * Gets all the TokenURi of an existing TokenID
     * @param tokenId the TokenID to get the TokenURi
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256  _batch = typeofbaseuri[tokenId];
        TokenUri memory _TokenUri = GoldPotTokenUri[_batch];
        return _TokenUri.TokenUri;
    }

   /**ADDING BLACKLIST ON TRANSFERS
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length

        require(TransferActive = true, "Transfer of the token is not active");
         require(_isnotBlacklisted(_msgSender()), "You are BlackListed");
        _transfer(from, to, tokenId);
        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(TransferActive = true, "Transfer of the token is not active");
         require(_isnotBlacklisted(_msgSender()), "You are BlackListed");
        safeTransferFrom(from, to, tokenId, "");
        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(TransferActive = true, "Transfer of the token is not active");
        require(_isnotBlacklisted(_msgSender()), "You are BlackListed");
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * Checks if an address is WhitheListed
     * @param _user the address to check
     */
    function _isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * Checks if an address is BlackListed
     * @param _user the address to check
     */
    function _isnotBlacklisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < blacklistedAddresses.length; i++) {
            if (blacklistedAddresses[i] == _user) {
                return false;
            }
        }
        return true;
    }

    /**
     * Checks if an address is Platinum Member
     * @param _user the address to check
     */
    function _isPlatinumMember(address _user) public view returns (bool) {
        for (uint256 i = 0; i < PlatinumMemberAddresses.length; i++) {
            if (PlatinumMemberAddresses[i] == _user) {
                return false;
            }
        }
        return true;
    }

   

    //only owner

    /**
     * Adds a new currency to the patments system
     * @param _paytoken the Token address to recive as Payament
     * @param _Token the Tick of the Token to recive as Payament
     */
    function addCurrency(
        IERC20 _paytoken,
        string memory _Token
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                Address: _paytoken,
                Token: _Token
            })
        );
    }

    // Reset all the currency in the payement system
    function resetCurrency () public onlyOwner {
        for (uint256 i=0; i<AllowedCrypto.length; i++) {
            delete AllowedCrypto[i];
        }
    }

    /**
     * Set the TokenUri of the Clove Rarity type
     * @param _batch the type of Batch of GoldPot to set the TokenUri
     * @param _tokenuri the TokenUri to set
     */
    function setGoldPotTokenUri(string memory _batch, string memory _tokenuri) public onlyOwner{
        GoldPotTokenUri.push(TokenUri({
            TokenUri: _tokenuri,
            BatchType: _batch
        }));
       
    }

    /**
     * Change the Price to mint The GoldPot
     * @param _newCost the New Price to set
     */
    function setCost(uint256 _newCost) public onlyOwner {
        uint256 conversion = 1 ether;
        cost = _newCost * conversion;

    }
    
    /**
     * Set the Treasury wallet that will recive all the funds
     * @param _Treasury the wallet to set as Treasury
     */
    function setTreasury(address _Treasury) public onlyOwner {
        Treasury = _Treasury;
    }

    function setNewmaxSupply(uint256 _BatchAmount) public onlyOwner {
        maxSupply += _BatchAmount;

    }

    /**
     * Set the Max NFT that a Platinum Member can Mint 
     * @param _MintCapPlatinumMember the Max Number of NFT mintable
     */
    function setMintCapPlatinumMember(uint256 _MintCapPlatinumMember)
        public
        onlyOwner
    {
       MintCapPlatinumMember = _MintCapPlatinumMember;
    }

    /**
     * Set the Max NFT Mintable for wallet
     * @param _MintCap the Max Number of NFT mintable for wallet
     */
    function setMintCap(uint256 _MintCap)
        public
        onlyOwner
    {
        MintCap = _MintCap;
    }

    /**
     * Set the Max NFT Mintable for Transaction
     * @param _newmaxMintAmountForTX the Max Number of NFT mintable for Transaction
     */
    function setmaxMintAmountForTX(uint256 _newmaxMintAmountForTX) public onlyOwner {
        maxMintAmountForTX = _newmaxMintAmountForTX;
    }

    /**
     * Set the Contrata Pause state
     * @param _state the State to set
     */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /**
     * Set the Contract Whitelist state
     * @param _state the State to set
     */
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }
    
    /**
     * Set the Contract Platinum Member state
     * @param _state the State to set
     */
    function setonlyPlatinumMember(bool _state) public onlyOwner {
        onlyPlatinumMember = _state;
    }

    /**
     * Set the Contract Mint Cap state
     * @param _state the State to set
     */
    function setStateMintCap(bool _state) public onlyOwner {
        MintCapState = _state;
    }

    /**
     * Set the Transfer of NFT state
     * @param _state the State to set
     */
    function setTransferActive(bool _state) public onlyOwner {
        TransferActive = _state;
    }

    // Reset the count of mint for wallet
    function RestMintCap() public onlyOwner {
        for (uint256 i = 0; i < addressofAddressMintedBalance.length; i++) {
            delete addressMintedBalance[addressofAddressMintedBalance[i]];
        }
    }


    /**
     * Set the root hash for the Platinum list
     * @param _PlantinumMerkleRoot the Root Hash to Set
     */
    function SetPlatinumMerkleRoot(bytes32 _PlantinumMerkleRoot) public onlyOwner {
        PlatinumMerkleRoot = _PlantinumMerkleRoot;
    }

    
    /**
     * Set the root hash for the Whitelist list
     * @param _WhitlelistMerkleRoot the Root Hash to Set
     */
    function SetWhitelistMerkleRoot(bytes32 _WhitlelistMerkleRoot) public onlyOwner {
        WhitelistMerkleRoot = _WhitlelistMerkleRoot;
    }

    


         /**
     * Add the address in the Platinum Members List
     * @param _users the addresses to add
     */
    function AddPlatinummember(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            PlatinumMemberAddresses.push(_users[i]);
        }
    }

    /**
     * Remove the address in the Platinum Members List
     * @param _users the addresses to remove
     */
    function RemovePlatinumMember(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = 0; a < PlatinumMemberAddresses.length; a++) {
                if (PlatinumMemberAddresses[a] == _users[i]) {
                    PlatinumMemberAddresses[a] = PlatinumMemberAddresses[
                        PlatinumMemberAddresses.length - 1
                    ];
                    PlatinumMemberAddresses.pop();
                }
            }
        }
    }
    
    /**
     * Add the address in the WhiteList
     * @param _users the addresses to add
     */
    function AddWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistedAddresses.push(_users[i]);
        }
    }

    /**
     * Remove the address in the WhiteList
     * @param _users the addresses to remove
     */
    function RemoveWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = 0; a < whitelistedAddresses.length; a++) {
                if (whitelistedAddresses[a] == _users[i]) {
                    whitelistedAddresses[a] = whitelistedAddresses[
                        whitelistedAddresses.length - 1
                    ];
                    whitelistedAddresses.pop();
                }
            }
        }
    }

    /**
     * Add the address in the BlackList
     * @param _users the addresses to add
     */
    function AddBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklistedAddresses.push(_users[i]);
        }
    }

    /**
     * Remove the address in the BlackList
     * @param _users the addresses to remove
     */
    function RemoveBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = blacklistedAddresses.length; a == 0; a--) {
                if (blacklistedAddresses[a] == _users[i]) {
                    blacklistedAddresses[a] = blacklistedAddresses[
                        blacklistedAddresses.length - 1
                    ];
                    blacklistedAddresses.pop();
                }
            }
        }
    }


}