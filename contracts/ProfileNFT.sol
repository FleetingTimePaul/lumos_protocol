// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./extensions/ERC721EnumerableUpgradeable.sol";
import "./interfaces/IController.sol";

contract ProfileNFT is PausableUpgradeable, ERC721EnumerableUpgradeable {
    uint256 private _nonce;
    mapping(uint256 => string) private _uris; //profileId => uris
    mapping(uint256 => address) private _owners; //profileId => owner
    mapping(address => uint256) private _profiles; //owner => profileId
    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "ProfileNFT: only controller");
        _;
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _controller
    ) external initializer {
        require(
            _controller != address(0),
            "ProfileNFT: initialize _controller with zero address"
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
        return _profiles[owner];
    }

    function getOwner(uint256 ownerId)
        internal
        view
        virtual
        override
        returns (address)
    {
        return _owners[ownerId];
    }

    function profileOf(address owner) external view returns (uint256) {
        return _profiles[owner];
    }

    function mint(address to, string calldata uri)
        external
        onlyController
        returns (uint256)
    {
        uint256 tokenId = ++_nonce;
        _mint(to, tokenId);
        _uris[tokenId] = uri;
        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _uris[tokenId];
    }

    function setTokenURI(uint256 tokenId, string calldata uri)
        external
        onlyController
    {
        _uris[tokenId] = uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        require(balanceOf(to) == 0, "ProfileNFT: transfer to has a profile");
        //mint
        if (from == address(0)) {
            _owners[tokenId] = to;
            _profiles[to] = tokenId;
        } else {
            uint256 profileId = _profiles[from];
            _owners[profileId] = to;
            _profiles[to] = profileId;
            delete _profiles[from];
        }
        IController(controller).onNFTTransfer(from, to, tokenId);
    }
}
