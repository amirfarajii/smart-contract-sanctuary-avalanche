/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract MarketPlaceProxy {

    error ExternalCallError(string message);

    address public marketplace;

    address public owner;

    address public marketFeeTaker;

    // Byte Code Generator
    address public erc721Gen;

    struct SellOrder {
        address nftContract;
        address orderOwner;
        address token;
        address buyer;
        uint256 nftId;
        uint256 totalPrice;
        uint256 orderStartedAt;
        uint256 orderEndedAt;
        bool isCanceled;
        bool isEnded;
    }
    uint256 public totalSellOrderCount = 1;

    struct Bid {
        uint256 totalPrice;
        uint256 nftId;
        uint256 bidStartedAt;
        uint256 bidEndedAt;
        uint256 orderId;
        address nftContractAddr;
        address seller;
        address bidOwner;
        address token;
        bool isCanceled;
        bool isEnded;
    }
    uint256 public totalBidCount = 1;

    event SellOrderCreated(address indexed creator,uint indexed orderId,address token);
    event BidCreated(address indexed creator,uint indexed bidId,address token);
    event ContractCreation(address indexed creator,string name,string symbol);

    // from orderId to order info (ERC721)
    mapping (uint256 => SellOrder) public order;
    // from order owner to all his sell orders (ERC721)
    mapping (address => uint[]) public userSellOrders;
    // from contract address to specific tokenids bids
    mapping (address => mapping (address => mapping (uint => uint[]))) public contractBids;
    // from user to is ERC721 contract created (ERC721)
    mapping (address => address) public userContract;
    // from bidId to bid info (ERC721)
    mapping (uint256 => Bid) public bid;
    // from bidder to bid id (ERC721)
    mapping (address => uint[]) public bidderBids;
    // from user to his added contract accounts
    mapping (address => address[]) public userAddedContracts;
    // from contract address to validation
    mapping (address => bool) public allMarketContracts;
    // from token too validation status
    mapping (address => bool) public allTokens;
    address[] public tokens;
    // Set owner & ...
    constructor(
        address[] memory _tokens,
        address _feeTaker,
        address _erc721Gen,
        address _implementation
    ) {
        tokens = _tokens;
        marketFeeTaker = _feeTaker;
        erc721Gen = _erc721Gen;
        owner = msg.sender;
        marketplace = _implementation;

        for (uint i; i < _tokens.length; ++i) {
            allTokens[_tokens[i]] = true;
        }
    }
    // Gaurd
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    //////////////////////////////////////// *Interact With Implemented Marketplace* ////////////////////////
    fallback() external {
        (bool res,) = marketplace.delegatecall(msg.data);
        require(res == true, "Delegate call failed.");
    }
    //////////////////////////////// Update Implementation Marketplace ////////////////////////////////////
    function upgrade(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }
    //////////////////////////////// Change Current Owner /////////////////////////////////////////////////
    function changeOwner(address _newOwner) external onlyOwner {
        require(owner != _newOwner, "You are owner right now!");

        owner = _newOwner;
    }
    
}