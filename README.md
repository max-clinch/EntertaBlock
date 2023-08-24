# EntertaBlock Smart Contract Documentation

## Overview

EntertaBlock is a smart contract developed on the Base blockchain for managing artists, their works, collaborations, events, and usage agreements in the entertainment industry. It allows registered artists to mint and manage their NFTs, schedule events, distribute royalties, and establish usage agreements with licensees.
EntertaBlock isn't merely a decentralized application; it's a paradigm shift in how the entertainment industry operates. By harnessing the capabilities of blockchain, EntertaBlock introduces transparency, security, and efficiency into various facets of the entertainment landscape. It's a platform that empowers artists, creators, collaborators, and event organizers with a comprehensive suite of tools, ultimately reshaping the way artists are managed and how their creations are valued.

##  Overview
ArtistToken is an ERC20 token contract that serves as the official token for EntertaBlock. It is used to facilitate transactions, rewards, and interactions within the EntertaBlock ecosystem.

## Table of Contents

- [Contract Structure](#contract-structure)
- [Modifiers](#modifiers)
- [Functions](#functions)
- [Utility Functions](#utility-functions)
- [Events](#events)
- [Data Structures](#data-structures)

## Contract Structure

The EntertaBlock smart contract is built on top of the OpenZeppelin ERC721URIStorage contract and contains additional functionality to support artist management, collaboration, event scheduling, royalty distribution, and usage agreements.

## Modifiers

- `onlyRegisteredArtist`: Ensures that the sender is a registered artist within the contract.
- `onlyCollaborator(bytes32 collaborationId)`: Ensures that the sender is a collaborator of a specified collaboration.
- `onlyPerformer(bytes32 eventId)`: Ensures that the sender is a performer for a specified event.

## Functions

The EntertaBlock contract provides various functions for artist registration, work management, collaboration, event scheduling, royalty distribution, and usage agreements. Here are some of the key functions:

- `registerWork(string memory work, string memory tokenUri)`: Allows a registered artist to register their work by minting an NFT and specifying its metadata.
- `verifyArtistPassword(string memory password)`: Verifies the password of a registered artist.
- `registerArtist(...)`: Registers a new artist with their personal details.
- `updateArtist(string memory firstName, string memory lastName)`: Updates the first name and last name of a registered artist.
- `receiveRoyalties()`: Allows artists to receive royalties and update their balances.
- `withdrawBalance()`: Allows artists to withdraw their accumulated balances.
- `setWorkRoyalty(string memory work, uint256 royaltyPercentage)`: Sets the royalty percentage for a specific work.
- `mintNFT(...)`: Internal function to mint an NFT for a specific work.
- `finalizeCollaboration(bytes32 collaborationId)`: Finalizes a collaboration, distributing royalties to collaborators.
- `scheduleEvent(...)`: Schedules an event with specified details and performers.
- `purchaseTickets(...)`: Allows users to purchase tickets for an event.
- `finalizeEvent(bytes32 eventId)`: Finalizes an event, distributing earnings to performers.
- `createUsageAgreement(...)`: Creates a usage agreement for a work between an artist and a licensee.
- `approveUsageAgreement(...)`: Approves a usage agreement for a work.
- `distributeRoyalties(string memory work)`: Distributes remaining royalties to the artist and mints an NFT.

## Utility Functions

The contract also provides several utility functions for retrieving information:

- `getRegisteredArtistsCount()`: Returns the count of registered artists.
- `getRegisteredArtistAtIndex(uint256 index)`: Returns the registered artist address at a specified index.
- `getArtistWorksCount(address artist)`: Returns the count of works registered by a specific artist.
- `getArtistWorkAtIndex(address artist, uint256 index)`: Returns the work name registered by a specific artist at a specified index.
- `getWorkTokenId(address artist, string memory work)`: Returns the token ID of an NFT associated with a specific work.
- `getWorkTokenUri(uint256 tokenId)`: Returns the token URI of an NFT with a specific token ID.
- `getWorkMetadata(...)`: Returns metadata for a specific work.

## Events

The EntertaBlock contract emits various events to notify actions taken within the contract, including:

- `ArtistRegistered(...)`: Triggered when an artist is registered.
- `WorkRegistered(...)`: Triggered when an artist registers a new work.
- `CollaborationCreated(...)`: Triggered when a collaboration is created.
- `ContributionAdded(...)`: Triggered when a contribution is added to a collaboration.
- `CollaborationFinalized(...)`: Triggered when a collaboration is finalized.
- `EventScheduled(...)`: Triggered when an event is scheduled.
- `TicketsPurchased(...)`: Triggered when tickets are purchased for an event.
- `EventFinalized(...)`: Triggered when an event is finalized.
- `AgreementCreated(...)`: Triggered when a usage agreement is created.
- `AgreementApproved(...)`: Triggered when a usage agreement is approved.
- `RoyaltiesDistributed(...)`: Triggered when royalties are distributed.

## Data Structures

The EntertaBlock contract defines several data structures to manage artists, works, collaborations, events, usage agreements, and work metadata. Some key data structures include:

- `struct Artist`: Represents an artist with various details.
- `struct Collaboration`: Represents a collaboration between artists.
- `struct Event`: Represents an entertainment event with details and performers.
- `struct UsageAgreement`: Represents a usage agreement between an artist and a licensee.
- `struct WorkMetadata`: Represents metadata associated with a specific work.

## Conclusion

The EntertaBlock smart contract provides a comprehensive solution for managing various aspects of the entertainment industry, including artist registration, work management, collaboration, event scheduling, royalty distribution, and usage agreements. With its well-defined functions, modifiers, and events, EntertaBlock offers transparency and flexibility for artists and stakeholders in the entertainment ecosystem.


# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
