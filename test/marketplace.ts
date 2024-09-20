import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("Marketplace", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployNftMarketplace() {
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const Lock = await hre.ethers.getContractFactory("NFTMarketplace");
    const NFTMarketplace = await Lock.deploy(owner);

    return { NFTMarketplace, owner };
  }


  describe("Deployment", function () {
    it("Should mint new token with token 1", async function () {
      const { NFTMarketplace, owner } = await loadFixture(deployNftMarketplace);

      const uri = "https://lavender-electric-gerbil-466.mypinata.cloud/ipfs/Qmaz3L8dtMxR3k1B8wauqZe5riv7xUFanQxMp2AkJz3V34";

      const newNFt = await NFTMarketplace.mint(uri)
      expect(newNFt).to.emit(NFTMarketplace, "NFTMinted").withArgs(owner.address, 1, uri);
      expect(await NFTMarketplace._tokenIds()).to.equal(1);
    });

    it("Should List new created NFT", async function () {
      const { NFTMarketplace, owner } = await loadFixture(deployNftMarketplace);

      const uri = "https://lavender-electric-gerbil-466.mypinata.cloud/ipfs/Qmaz3L8dtMxR3k1B8wauqZe5riv7xUFanQxMp2AkJz3V34";

      const newNFt = await NFTMarketplace.mint(uri)


      const newListing = await NFTMarketplace.listNFT(1, 1000); 

      expect(newListing).to.emit(NFTMarketplace, "NFTListed").withArgs(1, 1000);
    });

    it("Should List new created NFT", async function () {
      const { NFTMarketplace, owner } = await loadFixture(deployNftMarketplace);
      const uri = "https://lavender-electric-gerbil-466.mypinata.cloud/ipfs/Qmaz3L8dtMxR3k1B8wauqZe5riv7xUFanQxMp2AkJz3V34";
      const newNFt = await NFTMarketplace.mint(uri)
     
      const newListing = await NFTMarketplace.listNFT(1, 1000); 



      expect(newListing).to.emit(NFTMarketplace, "NFTListed").withArgs(1, 1000);
    });
    it("Should cancel new Listed NFT", async function () {
      const { NFTMarketplace, owner } = await loadFixture(deployNftMarketplace);
      const uri = "https://lavender-electric-gerbil-466.mypinata.cloud/ipfs/Qmaz3L8dtMxR3k1B8wauqZe5riv7xUFanQxMp2AkJz3V34";
      const newNFt = await NFTMarketplace.mint(uri)
      const newListing = await NFTMarketplace.listNFT(1, hre.ethers.parseEther("1000")); 
      

     
      const cancelListing = await NFTMarketplace.connect(owner).cancelListing(1); 

      expect(cancelListing).to.emit(NFTMarketplace, "NFTListingCancelled").withArgs(1, owner);
    });
    it("A buyer should make an offer on List Nft", async function () {
      const { NFTMarketplace, owner } = await loadFixture(deployNftMarketplace);
      const uri = "https://lavender-electric-gerbil-466.mypinata.cloud/ipfs/Qmaz3L8dtMxR3k1B8wauqZe5riv7xUFanQxMp2AkJz3V34";
      const newNFt = await NFTMarketplace.mint(uri)
      const newListing = await NFTMarketplace.listNFT(1, hre.ethers.parseEther("1000")); 
      const cancelListing = await NFTMarketplace.connect(owner).cancelListing(1); 


      expect(cancelListing).to.emit(NFTMarketplace, "NFTListingCancelled").withArgs(1, owner);
    });
    
    
  });

  // describe("Marketplace", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

     
  //     });
  //   });

});
