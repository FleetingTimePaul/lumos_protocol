// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IContentNFT {
    function mint(address to, string calldata contentIdURI) external returns (uint256);
}
