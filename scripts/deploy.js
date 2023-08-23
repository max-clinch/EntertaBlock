
const { ethers, JsonRpcProvider } = require('ethers');

const { deploy } = require("hardhat-deploy");


async function main() {
  const ArtistToken = await ethers.getContractFactory("ArtistToken");
  const artistToken = await ArtistToken.deploy();
  await artistToken.deployed();

  const provider = new JsonRpcProvider('https://goerli.base.org'); // add your rpc server url from Ganache


  console.log("ArtistToken deployed to:", artistToken.address);

  const EntertaBlock = await ethers.getContractFactory("EntertaBlock");
  const entertaBlock = await EntertaBlock.deploy(artistToken.address);
  await entertaBlock.deployed();

  console.log("EntertaBlock deployed to:", entertaBlock.address);

  // Set the EntertaBlock address in the ArtistToken contract
  await artistToken.setEntertaBlock(entertaBlock.address);

  console.log("EntertaBlock address set in ArtistToken contract");

  console.log("Deployment completed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});

