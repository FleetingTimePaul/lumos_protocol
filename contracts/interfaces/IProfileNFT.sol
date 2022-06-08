// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IProfileNFT is IERC721Upgradeable {
    function profileOf(address owner) external view returns(uint256);
    function ownerOf(uint256 profileId) external view returns(address);
    function mint(address to, string calldata profileIdURI) external returns (uint256);
}
