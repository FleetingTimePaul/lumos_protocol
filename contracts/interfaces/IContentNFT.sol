// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IContentNFT is IERC721EnumerableUpgradeable {
    function mint(address to, string calldata uri) external returns (uint256);
}
