// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMarket.sol";

contract ApaGalsMultiDelist {
    IMarket public constant APA_MARKET = IMarket(0x9615Fc5890F4585B14aABF433d0f73aACFfeC348);

    function multiDelist(uint256[] calldata _indexList) public {
        for (uint256 index = 0; index < _indexList.length; index++) {
            APA_MARKET.emergencyDelist(_indexList[index]);
        }
    }
    
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IMarket {
    event AddedListing(Market.Listing listing);
    event CanceledListing(Market.Listing listing);
    event FilledListing(Market.Purchase listing);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event UpdateListing(Market.Listing listing);

    function activeListings(uint256) external view returns (uint256);

    function addListing(uint256 tokenId, uint256 price) external;

    function adjustFees(uint256 newDistFee, uint256 newMarketFee) external;

    function allowEmergencyDelisting() external;

    function cancelListing(uint256 id) external;

    function claimListedRewards(uint256 from, uint256 length) external;

    function claimOwnedRewards(uint256 from, uint256 length) external;

    function claimRewards() external;

    function closeMarket() external;

    function communityFeePercent() external view returns (uint256);

    function communityHoldings() external view returns (uint256);

    function communityRewards(uint256) external view returns (uint256);

    function emergencyDelist(uint256 listingID) external;

    function emergencyDelisting() external view returns (bool);

    function emergencyWithdraw() external;

    function fulfillListing(uint256 id) external payable;

    function getActiveListings(uint256 from, uint256 length)
        external
        view
        returns (Market.Listing[] memory listing);

    function getMyActiveListings(uint256 from, uint256 length)
        external
        view
        returns (Market.Listing[] memory listing);

    function getMyActiveListingsCount() external view returns (uint256);

    function getRewards() external view returns (uint256 amount);

    function highestSalePrice() external view returns (uint256);

    function isMarketOpen() external view returns (bool);

    function listings(uint256)
        external
        view
        returns (
            bool active,
            uint256 id,
            uint256 tokenId,
            uint256 price,
            uint256 activeIndex,
            uint256 userActiveIndex,
            address owner,
            string memory tokenURI
        );

    function marketFeePercent() external view returns (uint256);

    function openMarket() external;

    function owner() external view returns (address);

    function renounceOwnership() external;

    function totalActiveListings() external view returns (uint256);

    function totalGivenRewardsPerToken() external view returns (uint256);

    function totalListings() external view returns (uint256);

    function totalSales() external view returns (uint256);

    function totalVolume() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updateListing(uint256 id, uint256 price) external;

    function userActiveListings(address, uint256)
        external
        view
        returns (uint256);

    function withdrawBalance() external;

    function withdrawableBalance() external view returns (uint256 value);
}

interface Market {
    struct Listing {
        bool active;
        uint256 id;
        uint256 tokenId;
        uint256 price;
        uint256 activeIndex;
        uint256 userActiveIndex;
        address owner;
        string tokenURI;
    }

    struct Purchase {
        Listing listing;
        address buyer;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"nft_address","type":"address"},{"internalType":"uint256","name":"dist_fee","type":"uint256"},{"internalType":"uint256","name":"market_fee","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"indexed":false,"internalType":"struct Market.Listing","name":"listing","type":"tuple"}],"name":"AddedListing","type":"event"},{"anonymous":false,"inputs":[{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"indexed":false,"internalType":"struct Market.Listing","name":"listing","type":"tuple"}],"name":"CanceledListing","type":"event"},{"anonymous":false,"inputs":[{"components":[{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"internalType":"struct Market.Listing","name":"listing","type":"tuple"},{"internalType":"address","name":"buyer","type":"address"}],"indexed":false,"internalType":"struct Market.Purchase","name":"listing","type":"tuple"}],"name":"FilledListing","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"indexed":false,"internalType":"struct Market.Listing","name":"listing","type":"tuple"}],"name":"UpdateListing","type":"event"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"activeListings","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"name":"addListing","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newDistFee","type":"uint256"},{"internalType":"uint256","name":"newMarketFee","type":"uint256"}],"name":"adjustFees","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"allowEmergencyDelisting","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"cancelListing","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"length","type":"uint256"}],"name":"claimListedRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"length","type":"uint256"}],"name":"claimOwnedRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"claimRewards","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"closeMarket","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"communityFeePercent","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"communityHoldings","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"communityRewards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"listingID","type":"uint256"}],"name":"emergencyDelist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"emergencyDelisting","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"emergencyWithdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"fulfillListing","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"length","type":"uint256"}],"name":"getActiveListings","outputs":[{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"internalType":"struct Market.Listing[]","name":"listing","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"from","type":"uint256"},{"internalType":"uint256","name":"length","type":"uint256"}],"name":"getMyActiveListings","outputs":[{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"internalType":"struct Market.Listing[]","name":"listing","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMyActiveListingsCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getRewards","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"highestSalePrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isMarketOpen","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"listings","outputs":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"uint256","name":"activeIndex","type":"uint256"},{"internalType":"uint256","name":"userActiveIndex","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"string","name":"tokenURI","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"marketFeePercent","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"openMarket","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"totalActiveListings","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalGivenRewardsPerToken","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalListings","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSales","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalVolume","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"name":"updateListing","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"userActiveListings","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"withdrawBalance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawableBalance","outputs":[{"internalType":"uint256","name":"value","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/