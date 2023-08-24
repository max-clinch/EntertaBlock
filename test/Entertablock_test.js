const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EntertaBlock Contract", function () {
  let EntertaBlock;
  let entertaBlock;
  let artist;
  let collaborator;
  let fan;
  let owner;
  const initialSupply = 1000000;

  beforeEach(async function () {
    EntertaBlock = await ethers.getContractFactory("EntertaBlock");
    entertaBlock = await EntertaBlock.deploy(initialSupply);
    await entertaBlock.deployed();
    [owner, artist, collaborator, fan] = await ethers.getSigners();
  });

  it("Should register an artist and update their profile", async function () {
    const emailAddress = "test@example.com";
    const password = "password";
    const firstName = "John";
    const lastName = "Doe";
    const stageName = "Artist1";

    await entertaBlock.registerArtist(emailAddress, password, firstName, lastName, stageName);

    const artistInfo = await entertaBlock.artists(owner.address);
    expect(artistInfo.isRegistered).to.equal(true);
    expect(artistInfo.emailAddress).to.equal(emailAddress);
    expect(artistInfo.password).to.equal(password);
    expect(artistInfo.firstName).to.equal(firstName);
    expect(artistInfo.lastName).to.equal(lastName);
    expect(artistInfo.stageName).to.equal(stageName);

    // Update artist's profile
    const newFirstName = "Jane";
    const newLastName = "Smith";
    await entertaBlock.updateArtist(newFirstName, newLastName);
    const updatedArtistInfo = await entertaBlock.artists(owner.address);
    expect(updatedArtistInfo.firstName).to.equal(newFirstName);
    expect(updatedArtistInfo.lastName).to.equal(newLastName);
  });

  it("Should create and update work metadata", async function () {
    const workName = "Artwork1";
    const releaseDate = "2023-08-25";
    const description = "A beautiful artwork.";
    const coverArtUrl = "https://example.com/artwork1.jpg";

    // Mint an NFT and set work metadata
    await entertaBlock.mintNFT(artist.address, workName, "");
    await entertaBlock.connect(artist).updateWorkMetadata(workName, releaseDate, description, coverArtUrl);

    // Retrieve and verify work metadata
    const metadata = await entertaBlock.getWorkMetadata(artist.address, workName);
    expect(metadata.releaseDate).to.equal(releaseDate);
    expect(metadata.description).to.equal(description);
    expect(metadata.coverArtUrl).to.equal(coverArtUrl);
  });

  it("Should handle ticket purchase and withdrawal", async function () {
    const eventName = "Concert1";
    const date = Math.floor(Date.now() / 1000) + 86400; // Tomorrow
    const ticketPrice = ethers.utils.parseEther("0.1");
    const ticketAmount = 3;

    // Schedule an event
    await entertaBlock.scheduleEvent(eventName, date, ticketPrice, [artist.address]);

    // Purchase tickets
    const totalCost = ticketPrice.mul(ticketAmount);
    await fan.sendTransaction({ to: entertaBlock.address, value: totalCost });
    await entertaBlock.connect(fan).purchaseTickets(0, ticketAmount);

    // Verify ticket purchase and withdrawal
    const fanBalanceBefore = await fan.getBalance();
    await entertaBlock.connect(fan).withdrawBalance();
    const fanBalanceAfter = await fan.getBalance();

    const eventDetails = await entertaBlock.getEventDetails(0);
    expect(eventDetails.ticketsSold[entertaBlock.address]).to.equal(ticketAmount);
    expect(fanBalanceAfter).to.be.above(fanBalanceBefore);
  });

  it("Should distribute royalties and create NFT after collaboration finalization", async function () {
    // Register artists
    const { address: artist1 } = artist;
    const { address: artist2 } = collaborator;
    await entertaBlock.registerArtist("artist1@example.com", "password", "Alice", "Johnson", "AliceArtist");
    await entertaBlock.connect(collaborator).registerArtist("artist2@example.com", "password", "Bob", "Smith", "BobArtist");

    // Create collaboration
    await entertaBlock.connect(artist).createCollaboration([artist1, artist2]);

    // Add contributions
    const collaborationId = await entertaBlock.collaborationIds(0);
    const contributionAmount = 200;
    await entertaBlock.connect(artist1).addContribution(collaborationId, contributionAmount);
    await entertaBlock.connect(artist2).addContribution(collaborationId, contributionAmount);

    // Finalize collaboration
    await entertaBlock.connect(artist).finalizeCollaboration(collaborationId);

    // Distribute royalties
    await entertaBlock.connect(artist).distributeRoyalties("Collaboration");

    // Check balances and NFT ownership
    const artist1Balance = await entertaBlock.balances(artist1);
    const artist2Balance = await entertaBlock.balances(artist2);
    const nftOwner = await entertaBlock.ownerOf(await entertaBlock.getWorkTokenId(artist1, "Collaboration"));
    expect(artist1Balance).to.be.above(0);
    expect(artist2Balance).to.be.above(0);
    expect(nftOwner).to.equal(artist1);
  });

  it("Should create usage agreement and approve it", async function () {
    // Register artists
    const { address: anotherArtist } = owner;
    await entertaBlock.connect(owner).registerArtist("anotherartist@example.com", "password", "Eve", "Miller", "EveArtist");

    // Create usage agreement
    const workName = "Artwork4";
    const paymentAmount = 300;
    await entertaBlock.connect(anotherArtist).createUsageAgreement(workName, artist.address, paymentAmount);

    // Approve usage agreement
    await entertaBlock.connect(artist).approveUsageAgreement(workName, anotherArtist);

    // Check usage agreement approval status
    const agreement = await entertaBlock.getUsageAgreement(workName, anotherArtist);
    expect(agreement.isApproved).to.equal(true);
  });


});
