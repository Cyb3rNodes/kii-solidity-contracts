// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CryptoPets is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Pet {
        uint256 lastFed;
        uint256 lastPlayed;
        uint256 lastCleaned;
        uint8 mood; // 0 = happy, 1 = hungry, 2 = sad, 3 = dead
        uint8 level;
    }

    mapping(uint256 => Pet) public pets;
    mapping(uint256 => bool) public isDead;

    constructor() ERC721("CryptoPets", "PET") {}

    function mintPet() external {
        uint256 newId = _tokenIds.current();
        _mint(msg.sender, newId);
        pets[newId] = Pet({
            lastFed: block.timestamp,
            lastPlayed: block.timestamp,
            lastCleaned: block.timestamp,
            mood: 0,
            level: 1
        });
        _tokenIds.increment();
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        _;
    }

    function feed(uint256 tokenId) external onlyOwnerOf(tokenId) {
        require(!isDead[tokenId], "Pet is dead");
        pets[tokenId].lastFed = block.timestamp;
        _updateMood(tokenId);
    }

    function play(uint256 tokenId) external onlyOwnerOf(tokenId) {
        require(!isDead[tokenId], "Pet is dead");
        pets[tokenId].lastPlayed = block.timestamp;
        _updateMood(tokenId);
    }

    function clean(uint256 tokenId) external onlyOwnerOf(tokenId) {
        require(!isDead[tokenId], "Pet is dead");
        pets[tokenId].lastCleaned = block.timestamp;
        _updateMood(tokenId);
    }

    function checkMood(uint256 tokenId) public view returns (uint8 mood) {
        Pet memory pet = pets[tokenId];
        if (block.timestamp - pet.lastFed > 1 days ||
            block.timestamp - pet.lastPlayed > 1 days ||
            block.timestamp - pet.lastCleaned > 2 days) {
            return 1; // hungry or neglected
        }
        return 0; // happy
    }

    function _updateMood(uint256 tokenId) internal {
        uint8 mood = checkMood(tokenId);
        if (mood == 1) {
            pets[tokenId].mood += 1;
        } else {
            if (pets[tokenId].mood > 0) pets[tokenId].mood -= 1;
        }

        if (pets[tokenId].mood >= 3) {
            isDead[tokenId] = true;
        } else {
            pets[tokenId].level += 1;
        }
    }

    function getPet(uint256 tokenId) external view returns (
        uint256 lastFed,
        uint256 lastPlayed,
        uint256 lastCleaned,
        uint8 mood,
        uint8 level,
        bool dead
    ) {
        Pet memory pet = pets[tokenId];
        return (
            pet.lastFed,
            pet.lastPlayed,
            pet.lastCleaned,
            pet.mood,
            pet.level,
            isDead[tokenId]
        );
    }
}
