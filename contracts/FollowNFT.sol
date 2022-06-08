// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./extensions/ERC721DynamicOwnershipUpgradeable.sol";
import "./interfaces/ILumos.sol";

contract FollowNFT is PausableUpgradeable, ERC721DynamicOwnershipUpgradeable {
    event FollowNFTTransfer(
        uint256 fromProfileId,
        uint256 toProfileId,
        uint256 tokenId
    );
    uint256 private _nonce;
    string private _followNFTURI;
    uint256 public profileId;
    address public lumos;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _profileId,
        address _lumos
    ) external initializer {
        require(_lumos != address(0), "initialize _lumos with zero address");
        require(_profileId != 0, "initialize _profileId with zero address");
        ERC721DynamicOwnershipUpgradeable.__ERC721_init(_name, _symbol);
        PausableUpgradeable.__Pausable_init();
        lumos = _lumos;
        profileId = _profileId;
    }

    function mint(address to) external returns (uint256) {
        require(msg.sender == lumos, "Permission denied");
        uint256 tokenId = ++_nonce;
        _mint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Permission denied");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token dose not exists");
        return _followNFTURI;
    }

    function reinterpret(address owner)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return ILumos(lumos).profileNFT().profileOf(owner);
    }

    function reinterpret(uint256 id)
        internal
        view
        virtual
        override
        returns (address)
    {
        return ILumos(lumos).profileNFT().ownerOf(id);
    }

    function setFollowNFTURI(string calldata followNFTURI) external {
        require(msg.sender == lumos, "Permission denied");
        _followNFTURI = followNFTURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        ILumos(lumos).onNFTTransfer(from, to, tokenId);
        emit FollowNFTTransfer(reinterpret(from), reinterpret(to), tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
