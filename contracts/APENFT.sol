// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./ERC721.sol";

contract APENFT is ERC721 {
    uint256 public MAX_APES;
    uint256 public MAX_HOLDS;
    uint256 public apePrice = 0;
    uint256 public REVEAL_TIMESTAMP;
    mapping(address => bool) public blacklist;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxNftSupply,
        uint256 maxHolds,
        uint256 saleStart
    ) ERC721(name_, symbol_) {
        MAX_APES = maxNftSupply;
        MAX_HOLDS = maxHolds;
        REVEAL_TIMESTAMP = saleStart + (86400);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setApePrice(uint256 newApePrice) public onlyOwner {
        apePrice = newApePrice;
    }

    function setBlackList(
        address account,
        bool _isBlacklisting
    ) public onlyOwner {
        blacklist[account] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal view override {
        require(!blacklist[from] && !blacklist[to], "blacklisted");
    }

    function mintApe(string memory tokenURI) public payable returns (uint256) {
        if (msg.sender == owner()) {
            require(totalSupply() < MAX_APES, "MAX_APES limit");
        } else {
            require(
                ownerTotal(msg.sender) < MAX_HOLDS && totalSupply() < MAX_APES,
                "mint limit"
            );
        }

        uint256 tokenId = _safeMint(msg.sender, tokenURI);
        return tokenId;
    }
}
