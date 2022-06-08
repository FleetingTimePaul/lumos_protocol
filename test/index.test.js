const { expect, assert } = require("chai");

describe("Token contract", function () {
    before(async function () {

        const [owner1, owner2, owner3, owner4, owner5] = await ethers.getSigners();

        var FollowNFT = await ethers.getContractFactory("FollowNFT");
        var ProfileNFT = await ethers.getContractFactory("ProfileNFT");
        var ContentNFT = await ethers.getContractFactory("ContentNFT");
        var Lumos = await ethers.getContractFactory("Lumos");
        var Factory = await ethers.getContractFactory("Factory");

        var followNFTImpl = await FollowNFT.deploy();
        await followNFTImpl.deployed();
        console.log("deploy followNFTImpl at: ", followNFTImpl.address);

        var profileNFTImpl = await ProfileNFT.deploy();
        await profileNFTImpl.deployed();
        console.log("deploy profileNFTImpl at: ", profileNFTImpl.address);

        var contentNFTImpl = await ContentNFT.deploy();
        await contentNFTImpl.deployed();
        console.log("deploy contentNFTImpl at: ", contentNFTImpl.address);

        var lumos = await upgrades.deployProxy(Lumos, [], {
            initializer: false,
        });
        await lumos.deployed();
        console.log("deploy lumos at: ", lumos.address);
        var factory = await upgrades.deployProxy(Factory, [
            owner1.address,
            lumos.address,
            followNFTImpl.address,
            contentNFTImpl.address,
            profileNFTImpl.address,
        ]);

        await factory.deployed();
        console.log("deploy factory at: ", factory.address);

        var contentNFTInitializeData = web3.eth.abi.encodeFunctionCall(
            {
                inputs: [
                    {
                        internalType: "string",
                        name: "_name",
                        type: "string",
                    },
                    {
                        internalType: "string",
                        name: "_symbol",
                        type: "string",
                    },
                    {
                        internalType: "address",
                        name: "_lumos",
                        type: "address",
                    },
                ],
                name: "initialize",
                outputs: [],
                stateMutability: "nonpayable",
                type: "function",
            },
            ["Lumos Content NFT", "LCN", lumos.address]
        );

        var profileNFTInitializeData = web3.eth.abi.encodeFunctionCall(
            {
                inputs: [
                    {
                        internalType: "string",
                        name: "_name",
                        type: "string",
                    },
                    {
                        internalType: "string",
                        name: "_symbol",
                        type: "string",
                    },
                    {
                        internalType: "address",
                        name: "_lumos",
                        type: "address",
                    },
                ],
                name: "initialize",
                outputs: [],
                stateMutability: "nonpayable",
                type: "function",
            },
            ["Lumos Profile NFT", "LPN", lumos.address]
        );
        await lumos.initialize(
            owner1.address,
            factory.address,
            profileNFTInitializeData,
            contentNFTInitializeData
        );

        this.factory = factory;
        this.lumos = lumos;
        this.profileNFT = await ethers.getContractAt("ProfileNFT", await this.lumos.profileNFT());
        this.contentNFT = await ethers.getContractAt("ContentNFT", await this.lumos.contentNFT());

        this.owner1 = owner1;
        this.owner2 = owner2;
        this.owner3 = owner3;
        this.owner4 = owner4;
        this.owner5 = owner5;

    });

    beforeEach(async function () {});

    it("create profiles", async function () {
        await this.lumos.connect(this.owner1).create("Owner1 profile URI");
        expect(await this.profileNFT.balanceOf(this.owner1.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner1.address)).to.equal(1); //profile id: 1
        expect(await this.profileNFT.ownerOf(1)).to.equal(this.owner1.address); 

        await this.lumos.connect(this.owner2).create("Owner2 profile URI");
        expect(await this.profileNFT.balanceOf(this.owner2.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner2.address)).to.equal(2); //profile id: 2
        expect(await this.profileNFT.ownerOf(2)).to.equal(this.owner2.address); 

        await this.lumos.connect(this.owner3).create("Owner3 profile URI");
        expect(await this.profileNFT.balanceOf(this.owner3.address)).to.equal(1);
        expect(await this.profileNFT.profileOf(this.owner3.address)).to.equal(3); //profile id: 3
        expect(await this.profileNFT.ownerOf(3)).to.equal(this.owner3.address); 

        try {
            await this.lumos.connect(this.owner3).create("Owner3 profile URI",);
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
        await this.lumos.connect(this.owner4).post("owner4 contentNFT1 URL");
        expect(await this.contentNFT.balanceOf(this.owner4.address)).to.equal(1);
        expect(await this.contentNFT.ownerOf(1)).to.equal(this.owner4.address); 

        await this.lumos.connect(this.owner4).post("owner4 contentNFT2 URL");
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
    })

    it("followNFT create", async function () {
        const profileIdOfOwner1 = await this.profileNFT.profileOf(this.owner1.address);
        await this.lumos.connect(this.owner4).follow([profileIdOfOwner1]);
        const followNFT1 = await ethers.getContractAt("FollowNFT", await this.lumos.getFollowNFT(profileIdOfOwner1)); 
        expect(await followNFT1.balanceOf(this.owner4.address)).to.equal(1);
        expect(await followNFT1.ownerOf(1)).to.equal(this.owner4.address); 
    });

    it("setFollowNFTURI", async function () {
        const profileIdOfOwner1 = await this.profileNFT.profileOf(this.owner1.address);
        const followNFT1 = await ethers.getContractAt("FollowNFT", await this.lumos.getFollowNFT(profileIdOfOwner1)); 
        expect(await followNFT1.tokenURI(1)).to.equal("");
        await this.lumos.connect(this.owner1).setFollowNFTURI("profileIdOfOwner1 followNFT URI");
        expect(await followNFT1.tokenURI(1)).to.equal("profileIdOfOwner1 followNFT URI");

        try {
            await this.lumos.connect(this.owner4).setFollowNFTURI("profileIdOfOwner1 followNFT URI");
        }
        catch (err) {
            console.error(err.message);
        }
        
    });
});
