// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "hardhat/console.sol";

contract ERC721 is
    Ownable,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Strings for uint256;
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    string private _name;
    string private _symbol;
    string private _baseURI = "https://ipfs.io/ipfs/";

    mapping(address => EnumerableSet.UintSet) private _holderTokens;
    EnumerableMap.UintToAddressMap private _tokenOwners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // metadata
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        if (_tokenOwners.contains(tokenId)) {
            return _tokenOwners.get(tokenId);
        } else {
            return address(0);
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _holderTokens[owner].length();
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        string memory tokenIdString = _tokenURIs[tokenId];
        if (bytes(tokenIdString).length > 0) {
            return tokenIdString;
        }

        return
            bytes(_baseURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenId.toString()))
                : "";
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    // transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = _tokenOwners.get(tokenId);
        return
            owner == spender ||
            spender == getApproved(tokenId) ||
            isApprovedForAll(owner, spender);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        _transfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        delete _tokenApprovals[tokenId];

        _holderTokens[to].add(tokenId);
        _holderTokens[from].remove(tokenId);
        _tokenOwners.set(tokenId, to);
        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    // 如果to是合约账户，检查是否实现了ERC721Received接口
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    // hook
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual {}

    // approve
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _tokenOwners.get(tokenId);
        require(to != owner, "ERC721: approve to the current owner");
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved"
        );

        _approval(to, tokenId);
    }

    function _approval(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: approve to the zero address");
        _tokenApprovals[tokenId] = to;

        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != address(0), "ERC721: approve to the zero address");
        require(msg.sender != operator, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // mint
    function _safeMint(
        address to,
        string memory tokenURL_,
        bytes memory data
    ) internal virtual returns (uint256) {
        uint256 tokenId = totalSupply();

        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );

        _mint(to, tokenId, tokenURL_);

        return tokenId;
    }

    function _safeMint(
        address to,
        string memory tokenURL_
    ) internal virtual returns (uint256) {
        uint256 tokenId = _safeMint(to, tokenURL_, "");
        return tokenId;
    }

    function _mint(
        address to,
        uint256 tokenId,
        string memory tokenURL_
    ) internal virtual {
        require(!_exists(tokenId), "ERC721: token already minted");
        require(to != address(0), "ERC721: mint to the zero address");
        _beforeTokenTransfer(address(0), to, tokenId, 1);

        _tokenOwners.set(tokenId, to);
        _holderTokens[to].add(tokenId);

        _tokenURIs[tokenId] = tokenURL_;

        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    // burn
    function _burn(uint256 tokenId) internal virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: caller is not token owner or approved"
        );

        address owner = ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        delete _tokenApprovals[tokenId];
        _holderTokens[owner].remove(tokenId);
        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenOwners.length();
    }

    function ownerTotal(address owner) public view returns (uint256) {
        return _holderTokens[owner].length();
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function tokenByIndex(
        uint256 index
    ) external view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }
}
