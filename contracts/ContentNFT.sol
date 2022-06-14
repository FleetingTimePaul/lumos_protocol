// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./extensions/ERC721EnumerableUpgradeable.sol";
import "./interfaces/IController.sol";

contract ContentNFT is PausableUpgradeable, ERC721EnumerableUpgradeable {
    uint256 private _nonce;
    mapping(uint256 => string) private _uris;

    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "ContentNFT: only controller");
        _;
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _controller
    ) external initializer {
        require(
            _controller != address(0),
            "ContentNFT: initialize _controller with zero address"
        );
        ERC721Upgradeable.__ERC721_init(_name, _symbol);
        PausableUpgradeable.__Pausable_init();
        controller = _controller;
    }

    function getOwnerId(address owner)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return IController(controller).getProfileId(owner);
    }

    function getOwner(uint256 ownerId)
        internal
        view
        virtual
        override
        returns (address)
    {
        return IController(controller).getProfileOwner(ownerId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ContentNFT: tokenId dose not exists");
        return _uris[tokenId];
    }

    function mint(address to, string memory uri)
        external
        onlyController
        returns (uint256)
    {
        uint256 tokenId = ++_nonce;
        _mint(to, tokenId);
        _uris[tokenId] = uri;
        return tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        IController(controller).onNFTTransfer(from, to, tokenId);
    }
}
