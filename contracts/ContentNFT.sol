// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./extensions/ERC721DynamicOwnershipUpgradeable.sol";
import "./interfaces/ILumos.sol";

contract ContentNFT is PausableUpgradeable, ERC721DynamicOwnershipUpgradeable {
    event ContentNFTTransfer(
        uint256 fromProfileId,
        uint256 toProfileId,
        uint256 tokenId
    );

    uint256 private _nonce;
    mapping(uint256 => string) private _contentURIs;

    address public lumos;

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _lumos
    ) external initializer {
        require(
            _lumos != address(0),
            "ContentNFT: initialize lumos with zero address"
        );
        ERC721DynamicOwnershipUpgradeable.__ERC721_init(_name, _symbol);
        PausableUpgradeable.__Pausable_init();
        lumos = _lumos;
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

    function reinterpret(uint256 profileId)
        internal
        view
        virtual
        override
        returns (address)
    {
        return ILumos(lumos).profileNFT().ownerOf(profileId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ContentNFT: tokenId not exists");
        return _contentURIs[tokenId];
    }

    function mint(address to, string memory contentURI)
        external
        returns (uint256)
    {
        require(msg.sender == lumos, "ContentNFT: not lumos");
        uint256 tokenId = ++_nonce;
        _mint(to, tokenId);
        _contentURIs[tokenId] = contentURI;
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        ILumos(lumos).onNFTTransfer(from, to, tokenId);
        emit ContentNFTTransfer(reinterpret(from), reinterpret(to), tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
