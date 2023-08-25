// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ArtistManagement.sol"; // Inherit from the previous part
// contract Address: 0xFbB7eF430EF8062AB0ce07a3056bA103763D6A1a

contract ArtistManagement1 is ArtistManagement {
    struct UsageAgreement {
        address licensee;
        uint256 paymentAmount;
        bool isApproved;
    }

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

    mapping(address => string) public artistAgreements;
    mapping(bytes32 => Collaboration) public collaborations;
    mapping(bytes32 => Event) public events;
    mapping(string => UsageAgreement[]) public workUsageAgreements;
    bytes32[] public collaborationIds;

    constructor() {}

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
    event CollaboratorRemoved(bytes32 collaborationId, address collaborator);
    event PerformerRemoved(bytes32 eventId, address performer);

    function _onlyRegisteredArtist() internal view {
        require(
            bytes(artists[msg.sender].emailAddress).length != 0,
            "Artist not registered"
        );
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

    /*function getUsageAgreement(string memory work, address licensee)
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
    }*/

    /*function approveUsageAgreement(string memory work, address licensee)
        public
        onlyRegisteredArtist
    {
        UsageAgreement[] storage agreements = workUsageAgreements[work];
        for (uint256 i = 0; i < agreements.length; i++) {
            if (agreements[i].licensee == licensee) {
                agreements[i].isApproved = true;
                emit AgreementApproved(work, licensee);
                break;
            }
        }
    }*/

    // Utility function to calculate royalties for a work
    
    function calculateRoyalties(
        uint256 totalRoyalties,
        uint256 totalContributions,
        uint256 contributorContribution
    ) internal pure returns (uint256) {
        return (contributorContribution * totalRoyalties) / totalContributions;
    }

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
}
