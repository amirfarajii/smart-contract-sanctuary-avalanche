// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BatchTransfer {
    /// @notice Tokens on the given ERC-721 contract are transferred from you to a recipient.
    ///         Don't forget to execute setApprovalForAll first to authorize this contract.
    /// @param  _tokenContract An ERC-721 contract
    /// @param  _recipients    Receivers array
    /// @param  _tokenIds      Token IDs array
    function batchTransfer(IERC721 _tokenContract, address[] calldata _recipients, uint256[] calldata _tokenIds) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            _tokenContract.transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
    }
}

// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// contract DegisNFT is ERC721, Ownable {
//     using SafeERC20 for IERC20;

//     // ---------------------------------------------------------------------------------------- //
//     // ************************************* Constants **************************************** //
//     // ---------------------------------------------------------------------------------------- //

//     // Status defined as constants rather than enum
//     uint256 public constant STATUS_INIT = 0;
//     uint256 public constant STATUS_AIRDROP = 1;
//     uint256 public constant STATUS_ALLOWLIST = 2;
//     uint256 public constant STATUS_PUBLICSALE = 3;

//     // ---------------------------------------------------------------------------------------- //
//     // ************************************* Variables **************************************** //
//     // ---------------------------------------------------------------------------------------- //

//     // Current status of minting
//     uint256 public status;

//     // address public constant DEG = 0x9f285507Ea5B4F33822CA7aBb5EC8953ce37A645;
//     address public DEG;

//     // Total supply: 500
//     uint256 public constant MAX_SUPPLY = 499;

//     // Public sale price is 200 DEG
//     uint256 public constant PRICE_PUBLICSALE = 200 ether;
//     uint256 public constant PRICE_ALLOWLIST = 200 ether;

//     uint256 public constant MAXAMOUNT_PUBLICSALE = 10;

//     // Amount of NFTs already minted
//     // Current token Id
//     uint256 public mintedAmount;

//     // wallet mapping that allows wallets to mint during airdrop and allowlist sale
//     mapping(address => bool) public airdroplistClaimed;
//     mapping(address => bool) public allowlistMinted;

//     // amount minted on public sale per wallet
//     mapping(address => uint256) public mintedOnPublic;

//     // Base uri for the images
//     string public baseURI;

//     // Merkle root of airdrop list
//     bytes32 public airdropMerkleRoot;

//     // Merkle root of allowlist
//     bytes32 public allowlistMerkleRoot;

//     // ---------------------------------------------------------------------------------------- //
//     // *************************************** Events ***************************************** //
//     // ---------------------------------------------------------------------------------------- //

//     event StatusChange(uint256 oldStatus, uint256 newStatus);
//     event SetBaseURI(string baseUri);
//     event WithdrawERC20(
//         address indexed token,
//         uint256 amount,
//         address receiver
//     );
//     event MintAirdrop(uint256 userAmount, uint256 startId, uint256 finishId);
//     event AirdropClaim(address user, uint256 tokenId);
//     event AllowlistSale(address user, uint256 quantity, uint256 tokenId);
//     event PublicSale(address user, uint256 quantity, uint256 tokenId);

//     // ---------------------------------------------------------------------------------------- //
//     // ************************************* Constructor ************************************** //
//     // ---------------------------------------------------------------------------------------- //

//     /**
//      * @notice Constructor
//      *
//      * @dev The initial status is Init (default as zero)
//      */
//     constructor(address _degis) ERC721("DegisNFT", "DegisNFT") {
//         DEG = _degis;
//     }

//     // ---------------------------------------------------------------------------------------- //
//     // ************************************ View Functions ************************************ //
//     // ---------------------------------------------------------------------------------------- //

//     /**
//      * @notice Check if the address is inside allow list
//      *
//      * @param _user        The user address to check
//      * @param _merkleProof Merkle proof
//      *
//      * @return isAllowlist Whether it is inside allowlist
//      */
//     function isAllowlist(address _user, bytes32[] calldata _merkleProof)
//         external
//         view
//         returns (bool)
//     {
//         return
//             MerkleProof.verify(
//                 _merkleProof,
//                 allowlistMerkleRoot,
//                 keccak256(abi.encodePacked(_user))
//             );
//     }

//     /**
//      * @notice Check if the address is inside airdrop list
//      *
//      * @param _user        The user address to check
//      * @param _merkleProof Merkle proof
//      *
//      * @return isAirdrop   Whether it is inside airdrop
//      */
//     function isAirdrop(address _user, bytes32[] calldata _merkleProof)
//         external
//         view
//         returns (bool)
//     {
//         return
//             MerkleProof.verify(
//                 _merkleProof,
//                 airdropMerkleRoot,
//                 keccak256(abi.encodePacked(_user))
//             );
//     }

//     // ---------------------------------------------------------------------------------------- //
//     // ************************************ Set Functions ************************************* //
//     // ---------------------------------------------------------------------------------------- //

//     /**
//      * @notice Change minting status
//      *
//      * @dev Only by the owner
//      *
//      * @param _newStatus New minting status
//      */
//     function setStatus(uint256 _newStatus) external onlyOwner {
//         emit StatusChange(status, _newStatus);
//         status = _newStatus;
//     }

//     /**
//      * @notice Set degis token address
//      *
//      * @dev Only by the owner
//      *
//      * @param _deg Degis address
//      */
//     function setDEG(address _deg) external onlyOwner {
//         require(_deg != address(0), "Zero address");
//         DEG = _deg;
//     }

//     /**
//      * @notice Set the base URI for the NFTs
//      *
//      * @param  baseURI_ New base URI for the collection
//      */
//     function setBaseURI(string calldata baseURI_) external onlyOwner {
//         baseURI = baseURI_;
//         emit SetBaseURI(baseURI_);
//     }

//     /**
//      * @notice Set the airdrop merkle root
//      *
//      * @param _merkleRoot Merkle root for airdrop list
//      */
//     function setAirdropMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
//         airdropMerkleRoot = _merkleRoot;
//     }

//     /**
//      * @notice Set the allow list root
//      *
//      * @param _merkleRoot Merkle root for allowlist
//      */
//     function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
//         allowlistMerkleRoot = _merkleRoot;
//     }

//     // ---------------------------------------------------------------------------------------- //
//     // ************************************ Main Functions ************************************ //
//     // ---------------------------------------------------------------------------------------- //

//     /**
//      * @notice Owner minting
//      *
//      * @param _user     User address to mint
//      * @param _quantity Amount of NFTs to mint
//      */
//     function ownerMint(address _user, uint256 _quantity) external onlyOwner {
//         require(mintedAmount + _quantity <= MAX_SUPPLY, "Exceed max supply");
//         _mint(_user, _quantity);
//     }

//     /**
//      * @notice Mint airdrop for users
//      *
//      * @param _users User address list
//      */
//     function mintAirdrop(address[] calldata _users) external onlyOwner {
//         require(status == STATUS_AIRDROP, "Not in airdrop phase");

//         uint256 userAmount = _users.length;
//         require(mintedAmount + userAmount <= MAX_SUPPLY, "Exceed max supply");

//         uint256 startId = mintedAmount + 1;

//         for (uint256 i; i < userAmount; ) {
//             _mint(_users[i], 1);

//             unchecked {
//                 ++i;
//             }
//         }

//         emit MintAirdrop(userAmount, startId, mintedAmount);
//     }

//     /**
//      * @notice Airdrop claim
//      *
//      * @param _merkleProof Merkle proof for airdrop
//      */
//     function airdropClaim(bytes32[] calldata _merkleProof) external {
//         require(status == STATUS_AIRDROP, "Not in airdrop phase");
//         require(!airdroplistClaimed[msg.sender], "already claimed");
//         require(
//             MerkleProof.verify(
//                 _merkleProof,
//                 airdropMerkleRoot,
//                 keccak256(abi.encodePacked(msg.sender))
//             ),
//             "Invalid merkle proof"
//         );
//         airdroplistClaimed[msg.sender] = true;

//         _mint(msg.sender, 1);

//         emit AirdropClaim(msg.sender, mintedAmount);
//     }

//     /**
//      * @notice Allowlist minting
//      *
//      * @param _merkleProof Merkle proof for this user
//      */
//     function allowlistSale(bytes32[] calldata _merkleProof) external payable {
//         require(status == STATUS_ALLOWLIST, "Not in allowlist sale phase");
//         require(!allowlistMinted[msg.sender], "Already minted");
//         require(mintedAmount < MAX_SUPPLY, "Exceed max supply");
//         require(
//             MerkleProof.verify(
//                 _merkleProof,
//                 allowlistMerkleRoot,
//                 keccak256(abi.encodePacked(msg.sender))
//             ),
//             "Invalid merkle proof"
//         );

//         uint256 amountToPay = PRICE_ALLOWLIST;

//         // Transfer deg tokens
//         IERC20(DEG).safeTransferFrom(msg.sender, address(this), amountToPay);

//         _mint(msg.sender, 1);
//         allowlistMinted[msg.sender] = true;

//         emit AllowlistSale(msg.sender, 1, mintedAmount);
//     }

//     /**
//      * @notice Public sale mint
//      *
//      * @dev Allowed to mint several times as long as total per wallet is bellow maxPublicSale
//      *
//      * @param _quantity Amount of NFTs to mint
//      */
//     function publicSale(uint256 _quantity) external payable {
//         require(status == STATUS_PUBLICSALE, "Not in public sale phase");
//         require(tx.origin == msg.sender, "No proxy transactions");

//         require(
//             mintedOnPublic[msg.sender] + _quantity <= MAXAMOUNT_PUBLICSALE,
//             "Max public sale amount reached"
//         );
//         require(_quantity + mintedAmount <= MAX_SUPPLY, "Exceed max supply");

//         // DEG to pay for minting
//         uint256 amountToPay = _quantity * PRICE_PUBLICSALE;

//         // Transfer DEG to this contract
//         IERC20(DEG).safeTransferFrom(msg.sender, address(this), amountToPay);

//         _mint(msg.sender, _quantity);

//         unchecked {
//             mintedOnPublic[msg.sender] += _quantity;
//         }

//         emit PublicSale(msg.sender, _quantity, mintedAmount);
//     }

//     /**
//      * @notice Withdraw avax by the owner
//      */
//     function withdraw() external onlyOwner {
//         payable(msg.sender).transfer(address(this).balance);
//     }

//     /**
//      * @notice Withdraw specificed ERC20 and amount to owner
//      *
//      * @param  _token  ERC20 to withdraw
//      * @param  _amount amount to withdraw
//      */
//     function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
//         IERC20(_token).transfer(msg.sender, _amount);
//         emit WithdrawERC20(_token, _amount, msg.sender);
//     }

//     // ---------------------------------------------------------------------------------------- //
//     // *********************************** Internal Functions ********************************* //
//     // ---------------------------------------------------------------------------------------- //

//     /**
//      * @notice BaseURI
//      */
//     function _baseURI() internal view override returns (string memory) {
//         return baseURI;
//     }

//     /**
//      * @notice Mint multiple NFTs
//      *
//      * @param  _to     Address to mint NFTs to
//      * @param  _amount Amount to mint
//      */
//     function _mint(address _to, uint256 _amount) internal override {
//         uint256 alreadyMinted = mintedAmount;

//         for (uint256 i = 1; i <= _amount; ) {
//             super._mint(_to, ++alreadyMinted);

//             unchecked {
//                 ++i;
//             }
//         }

//         unchecked {
//             mintedAmount += _amount;
//         }
//     }
// }