// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IProfileNFT is IERC721EnumerableUpgradeable {
    function profileOf(address owner) external view returns(uint256);
    function mint(address to, string calldata uri) external returns (uint256);
}
