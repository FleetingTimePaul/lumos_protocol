// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/IProfileNFT.sol";
import "./interfaces/IContentNFT.sol";
import "./interfaces/IFollowNFT.sol";

contract Lumos is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    event SetFollowNFTURI(address owner, uint256 profile, string followNFTURI);

    event Post(address owner, uint256 profileId, uint256 contentIdIndex, uint256 contentId, string contentIdURI);
    event Create(address owner, uint256 profileId, string profileIdURI);
    event Follow(
        address owner,
        uint256 profileId,
        uint256 followedProfileId,
        address followNFT,
        uint256 followId
    );

    mapping(uint256 => address) private _followNFTs; // profileId => followNFT
    mapping(address => uint256) private _followNFTOwners; // followNFT => profileId
    mapping(uint256 => mapping(uint256 => uint256)) private _indexedContentIds; //profileId => index => contentNFT Ids
    mapping(uint256 => uint256) private _contentIdCount; // profileId => size of contentNFT Ids
    address public factory;
    address public profileNFT;
    address public contentNFT;

    function initialize(
        address _admin,
        address _factory,
        bytes memory profileNFTInitializeData,
        bytes memory contentNFTInitializeData
    ) external initializer {
        require(_admin != address(0), "Lumos: invalid _admin params");
        require(_factory != address(0), "Lumos: invalid _factory params");
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        PausableUpgradeable.__Pausable_init();
        factory = _factory;
        profileNFT = IFactory(factory).deployProfileNFT(
            profileNFTInitializeData
        );
        contentNFT = IFactory(factory).deployContentNFT(
            contentNFTInitializeData
        );
    }

    modifier onlyProfileOwner(uint256 profileId) {
        require(
            msg.sender == IProfileNFT(profileNFT).ownerOf(profileId),
            "Lumos: sender not profile owner"
        );
        _;
    }

    function create(string memory profileIdURI) external whenNotPaused {
        require(
            IProfileNFT(profileNFT).balanceOf(msg.sender) == 0,
            "Lumos: profile exist"
        );
        uint256 profileId = IProfileNFT(profileNFT).mint(
            msg.sender,
            profileIdURI
        );
        emit Create(msg.sender, profileId, profileIdURI);
    }

    function post(string memory contentIdURI) external whenNotPaused {
        uint256 profileId = IProfileNFT(profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Lumos: profile does not exist");
        uint256 contentId = IContentNFT(contentNFT).mint(
            msg.sender,
            contentIdURI
        );
        uint256 index = _contentIdCount[profileId]++;
        _indexedContentIds[profileId][index] = contentId;
        emit Post(msg.sender, profileId, index, contentId, contentIdURI);
    }

    function follow(uint256[] calldata profileIds) external whenNotPaused {
        uint256 profileId = IProfileNFT(profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Lumos: profile does not exist");
        for (uint256 i = 0; i < profileIds.length; ++i) {
            uint256 followerId = profileIds[i];
            require(
                IProfileNFT(profileNFT).ownerOf(followerId) != address(0),
                "Lumos: invalid follower Id"
            );
            address followNFT = _followNFTs[followerId];
            if (followNFT == address(0)) {
                bytes memory initializeData = abi.encodeWithSelector(
                    IFollowNFT.initialize.selector,
                    string(abi.encodePacked(followerId, "-Follower")),
                    string(abi.encodePacked(followerId, "-Fl")),
                    followerId,
                    address(this)
                );
                followNFT = IFactory(factory).deployFollowNFT(initializeData);
                _followNFTs[followerId] = followNFT;
                _followNFTOwners[followNFT] = followerId;
            }
            uint256 followId = IFollowNFT(followNFT).mint(msg.sender);
            emit Follow(
                msg.sender,
                profileId,
                profileIds[i],
                followNFT,
                followId
            );
        }
    }

    function unfollow(uint256[] calldata profileIds) external whenNotPaused {}

    function getFollowNFT(uint256 profileId) external view returns (address) {
        return _followNFTs[profileId];
    }

    function getContentIdCount(uint256 profileId)
        external
        view
        returns (uint256)
    {
        return _contentIdCount[profileId];
    }

    function setFollowNFTURI(string calldata followNFTURI)
        external
        whenNotPaused
    {
        uint256 profileId = IProfileNFT(profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Lumos: profile does not exist");
        require(_followNFTs[profileId] != address(0), "Lumos: profile no followed");
        IFollowNFT(_followNFTs[profileId]).setFollowNFTURI(followNFTURI);
        emit SetFollowNFTURI(msg.sender, profileId, followNFTURI);
    }

    function onNFTTransfer(
        address from,
        address to,
        uint256 tokenId
    ) public whenNotPaused {
        require(
            msg.sender == contentNFT || _followNFTOwners[msg.sender] != 0,
            "Lumos: Unknown sender"
        );
        if (IProfileNFT(profileNFT).balanceOf(to) == 0) {
            uint256 profileId = IProfileNFT(profileNFT).mint(to, "");
            emit Create(to, profileId, "");
        }
    }
}
