// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./INodeType.sol";
import "./INode.sol";
import "./ILuckyBox.sol";
import "./ISwapper.sol";
import "./Owners.sol";


contract Handler is Owners {
	event NewNode(
		address indexed owner,
		string indexed name,
		uint count
	);

	struct NodeType {
		string[] keys; // nodeTypeName to address
		mapping(string => address) values;
		mapping(string => uint256) indexOf;
		mapping(string => bool) inserted;
	}

	struct Token {
		uint[] keys; // token ids to nodeTypeName
		mapping(uint => string) values;
		mapping(uint => uint) indexOf;
		mapping(uint => bool) inserted;
	}

	NodeType private mapNt;
	Token private mapToken;

	address public nft;
	
	ILuckyBox private lucky;
	ISwapper private swapper;

	modifier onlyNft() {
		require(msg.sender == nft, "Handler: Only Nft");
		_;
	}

	// external
	function addMultipleNodeTypes(address[] calldata _addrs) external onlySuperOwner {
		for (uint i = 0; i < _addrs.length; i++) {
			string memory name = INodeType(_addrs[i]).name();
			mapNtSet(name, _addrs[i]);
		}
	}

	function updateNodeTypeAddress(string calldata name, address _addr) external onlySuperOwner {
		require(mapNt.inserted[name], "Handler: NodeType doesnt exist");
		mapNt.values[name] = _addr;
	}

	function transferFrom(address from, address to, uint tokenId) external onlyNft {
		require(from != to, "Handler: Already owner");
		INodeType(mapNt.values[mapToken.values[tokenId]])
			.transferFrom(from, to, tokenId);
	}
	
	function createNodesWithTokens(
		address tokenIn,
		address user,
		string calldata name,
		uint count,
		string calldata sponso
	) 
		external 
	{
		uint[] memory tokenIds = _setUpNodes(name, user, count);

		uint price = INodeType(mapNt.values[name])
			.createNodesWithTokens(user, tokenIds);
		
		swapper.swapCreate(tokenIn, msg.sender, price, sponso);
	
		emit NewNode(user, name, count);
	}

	function createNodesLevelUp(
		address tokenOut,
		string[] calldata nameFrom,
		uint[][] calldata tokenIdsToBurn,
		string calldata nameTo,
		uint count
	)
		external
	{
		require(nameFrom.length == tokenIdsToBurn.length, "Handler: Length mismatch");

		uint[] memory tokenIds = _setUpNodes(nameTo, msg.sender, count);
		
		claimRewardsBatch(tokenOut, msg.sender, nameFrom, tokenIdsToBurn);

		uint price = INodeType(mapNt.values[nameTo])
			.createNodesLevelUp(msg.sender, tokenIds);

		for (uint i = 0; i < nameFrom.length && price > 0; i++) {
			require(mapNt.inserted[nameFrom[i]], "Handler: NodeType doesnt exist");
			
			INode(nft).burnBatch(msg.sender, tokenIdsToBurn[i]);

			for (uint j = 0; j < tokenIdsToBurn[i].length; j++) {
				require(mapToken.inserted[tokenIdsToBurn[i][j]], "Handler: TokenId doesnt exist");
				mapTokenRemove(tokenIdsToBurn[i][j]);
			}

			address nt = mapNt.values[nameFrom[i]];

			uint burnedPrice = INodeType(nt).burnFrom(msg.sender, tokenIdsToBurn[i]);

			price = price > burnedPrice ? price - burnedPrice : 0;
		}

		require(price == 0, "Handler: Nice try buddy");
		
		emit NewNode(msg.sender, nameTo, count);
	}

	function createNodesWithPending(
		address tokenOut,
		string[] calldata nameFrom,
		uint[][] calldata tokenIdsToClaim,
		string calldata nameTo,
		uint count
	)
		external
	{
		require(nameFrom.length == tokenIdsToClaim.length, "Handler: Length mismatch");
		
		uint[] memory tokenIds = _setUpNodes(nameTo, msg.sender, count);
		
		uint rewardsTotal;
		uint feesTotal;
		
		uint price = INodeType(mapNt.values[nameTo])
			.createNodesWithPendings(msg.sender, tokenIds);

		for (uint i = 0; i < nameFrom.length; i++) {
			require(mapNt.inserted[nameFrom[i]], "Handler: NodeType doesnt exist");
			
			(uint rewards, uint fees) = INodeType(mapNt.values[nameFrom[i]])
				.claimRewardsBatch(msg.sender, tokenIdsToClaim[i]);

			rewardsTotal += rewards;
			feesTotal += fees;
		}

		require(price <= rewardsTotal, "Handler: Not enough pending");

		swapper.swapClaim(
			tokenOut, msg.sender, rewardsTotal - price, feesTotal);
		
		emit NewNode(msg.sender, nameTo, count);
	}

	function createNodesWithLuckyBoxes(uint[] calldata tokenIdsLuckyBoxes) external {
		string[] memory nodeTypes;
		string[] memory features;
		
		(nodeTypes, features) = lucky
			.createNodesWithLuckyBoxes(msg.sender, tokenIdsLuckyBoxes);

		for (uint i = 0; i < nodeTypes.length; i++) {
			uint[] memory tokenIds = _setUpNodes(nodeTypes[i], msg.sender, 1);

			INodeType(mapNt.values[nodeTypes[i]])
				.createNodeWithLuckyBox(
					msg.sender,
					tokenIds, 
					features[i]
				);
		
			emit NewNode(msg.sender, nodeTypes[i], 1);
		}
	}
	
	function createNodesAirDrop(
		string calldata name,
		address user,
		uint isBoostedAirDropRate,
		string calldata feature, 
		uint count
	) 
		external 
		onlyOwners 
	{
		require(count > 0, "Handler: Count must be greater than 0");
		
		uint[] memory tokenIds = _setUpNodes(name, user, count);

		INodeType(mapNt.values[name])
			.createNodeCustom(
				user,
				isBoostedAirDropRate,
				tokenIds, 
				feature
			);

		emit NewNode(user, name, count);
	}

	function createLuckyBoxesWithTokens(
		address tokenIn,
		address user,
		string calldata name,
		uint count,
		string calldata sponso
	) 
		external 
	{
		uint price = lucky
			.createLuckyBoxesWithTokens(name, count, user);
		
		swapper.swapCreate(tokenIn, msg.sender, price, sponso);
	}

	function createLuckyBoxesAirDrop(
		string calldata name,
		address user,
		uint count
	) 
		external 
		onlyOwners 
	{
		lucky.createLuckyBoxesAirDrop(name, count, user);
	}

	function nodeEvolution(
		string calldata name,
		address user,
		uint[] calldata tokenIds,
		uint isBoostedAirDropRate,
		string calldata feature
	) 
		external 
		onlyOwners 
	{
		require(tokenIds.length == 1, "Handler: Evolve one by one");
		require(mapNt.inserted[name], "Handler: NodeType doesnt exist");
		require(mapToken.inserted[tokenIds[0]], "Handler: Token doesnt exist");

		INodeType(mapNt.values[mapToken.values[tokenIds[0]]])
			.burnFrom(user, tokenIds);
		
		mapTokenSet(tokenIds[0], name);
		
		INodeType(mapNt.values[name])
			.createNodeCustom(
				user, 
				isBoostedAirDropRate, 
				tokenIds,
				feature
			);

		INode(nft).setTokenIdToType(tokenIds[0], name);
	}

	function claimRewardsAll(address tokenOut, address user) external {
		require(user == msg.sender || isOwner[msg.sender], "Handler: Dont mess with other claims");
		
		uint rewardsTotal;
		uint feesTotal;

		for (uint i = 0; i < mapNt.keys.length; i++) {
			(uint rewards, uint fees) = INodeType(mapNt.values[mapNt.keys[i]])
				.claimRewardsAll(user);
			rewardsTotal += rewards;
			feesTotal += fees;
		}

		swapper.swapClaim(tokenOut, user, rewardsTotal, feesTotal);
	}

	function claimRewardsBatch(
		address tokenOut,
		address user,
		string[] calldata names,
		uint[][] calldata tokenIds
	)
		public
	{
		require(user == msg.sender || isOwner[msg.sender], "Handler: Dont mess with other claims");

		uint rewardsTotal;
		uint feesTotal;

		require(names.length == tokenIds.length, "Handler: Length mismatch");

		for (uint i = 0; i < names.length; i++) {
			require(mapNt.inserted[names[i]], "Handler: NodeType doesnt exist");
			
			(uint rewards, uint fees) = INodeType(mapNt.values[names[i]])
				.claimRewardsBatch(user, tokenIds[i]);
			rewardsTotal += rewards;
			feesTotal += fees;
		}
		
		swapper.swapClaim(tokenOut, user, rewardsTotal, feesTotal);
	}
	
	// external setters
	// handler setters
	function setNft(address _new) external onlySuperOwner {
		require(_new != address(0), "Handler: Nft cannot be address zero");
		nft = _new;
	}
	
	function setLucky(address _new) external onlySuperOwner {
		require(_new != address(0), "Handler: Loot cannot be address zero");
		lucky = ILuckyBox(_new);
	}
	
	function setSwapper(address _new) external onlySuperOwner {
		require(_new != address(0), "Handler: Swapper cannot be address zero");
		swapper = ISwapper(_new);
	}
	
	// external view
	function getNodeTypesSize() external view returns(uint) {
		return mapNt.keys.length;
	}

	function getTotalCreatedNodes() external view returns(uint) {
		uint totalNodes;
		for (uint i = 0; i < mapNt.keys.length; i++) {
			totalNodes += INodeType(mapNt.values[mapNt.keys[i]])
				.totalCreatedNodes();
		}
		return totalNodes;
	}
	
	function getNodeTypesBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(string[] memory) 
	{
		string[] memory nodeTypes = new string[](iEnd - iStart);
		for (uint i = iStart; i < iEnd; i++)
			nodeTypes[i - iStart] = mapNt.keys[i];
		return nodeTypes;
	}
	
	function getNodeTypesAddress(string calldata key) external view returns(address) {
		require(mapNt.inserted[key], "NodeType doesnt exist");
		return mapNt.values[key];
	}

	function getAttribute(uint tokenId) external view returns(string memory) {
		return INodeType(mapNt.values[mapToken.values[tokenId]])
			.getAttribute(tokenId);
	}
	
	function getTokenIdsSize() external view returns(uint) {
		return mapToken.keys.length;
	}
	
	function getTokenIdsBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(uint[] memory) 
	{
		uint[] memory ids = new uint[](iEnd - iStart);
		for (uint i = iStart; i < iEnd; i++)
			ids[i - iStart] = mapToken.keys[i];
		return ids;
	}
	
	function getTokenIdsNodeTypeBetweenIndexes(
		uint iStart, 
		uint iEnd
	) 
		external 
		view 
		returns(string[] memory) 
	{
		string[] memory names = new string[](iEnd - iStart);
		for (uint i = iStart; i < iEnd; i++)
			names[i - iStart] = mapToken.values[mapToken.keys[i]];
		return names;
	}
	
	function getTokenIdNodeTypeName(uint key) external view returns(string memory) {
		require(mapToken.inserted[key], "TokenId doesnt exist");
		return mapToken.values[key];
	}

	function getTotalNodesOf(address user) external view returns(uint) {
		uint totalNodes;
		for (uint i = 0; i < mapNt.keys.length; i++) {
			totalNodes += INodeType(mapNt.values[mapNt.keys[i]])
				.getTotalNodesNumberOf(user);
		}
		return totalNodes;
	}
	
	function getClaimableRewardsOf(address user) external view returns(uint, uint) {
		uint rewardsTotal;
		uint feesTotal;
		for (uint i = 0; i < mapNt.keys.length; i++) {
			(uint rewards, uint fees) = INodeType(mapNt.values[mapNt.keys[i]])
				.calculateUserRewards(user);
				rewardsTotal += rewards;
				feesTotal += fees;
		}
		return (rewardsTotal, feesTotal);
	}

	// internal
	function _setUpNodes(
		string memory name,
		address user,
		uint count
	)
		private
		returns(
			uint[] memory
		)
	{
		require(mapNt.inserted[name], "Handler: NodeType doesnt exist");

		uint[] memory tokenIds = INode(nft).generateNfts(name, user, count);

		for (uint i = 0; i < tokenIds.length; i++)
			mapTokenSet(tokenIds[i], name);

		return tokenIds;
	}

	 function strcmp(string memory s1, string memory s2) internal pure returns(bool) {
		 return (keccak256(abi.encodePacked((s1))) == keccak256(abi.encodePacked((s2))));
	 }

	// private
	// maps
	function mapNtSet(
        string memory key,
        address value
    ) private {
        if (mapNt.inserted[key]) {
            mapNt.values[key] = value;
        } else {
            mapNt.inserted[key] = true;
            mapNt.values[key] = value;
            mapNt.indexOf[key] = mapNt.keys.length;
            mapNt.keys.push(key);
        }
    }
	
	function mapTokenSet(
        uint key,
        string memory value
    ) private {
        if (mapToken.inserted[key]) {
            mapToken.values[key] = value;
        } else {
            mapToken.inserted[key] = true;
            mapToken.values[key] = value;
            mapToken.indexOf[key] = mapToken.keys.length;
            mapToken.keys.push(key);
        }
    }

	function mapNtRemove(string memory key) private {
        if (!mapNt.inserted[key]) {
            return;
        }

        delete mapNt.inserted[key];
        delete mapNt.values[key];

        uint256 index = mapNt.indexOf[key];
        uint256 lastIndex = mapNt.keys.length - 1;
        string memory lastKey = mapNt.keys[lastIndex];

        mapNt.indexOf[lastKey] = index;
        delete mapNt.indexOf[key];

		if (lastIndex != index)
			mapNt.keys[index] = lastKey;
        mapNt.keys.pop();
    }

	function mapTokenRemove(uint key) private {
        if (!mapToken.inserted[key]) {
            return;
        }

        delete mapToken.inserted[key];
        delete mapToken.values[key];

        uint256 index = mapToken.indexOf[key];
        uint256 lastIndex = mapToken.keys.length - 1;
        uint lastKey = mapToken.keys[lastIndex];

        mapToken.indexOf[lastKey] = index;
        delete mapToken.indexOf[key];

		if (lastIndex != index)
			mapToken.keys[index] = lastKey;
        mapToken.keys.pop();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface INodeType {

	function transferFrom(address from, address to, uint tokenId) external;
	function burnFrom(address from, uint[] calldata tokenIds) external returns(uint);

	function createNodesWithTokens(
		address user,
		uint[] calldata tokenIds
	) external returns(uint);

	function createNodesLevelUp(
		address user,
		uint[] calldata tokenIds
	) external returns(uint);

	function createNodesWithPendings(
		address user,
		uint[] calldata tokenIds
	) external returns(uint);
	
	function createNodeWithLuckyBox(
		address user,
		uint[] calldata tokenIds,
		string calldata feature
	) external;

	function createNodeCustom(
		address user,
		uint isBoostedAirDropRate,
		uint[] calldata tokenIds,
		string calldata feature
	) external;

	function getTotalNodesNumberOf(address user) external view returns(uint);
	function getAttribute(uint tokenId) external view returns(string memory);

	function claimRewardsAll(address user) external returns(uint, uint);
	function claimRewardsBatch(address user, uint[] calldata tokenIds) external returns(uint, uint);
	function calculateUserRewards(address user) external view returns(uint, uint);

	function name() external view returns(string memory);
	function totalCreatedNodes() external view returns(uint);
	function price() external view returns(uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface INode {
	function generateNfts(
		string calldata name,
		address user,
		uint count
	)
		external
		returns(uint[] memory);
	
	function burnBatch(address user, uint[] calldata tokenIds) external;

	function setTokenIdToType(uint tokenId, string calldata nodeType) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface ILuckyBox {
	function createLuckyBoxesWithTokens(
		string calldata name,
		uint count,
		address user
	) external returns(uint);
	
	function createLuckyBoxesAirDrop(
		string calldata name,
		uint count,
		address user
	) external;
	
	function createNodesWithLuckyBoxes(
		address user,
		uint[] calldata tokenIds
	)
		external
		returns(
			string[] memory,
			string[] memory
		);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface ISwapper {
	function swapCreate(
		address tokenIn, 
		address user, 
		uint price,
		string calldata sponso
	) external;
	
	function swapClaim(
		address tokenOut, 
		address user, 
		uint rewardsTotal, 
		uint feesTotal
	) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;


contract Owners {
	address[] public owners;
	mapping(address => bool) public isOwner;
	mapping(address => mapping(bytes4 => uint)) private last;
	uint private resetTime = 12 * 3600;

	constructor() {
		owners.push(msg.sender);
		isOwner[msg.sender] = true;
	}

	modifier onlySuperOwner() {
		require(owners[0] == msg.sender, "Owners: Only Super Owner");
		_;
	}
	
	modifier onlyOwners() {
		require(isOwner[msg.sender], "Owners: Only Owner");
		if (owners[0] != msg.sender) {
			require(
				last[msg.sender][msg.sig] + resetTime < block.timestamp,
				"Owners: Not yet"
			);
			last[msg.sender][msg.sig] = block.timestamp;
		}
		_;
	}

	function addOwner(address _new, bool _change) external onlySuperOwner {
		require(!isOwner[_new], "Owners: Already owner");

		isOwner[_new] = true;

		if (_change) {
			owners.push(owners[0]);
			owners[0] = _new;
		} else {
			owners.push(_new);
		}
	}

	function removeOwner(address _new) external onlySuperOwner {
		require(isOwner[_new], "Owner: Not owner");
		require(_new != owners[0]);

		uint length = owners.length;

		for (uint i = 1; i < length; i++) {
			if (owners[i] == _new) {
				owners[i] = owners[length - 1];
				owners.pop();
				break;
			}
		}

		isOwner[_new] = false;
	}

	function getOwnersSize() external view returns(uint) {
		return owners.length;
	}

	function setResetTime(uint _new) external onlySuperOwner {
		resetTime = _new;
	}
}