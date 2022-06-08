// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./IProfileNFT.sol";

interface ILumos {
	function profileNFT() external view returns(IProfileNFT);
	function contentNFT() external view returns(IProfileNFT);
	function onNFTTransfer(address from, address to, uint256 tokenId) external;
}