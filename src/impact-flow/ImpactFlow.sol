//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

contract ImpactRegistry {
    struct Donation {
        address donor;
        address donee;
        uint256 donationAmount;
        bytes32 donationHash;
        bytes32 reportHash;
        bytes32[] reportImages;
        bytes32[] reportPDFs;
        bytes32 reportJson;
        bytes32 status;
        uint256 expectedCompletionTimestamp;
        uint256 acceptedTimestamp;
        uint256 completionTimestamp;
    }

    mapping(bytes32 => Donation) public donations;
    mapping(address => bytes32[]) public donorDonations;
    mapping(address => bytes32[]) public doneeDonations;

    event DonationCreated(
        bytes32 indexed donationId,
        address indexed donor,
        address indexed donee,
        uint256 donationAmount,
        bytes32 donationHash,
        uint256 expectedCompletionTimestamp
    );

    event DonationAccepted(bytes32 indexed donationId, address indexed donee, uint256 acceptedTimestamp);
    event DonationStatusUpdated(bytes32 indexed donationId, bytes32 newStatus);
    event DonationReportHashAdded(bytes32 indexed donationId, bytes32 reportHash);

    EntityRegistry entityRegistry;

    constructor(address entityRegistryAddress) {
        entityRegistry = EntityRegistry(entityRegistryAddress);
    }

    function createDonation(
        address _donee,
        uint256 _donationAmount,
        bytes32 _donationHash,
        bytes32 _reportJson,
        bytes32[] memory _reportPDFs,
        bytes32[] memory _reportImages,
        uint256 _expectedCompletionTimestamp
    ) external returns (bytes32 donationId) {
        require(_donationAmount > 0, "Donation amount must be greater than zero");
        require(_donee != address(0), "Invalid donee address");
        require(_expectedCompletionTimestamp > block.timestamp, "Invalid expected completion timestamp");

        bytes32[2] memory entityNames = entityRegistry.getEntityNames(_donee);
        require(entityNames[0] != bytes32(0), "Donee is not registered");
        require(entityNames[1] == "donee", "The provided address is not a donee");

        donationId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _donee));
        Donation storage donation = donations[donationId];
        donation.donor = msg.sender;
        donation.donee = _donee;
        donation.donationAmount = _donationAmount;
        donation.donationHash = _donationHash;
        donation.reportJson = _reportJson;
        donation.reportPDFs = _reportPDFs;
        donation.reportImages = _reportImages;
        donation.expectedCompletionTimestamp = _expectedCompletionTimestamp;

        donorDonations[msg.sender].push(donationId);
        doneeDonations[_donee].push(donationId);

        emit DonationCreated(donationId, msg.sender, _donee, _donationAmount, _donationHash, _expectedCompletionTimestamp);
    }

    function acceptDonation(bytes32 _donationId) external {
        Donation storage donation = donations[_donationId];
        require(donation.donee == msg.sender, "Only donee can accept the donation");
        require(donation.acceptedTimestamp == 0, "Donation has already been accepted");

        donation.acceptedTimestamp = block.timestamp;
        donation.status = "active";

        emit DonationAccepted(_donationId, msg.sender, block.timestamp);
        emit DonationStatusUpdated(_donationId, "active");
    }

    function updateDonationStatus(bytes32 _donationId, bytes32 _newStatus) external {
        Donation storage donation = donations[_donationId];
        require(entityRegistry.isEntityVerified(donation.donor), "Donor is
