// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./extensions/ERC721DynamicOwnershipUpgradeable.sol";
import "./interfaces/ILumos.sol";

contract ProfileNFT is ERC721DynamicOwnershipUpgradeable, PausableUpgradeable {
    event SetTokenURI(uint256 tokenId, string profileMetadataURI);

    uint256 private _nonce;
    mapping(uint256 => address) private _owners; //profileId => owner
    mapping(address => uint256) private _profiles; //owner => profileId
    mapping(uint256 => string) private _profileMetadataURIs; //profileId => profileMetadataURI

    address public lumos;

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _lumos
    ) external initializer {
        require(
            _lumos != address(0),
            "ProfileNFT: initialize _lumos with zero address"
        );
        ERC721DynamicOwnershipUpgradeable.__ERC721_init(_name, _symbol);
        PausableUpgradeable.__Pausable_init();
        lumos = _lumos;
    }

    function profileOf(address owner) public view returns (uint256) {
        return _profiles[owner];
    }

    function reinterpret(address owner)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return profileOf(owner);
    }

    function reinterpret(uint256 profileId)
        internal
        view
        virtual
        override
        returns (address)
    {
        return _owners[profileId];
    }

    function mint(address to, string calldata profileMetadataURI)
        external
        returns (uint256)
    {
        require(msg.sender == lumos, "ProfileNFT: only lumos");
        uint256 tokenId = ++_nonce;
        _mint(to, tokenId);
        _profileMetadataURIs[tokenId] = profileMetadataURI;
        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _profileMetadataURIs[tokenId];
    }

    function setTokenURI(uint256 tokenId, string calldata profileMetadataURI)
        external
    {
        require(msg.sender == lumos, "ProfileNFT: only lumos");
        _profileMetadataURIs[tokenId] = profileMetadataURI;
        emit SetTokenURI(tokenId, profileMetadataURI);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        require(balanceOf(to) == 0, "ProfileNFT: transfer to address already has a profileID");
        if(from == address(0)) { //mint
            _owners[tokenId] = to;
            _profiles[to] = tokenId;
        } else {
             uint256 profileId = profileOf(from);
            _owners[profileId] = to;
            _profiles[to] = profileId;
            delete _profiles[from];
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
