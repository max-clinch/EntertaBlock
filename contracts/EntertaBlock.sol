// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "@openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ArtistToken.sol";

contract EntertaBlock is ERC721URIStorage {
    ArtistToken public artistToken;
    struct Artist {
        bool isRegistered;
        string emailAddress;
        string password; // Add this field
        string firstName;
        string lastName;
        string stageName;
        uint256 totalRoyalties;
    }
    // Internal counter for generating unique token IDs
    uint256 private tokenCounter;

    struct Collaboration {
        address[] collaborators;
        uint256 totalContributions;
        uint256 totalRoyalties;
        bool isFinalized;
        mapping(address => uint256) contributions;
    }

    struct Event {
        string name;
        uint256 date;
        uint256 ticketPrice;
        uint256 totalEarnings;
        mapping(address => uint256) contributions;
        mapping(address => uint256) ticketsSold;
        address[] performers;
        bool isFinalized;
    }

    struct UsageAgreement {
        address licensee;
        uint256 paymentAmount;
        bool isApproved;
    }

    struct WorkMetadata {
        uint256 tokenId;
        string releaseDate;
        string description;
        string coverArtUrl;
    }

    mapping(address => Artist) public artists;
    mapping(address => mapping(string => WorkMetadata)) public workMetadata;
    mapping(address => uint256) public balances;
    mapping(address => string[]) public artistWorks;
    mapping(address => string) public artistAgreements;
    mapping(string => uint256) public workRoyalties;
    mapping(bytes32 => Collaboration) public collaborations;
    mapping(bytes32 => Event) public events;
    mapping(string => UsageAgreement[]) public workUsageAgreements;

    bytes32[] public collaborationIds; // Track collaboration IDs
    address[] public registeredArtists;

    event ArtistRegistered(
        address indexed artistAddress,
        string name,
        string genre
    );
    event WorkRegistered(address indexed artistAddress, string work);
    event ArtistAgreementSet(
        address indexed artistAddress,
        string agreementHash
    );
    event CollaborationCreated(
        bytes32 indexed collaborationId,
        address[] collaborators
    );
    event ContributionAdded(
        bytes32 indexed collaborationId,
        address contributor,
        uint256 contributionAmount
    );
    event CollaborationFinalized(bytes32 indexed collaborationId);
    event EventScheduled(
        bytes32 indexed eventId,
        string name,
        uint256 date,
        uint256 ticketPrice,
        address[] performers
    );
    event TicketsPurchased(
        bytes32 indexed eventId,
        address buyer,
        uint256 amount
    );
    event EventFinalized(bytes32 indexed eventId, uint256 totalEarnings);
    event AgreementCreated(
        string indexed work,
        address licensee,
        uint256 paymentAmount
    );
    event AgreementApproved(string indexed work, address licensee);

    modifier onlyRegisteredArtist() {
        require(
            bytes(artists[msg.sender].emailAddress).length != 0,
            "Artist not registered"
        );
        _;
    }

    modifier onlyCollaborator(bytes32 collaborationId) {
        require(
            collaborations[collaborationId].isFinalized == false,
            "Collaboration is finalized"
        );
        bool foundCollaborator = false;
        for (
            uint256 i = 0;
            i < collaborations[collaborationId].collaborators.length;
            i++
        ) {
            if (
                collaborations[collaborationId].collaborators[i] == msg.sender
            ) {
                foundCollaborator = true;
                break;
            }
        }
        require(foundCollaborator, "You are not a collaborator");
        _;
    }

    modifier onlyPerformer(bytes32 eventId) {
        bool isPerformer = false;
        for (uint256 i = 0; i < events[eventId].performers.length; i++) {
            if (events[eventId].performers[i] == msg.sender) {
                isPerformer = true;
                break;
            }
        }
        require(isPerformer, "You are not a performer for this event");
        _;
    }

    constructor(uint256 initialSupply) ERC721("ArtistManagement", "EB") {
        artistToken = new ArtistToken(initialSupply);

        // Initialize the contract with an empty array
        collaborationIds = new bytes32[](0);
    }

    function registerWork(string memory work, string memory tokenUri)
        public
        onlyRegisteredArtist
    {
        artistWorks[msg.sender].push(work);
        emit WorkRegistered(msg.sender, work);

        // Mint an NFT for the work
        mintNFT(msg.sender, work, tokenUri);
    }

    function verifyArtistPassword(string memory password)
        public
        view
        returns (bool)
    {
        return
            keccak256(bytes(artists[msg.sender].password)) ==
            keccak256(bytes(password));
    }

    // Register an artist
    function registerArtist(
        string memory emailAddress,
        string memory password,
        string memory firstName,
        string memory lastName,
        string memory stageName
    ) public {
        require(!artists[msg.sender].isRegistered, "Artist already registered");
        artists[msg.sender] = Artist({
            isRegistered: true, // Set the flag to true
            password: password, // Store the password
            emailAddress: emailAddress,
            firstName: firstName,
            lastName: lastName,
            stageName: stageName,
            totalRoyalties: 0
        });
        registeredArtists.push(msg.sender);
        emit ArtistRegistered(msg.sender, firstName, stageName);
    }

    function updateArtist(string memory firstName, string memory lastName)
        public
        onlyRegisteredArtist
    {
        artists[msg.sender].firstName = firstName;
        artists[msg.sender].lastName = lastName;
    }

    function receiveRoyalties() public payable {
        require(
            bytes(artists[msg.sender].emailAddress).length != 0,
            "Artist not registered"
        );
        artists[msg.sender].totalRoyalties += msg.value;
        balances[msg.sender] += msg.value;
    }

    function withdrawBalance() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance available");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    
    function setWorkRoyalty(string memory work, uint256 royaltyPercentage)
        public
        onlyRegisteredArtist
    {
        require(
            royaltyPercentage <= 100,
            "Royalty percentage should be <= 100"
        );
        workRoyalties[work] = royaltyPercentage;
    }

    
    function mintNFT(
        address artist,
        string memory work,
        string memory tokenUri
    ) internal {
        uint256 tokenId = tokenCounter;
        tokenCounter++;

        _mint(artist, tokenId);
        _setTokenURI(tokenId, tokenUri); // Use _setTokenURI to set the token URI
        workMetadata[artist][work].tokenId = tokenId;
    }

    function getWorkTokenId(address artist, string memory work)
        public
        view
        returns (uint256)
    {
        return workMetadata[artist][work].tokenId;
    }

    function getWorkTokenUri(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return tokenURI(tokenId);
    }

    function totalRoyaltiesClaimed(string memory work)
        internal
        view
        returns (uint256)
    {
        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < registeredArtists.length; i++) {
            address artistAddress = registeredArtists[i];
            totalClaimed +=
                (artists[artistAddress].totalRoyalties * workRoyalties[work]) /
                100;
        }
        return totalClaimed;
    }

    function setArtistAgreement(string memory agreementHash)
        public
        onlyRegisteredArtist
    {
        artistAgreements[msg.sender] = agreementHash;
        emit ArtistAgreementSet(msg.sender, agreementHash);
    }

    function createCollaboration(address[] memory collaborators)
        public
        onlyRegisteredArtist
    {
        bytes32 collaborationId = keccak256(
            abi.encodePacked(collaborators, block.timestamp)
        );
        require(
            collaborations[collaborationId].collaborators.length == 0,
            "Collaboration already exists"
        );

        collaborations[collaborationId].collaborators = collaborators;
        collaborationIds.push(collaborationId); // Add the collaboration ID to the list
        emit CollaborationCreated(collaborationId, collaborators);
    }

    function addContribution(bytes32 collaborationId, uint256 amount)
        public
        onlyCollaborator(collaborationId)
    {
        collaborations[collaborationId].totalContributions += amount;
        events[collaborationId].contributions[msg.sender] += amount;
        balances[msg.sender] -= amount;
        emit ContributionAdded(collaborationId, msg.sender, amount);
    }

    function removeCollaborator(bytes32 collaborationId) public {
        require(
            collaborations[collaborationId].isFinalized == false,
            "Collaboration is finalized"
        );

        Collaboration storage collaboration = collaborations[collaborationId];
        for (uint256 i = 0; i < collaboration.collaborators.length; i++) {
            if (collaboration.collaborators[i] == msg.sender) {
                // Remove the collaborator from the array
                collaboration.collaborators[i] = collaboration.collaborators[
                    collaboration.collaborators.length - 1
                ];
                collaboration.collaborators.pop();
                break;
            }
        }

        // Transfer the collaborator's contributions back to their balance
        uint256 contributorContribution = collaboration.contributions[
            msg.sender
        ];
        balances[msg.sender] += contributorContribution;
        collaboration.totalContributions -= contributorContribution;
        collaboration.contributions[msg.sender] = 0;

        emit CollaboratorRemoved(collaborationId, msg.sender);
    }

    event CollaboratorRemoved(bytes32 collaborationId, address collaborator);
    event PerformerRemoved(bytes32 eventId, address performer);

    function removePerformer(bytes32 eventId) public {
        Event storage eventDetails = events[eventId];
        require(!eventDetails.isFinalized, "Event is already finalized");

        int256 performerIndex = findPerformerIndex(eventId, msg.sender);
        require(performerIndex >= 0, "You are not a performer for this event");

        // Remove the performer from the array
        uint256 lastIndex = eventDetails.performers.length - 1;
        address lastPerformer = eventDetails.performers[lastIndex];
        eventDetails.performers[uint256(performerIndex)] = lastPerformer;
        eventDetails.performers.pop();

        emit PerformerRemoved(eventId, msg.sender);
    }

    event WorkMetadataUpdated(address indexed artist, string work);

    function updateWorkMetadata(
        string memory work,
        string memory releaseDate,
        string memory description,
        string memory coverArtUrl
    ) public onlyRegisteredArtist {
        require(bytes(releaseDate).length > 0, "Release date is required");

        WorkMetadata storage metadata = workMetadata[msg.sender][work];
        require(metadata.tokenId != 0, "Work not found");

        metadata.releaseDate = releaseDate;
        metadata.description = description;
        metadata.coverArtUrl = coverArtUrl;

        emit WorkMetadataUpdated(msg.sender, work);
    }

    function finalizeCollaboration(bytes32 collaborationId)
        public
        onlyCollaborator(collaborationId)
    {
        collaborations[collaborationId].isFinalized = true;

        uint256 totalContributions = collaborations[collaborationId]
            .totalContributions;
        uint256 totalRoyalties = collaborations[collaborationId].totalRoyalties;

        for (
            uint256 i = 0;
            i < collaborations[collaborationId].collaborators.length;
            i++
        ) {
            address collaborator = collaborations[collaborationId]
                .collaborators[i];
            uint256 contribution = events[collaborationId].contributions[
                collaborator
            ];
            uint256 collaboratorRoyalties = (contribution * totalRoyalties) /
                totalContributions;
            balances[collaborator] += collaboratorRoyalties;
        }

        emit CollaborationFinalized(collaborationId);
    }

    function scheduleEvent(
        string memory name,
        uint256 date,
        uint256 ticketPrice,
        address[] memory performers
    ) public onlyRegisteredArtist {
        bytes32 eventId = keccak256(
            abi.encodePacked(name, date, block.timestamp)
        );
        require(
            events[eventId].performers.length == 0,
            "Event already scheduled"
        );

        events[eventId].name = name;
        events[eventId].date = date;
        events[eventId].ticketPrice = ticketPrice;
        events[eventId].totalEarnings = 0;
        events[eventId].performers = performers;
        events[eventId].isFinalized = false;

        emit EventScheduled(eventId, name, date, ticketPrice, performers);
    }

    function purchaseTickets(bytes32 eventId, uint256 amount) public payable {
        Event storage eventDetails = events[eventId];
        require(eventDetails.performers.length > 0, "Event not found");
        require(
            msg.value >= eventDetails.ticketPrice * amount,
            "Insufficient payment"
        );
        require(amount > 0, "Amount must be greater than zero");

        eventDetails.ticketsSold[msg.sender] += amount;
        eventDetails.totalEarnings += eventDetails.ticketPrice * amount;

        if (msg.value > eventDetails.ticketPrice * amount) {
            uint256 refundAmount = msg.value -
                eventDetails.ticketPrice *
                amount;
            payable(msg.sender).transfer(refundAmount);
        }

        emit TicketsPurchased(eventId, msg.sender, amount);
    }

    function finalizeEvent(bytes32 eventId) public onlyPerformer(eventId) {
        Event storage eventDetails = events[eventId];
        require(!eventDetails.isFinalized, "Event is already finalized");

        eventDetails.isFinalized = true;

        uint256 totalEarnings = eventDetails.totalEarnings;
        uint256 totalPerformers = eventDetails.performers.length;

        uint256 earningsPerPerformer = totalEarnings / totalPerformers;
        for (uint256 i = 0; i < totalPerformers; i++) {
            address performer = eventDetails.performers[i];
            balances[performer] += earningsPerPerformer;
        }

        emit EventFinalized(eventId, totalEarnings);
    }

    function createUsageAgreement(
        string memory work,
        address licensee,
        uint256 paymentAmount
    ) public onlyRegisteredArtist {
        require(workRoyalties[work] > 0, "Work has no set royalty");
        workUsageAgreements[work].push(
            UsageAgreement(licensee, paymentAmount, false)
        );
        emit AgreementCreated(work, licensee, paymentAmount);
    }

    function createArtistToken(uint256 initialSupply) public onlyRegisteredArtist {
    require(address(artistToken) == address(0), "ArtistToken already created");

    artistToken = new ArtistToken(initialSupply);
    balances[msg.sender] = initialSupply;
}


    function approveUsageAgreement(string memory work, address licensee)
        public
        onlyRegisteredArtist
    {
        UsageAgreement[] storage agreements = workUsageAgreements[work];
        for (uint256 i = 0; i < agreements.length; i++) {
            if (agreements[i].licensee == licensee) {
                agreements[i].isApproved = true;
                emit AgreementApproved(work, licensee);
                return;
            }
        }
    }

    function getUsageAgreement(string memory work, address licensee)
        public
        view
        returns (
            address,
            uint256,
            bool
        )
    {
        UsageAgreement[] storage agreements = workUsageAgreements[work];
        for (uint256 i = 0; i < agreements.length; i++) {
            if (agreements[i].licensee == licensee) {
                return (
                    agreements[i].licensee,
                    agreements[i].paymentAmount,
                    agreements[i].isApproved
                );
            }
        }
        return (address(0), 0, false);
    }

    function getContribution(bytes32 collaborationId, address collaborator)
        public
        view
        returns (uint256)
    {
        require(
            collaborations[collaborationId].isFinalized == true,
            "Collaboration not finalized"
        );
        require(
            isCollaborator(collaborationId, collaborator),
            "Not a collaborator"
        );

        uint256 contribution = collaborations[collaborationId].contributions[
            collaborator
        ];
        return contribution;
    }

    function isCollaborator(bytes32 collaborationId, address collaborator)
        internal
        view
        returns (bool)
    {
        for (
            uint256 i = 0;
            i < collaborations[collaborationId].collaborators.length;
            i++
        ) {
            if (
                collaborations[collaborationId].collaborators[i] == collaborator
            ) {
                return true;
            }
        }
        return false;
    }

    function getCollaborationDetails(bytes32 collaborationId)
        public
        view
        returns (
            address[] memory collaborators,
            uint256 totalContributions,
            uint256 totalRoyalties,
            bool isFinalized
        )
    {
        Collaboration storage collaboration = collaborations[collaborationId];
        return (
            collaboration.collaborators,
            collaboration.totalContributions,
            collaboration.totalRoyalties,
            collaboration.isFinalized
        );
    }

    function getEventDetails(bytes32 eventId)
        public
        view
        returns (
            string memory name,
            uint256 date,
            uint256 ticketPrice,
            uint256 totalEarnings,
            bool isFinalized
        )
    {
        Event storage eventDetails = events[eventId];
        return (
            eventDetails.name,
            eventDetails.date,
            eventDetails.ticketPrice,
            eventDetails.totalEarnings,
            eventDetails.isFinalized
        );
    }

    function getUsageAgreementCount(string memory work)
        public
        view
        returns (uint256)
    {
        return workUsageAgreements[work].length;
    }

    function getUsageAgreementDetails(string memory work, uint256 index)
        public
        view
        returns (
            address licensee,
            uint256 paymentAmount,
            bool isApproved
        )
    {
        require(index < workUsageAgreements[work].length, "Invalid index");
        UsageAgreement storage agreement = workUsageAgreements[work][index];
        return (
            agreement.licensee,
            agreement.paymentAmount,
            agreement.isApproved
        );
    }

    // ... (other functions)
    // ... (previous code)

    // Utility functions
    function getRegisteredArtistsCount() public view returns (uint256) {
        return registeredArtists.length;
    }

    function getRegisteredArtistAtIndex(uint256 index)
        public
        view
        returns (address)
    {
        require(index < registeredArtists.length, "Invalid index");
        return registeredArtists[index];
    }

    function getArtistWorksCount(address artist) public view returns (uint256) {
        return artistWorks[artist].length;
    }

    function getArtistWorkAtIndex(address artist, uint256 index)
        public
        view
        returns (string memory)
    {
        require(index < artistWorks[artist].length, "Invalid index");
        return artistWorks[artist][index];
    }

    function setWorkMetadata(
        string memory work,
        string memory releaseDate,
        string memory description,
        string memory coverArtUrl
    ) public onlyRegisteredArtist {
        uint256 tokenId = tokenCounter;
        workMetadata[msg.sender][work] = WorkMetadata(
            tokenId,
            releaseDate,
            description,
            coverArtUrl
        );
        tokenCounter++;
    }

    function getWorkMetadata(address artist, string memory work)
        public
        view
        returns (
            uint256 tokenId,
            string memory releaseDate,
            string memory description,
            string memory coverArtUrl
        )
    {
        return (
            workMetadata[artist][work].tokenId,
            workMetadata[artist][work].releaseDate,
            workMetadata[artist][work].description,
            workMetadata[artist][work].coverArtUrl
        );
    }

    // Utility function to find the index of a performer
    function findPerformerIndex(bytes32 eventId, address performer)
        internal
        view
        returns (int256)
    {
        Event storage eventDetails = events[eventId];
        for (uint256 i = 0; i < eventDetails.performers.length; i++) {
            if (eventDetails.performers[i] == performer) {
                return int256(i);
            }
        }
        return -1;
    }

    // Utility function to calculate royalties for a work
    function calculateRoyalties(
        uint256 totalRoyalties,
        uint256 totalContributions,
        uint256 contributorContribution
    ) internal pure returns (uint256) {
        return (contributorContribution * totalRoyalties) / totalContributions;
    }

    // Event to notify when royalties are distributed
    event RoyaltiesDistributed(
        address indexed artist,
        string work,
        uint256 amount
    );

    function distributeRoyalties(string memory work) public {
        uint256 royaltyPercentage = workRoyalties[work];
        require(royaltyPercentage > 0, "Work has no set royalty");

        uint256 totalRoyalties = (artists[msg.sender].totalRoyalties *
            royaltyPercentage) / 100;
        require(totalRoyalties > 0, "No royalties to distribute");

        uint256 remainingRoyalties = totalRoyalties -
            totalRoyaltiesClaimed(work);
        balances[msg.sender] += remainingRoyalties;

        // Emit an event for royalty distribution
        emit RoyaltiesDistributed(msg.sender, work, remainingRoyalties);

        // Mint an NFT with the remaining royalties
        mintNFT(msg.sender, work, "");
    }

    // ... (other functions)
}
