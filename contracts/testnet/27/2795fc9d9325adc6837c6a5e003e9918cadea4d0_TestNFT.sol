// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721URIStorage.sol";
import "Counters.sol";
import "Ownable.sol";

contract TestNFT is ERC721URIStorage,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("TestNFT", "TI") {}

    function mintNFT(address to, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }


    function contractURI() public pure returns (string memory) {
        return "https://arweave.net/r_iU0U5UsAQ1DDWUiAQT64Z_ysTas3tofR8-8kpcXhY";
    }

    function totalSupply() public view returns (uint256){
        return _tokenIds.current();
    }

}