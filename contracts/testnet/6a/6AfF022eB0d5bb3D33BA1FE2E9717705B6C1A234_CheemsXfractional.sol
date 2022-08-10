/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-09
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-14
*/

// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

contract CheemsXfractional is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;

    Counters.Counter public _tokenIds;
    Counters.Counter[10] private _tokenIdsByTier;
    address public WAVAX = 0x9b6AFC6f69C556e2CBf79fbAc1cb19B75E6B51E2;  // for test
    // address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    uint[11] public max_Regular_tier;
    uint public maxTier0 = 50_000_000_000;
    uint[11] public price;
    uint[11] public maxWalletLimit;
    string[11] public defaultURI;
    address public currencyToken = WAVAX; // default WAVAX
    address treasureWallet = 0x0Ae7d6d08Af59B715157139257cD3fB1210506F0;
    address public XYZToken = 0xb0b598FCd066058a83FEa073d56522b5BaE0522B;
    uint public priceDivisor = 10000000000;
    bool public upgradable = false;
    uint public swapFee = 100;
    uint public flatFee = 10 ** 17;

    uint8 REGULAR_TIER = 0;
    uint8 WALLETLIMIT = 1;
    uint8 PRICE = 2;

    uint public maxTier0PerWallet = 25000000000;

    mapping(uint=>uint) public tBalance;

    uint8 public mintOption = 0;

    mapping(address => bool) public whiteList;
    struct UserInfo {
        mapping(uint => uint[]) amount;
        uint tier0; 
    }
    mapping(address => UserInfo) public userInfo;
    mapping(uint => uint) public tierInfo;
    mapping(address => bool) public exemptMaxAmountUser;

    event UodateURI(address indexed user, bool success);
    event UpgradeNFTByAvax(address indexed user, uint amount, uint cal);

    struct MintInfo {
        address user;
        address mintCurrency;
        // bool isValid;
    }
    mapping (uint=>MintInfo) public royaltyList;
    uint8 public royaltyOption;
    mapping(address=>bool) public swapFeeExempt;
    uint public roayltyFee = 2;
    bool public ableUpdateURI;
    
    struct BorrowInfo {
        address user;
        uint borrowTime;
        uint nftId;
    }

    mapping (uint=>BorrowInfo) public borrowList;
    uint[] public borrowNFTList;
    uint public borrowFee = 60;
    uint public redeemFee = 10;
    uint public graceFee = 10;
    uint public discountFee = 10;
    uint public holdPeriod = 10 seconds ;
    uint public gracePeriod = 2 seconds;
    bool public isBorrowable;

    constructor() ERC721("CheemsXfractional NFT", "CXN") {
        max_Regular_tier[0] = 500;
        max_Regular_tier[1] = 500;
        max_Regular_tier[2] = 450;
        max_Regular_tier[3] = 222;
        max_Regular_tier[4] = 180;
        max_Regular_tier[5] = 95;
        max_Regular_tier[6] = 85;
        max_Regular_tier[7] = 75;
        max_Regular_tier[8] = 65;
        max_Regular_tier[9] = 50;
        max_Regular_tier[10] = maxTier0;

        price[0] = 25 * priceDivisor / 100;
        price[1] = 50 * priceDivisor / 100;
        price[2] = 1 * priceDivisor;
        price[3] = 2 * priceDivisor;
        price[4] = 3 * priceDivisor;
        price[5] = 4 * priceDivisor;
        price[6] = 5 * priceDivisor;
        price[7] = 6 * priceDivisor;
        price[8] = 7 * priceDivisor;
        price[9] = 8 * priceDivisor;
        price[10] = 25;

        maxWalletLimit[0] = 8;
        maxWalletLimit[1] = 7;
        maxWalletLimit[2] = 7;
        maxWalletLimit[3] = 7;
        maxWalletLimit[4] = 6;
        maxWalletLimit[5] = 6;
        maxWalletLimit[6] = 6;
        maxWalletLimit[7] = 5;
        maxWalletLimit[8] = 5;
        maxWalletLimit[9] = 4;
        maxWalletLimit[10] = 0;

        exemptMaxAmountUser[address(this)] = true;

        tierInfo[0] = 10;  // tire0 hard coded
        whiteList[address(this)] = true;
        whiteList[_msgSender()] = true;
    }

    function getTierInfo(uint tokenId) external view returns(uint) {
        return tierInfo[tokenId];
    }

    function setListOption(address[] memory list, bool flag, uint8 option) public onlyOwner {
        if(option == 1) {
            for (uint i = 0; i < list.length; i++) {
                swapFeeExempt[list[i]] = flag;
            }
        } else if(option == 2) {
            for(uint i = 0; i < list.length; i++) {
                whiteList[list[i]] = flag;
            }
        } else {
            for(uint i = 0; i < list.length; i++) {
                exemptMaxAmountUser[list[i]] = flag;
            }
        }
        
    }

    function setMaxTier0PerWallet (uint amount) public onlyOwner {
        maxTier0PerWallet = amount;
    }

    function setFlatFee(uint _fee) public onlyOwner {
        flatFee = _fee;
    }

    function setMaxTier0 (uint amount) public onlyOwner {
        maxTier0 = amount;
        max_Regular_tier[10] = amount;
    }

    function setListConfig(uint[] memory vals, uint8 conf) public onlyOwner {
        if(conf == REGULAR_TIER) {
            require(vals.length == 10, "invalid input");
            for(uint i = 0; i < vals.length; i++) {
                max_Regular_tier[i] = vals[i];
            }
        } else if(conf == WALLETLIMIT) {
            require(vals.length == 10, "invalid input");
            for(uint i = 0; i < vals.length; i++) {
                maxWalletLimit[i] = vals[i];
            }
        } else {
            require(vals.length == 11, "invalid input");
            for(uint i = 0; i < vals.length; i++) {
                price[i] = vals[i];
            }
        }
    }

    function setRoyaltyOption(uint8 option) public onlyOwner {
        royaltyOption = option;
    }

    function setMintOption( uint8 option ) public onlyOwner {
        mintOption = option;
    }

    function setXYZtoken(address token) public onlyOwner {
        XYZToken = token;
    }

    function updateDefaultURI(uint tier, string memory uri) public onlyOwner {
        require(tier < 10, "invalid tier");
        defaultURI[tier] = uri;
    }

    function setAbleUpdataURI(bool value) public onlyOwner {
        ableUpdateURI = value;
    }

    function updateURI(uint tokenId, string memory uri) public payable returns(bool) {
        require(ableUpdateURI == true, "not update");
        require(msg.value == flatFee, "not eq value");
        if((owner() == msg.sender && mintOption == 0) ||
           (whiteList[msg.sender] && mintOption == 1) || 
           (mintOption == 2) ) {
            _setTokenURI(tokenId, uri);
            emit UodateURI(_msgSender(), true);
            payable(treasureWallet).transfer(address(this).balance);
            return true;
        }
        emit UodateURI(_msgSender(), false);
        payable(treasureWallet).transfer(address(this).balance);
        return false;
    }

    function setNFTmintCurrency(address token) public onlyOwner {
        currencyToken = token;
    }

    function setTreasureWallet(address wallet) public onlyOwner {
        treasureWallet = wallet;
    }

    function sendAllBalance(address token) public onlyOwner {
        IERC20(token).transfer(treasureWallet, IERC20(token).balanceOf(address(this)));
    }

    function setSwapFee(uint fee) public onlyOwner {
        swapFee = fee;
    } 

    receive() external payable { }
    function mintNFTWithAvax(address wallet, uint tie, uint _amount) public payable { 
        if(_amount > 10) _amount = 10;
        uint amount = price[tie] * _amount;
        if(currencyToken == WAVAX) {
            require(msg.value == amount * 10 ** 18 / priceDivisor + flatFee, "not eq value");
        } else {
            require(msg.value == flatFee, "not eq value");
            IERC20(currencyToken).transferFrom(_msgSender(), address(this), amount * 10 ** IERC20Metadata(currencyToken).decimals() / priceDivisor);
        }
        for(uint i = 0; i < _amount; i ++) {
            uint tokenId = mintNFT(wallet, tie);
            royaltyList[tokenId].user = _msgSender();
            royaltyList[tokenId].mintCurrency = WAVAX;
        }
        payable(treasureWallet).transfer(address(this).balance);
    }

    function getMintUri (uint tier) public view returns(string memory) {
        uint[] storage nftList = userInfo[address(this)].amount[tier];
        if(nftList.length > 0 && borrowList[nftList[nftList.length - 1]].nftId != nftList[nftList.length - 1]) {
            uint tokenId = nftList[nftList.length - 1];
            return tokenURI(tokenId);
        } else {
            string memory tmp = string.concat(defaultURI[tier] ,(_tokenIdsByTier[tier].current()+1).toString());
            return string.concat(tmp, ".json");
        }
    }
    
    function mintNFT(address wallet, uint tier) private returns(uint) {
        require(tier < 11, "invalid tie");
        if((owner() == msg.sender && mintOption == 0) ||
           (whiteList[msg.sender] && mintOption == 1) || 
           (mintOption == 2) ) {
            uint tokenId;
            if(tier == 10) {
                require(canMint(tier, 1), "limit mint");
                userInfo[address(this)].tier0 ++;
                _tier0transferFrom(address(this), wallet, 1);
                return 0;
            }
            uint[] storage nftList = userInfo[address(this)].amount[tier];
            if(nftList.length > 0 && borrowList[nftList[nftList.length - 1]].nftId != nftList[nftList.length - 1]) {
                tokenId = nftList[nftList.length - 1];
            } else {
                require(canMint(tier, 1), "limit mint");
                _tokenIds.increment();
                _tokenIdsByTier[tier].increment();
                tokenId = _tokenIds.current();
                _safeMint(address(this), tokenId);
                tierInfo[tokenId] = tier;
                nftList.push(tokenId);
                string memory tmp = string.concat(defaultURI[tier] ,_tokenIdsByTier[tier].current().toString());
                string memory uri = string.concat(tmp, ".json");
                _setTokenURI(tokenId, uri);
            }
            IERC721Metadata(address(this)).approve(wallet, tokenId);
            transferFrom(address(this), wallet, tokenId);
            // _setTokenURI(tokenId, uri);
            return tokenId;
            
        } else {
            require(false, "invalid Option");
            return 0;
        }

    }

    function canMint(uint tier, uint amount) public view returns(bool) {
        if(tier < 10 && (tBalance[tier] + amount) <= max_Regular_tier[tier] && getMintedTotalAmount() + maxTier0 / max_Regular_tier[tier] * amount <= maxTier0 * 10) return true;
        else if(tier == 10 && getMintedTotalAmount() + amount <= maxTier0 * 10) return true;
        return false;
    }

    function getUserTotalAmount(address wallet) private view returns(uint) {
        uint amount = 0;
        for(uint i = 0; i < 10; i++) {
            uint[] storage nftList = userInfo[wallet].amount[i];
            amount += maxTier0 / max_Regular_tier[i] * nftList.length;
        }
        return amount + userInfo[wallet].tier0;
    }

    function getMintedTotalAmount() private view returns(uint) {
        uint amount = 0;
        for(uint i = 0; i <= 10; i++) {
            uint nftList = tBalance[i];
            amount += maxTier0 / max_Regular_tier[i] * nftList;
        }
        return amount;
    }

    function getMaxUserAmount() private view returns(uint) {
        uint amount = 0;
        for(uint i = 0; i <= 10; i++) {
            amount += maxWalletLimit[i] * maxTier0 / max_Regular_tier[i];
        }
        return amount;
    }

    function tier0transfer(address to, uint amount) public {
        require(_msgSender() != to, "Invalid to");
        _tier0transferFrom(_msgSender(), to, amount);
    }

    function _tier0transferFrom(address from, address to, uint amount) private {
        require(userInfo[from].tier0 >= amount, "insufficeint balance");
        require(canTransfer(to, 0, amount), "exceed max amount2");
        userInfo[from].tier0 -= amount;
        userInfo[to].tier0 += amount;
        if(from == address(this)) {
            tBalance[tierInfo[0]] += amount;
        }
        if( to == address(this) ) {
            tBalance[tierInfo[0]] -= amount;
        }
    }

    function transferFrom (address from, address to, uint tokenId) public override {
        transferNFT(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom (address from, address to, uint tokenId) public override {
        transferNFT(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferNFT(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function canTransfer(address to, uint tokenId, uint amount) public view returns(bool) {
        uint tier = tierInfo[tokenId];
        
        if(exemptMaxAmountUser[to] == true) return true;
        if(exemptMaxAmountUser[to] == false && tier == 10 && userInfo[to].tier0 + amount  <= maxTier0PerWallet ) return true;
        else if(tier == 10) return false;
        uint normalTierLen = userInfo[to].amount[tier].length;
        if(exemptMaxAmountUser[to] == false && 
            tier < 10 && (normalTierLen + amount) <= maxWalletLimit[tier] && 
            getUserTotalAmount(to) + maxTier0 / max_Regular_tier[tier]  <= getMaxUserAmount() ) return true;
        return false;
    }

    function transferNFT(address from, address to, uint tokenId) private {
        uint[] storage fromTokenList = userInfo[from].amount[tierInfo[tokenId]];
        uint[] storage toTokenList = userInfo[to].amount[tierInfo[tokenId]];
        require(canTransfer(to, tokenId, 1), "exceed max amount1");

        bool flag = false;
        for(uint i = 0; i < fromTokenList.length; i++) {
            if(tokenId == fromTokenList[i]) {
                fromTokenList[i] = fromTokenList[fromTokenList.length - 1];
                fromTokenList.pop();
                flag = true;
                break;
            }
        }
        require(flag, "from has no tokenId");
        toTokenList.push(tokenId);
        if(from == address(this)) {
            tBalance[tierInfo[tokenId]]++;
        }
        if( to == address(this) ) {
            tBalance[tierInfo[tokenId]]--;
        }

        if(from != address(this) && to != address(this)) {
            dealwithRoyalty(tokenId);
        }
    }

    function updateRoyaltyInfo(uint tokenId, uint nftId) private {
        //update royalty information
        if(tokenId == 0) return;
        royaltyList[tokenId].user = _msgSender();
        royaltyList[tokenId].mintCurrency = royaltyList[nftId].mintCurrency;
        delete royaltyList[nftId];
        payable(treasureWallet).transfer(address(this).balance);
    }

    function downgradeNFT(uint nftId, uint tierGroup) public payable {
        require(msg.value == flatFee, "not eq value");
        require(upgradable, "no permission");
        uint tier = tierInfo[nftId];
        require(tier < 10 && tierGroup < 10 && tierGroup < tier, "invalid tier");
        uint tier0From = maxTier0 / max_Regular_tier[tier];
        uint tier0To = maxTier0 / max_Regular_tier[tierGroup];
        transferFrom(_msgSender(), address(this), nftId);
        uint tokenId = mintNFT(_msgSender(), tierGroup);
        if(userInfo[address(this)].tier0 < tier0From - tier0To) {
            require(canMint(10, tier0From - tier0To), "limit mint");
            userInfo[address(this)].tier0 = tier0From - tier0To;
        }
        _tier0transferFrom(address(this), _msgSender(), tier0From - tier0To);

        updateRoyaltyInfo(tokenId, nftId);
    }

    function upgradeNFT(uint nftId, uint tierGroup) public payable {
        require(upgradable, "no permission");
        // require(currencyToken == WAVAX, "invalid Currency0");
        uint tier = tierInfo[nftId];
        uint amount = price[tierGroup] - price[tier];
        emit UpgradeNFTByAvax(msg.sender, msg.value, amount * 10 ** 18 / priceDivisor);
        require(msg.value == amount * 10 ** 18 / priceDivisor + flatFee, "not eq value");
        
        require(tier < 10 && tierGroup < 10 && tierGroup > tier, "invalid tier");
        transferFrom(_msgSender(), address(this), nftId);
        uint tokenId = mintNFT(_msgSender(), tierGroup);
        updateRoyaltyInfo(tokenId, nftId);
    }

    function setUpgradable(bool flag) public onlyOwner {
        upgradable = flag;
    }

    function aggregation(uint amount, uint tierGroup) public payable {
        require(msg.value == flatFee, "not eq value");
        require(amount >= maxTier0 / max_Regular_tier[tierGroup], "too small");
        require(tierGroup < 10, "Invalid tier");
        uint count  = amount / (maxTier0 / max_Regular_tier[tierGroup]);
        if(count > 10) count = 10;
        _tier0transferFrom(_msgSender(), address(this), count * (maxTier0 / max_Regular_tier[tierGroup]));

        for (uint i = 0; i < count; i++) {
            uint tokenId = mintNFT(_msgSender(), tierGroup);
            if(tokenId == 0) continue;
            royaltyList[tokenId].user = _msgSender();
            royaltyList[tokenId].mintCurrency = currencyToken;
        }
        payable(treasureWallet).transfer(address(this).balance);
    }

    function fractionalize(uint tokenId) public payable {
        require(msg.value == flatFee, "not eq value");
        uint tier = tierInfo[tokenId];
        uint amount = maxTier0 / max_Regular_tier[tier];
        transferFrom(_msgSender(), address(this), tokenId);
        delete royaltyList[tokenId];
        if(userInfo[address(this)].tier0 < amount) {
            require(canMint(10, amount), "limit mint");
            userInfo[address(this)].tier0 = amount;
        }
        _tier0transferFrom(address(this), _msgSender(), amount);
        payable(treasureWallet).transfer(address(this).balance);
    }

    function exchangeXYZAndTier0(uint amount, bool buyTier0) public payable {
        require(msg.value == flatFee, "not eq value");
        if(buyTier0) {
            uint swapAmount;
            if(swapFeeExempt[_msgSender()]) swapAmount = amount;
            else swapAmount = amount * swapFee / 100;
            
            require(swapAmount > 0, "too small");
            if(userInfo[address(this)].tier0 < swapAmount) {
                require(canMint(10, swapAmount), "limit mint");
                userInfo[address(this)].tier0 = swapAmount;
            }
            IERC20(XYZToken).transferFrom(_msgSender(), address(this), amount * 10 ** IERC20Metadata(XYZToken).decimals());
            _tier0transferFrom(address(this), _msgSender(), swapAmount);
        } else {
            uint swapAmount;
            if(swapFeeExempt[_msgSender()]) swapAmount = amount * 10 ** IERC20Metadata(XYZToken).decimals();
            else swapAmount = amount * 10 ** IERC20Metadata(XYZToken).decimals() * swapFee / 100;
            _tier0transferFrom(_msgSender(),address(this), amount);
            IERC20(XYZToken).transfer(_msgSender(), swapAmount);
        }
        payable(treasureWallet).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function getLen(address user, uint tire) public view returns(uint) { // for test
        if(tire == 10) return userInfo[user].tier0;
        return userInfo[user].amount[tire].length;
    }

    function getInfo(address user, uint tier) public view returns(uint[] memory res, string[] memory uriList) {
        res = userInfo[user].amount[tier];
        uriList = new string [](res.length);
        for(uint i = 0; i < res.length; i++) {
            uriList[i] = tokenURI(res[i]);
        }
        return (res, uriList);
    }

    function borrow(uint nftId) public payable {
        require(msg.value == flatFee, "not eq value");
        require(isBorrowable, "no setting");
        require(_msgSender() != owner(), "owner cannot borrow");
        require(ownerOf(nftId) == _msgSender(), "not owner");
        uint tire = tierInfo[nftId];
        uint amount = maxTier0 / max_Regular_tier[tire];
        transferFrom(_msgSender(), address(this), nftId);
        _tier0transferFrom(address(this), _msgSender(), amount * borrowFee / 100);
        borrowList[nftId].user = _msgSender();
        borrowList[nftId].borrowTime = block.timestamp;
        borrowList[nftId].nftId = nftId;
        borrowNFTList.push(nftId);
        dealwithRoyalty(nftId);
        payable(treasureWallet).transfer(address(this).balance);
    }

    function redeemNFT(uint nftId, bool isOwner) public payable {
        require(msg.value == flatFee, "not eq value");
        require((isOwner == true && _msgSender() == owner()) || isOwner == false);
        bool isExist = false;
        for(uint i = 0; i < borrowNFTList.length; i++) {
            if(borrowNFTList[i] == nftId) {
                borrowNFTList[i] = borrowNFTList[borrowNFTList.length - 1];
                borrowNFTList.pop();
                isExist = true;
                break;
            }
        }
        require(isExist, "no borrow id");
        require(
            (block.timestamp - borrowList[nftId].borrowTime <= holdPeriod + gracePeriod && borrowList[nftId].user == _msgSender()) || 
            (block.timestamp - borrowList[nftId].borrowTime > holdPeriod + gracePeriod && borrowList[nftId].user != _msgSender()),
            "invalid user"
        );

        dealwithRoyalty(nftId);

        if (isOwner == true) {
            IERC721Metadata(address(this)).transferFrom(address(this), treasureWallet, nftId);
            delete borrowList[nftId];
            return;
        }
        uint rate;
        if(block.timestamp - borrowList[nftId].borrowTime <= holdPeriod + gracePeriod && borrowList[nftId].user == _msgSender()) {
            if(block.timestamp - borrowList[nftId].borrowTime <= holdPeriod) rate = borrowFee * 100 + borrowFee * redeemFee;
            else if(block.timestamp - borrowList[nftId].borrowTime <= holdPeriod + gracePeriod) rate = borrowFee * 100 + (redeemFee + graceFee) * borrowFee;
            
        } else {
            rate = (100 - discountFee) * 100;
        }

        delete borrowList[nftId];
        
        uint amount = maxTier0 / max_Regular_tier[tierInfo[nftId]];
        _tier0transferFrom(_msgSender(), address(this), amount * rate / 10000);
        IERC721Metadata(address(this)).transferFrom(address(this), _msgSender(), nftId);
        payable(treasureWallet).transfer(address(this).balance);
    }

    function dealwithRoyalty (uint nftId) private {
        // royalty fee
        address minter = royaltyList[nftId].user;
        address mintCurrency = royaltyList[nftId].mintCurrency;
        address token;

        uint tierId = tierInfo[nftId];

        if(mintCurrency == WAVAX) {
            token = WAVAX;
        } else {
            token = mintCurrency;
        }
        if(royaltyOption == 1) {
            IERC20(token).transferFrom(_msgSender(), address(this), price[tierId] * roayltyFee * 10 ** IERC20Metadata(token).decimals() / 100 / priceDivisor);
        } else if(royaltyOption == 2) {
            if(minter == _msgSender()) return;
            IERC20(token).transferFrom(_msgSender(), minter, price[tierId] * roayltyFee * 10 ** IERC20Metadata(token).decimals() / 100 / priceDivisor);
        }
    }

    function setRoyaltyFee (uint fee) public onlyOwner {
        roayltyFee = fee;
    }

    function setBorrowConf(uint holdTime, uint graceTime, uint _borrowFee, uint _discount, uint _redeemFee, uint _graceFee) public onlyOwner{
        holdPeriod = holdTime * 1 days;
        gracePeriod = graceTime * 1 days;
        borrowFee = _borrowFee;
        discountFee = _discount;
        graceFee = _graceFee;
        redeemFee = _redeemFee;
    }

    function setBorrowable(bool flag) public onlyOwner {
        isBorrowable = flag;
    }

    function getBorrowInfo() public view returns(BorrowInfo[] memory borrowInfoList) {
        borrowInfoList = new BorrowInfo[](borrowNFTList.length);
        for(uint i = 0; i < borrowNFTList.length; i++) {
            if(ownerOf(borrowList[borrowNFTList[i]].nftId) != address(this)) continue;
            borrowInfoList[i] = borrowList[borrowNFTList[i]];
        }
        return borrowInfoList;
    }
}