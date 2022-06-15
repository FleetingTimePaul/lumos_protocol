const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("Token contract", function () {
    before(async function () {

        const [owner1, owner2, owner3, owner4, owner5] = await ethers.getSigners();

        var FollowNFT = await ethers.getContractFactory("FollowNFT");
        var ProfileNFT = await ethers.getContractFactory("ProfileNFT");
        var ContentNFT = await ethers.getContractFactory("ContentNFT");
        var Controller = await ethers.getContractFactory("Controller");

        var followNFTImpl = await FollowNFT.deploy();
        await followNFTImpl.deployed();
        console.log("deploy followNFTImpl at: ", followNFTImpl.address);

        // var followNFTBeacon = await UpgradeableBeacon.deploy(followNFTImpl.address);
        var followNFTBeacon = await upgrades.deployBeacon(FollowNFT);
        await followNFTBeacon.deployed();
        console.log("deploy followNFTBeacon at: ", followNFTBeacon.address);

        var controller = await upgrades.deployProxy(Controller, [], {
            initializer: false,
        });
        await controller.deployed();
        console.log("deploy controller at: ", controller.address);

        var profileNFTProxy = await upgrades.deployProxy(ProfileNFT, ["Profile NFT", "ProfileNFT", controller.address]);
        await profileNFTProxy.deployed();
        console.log("deploy ProfileNFT at: ", profileNFTProxy.address);
        var contentNFTProxy = await upgrades.deployProxy(ContentNFT, ["Content NFT", "ContentNFT", controller.address]);
        await contentNFTProxy.deployed();
        console.log("deploy ContentNFT at: ", contentNFTProxy.address);

        await controller.initialize(owner1.address, profileNFTProxy.address, contentNFTProxy.address, followNFTBeacon.address);

        this.controller = controller;
        this.profileNFT = profileNFTProxy;
        this.contentNFT = contentNFTProxy;

        this.owner1 = owner1;
        this.owner2 = owner2;
        this.owner3 = owner3;
        this.owner4 = owner4;
        this.owner5 = owner5;
    });

    beforeEach(async function () {});

    it("create profiles", async function () {
        await this.controller.connect(this.owner1).create("Owner1 profile URI");
        expect(await this.profileNFT.balanceOf(this.owner1.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner1.address)).to.equal(1); //profile id: 1
        expect(await this.profileNFT.ownerOf(1)).to.equal(this.owner1.address); 

        await this.controller.connect(this.owner2).create("Owner2 profile URI");
        expect(await this.profileNFT.balanceOf(this.owner2.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner2.address)).to.equal(2); //profile id: 2
        expect(await this.profileNFT.ownerOf(2)).to.equal(this.owner2.address); 

        await this.controller.connect(this.owner3).create("Owner3 profile URI");
        expect(await this.profileNFT.balanceOf(this.owner3.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner3.address)).to.equal(3); //profile id: 3
        expect(await this.profileNFT.ownerOf(3)).to.equal(this.owner3.address); 

        try {
            await this.controller.connect(this.owner3).create("Owner3 profile URI",);
        }
        catch (err) {
            console.error(err.message);
        }
    });

    it("profiles transfer", async function () {
        await this.profileNFT.connect(this.owner1)['safeTransferFrom(address,address,uint256)'](this.owner1.address, this.owner4.address, 1);
        expect(await this.profileNFT.balanceOf(this.owner1.address)).to.equal(0);
        expect(await this.profileNFT.balanceOf(this.owner4.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner4.address)).to.equal(1); //profile id: 1
        expect(await this.profileNFT.ownerOf(1)).to.equal(this.owner4.address); 

        try {
            await this.profileNFT.connect(this.owner2)['safeTransferFrom(address,address,uint256)'](this.owner2.address, this.owner4.address, 2);
        }
        catch (err) {
            console.error(err.message);
        }
    });

    it("contentNFT create", async function () {
        await this.controller.connect(this.owner4).post("owner4 contentNFT1 URL");
        expect(await this.contentNFT.balanceOf(this.owner4.address)).to.equal(1);
        expect(await this.contentNFT.ownerOf(1)).to.equal(this.owner4.address); 

        await this.controller.connect(this.owner4).post("owner4 contentNFT2 URL");
        expect(await this.contentNFT.balanceOf(this.owner4.address)).to.equal(2);
        expect(await this.contentNFT.ownerOf(2)).to.equal(this.owner4.address); 
    });

    it("contentNFT transfer", async function () {
        await this.profileNFT.connect(this.owner4)['safeTransferFrom(address,address,uint256)'](this.owner4.address, this.owner1.address, 1);

        expect(await this.profileNFT.balanceOf(this.owner1.address)).to.equal(1);
        expect(await this.profileNFT.balanceOf(this.owner4.address)).to.equal(0);
        expect(await this.profileNFT.profileOf(this.owner1.address)).to.equal(1); 
        expect(await this.profileNFT.ownerOf(1)).to.equal(this.owner1.address); 

        expect(await this.contentNFT.balanceOf(this.owner1.address)).to.equal(2);
        expect(await this.contentNFT.ownerOf(1)).to.equal(this.owner1.address); 
        expect(await this.contentNFT.ownerOf(2)).to.equal(this.owner1.address); 

        await this.contentNFT.connect(this.owner1)['safeTransferFrom(address,address,uint256)'](this.owner1.address, this.owner2.address, 2);

        expect(await this.contentNFT.balanceOf(this.owner2.address)).to.equal(1);
        expect(await this.contentNFT.ownerOf(2)).to.equal(this.owner2.address); 

        await this.contentNFT.connect(this.owner1)['safeTransferFrom(address,address,uint256)'](this.owner1.address, this.owner4.address, 1);

        expect(await this.contentNFT.balanceOf(this.owner4.address)).to.equal(1);
        expect(await this.contentNFT.ownerOf(1)).to.equal(this.owner4.address); 

        expect(await this.profileNFT.balanceOf(this.owner4.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner4.address)).to.equal(4); 
        expect(await this.profileNFT.ownerOf(4)).to.equal(this.owner4.address); 
        expect(await this.profileNFT.balanceOf(this.owner1.address)).to.equal(1); 
    })

    it("followNFT create", async function () {
        const profileIdOfOwner1 = await this.profileNFT.profileOf(this.owner1.address);
        await this.controller.connect(this.owner3).follow([profileIdOfOwner1]);
        await this.controller.connect(this.owner4).follow([profileIdOfOwner1]);
        const followNFT1 = await ethers.getContractAt("FollowNFT", await this.controller.getFollowNFT(profileIdOfOwner1)); 
        expect(await followNFT1.balanceOf(this.owner3.address)).to.equal(1);
        expect(await followNFT1.balanceOf(this.owner4.address)).to.equal(1); 
        expect(await followNFT1.ownerOf(1)).to.equal(this.owner3.address);
        expect(await followNFT1.ownerOf(2)).to.equal(this.owner4.address); 
    });

    it("followNFT burn", async function () {
        const profileIdOfOwner1 = await this.profileNFT.profileOf(this.owner1.address);
        await this.controller.connect(this.owner3).unfollow([profileIdOfOwner1]);
        const followNFT1 = await ethers.getContractAt("FollowNFT", await this.controller.getFollowNFT(profileIdOfOwner1)); 
        expect(await followNFT1.balanceOf(this.owner3.address)).to.equal(0);
        expect(await followNFT1.balanceOf(this.owner4.address)).to.equal(1);
        expect(await followNFT1.tokenOfOwnerByIndex(this.owner4.address, 0)).to.equal(2);
    });

    it("followNFT transfer", async function () {
        const profileIdOfOwner1 = await this.profileNFT.profileOf(this.owner1.address);
        const followNFT1 = await ethers.getContractAt("FollowNFT", await this.controller.getFollowNFT(profileIdOfOwner1)); 
        followNFT1.connect(this.owner4)['safeTransferFrom(address,address,uint256)'](this.owner4.address, this.owner5.address, 2);
        expect(await followNFT1.tokenOfOwnerByIndex(this.owner5.address, 0)).to.equal(2);
    });

    it("setFollowNFTURI", async function () {
        const profileIdOfOwner1 = await this.profileNFT.profileOf(this.owner1.address);
        const followNFT1 = await ethers.getContractAt("FollowNFT", await this.controller.getFollowNFT(profileIdOfOwner1)); 
        expect(await followNFT1.tokenURI(2)).to.equal("");
        await this.controller.connect(this.owner1).setFollowNFTURI("profileIdOfOwner1 followNFT URI");
        expect(await followNFT1.tokenURI(2)).to.equal("profileIdOfOwner1 followNFT URI");

        try {
            await this.controller.connect(this.owner4).setFollowNFTURI("profileIdOfOwner1 followNFT URI");
        }
        catch (err) {
            console.error(err.message);
        }
    });
});
