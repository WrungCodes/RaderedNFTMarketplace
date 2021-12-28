//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* RaderedCreation
* 
* @dev This contract is the contract to create and mint RaderedShardNFTs and RaderedNFTs
*      
*/

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './RaderedShardNFT.sol';
import './RaderedHunkNFT.sol';
import './RaderedUtils.sol';

contract RaderedCreation is ReentrancyGuard {
    using RaderedUtils for *;
    using Strings for *;
    using Counters for Counters.Counter;

    Counters.Counter private _hunksUnlocked;
    Counters.Counter private _hunksIds;

    uint discoveryFee = 0.0004 ether;

    address payable owner;

    struct TotalInfo {
        uint256 main;
        uint256[] shards;
        bool isUnlocked;
        bool exist;
        address payable creator;
        address payable unlocker;
    }

    mapping(uint256 => TotalInfo) private _createdRaders;

    struct AddressCheckIn {
        bool isValue;
        uint256 shardId;
        uint timestamp;
    }

    struct UserDiscoveredShard {
        uint256[] shards;
    }

    mapping(bytes => AddressCheckIn) private _addressCheckIn;
    mapping(address => UserDiscoveredShard) private _userDescovery;

    constructor() {
        owner = payable(msg.sender);
    }

    // get descovery fee
    function getDiscoveryFee() public view returns (uint) {
        return discoveryFee;
    }

    function mintToken(address raderedNFTContractAddress, address raderedShardNFTContractAddress, string[] memory tokenURIs, uint[] memory prices, string[] memory locations) public returns(uint256){

        require(tokenURIs.length > 2, "RaderedCreation: tokenURIs length must be greater than 2");
        require(tokenURIs.length == locations.length + 1, "RaderedCreation: you must provide a location for each token");
        require(prices.length == locations.length, "RaderedCreation: you must provide a price for each token");

        RaderedHunkNFT raderedNFTInstance = RaderedHunkNFT(raderedNFTContractAddress);
        uint256 mainTokenId = raderedNFTInstance.mintToken(tokenURIs[0]);

        uint256[] memory shardsIds = new uint256[](locations.length);

        for (uint i = 1; i < tokenURIs.length; i++) {
            RaderedShardNFT raderedShardNFTInstance = RaderedShardNFT(raderedShardNFTContractAddress);
            uint256 tempTokenId = raderedShardNFTInstance.mintToken(tokenURIs[i], mainTokenId, locations[i - 1], prices[i - 1]);
            shardsIds[i - 1] = tempTokenId;
        }

        _hunksIds.increment();
        uint hunkId = _hunksIds.current();

        _createdRaders[hunkId] = TotalInfo({
            main: mainTokenId,
            shards: shardsIds,
            isUnlocked: false,
            exist: true,
            creator: payable(msg.sender),
            unlocker: payable(address(0))
        });

        return mainTokenId;
    }

    function isLocationVerifcation(address raderedShardNFTContractAddress, uint256 shardTokenId, string memory _locationLat, string memory _locationLong) public payable returns (bool) {

        // get the Shard NFT via the tokenId
        RaderedShardNFT shardNFT = RaderedShardNFT(raderedShardNFTContractAddress);

        // get RaderedUtils.Shard object
        RaderedUtils.Shard memory shard = shardNFT.getShardDetails(shardTokenId);

        // require that the Shard is not unlocked
        require(!shard.isDiscovered, "RaderedCreation: Shard is already unlocked");

        // reqiure value equals to the discovery fee & shard price
        require(msg.value >= discoveryFee, "RaderedCreation: Price must equal to discovery fee");

        // TODO get location using ChainLink API call

        // pay the owner the discovery fee
        payable(owner).transfer(discoveryFee);

        // if location is not within the shard location charge the user
        if (
            !RaderedUtils._checkIfPositionIsWithinLocation(
                _locationLat, 
                _locationLong,
                shardNFT.getRaderedShardLocation(shardTokenId)
            )
        ) {
            return false;
        }

        bytes memory addr = abi.encodePacked(msg.sender, shardTokenId);

        _addressCheckIn[addr] = AddressCheckIn({
            isValue: true,
            shardId: shardTokenId,
            timestamp: block.timestamp
        });

        _userDescovery[msg.sender].shards.push(shardTokenId);

        return true;
    }


    /**
    * unlock a Shard via location
    * 
    * this is like buying a Shard but your location must be the location of the Shard _location already saved
     */
    function buyShard(address raderedShardNFTContractAddress, uint256 shardTokenId) public payable nonReentrant returns (uint256) {

        bytes memory addr = abi.encodePacked(msg.sender, shardTokenId);

        AddressCheckIn memory checkIn = _addressCheckIn[addr];

        // require that the user has checked in
        require(checkIn.isValue, "RaderedCreation: You must check in the Location before you can unlock");

        // require that the check in is not older than 12 hours
        require(block.timestamp - checkIn.timestamp <= 43200, "RaderedCreation: You must buy the shard within 12 hours of check in");

        // get the Shard NFT via the tokenId
        RaderedShardNFT shardNFT = RaderedShardNFT(raderedShardNFTContractAddress);

        // get RaderedUtils.Shard object
        RaderedUtils.Shard memory shard = shardNFT.getShardDetails(shardTokenId);

        // require that the Shard is not unlocked
        require(!shard.isDiscovered, "RaderedConsolidation: Shard is already unlocked");

        // reqiure value equals to the discovery fee & shard price
        require(msg.value >= shard.price, "Price must equal to Shard price");

        // unlock the Shard
        shardNFT.setRaderedShardUnlocked(shardTokenId);

        // get the total info of the Radered via the hunkTokenId
        TotalInfo memory totalInfo = _createdRaders[shard.hunkId];

        // send the price to the creator
        totalInfo.creator.transfer(shard.price);

        // transfer nft to the user
        IERC721(raderedShardNFTContractAddress).transferFrom(address(this), msg.sender, shardTokenId);

        return shardTokenId;
    }

    // unlock a Hunk
    function unlockHunk(address raderedNFTContractAddress, address raderedShardNFTContractAddress, uint256 hunkId) public nonReentrant returns (uint256) {
        // require the user has unlocked all shards with the hasUserUnlockedAllShards
        require(hasUserUnlockedAllShards(raderedShardNFTContractAddress, hunkId), "RaderedCreation: You must unlock all shards before you can unlock the Hunk");

        // get the Hunk NFT via the tokenId
        TotalInfo memory totalInfo = _createdRaders[hunkId];

        // transfer nft to the user
        IERC721(raderedNFTContractAddress).transferFrom(address(this), msg.sender, hunkId);

        totalInfo.isUnlocked = true;
        totalInfo.unlocker = payable(msg.sender);

        _hunksUnlocked.increment();

        return hunkId;
    } 

    // function for users to check if he has all the shards of a total info in his address
    function hasUserUnlockedAllShards(address raderedShardNFTContractAddress, uint256 hunkId) public view returns (bool) {

        // get the Total Info of the Radered via the raderedNFTId
        TotalInfo memory totalInfo = _createdRaders[hunkId];

        // require that the hunk has not been unlocked
        require(!totalInfo.isUnlocked, "RaderedConsolidation: Hunk is already unlocked");

        // get the shards of the total info
        uint256[] memory shards = totalInfo.shards;
        
        // loop the shards and check for the ownership of each shard
        for (uint i = 0; i < shards.length; i++) 
        {
            if(IERC721(raderedShardNFTContractAddress).ownerOf(shards[i]) != msg.sender) {
                return false;
            }
        }

        return true;
    }

    // function to fetch all total info of the radereds
    function getAllRadereds() public view returns (TotalInfo[] memory) {
        TotalInfo[] memory radereds = new TotalInfo[](_hunksIds.current());

        for (uint i = 0; i < _hunksIds.current(); i++) {
            radereds[i] = _createdRaders[i];
        }

        return radereds;
    } 

    // function to fetch all locked radereds
    function getAllLockedRadereds() public view returns (TotalInfo[] memory) {
        TotalInfo[] memory radereds = new TotalInfo[](_hunksIds.current());

        uint256 index = 0;

        for (uint i = 0; i < _hunksIds.current(); i++) {
            TotalInfo memory totalInfo = _createdRaders[i];

            if(!totalInfo.isUnlocked) {
                radereds[index] = totalInfo;
                index++;
            }
        }

        return radereds;
    }

    // function to fetch all unlocked radereds
    function getAllUnlockedRadereds() public view returns (TotalInfo[] memory) {
        TotalInfo[] memory radereds = new TotalInfo[](_hunksIds.current());

        uint256 index = 0;

        for (uint i = 0; i < _hunksIds.current(); i++) {
            TotalInfo memory totalInfo = _createdRaders[i];

            if(totalInfo.isUnlocked) {
                radereds[index] = totalInfo;
                index++;
            }
        }

        return radereds;
    }

    // function to fetch all user unlocked radereds
    function getAllUserUnlockedRadereds() public view returns (TotalInfo[] memory) {
        TotalInfo[] memory radereds = new TotalInfo[](_hunksIds.current());

        uint256 index = 0;

        for (uint i = 0; i < _hunksIds.current(); i++) {
            TotalInfo memory totalInfo = _createdRaders[i];

            if(totalInfo.isUnlocked && totalInfo.unlocker == msg.sender) {
                radereds[index] = totalInfo;
                index++;
            }
        }

        return radereds;
    }

    // fetch shard by tokenId
    function getShard(address raderedShardNFTContractAddress, uint256 shardTokenId) public view returns (RaderedUtils.ShardAndURI memory) {
        RaderedShardNFT shardNFT = RaderedShardNFT(raderedShardNFTContractAddress);

        return RaderedUtils.ShardAndURI({
            shard: shardNFT.getShardDetails(shardTokenId),
            uri: shardNFT.tokenURI(shardTokenId)
        });
    }

    // fetch hunk by tokenId
    function getHunk(address raderedNFTContractAddress, uint256 hunkTokenId) public view returns (RaderedUtils.Hunk memory) {
        RaderedHunkNFT hunk = RaderedHunkNFT(raderedNFTContractAddress);

        return RaderedUtils.Hunk({
            hunkId: hunkTokenId,
            uri: hunk.tokenURI(hunkTokenId),
            isUnlocked: hunk._getRaderedNFTUnlockedStatus(hunkTokenId)
        });
    }

    // get all shards user has descorved
    function getUserDiscoveredShards() public view returns (uint256[] memory) {
        return _userDescovery[msg.sender].shards;
    }

    function _isTokenMinted(uint256 tokenId) public view returns(bool exist) {
        return _createdRaders[tokenId].exist;
    }

}