//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

contract EntityRegistry {
  struct Entity {
    bytes32 name;
    address wallet;
    bytes32 ensName;
    bool isVerified;
    address verifiedBy;
  }

  mapping(address => Entity) public entities;

  event EntityRegistered(address indexed id, bytes32 name, address wallet);
  event EntityVerified(address indexed id, address indexed verifiedBy);

  function registerEntity(bytes32 name, bytes32 ensName) public {
    require(entities[msg.sender].wallet == address(0), 'Entity already exists');

    entities[msg.sender] = Entity(name, msg.sender, ensName, false, address(0));

    emit EntityRegistered(msg.sender, name, msg.sender);
  }

  function verifyEntity(address entityAddress, address verifier) public {
    require(entities[entityAddress].wallet != address(0), 'Entity does not exist');
    require(verifier != address(0), 'Invalid verifier address');

    entities[entityAddress].isVerified = true;
    entities[entityAddress].verifiedBy = verifier;

    emit EntityVerified(entityAddress, verifier);
  }

  function isEntityVerified(address entityAddress) public view returns (bool) {
    return entities[entityAddress].isVerified;
  }

  function lookupENS(bytes32 ensName) public view returns (address) {
    // Implement the ENS lookup logic here
    // Return the corresponding address associated with the ENS name
  }
}
