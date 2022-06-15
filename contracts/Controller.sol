// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import "./interfaces/IProfileNFT.sol";
import "./interfaces/IContentNFT.sol";
import "./interfaces/IFollowNFT.sol";

contract Controller is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    event Post(
        address owner,
        uint256 profileId,
        uint256 contentIdIndex,
        uint256 contentId,
        string contentIdURI
    );
    event Create(address owner, uint256 profileId, string profileIdURI);
    event Follow(
        address owner,
        uint256 follower,
        uint256 followee,
        address followNFT,
        uint256 followId
    );
    event Unfollow(
        address owner,
        uint256 follower,
        uint256 followee,
        address followNFT,
        uint256 followId
    );
    event OnNFTTransfer(
        address nftAddress,
        address from,
        uint256 fromProfileId,
        address to,
        uint256 toProfileId,
        uint256 tokenId
    );

    address private _followNFTBeacon;
    address private _profileNFT;
    address private _contentNFT;
    mapping(uint256 => address) private _followNFTs; // profileId => followNFT
    mapping(address => uint256) private _followNFTOwners; // followNFT => profileId
    // mapping(uint256 => mapping(uint256 => uint256)) private _indexedFollowees; //follower profileId => index => followee profileId
    // mapping(uint256 => mapping(uint256 => uint256)) private _followeesIndex; //follower profileId  => followee profileId => index
    // mapping(uint256 => uint256) private _numberFollowees; //profileId => number of followees
    mapping(uint256 => mapping(uint256 => uint256)) private _indexedContents; //profileId => index => Content NFT Tokens
    mapping(uint256 => uint256) private _numberContents; // profileId => number of ContentNFT Tokens

    function initialize(
        address admin,
        address profileNFT,
        address contentNFT,
        address followNFTBeacon
    ) external initializer {
        require(
            admin != address(0),
            "Controller: initialize admin with zero address"
        );
        require(
            profileNFT != address(0),
            "Controller: initialize followNFTFactory with zero address"
        );
        require(
            contentNFT != address(0),
            "Controller: initialize followNFTFactory with zero address"
        );
        require(
            followNFTBeacon != address(0),
            "Controller: initialize followNFTFactory with zero address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        PausableUpgradeable.__Pausable_init();
        _profileNFT = profileNFT;
        _contentNFT = contentNFT;
        _followNFTBeacon = followNFTBeacon;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Controller: only admin"
        );
        _;
    }

    function create(string memory uri) external whenNotPaused {
        require(
            IProfileNFT(_profileNFT).balanceOf(msg.sender) == 0,
            "Controller: profile exist"
        );
        uint256 profileId = IProfileNFT(_profileNFT).mint(msg.sender, uri);
        emit Create(msg.sender, profileId, uri);
    }

    function post(string memory uri) external whenNotPaused {
        uint256 profileId = IProfileNFT(_profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Controller: profile does not exist");
        uint256 tokenId = IContentNFT(_contentNFT).mint(msg.sender, uri);
        uint256 number = _numberContents[profileId]++;
        _indexedContents[profileId][number] = tokenId;
        emit Post(msg.sender, profileId, number, tokenId, uri);
    }

    function follow(uint256[] calldata profileIds) external whenNotPaused {
        uint256 profileId = IProfileNFT(_profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Controller: profile does not exist");
        for (uint256 i = 0; i < profileIds.length; ++i) {
            uint256 followee = profileIds[i];
            require(
                IProfileNFT(_profileNFT).ownerOf(followee) != address(0),
                "Controller: follower profile does not exist"
            );
            address followNFT = _followNFTs[followee];
            if (followNFT == address(0)) {
                bytes memory initializeData = abi.encodeWithSelector(
                    IFollowNFT.initialize.selector,
                    string(abi.encodePacked(followee, "-Follower")),
                    string(abi.encodePacked(followee, "-Fl")),
                    address(this)
                );
                followNFT = _deployFollowNFT(initializeData);
                _followNFTs[followee] = followNFT;
                _followNFTOwners[followNFT] = followee;
            }
            require(
                IFollowNFT(followNFT).balanceOf(msg.sender) == 0,
                "Controller: already following"
            );
            uint256 tokenId = IFollowNFT(followNFT).mint(msg.sender);
            emit Follow(msg.sender, profileId, followee, followNFT, tokenId);
        }
    }

    function unfollow(uint256[] calldata profileIds) external whenNotPaused {
        uint256 profileId = IProfileNFT(_profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Controller: profile does not exist");
        for (uint256 i = 0; i < profileIds.length; ++i) {
            uint256 followee = profileIds[i];
            require(
                IProfileNFT(_profileNFT).ownerOf(followee) != address(0),
                "Controller: follower profile does not exist"
            );
            address followNFT = _followNFTs[followee];
            require(
                IFollowNFT(followNFT).balanceOf(msg.sender) == 1,
                "Controller: not yet following"
            );
            uint256 tokenId = IFollowNFT(followNFT).tokenOfOwnerByIndex(
                msg.sender,
                0
            );
            IFollowNFT(followNFT).burn(msg.sender, tokenId);
            emit Unfollow(msg.sender, profileId, followee, followNFT, tokenId);
        }
    }

    function getContentsNumber(uint256 profileId)
        external
        view
        returns (uint256)
    {
        return _numberContents[profileId];
    }

    // function getFollowees(uint256 follower)
    //     external
    //     view
    //     returns (uint256[] memory)
    // {
    //     uint256 number = _numberFollowees[follower];
    //     uint256[] memory tokenIds = new uint256[](number);
    //     for (uint256 i = 0; i < number; ++i) {
    //         tokenIds[i] = _indexedFollowees[follower][i];
    //     }
    //     return tokenIds;
    // }

    function getContents(uint256 profileId)
        public
        view
        returns (uint256[] memory)
    {
        uint256 number = _numberContents[profileId];
        uint256[] memory tokenIds = new uint256[](number);
        for (uint256 i = 0; i < number; i++)
            tokenIds[i] = _indexedContents[profileId][i];
        return tokenIds;
    }

    function getProfileId(address owner) external view returns (uint256) {
        return IProfileNFT(_profileNFT).profileOf(owner);
    }

    function getProfileOwner(uint256 profileId)
        external
        view
        returns (address)
    {
        return IProfileNFT(_profileNFT).ownerOf(profileId);
    }

    function getFollowNFT(uint256 profileId) external view returns (address) {
        return _followNFTs[profileId];
    }

    function getContentNFT() external view returns (address) {
        return _contentNFT;
    }

    function getProfileNFT() external view returns (address) {
        return _profileNFT;
    }

    function onNFTTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(
            msg.sender == _profileNFT ||
                msg.sender == _contentNFT ||
                _followNFTOwners[msg.sender] != 0,
            "Controller: unknown sender"
        );

        if (msg.sender != _profileNFT && to != address(0)) {
            if (IProfileNFT(_profileNFT).balanceOf(to) == 0) {
                uint256 profileId = IProfileNFT(_profileNFT).mint(to, "");
                emit Create(to, profileId, "");
            }
        }
        emit OnNFTTransfer(
            msg.sender,
            from,
            IProfileNFT(_profileNFT).profileOf(from),
            to,
            IProfileNFT(_profileNFT).profileOf(to),
            tokenId
        );
    }

    function setFollowNFTURI(string calldata uri) external {
        uint256 profileId = IProfileNFT(_profileNFT).profileOf(msg.sender);
        require(profileId != 0, "Controller: profile does not exist");
        IFollowNFT(_followNFTs[profileId]).setURI(uri);
    }

    function setFollowNFTBeacon(address followNFTBeacon) external onlyAdmin {
        _followNFTBeacon = followNFTBeacon;
    }

    function getFollowNFTImpl() external view returns (address) {
        return IBeacon(_followNFTBeacon).implementation();
    }

    function getFollowNFTBeacon() external view returns (address) {
        return _followNFTBeacon;
    }

    function _deployFollowNFT(bytes memory data) internal returns (address) {
        return address(new BeaconProxy(_followNFTBeacon, data));
    }
}
