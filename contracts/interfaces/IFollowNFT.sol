// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IFollowNFT is IERC721EnumerableUpgradeable {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _lumos
    ) external;

    function mint(address to) external returns (uint256);
    function burn(address to, uint256 tokenId) external;
    function setURI(string calldata uri) external;
}
