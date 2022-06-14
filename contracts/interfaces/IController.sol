// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IController {
	function onNFTTransfer(address from, address to, uint256 tokenId) external;
	function getProfileId(address owner) external view returns (uint256);
	function getProfileOwner(uint256 profileId) external view returns (address);
}