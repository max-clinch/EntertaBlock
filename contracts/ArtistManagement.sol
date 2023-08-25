// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ArtistToken.sol"; // Make sure to include proper import for ArtistToken;
//contract Address : 0xa95144fc9871FDf9494507f9038956fB62955De1

contract ArtistManagement is ERC721URIStorage {
    ArtistToken public artistToken;

    struct Artist {
        bool isRegistered;
        string emailAddress;
        string password;
        string firstName;
        string lastName;
        string stageName;
        uint256 totalRoyalties;
    }

    struct WorkMetadata {
        uint256 tokenId;
        string releaseDate;
        string description;
        string coverArtUrl;
    }

    uint256 private tokenCounter;
    mapping(address => mapping(string => WorkMetadata)) public workMetadata;
    address[] public registeredArtists;
    mapping(string => uint256) public workRoyalties;
    mapping(address => Artist) public artists;
    mapping(address => string[]) public artistWorks;
    mapping(address => uint256) public balances;

    constructor() ERC721("ArtistManagement", "EB") {
        tokenCounter = 0;
    }

    event WorkMetadataUpdated(address indexed artist, string work);

    event WorkRegistered(address indexed artistAddress, string work);
    event ArtistAgreementSet(
        address indexed artistAddress,
        string agreementHash
    );

    modifier onlyRegisteredArtist()   {
        require(
            bytes(artists[msg.sender].emailAddress).length != 0,
            "Artist not registered"
        );
        _;
    }

    function registerArtist(
        string memory emailAddress,
        string memory password,
        string memory firstName,
        string memory lastName,
        string memory stageName
    ) public {
        require(!artists[msg.sender].isRegistered, "Artist already registered");
        artists[msg.sender] = Artist({
            isRegistered: true,
            password: password,
            emailAddress: emailAddress,
            firstName: firstName,
            lastName: lastName,
            stageName: stageName,
            totalRoyalties: 0
        });
        registeredArtists.push(msg.sender);
    }

    function createArtistToken(uint256 initialSupply)
        public
        onlyRegisteredArtist
    {
        require(
            address(artistToken) == address(0),
            "ArtistToken already created"
        );
        artistToken = new ArtistToken(initialSupply);
        balances[msg.sender] = initialSupply;
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

    function registerWork(string memory work, string memory tokenUri)
        public
        onlyRegisteredArtist
    {
        artistWorks[msg.sender].push(work);
        emit WorkRegistered(msg.sender, work);
        // Mint an NFT for the work
        mintNFT(msg.sender, work, tokenUri);
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
    

   
}
