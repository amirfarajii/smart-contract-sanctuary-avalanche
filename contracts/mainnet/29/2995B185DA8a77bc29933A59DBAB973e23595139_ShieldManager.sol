// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../interfaces/IERC20.sol';
import '../../interfaces/ICategories.sol';
import '../../interfaces/IEmblemWeaver.sol';
import '../../interfaces/IShieldManager.sol';
import '../../interfaces/IPfpStaker.sol';

import '../../utils/tokens/erc721/ERC721.sol';
import '../../utils/Owned.sol';

import '../../libraries/HexStrings.sol';

contract ShieldManager is Owned, ERC721, IShieldManager {
	using HexStrings for uint16;

	/*///////////////////////////////////////////////////////////////
													EVENTS
	//////////////////////////////////////////////////////////////*/

	event ShieldBuilt(
		address indexed builder,
		uint256 indexed tokenId,
		bytes32 oldShieldHash,
		bytes32 newShieldHash,
		uint16 field,
		uint16[9] hardware,
		uint16 frame,
		uint24[4] colors
	);

	event MintingStatus(bool live);

	/*///////////////////////////////////////////////////////////////
													ERRORS
	//////////////////////////////////////////////////////////////*/

	error MintingClosed();

	error DuplicateShield();

	error InvalidShield();

	error ColorError();

	error IncorrectValue();

	error Unauthorised();

	/*///////////////////////////////////////////////////////////////
												SHIELD	STORAGE
	//////////////////////////////////////////////////////////////*/

	// Contracts
	IEmblemWeaver public emblemWeaver;
	IPfpStaker public pfpStaker;

	// Roundtable Contract Addresses
	address payable public roundtableFactory;
	address payable public roundtableRelay;

	// Fees
	uint256 epicFieldFee = 0.1 ether;
	uint256 heroicFieldFee = 0.25 ether;
	uint256 olympicFieldFee = 0.5 ether;
	uint256 legendaryFieldFee = 1 ether;

	uint256 epicHardwareFee = 0.1 ether;
	uint256 doubleHardwareFee = 0.2 ether;
	uint256 multiHardwareFee = 0.3 ether;

	uint256 adornedFrameFee = 0.1 ether;
	uint256 menacingFrameFee = 0.25 ether;
	uint256 securedFrameFee = 0.5 ether;
	uint256 floriatedFrameFee = 1 ether;
	uint256 everlastingFrameFee = 2 ether;

	uint256 shieldPassPrice = 0.5 ether;

	uint256 private _currentId = 1;
	uint256 public preLaunchSupply = 120;

	bool public publicMintActive = false;

	// Transient variable that's immediately cleared after checking for duplicate colors
	mapping(uint24 => bool) private _checkDuplicateColors;
	// Store of all shields
	mapping(uint256 => Shield) private _shields;
	// Hashes that let us check for duplicates
	mapping(bytes32 => bool) public shieldHashes;
	// Whitelist for each type of reward
	mapping(address => mapping(WhitelistItems => bool)) public whitelist;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/
	constructor(
		address deployer,
		string memory name_,
		string memory symbol_,
		IEmblemWeaver _emblemWeaver
	) ERC721(name_, symbol_) Owned(deployer) {
		emblemWeaver = _emblemWeaver;
	}

	// ============ OWNER INTERFACE ============

	function collectFees() external onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
		require(success, 'ShieldManager: Transfer failed');
	}

	function collectERC20(IERC20 erc20) external onlyOwner {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	function setPublicMintActive(bool setting) external onlyOwner {
		publicMintActive = setting;

		emit MintingStatus(setting);
	}

	// Owner or relay can set whitelist
	function toggleItemWhitelist(address user, WhitelistItems itemId) external {
		if (!(msg.sender == owner || msg.sender == roundtableRelay)) revert Unauthorised();

		whitelist[user][itemId] = !whitelist[user][itemId];
	}

	function setPreLaunchSupply(uint256 supply) external onlyOwner {
		preLaunchSupply = supply;
	}

	function setShieldPassPrice(uint256 _shieldPassPrice) external onlyOwner {
		shieldPassPrice = _shieldPassPrice;
	}

	// Allows for price adjustments
	function setShieldItemPrices(
		uint256[] calldata fieldPrices,
		uint256[] calldata hardwarePrices,
		uint256[] calldata framePrices
	) external onlyOwner {
		if (fieldPrices.length != 0) {
			epicFieldFee = fieldPrices[0];
			heroicFieldFee = fieldPrices[1];
			olympicFieldFee = fieldPrices[2];
			legendaryFieldFee = fieldPrices[3];
		}

		if (hardwarePrices.length != 0) {
			epicHardwareFee = hardwarePrices[0];
			doubleHardwareFee = hardwarePrices[1];
			multiHardwareFee = hardwarePrices[2];
		}

		if (framePrices.length != 0) {
			adornedFrameFee = framePrices[0];
			menacingFrameFee = framePrices[1];
			securedFrameFee = framePrices[2];
			floriatedFrameFee = framePrices[3];
			everlastingFrameFee = framePrices[4];
		}
	}

	function setRoundtableRelay(address payable relay) external onlyOwner {
		roundtableRelay = relay;
	}

	function setRoundtableFactory(address payable factory) external onlyOwner {
		roundtableFactory = factory;
	}

	function setEmblemWeaver(address payable emblemWeaver_) external onlyOwner {
		emblemWeaver = IEmblemWeaver(emblemWeaver_);
	}

	function setPfpStaker(address payable pfpStaker_) external onlyOwner {
		pfpStaker = IPfpStaker(pfpStaker_);
	}

	function buildAndDropShields(address[] calldata receivers, Shield[] calldata shieldBatch)
		external
	{
		if (msg.sender != roundtableRelay) revert Unauthorised();

		uint256 len = receivers.length;
		uint256 id = _currentId;

		for (uint256 i = 0; i < len; ) {
			buildShield(
				shieldBatch[i].field,
				shieldBatch[i].hardware,
				shieldBatch[i].frame,
				shieldBatch[i].colors,
				id + i
			);

			ownerOf[id + i] = receivers[i];
			emit Transfer(msg.sender, receivers[i], id + i);

			// Receives will never be a large number
			unchecked {
				++i;
			}
		}
		// Receives will never be a large number
		// Updated apart from the above code to save writes to storage
		unchecked {
			_currentId += len;
		}
	}

	// ============ PUBLIC INTERFACE ============

	function mintShieldPass(address to) public payable returns (uint256) {
		// If not minted by factory or relay
		if (!(msg.sender == roundtableFactory || msg.sender == roundtableRelay)) {
			// Check correct price was paid
			if (msg.value != shieldPassPrice) revert IncorrectValue();
			// If pre-launch, ensure currentId is less than preLaunchSupply
			if (!publicMintActive)
				if (!whitelist[to][WhitelistItems.MINT_SHIELD_PASS] && _currentId > preLaunchSupply)
					revert MintingClosed();
		}

		_mint(to, _currentId);

		// Return the id of the token minted, then increment currentId
		unchecked {
			return _currentId++;
		}
	}

	function buildShield(
		uint16 field,
		uint16[9] calldata hardware,
		uint16 frame,
		uint24[4] memory colors,
		uint256 tokenId
	) public payable {
		// Can only be built by owner of tokenId or relay. If staked in pfpStaker, if can be built by the staker.
		if (!(msg.sender == ownerOf[tokenId] || msg.sender == roundtableRelay)) {
			(address NFTContract, uint256 stakedToken) = pfpStaker.getStakedNFT();

			if (!(NFTContract == address(this) && stakedToken == tokenId)) revert Unauthorised();
		}

		validateColors(colors, field);

		// Here we combine the hardware items into a single string
		bytes32 fullHardware;
		{
			string memory combinedHardware;
			string memory currentHardwareItem;

			// Will not over or underflow due to i > 0 check and array length = 9
			unchecked {
				for (uint16 i; i < 9; ) {
					if (i > 0) {
						// If new hardware item differs to previous, generate the padded string
						if (hardware[i] != hardware[i - 1])
							currentHardwareItem = hardware[i].toHexStringNoPrefix(2);
						// Else reuse currentHardwareItem
						combinedHardware = string(abi.encodePacked(combinedHardware, currentHardwareItem));
						// When i=0 set currentHardwareItem to first item
					} else {
						currentHardwareItem = hardware[i].toHexStringNoPrefix(2);
						combinedHardware = currentHardwareItem;
					}
					++i;
				}
			}
			fullHardware = keccak256(bytes(combinedHardware));
		}

		// We then hash the field, hardware and frame to give a unique shield hash
		bytes32 newShieldHash = keccak256(
			abi.encodePacked(field.toHexStringNoPrefix(2), fullHardware, frame.toHexStringNoPrefix(2))
		);

		if (shieldHashes[newShieldHash]) revert DuplicateShield();

		Shield memory oldShield = _shields[tokenId];

		// Set new shield hash to prevent duplicates, and remove old shield to free design
		shieldHashes[oldShield.shieldHash] = false;
		shieldHashes[newShieldHash] = true;

		uint256 fee;
		uint256 tmpOldPrice;
		uint256 tmpNewPrice;

		if (_shields[tokenId].colors[0] == 0) {
			fee += calculateFieldFee(field, colors);
			fee += calculateHardwareFee(hardware);
			fee += calculateFrameFee(frame);
		} else {
			// This prevents Roundtable from editing a shield after it is created
			if (msg.sender == roundtableRelay) revert Unauthorised();

			if (field != oldShield.field) {
				tmpOldPrice = calculateFieldFee(oldShield.field, oldShield.colors);
				tmpNewPrice = calculateFieldFee(field, colors);

				fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
			}

			if (fullHardware != oldShield.hardwareConfiguration) {
				tmpOldPrice = calculateHardwareFee(oldShield.hardware);
				tmpNewPrice = calculateHardwareFee(hardware);

				fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
			}

			if (frame != oldShield.frame) {
				tmpOldPrice = calculateFrameFee(oldShield.frame);
				tmpNewPrice = calculateFrameFee(frame);

				fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
			}
		}

		if (msg.value != fee && msg.sender != roundtableRelay) {
			if (whitelist[msg.sender][WhitelistItems.HALF_PRICE_BUILD]) {
				fee = (fee * 50) / 100;
				whitelist[msg.sender][WhitelistItems.HALF_PRICE_BUILD] = false;
			}
			if (whitelist[msg.sender][WhitelistItems.FREE_BUILD]) {
				fee = 0;
				whitelist[msg.sender][WhitelistItems.FREE_BUILD] = false;
			}
			if (msg.value != fee) revert IncorrectValue();
		}

		_shields[tokenId] = Shield({
			field: field,
			hardware: hardware,
			frame: frame,
			colors: colors,
			shieldHash: newShieldHash,
			hardwareConfiguration: fullHardware
		});

		emit ShieldBuilt(
			msg.sender,
			tokenId,
			oldShield.shieldHash,
			newShieldHash,
			field,
			hardware,
			frame,
			colors
		);
	}

	// ============ PUBLIC VIEW FUNCTIONS ============

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		if (tokenId >= _currentId || tokenId == 0) revert InvalidShield();

		Shield memory shield = _shields[tokenId];

		if (shield.colors[0] != 0) {
			return emblemWeaver.generateShieldURI(shield);
		} else {
			return emblemWeaver.generateShieldPass();
		}
	}

	function totalSupply() public view returns (uint256) {
		unchecked {
			// starts with 1
			return _currentId - 1;
		}
	}

	function shields(uint256 tokenId)
		external
		view
		returns (
			uint16 field,
			uint16[9] memory hardware,
			uint16 frame,
			uint24 color1,
			uint24 color2,
			uint24 color3,
			uint24 color4
		)
	{
		Shield memory shield = _shields[tokenId];
		return (
			shield.field,
			shield.hardware,
			shield.frame,
			shield.colors[0],
			shield.colors[1],
			shield.colors[2],
			shield.colors[3]
		);
	}

	function priceInfo()
		external
		view
		returns (
			uint256 epicFieldFee_,
			uint256 heroicFieldFee_,
			uint256 olympicFieldFee_,
			uint256 legendaryFieldFee_,
			uint256 epicHardwareFee_,
			uint256 doubleHardwareFee_,
			uint256 multiHardwareFee_,
			uint256 adornedFrameFee_,
			uint256 menacingFrameFee_,
			uint256 securedFrameFee_,
			uint256 floriatedFrameFee_,
			uint256 everlastingFrameFee_
		)
	{
		return (
			epicFieldFee,
			heroicFieldFee,
			olympicFieldFee,
			legendaryFieldFee,
			epicHardwareFee,
			doubleHardwareFee,
			multiHardwareFee,
			adornedFrameFee,
			menacingFrameFee,
			securedFrameFee,
			floriatedFrameFee,
			everlastingFrameFee
		);
	}

	// ============ INTERNAL INTERFACE ============

	function calculateFieldFee(uint16 field, uint24[4] memory colors) internal returns (uint256 fee) {
		ICategories.FieldCategories fieldType = emblemWeaver
			.fieldGenerator()
			.generateField(field, colors)
			.fieldType;

		if (fieldType == ICategories.FieldCategories.EPIC) return epicFieldFee;

		if (fieldType == ICategories.FieldCategories.HEROIC) return heroicFieldFee;

		if (fieldType == ICategories.FieldCategories.OLYMPIC) return olympicFieldFee;

		if (fieldType == ICategories.FieldCategories.LEGENDARY) return legendaryFieldFee;
	}

	function calculateHardwareFee(uint16[9] memory hardware) internal returns (uint256 fee) {
		ICategories.HardwareCategories hardwareType = emblemWeaver
			.hardwareGenerator()
			.generateHardware(hardware)
			.hardwareType;

		if (hardwareType == ICategories.HardwareCategories.EPIC) return epicHardwareFee;

		if (hardwareType == ICategories.HardwareCategories.DOUBLE) return doubleHardwareFee;

		if (hardwareType == ICategories.HardwareCategories.MULTI) return multiHardwareFee;
	}

	function calculateFrameFee(uint16 frame) internal returns (uint256 fee) {
		ICategories.FrameCategories frameType = emblemWeaver
			.frameGenerator()
			.generateFrame(frame)
			.frameType;

		if (frameType == ICategories.FrameCategories.NONE) return 0;

		if (frameType == ICategories.FrameCategories.ADORNED) return adornedFrameFee;

		if (frameType == ICategories.FrameCategories.MENACING) return menacingFrameFee;

		if (frameType == ICategories.FrameCategories.SECURED) return securedFrameFee;

		if (frameType == ICategories.FrameCategories.FLORIATED) return floriatedFrameFee;

		if (frameType == ICategories.FrameCategories.EVERLASTING) return everlastingFrameFee;
	}

	function validateColors(uint24[4] memory colors, uint16 field) internal {
		if (field == 0) {
			checkExistsDupsMax(colors, 1);
		} else if (field <= 242) {
			checkExistsDupsMax(colors, 2);
		} else if (field <= 293) {
			checkExistsDupsMax(colors, 3);
		} else {
			checkExistsDupsMax(colors, 4);
		}
	}

	function checkExistsDupsMax(uint24[4] memory colors, uint8 nColors) private {
		for (uint8 i = 0; i < nColors; i++) {
			if (_checkDuplicateColors[colors[i]] == true) revert ColorError();
			if (!emblemWeaver.fieldGenerator().colorExists(colors[i])) revert ColorError();
			_checkDuplicateColors[colors[i]] = true;
		}
		for (uint8 i = 0; i < nColors; i++) {
			_checkDuplicateColors[colors[i]] = false;
		}
		for (uint8 i = nColors; i < 4; i++) {
			if (colors[i] != 0) revert ColorError();
		}
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

/// @dev Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface ICategories {
	enum FieldCategories {
		BASIC,
		EPIC,
		HEROIC,
		OLYMPIC,
		LEGENDARY
	}

	enum HardwareCategories {
		BASIC,
		EPIC,
		DOUBLE,
		MULTI
	}

	enum FrameCategories {
		NONE,
		ADORNED,
		MENACING,
		SECURED,
		FLORIATED,
		EVERLASTING
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IShieldManager.sol';
import './IFrameGenerator.sol';
import './IFieldGenerator.sol';
import './IHardwareGenerator.sol';

/// @dev Generate Customizable Shields
interface IEmblemWeaver {
	function fieldGenerator() external returns (IFieldGenerator);

	function hardwareGenerator() external returns (IHardwareGenerator);

	function frameGenerator() external returns (IFrameGenerator);

	function generateShieldPass() external pure returns (string memory);

	function generateShieldURI(IShieldManager.Shield memory shield)
		external
		view
		returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @dev Build Customizable Shields for an NFT
interface IShieldManager {
	enum WhitelistItems {
		MINT_SHIELD_PASS,
		HALF_PRICE_BUILD,
		FREE_BUILD
	}

	struct Shield {
		uint16 field;
		uint16[9] hardware;
		uint16 frame;
		uint24[4] colors;
		bytes32 shieldHash;
		bytes32 hardwareConfiguration;
	}

	function mintShieldPass(address to) external payable returns (uint256);

	function buildShield(
		uint16 field,
		uint16[9] memory hardware,
		uint16 frame,
		uint24[4] memory colors,
		uint256 tokenId
	) external payable;

	function shields(uint256 tokenId)
		external
		view
		returns (
			uint16 field,
			uint16[9] memory hardware,
			uint16 frame,
			uint24 color1,
			uint24 color2,
			uint24 color3,
			uint24 color4
			// ShieldBadge shieldBadge
		);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp - defaults to shield
interface IPfpStaker {
	struct StakedPFP {
		address NFTcontract;
		uint256 tokenId;
	}

	function stakeInitialShield(address, uint256) external;

	function stakeNFT(
		address,
		address,
		uint256
	) external;

	function getURI() external view returns (string memory nftURI);

	function getStakedNFT() external view returns (address NFTContract, uint256 tokenId);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// License-Identifier: AGPL-3.0-only
interface ERC721TokenReceiver {
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation.
abstract contract ERC721 {
	/*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

	error NotApproved();

	error NotTokenOwner();

	error InvalidRecipient();

	error SignatureExpired();

	error InvalidSignature();

	error AlreadyMinted();

	error NotMinted();

	/*///////////////////////////////////////////////////////////////
                            METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

	string public name;

	string public symbol;

	function tokenURI(uint256 tokenId) public view virtual returns (string memory);

	/*///////////////////////////////////////////////////////////////
                            ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(address => uint256) public balanceOf;

	mapping(uint256 => address) public ownerOf;

	mapping(uint256 => address) public getApproved;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/

	bytes32 public constant PERMIT_TYPEHASH =
		keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');

	bytes32 public constant PERMIT_ALL_TYPEHASH =
		keccak256('Permit(address owner,address spender,uint256 nonce,uint256 deadline)');

	uint256 internal immutable INITIAL_CHAIN_ID;

	bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

	mapping(uint256 => uint256) public nonces;

	mapping(address => uint256) public noncesForAll;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(string memory name_, string memory symbol_) {
		name = name_;

		symbol = symbol_;

		INITIAL_CHAIN_ID = block.chainid;

		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
	}

	/*///////////////////////////////////////////////////////////////
                            ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

	function approve(address spender, uint256 tokenId) public virtual {
		address owner = ownerOf[tokenId];

		if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert NotApproved();

		getApproved[tokenId] = spender;

		emit Approval(owner, spender, tokenId);
	}

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function transfer(address to, uint256 tokenId) public virtual returns (bool) {
		if (msg.sender != ownerOf[tokenId]) revert NotTokenOwner();

		if (to == address(0)) revert InvalidRecipient();

		// underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow
		unchecked {
			balanceOf[msg.sender]--;

			balanceOf[to]++;
		}

		delete getApproved[tokenId];

		ownerOf[tokenId] = to;

		emit Transfer(msg.sender, to, tokenId);

		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual {
		if (from != ownerOf[tokenId]) revert NotTokenOwner();

		if (to == address(0)) revert InvalidRecipient();

		if (
			msg.sender != from &&
			msg.sender != getApproved[tokenId] &&
			!isApprovedForAll[from][msg.sender]
		) revert NotApproved();

		// underflow of the sender's balance is impossible because we check for
		// ownership above and the recipient's balance can't realistically overflow
		unchecked {
			balanceOf[from]--;

			balanceOf[to]++;
		}

		delete getApproved[tokenId];

		ownerOf[tokenId] = to;

		emit Transfer(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual {
		transferFrom(from, to, tokenId);

		if (
			to.code.length != 0 &&
			ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, '') !=
			ERC721TokenReceiver.onERC721Received.selector
		) revert InvalidRecipient();
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public virtual {
		transferFrom(from, to, tokenId);

		if (
			to.code.length != 0 &&
			ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) !=
			ERC721TokenReceiver.onERC721Received.selector
		) revert InvalidRecipient();
	}

	/*///////////////////////////////////////////////////////////////
                            ERC-165 LOGIC
    //////////////////////////////////////////////////////////////*/

	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x80ac58cd || // ERC-165 Interface ID for ERC-721
			interfaceId == 0x5b5e139f || // ERC-165 Interface ID for ERC-165
			interfaceId == 0x01ffc9a7; // ERC-165 Interface ID for ERC-721 Metadata
	}

	/*///////////////////////////////////////////////////////////////
                            EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		address owner = ownerOf[tokenId];

		// cannot realistically overflow on human timescales
		unchecked {
			bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					DOMAIN_SEPARATOR(),
					keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[tokenId]++, deadline))
				)
			);

			address recoveredAddress = ecrecover(digest, v, r, s);

			if (recoveredAddress == address(0)) revert InvalidSignature();

			if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress])
				revert InvalidSignature();
		}

		getApproved[tokenId] = spender;

		emit Approval(owner, spender, tokenId);
	}

	function permitAll(
		address owner,
		address operator,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		// cannot realistically overflow on human timescales
		unchecked {
			bytes32 digest = keccak256(
				abi.encodePacked(
					'\x19\x01',
					DOMAIN_SEPARATOR(),
					keccak256(
						abi.encode(PERMIT_ALL_TYPEHASH, owner, operator, noncesForAll[owner]++, deadline)
					)
				)
			);

			address recoveredAddress = ecrecover(digest, v, r, s);

			if (recoveredAddress == address(0)) revert InvalidSignature();

			if (recoveredAddress != owner && !isApprovedForAll[owner][recoveredAddress])
				revert InvalidSignature();
		}

		isApprovedForAll[owner][operator] = true;

		emit ApprovalForAll(owner, operator, true);
	}

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
	}

	function _computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256(
						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
					),
					keccak256(bytes(name)),
					keccak256(bytes('1')),
					block.chainid,
					address(this)
				)
			);
	}

	/*///////////////////////////////////////////////////////////////
                            MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

	function _mint(address to, uint256 tokenId) internal virtual {
		if (to == address(0)) revert InvalidRecipient();

		if (ownerOf[tokenId] != address(0)) revert AlreadyMinted();

		// cannot realistically overflow on human timescales
		unchecked {
			balanceOf[to]++;
		}

		ownerOf[tokenId] = to;

		emit Transfer(address(0), to, tokenId);
	}

	function _burn(uint256 tokenId) internal virtual {
		address owner = ownerOf[tokenId];

		if (ownerOf[tokenId] == address(0)) revert NotMinted();

		// ownership check ensures no underflow
		unchecked {
			balanceOf[owner]--;
		}

		delete ownerOf[tokenId];

		delete getApproved[tokenId];

		emit Transfer(owner, address(0), tokenId);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event OwnerUpdated(address indexed user, address indexed newOwner);

	/*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

	address public owner;

	modifier onlyOwner() virtual {
		require(msg.sender == owner, 'UNAUTHORIZED');

		_;
	}

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(address _owner) {
		owner = _owner;

		emit OwnerUpdated(address(0), _owner);
	}

	/*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

	function setOwner(address newOwner) public virtual onlyOwner {
		owner = newOwner;

		emit OwnerUpdated(msg.sender, newOwner);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

library HexStrings {
	bytes16 internal constant ALPHABET = '0123456789abcdef';

	function toHexStringNoPrefix(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes memory buffer = new bytes(2 * length);
		for (uint256 i = buffer.length; i > 0; i--) {
			buffer[i - 1] = ALPHABET[value & 0xf];
			value >>= 4;
		}
		return string(buffer);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
	struct FrameSVGs {
		IFrameSVGs frameSVGs1;
		IFrameSVGs frameSVGs2;
	}

	/// @param Frame uint representing Frame selection
	/// @return FrameData containing svg snippet and Frame title and Frame type
	function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IFieldSVGs.sol';

/// @dev Generate Field SVG
interface IFieldGenerator {
	/// @param field uint representing field selection
	/// @param colors to be rendered in the field svg
	/// @return FieldData containing svg snippet and field title
	function generateField(uint16 field, uint24[4] memory colors)
		external
		view
		returns (IFieldSVGs.FieldData memory);

	event ColorsAdded(uint24 firstColor, uint24 lastColor, uint256 count);

	struct Color {
		string title;
		bool exists;
	}

	function addColors(uint24[] calldata colors, string[] calldata titles) external;

	/// @notice Returns true if color exists in contract, else false.
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorExists(uint24 color) external view returns (bool);

	/// @notice Returns the title string corresponding to the 3-byte color
	/// @param color 3-byte uint representing color
	/// @return true or false
	function colorTitle(uint24 color) external view returns (string memory);

	struct FieldSVGs {
		IFieldSVGs fieldSVGs1;
		IFieldSVGs fieldSVGs2;
		IFieldSVGs fieldSVGs3;
		IFieldSVGs fieldSVGs4;
		IFieldSVGs fieldSVGs5;
		IFieldSVGs fieldSVGs6;
		IFieldSVGs fieldSVGs7;
		IFieldSVGs fieldSVGs8;
		IFieldSVGs fieldSVGs9;
		IFieldSVGs fieldSVGs10;
		IFieldSVGs fieldSVGs11;
		IFieldSVGs fieldSVGs12;
		IFieldSVGs fieldSVGs13;
		IFieldSVGs fieldSVGs14;
		IFieldSVGs fieldSVGs15;
		IFieldSVGs fieldSVGs16;
		IFieldSVGs fieldSVGs17;
		IFieldSVGs fieldSVGs18;
		IFieldSVGs fieldSVGs19;
		IFieldSVGs fieldSVGs20;
		IFieldSVGs fieldSVGs21;
		IFieldSVGs fieldSVGs22;
		IFieldSVGs fieldSVGs23;
		IFieldSVGs fieldSVGs24;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IHardwareSVGs.sol';

/// @dev Generate Hardware SVG
interface IHardwareGenerator {
	/// @param hardware uint representing hardware selection
	/// @return HardwareData containing svg snippet and hardware title and hardware type
	function generateHardware(uint16[9] calldata hardware)
		external
		view
		returns (IHardwareSVGs.HardwareData memory);

	struct HardwareSVGs {
		IHardwareSVGs hardwareSVGs1;
		IHardwareSVGs hardwareSVGs2;
		IHardwareSVGs hardwareSVGs3;
		IHardwareSVGs hardwareSVGs4;
		IHardwareSVGs hardwareSVGs5;
		IHardwareSVGs hardwareSVGs6;
		IHardwareSVGs hardwareSVGs7;
		IHardwareSVGs hardwareSVGs8;
		IHardwareSVGs hardwareSVGs9;
		IHardwareSVGs hardwareSVGs10;
		IHardwareSVGs hardwareSVGs11;
		IHardwareSVGs hardwareSVGs12;
		IHardwareSVGs hardwareSVGs13;
		IHardwareSVGs hardwareSVGs14;
		IHardwareSVGs hardwareSVGs15;
		IHardwareSVGs hardwareSVGs16;
		IHardwareSVGs hardwareSVGs17;
		IHardwareSVGs hardwareSVGs18;
		IHardwareSVGs hardwareSVGs19;
		IHardwareSVGs hardwareSVGs20;
		IHardwareSVGs hardwareSVGs21;
		IHardwareSVGs hardwareSVGs22;
		IHardwareSVGs hardwareSVGs23;
		IHardwareSVGs hardwareSVGs24;
		IHardwareSVGs hardwareSVGs25;
		IHardwareSVGs hardwareSVGs26;
		IHardwareSVGs hardwareSVGs27;
		IHardwareSVGs hardwareSVGs28;
		IHardwareSVGs hardwareSVGs29;
		IHardwareSVGs hardwareSVGs30;
		IHardwareSVGs hardwareSVGs31;
		IHardwareSVGs hardwareSVGs32;
		IHardwareSVGs hardwareSVGs33;
		IHardwareSVGs hardwareSVGs34;
		IHardwareSVGs hardwareSVGs35;
		IHardwareSVGs hardwareSVGs36;
		IHardwareSVGs hardwareSVGs37;
		IHardwareSVGs hardwareSVGs38;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFrameSVGs {
	struct FrameData {
		string title;
		ICategories.FrameCategories frameType;
		string svgString;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFieldSVGs {
	struct FieldData {
		string title;
		ICategories.FieldCategories fieldType;
		string svgString;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IHardwareSVGs {
	struct HardwareData {
		string title;
		ICategories.HardwareCategories hardwareType;
		string svgString;
	}
}