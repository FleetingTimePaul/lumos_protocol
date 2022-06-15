// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./extensions/ERC721EnumerableUpgradeable.sol";
import "./interfaces/IController.sol";

contract FollowNFT is PausableUpgradeable, ERC721EnumerableUpgradeable {
    uint256 private _nonce;
    string private _uri;
    address public controller;

    modifier onlyController() {
        require(msg.sender == controller, "FollowNFT: only controller");
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _controller
    ) external initializer {
        require(
            _controller != address(0),
            "FollowNFT: initialize _controller with zero address"
        );
        ERC721Upgradeable.__ERC721_init(_name, _symbol);
        PausableUpgradeable.__Pausable_init();
        controller = _controller;
    }

    function mint(address to) external onlyController returns (uint256) {
        uint256 tokenId = ++_nonce;
        _mint(to, tokenId);
        return tokenId;
    }

    function burn(address to, uint256 tokenId) external onlyController {
        require(
            _isApprovedOrOwner(to, tokenId),
            "FollowNFT: not approved or owner"
        );
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "FollowNFT: tokenId dose not exists");
        return _uri;
    }

    function setURI(string calldata uri) external onlyController {
        _uri = uri;
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        IController(controller).onNFTTransfer(from, to, tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
