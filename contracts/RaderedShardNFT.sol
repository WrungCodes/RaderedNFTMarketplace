//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* RaderedShardNFT
* 
* @dev This contract is the contract for the ShardNFTs that form a main RaderedNFT
*      this is just a basic NFT contract.
*/

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import './RaderedCreation.sol';
import './RaderedUtils.sol';
import "./libs/Float.sol";

contract RaderedShardNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    using RaderedUtils for *;
    using Float for Float.float;

    Counters.Counter private _tokenIds;
    Counters.Counter private _shardsDiscoverd;

    /**
    * MarketPlaceContractAddress 
    * this is the address of the marketplace contract
    * contracts/RaderedMarket.sol
     */
    address marketPlaceContractAddress;

    /**
    * creationContractAddress 
    * this is the address of the Consolidation contract
    * contracts/RaderedConsolidation.sol
     */
    address creationContractAddress;

    /**
    * raderedNFTContractAddress 
    * this is the address of the raderedNFT contract
    * contracts/RaderedConsolidation.sol
     */
    address raderedCreationContractAddress;

    mapping(uint256 => RaderedUtils.Shard) private _shardDetails;

    constructor(
        address _marketPlaceContractAddress, 
        address _creationContractAddress, 
        address _raderedCreationContractAddress
    )ERC721('RaderedShard', 'RADSHARD') {
        marketPlaceContractAddress = _marketPlaceContractAddress;
        creationContractAddress = _creationContractAddress;
        raderedCreationContractAddress = _raderedCreationContractAddress;
    }

    function mintToken(string memory tokenURI, uint256 _hunkId, string memory _location, uint price) external returns(uint){

        RaderedCreation raderedCreationInstance = RaderedCreation(raderedCreationContractAddress);        
        require(!raderedCreationInstance._isTokenMinted(_hunkId), "RaderedShardNFT: Token and its Shard is already minted");
        
        _tokenIds.increment();
        uint256 newMintedTokenId = _tokenIds.current();

        /**
        * first element is the max-latitude 0 
        * second element is the max-longitude 1
        * third element is the min-latitude 2
        * fourth element is the min-longitude 3
        */
        string[] memory positionShardArray = RaderedUtils._splitWordsToArray(_location, ",");
        
        _mint(msg.sender, newMintedTokenId);
        _setTokenURI(newMintedTokenId, tokenURI);

        _shardDetails[newMintedTokenId] = RaderedUtils.Shard({
            shardId: newMintedTokenId,
            hunkId: _hunkId,
            location: RaderedUtils.Location({
                minLat: Float.stringToFloat(positionShardArray[2]),
                minLong: Float.stringToFloat(positionShardArray[3]),
                maxLat: Float.stringToFloat(positionShardArray[0]),
                maxLong: Float.stringToFloat(positionShardArray[1])
            }),
            isDiscovered: false,
            price: price
        });

        setApprovalForAll(marketPlaceContractAddress, true);
        setApprovalForAll(creationContractAddress, true);

        return newMintedTokenId;
    }

    // fetch all the shards return RaderedUtils.Shard
    function getAllShards() external view returns(RaderedUtils.ShardAndURI[] memory){
        RaderedUtils.ShardAndURI[] memory shards = new RaderedUtils.ShardAndURI[](_tokenIds.current());
        uint256 index = 0;

        for(uint256 i = 0; i < _tokenIds.current(); i++){
            shards[index] = RaderedUtils.ShardAndURI({
                shard: _shardDetails[i + 1],
                uri: tokenURI(i + 1)
            });

            index++;
        }

        return shards;
    }

    // fetch all the shards that are not discorved return RaderedUtils.Shard
    function getAllUndiscoveredShards() external view returns(RaderedUtils.ShardAndURI[] memory){
        RaderedUtils.ShardAndURI[] memory shards = new RaderedUtils.ShardAndURI[](_tokenIds.current() - _shardsDiscoverd.current());
        uint256 index = 0;

        for(uint256 i = 0; i < _tokenIds.current(); i++){
            if(_shardDetails[i + 1].isDiscovered == false){
                shards[index] = RaderedUtils.ShardAndURI({
                    shard: _shardDetails[i + 1],
                    uri: tokenURI(i + 1)
                });
            }
        }
        return shards;
    }

    // get all user owned shards
    function getUserShards() external view returns(RaderedUtils.ShardAndURI[] memory){
        uint256 totalItemCount = _tokenIds.current();
        uint256 count = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (ownerOf(i + 1) == msg.sender) {
                count++;
            }
        }

        RaderedUtils.ShardAndURI[] memory shards = new RaderedUtils.ShardAndURI[](count);

        for (uint i = 0; i < totalItemCount; i++) {
            if (ownerOf(i + 1) == msg.sender) {
                shards[currentIndex] = RaderedUtils.ShardAndURI({
                    shard: _shardDetails[i + 1],
                    uri: tokenURI(i + 1)
                });
                currentIndex++;
            }
        }

        return shards;
    }

    // get shard details by id
    function getShardDetails(uint256 _shardId) public view returns(RaderedUtils.Shard memory){
        require(_exists(_shardId), "RaderedShardNFT: RaderedShardNFT get of nonexistent token");
        return _shardDetails[_shardId];
    }

    // get if shard is unlocked
    function isRaderedShardUnlocked(uint256 tokenId) public view returns(bool){
        require(_exists(tokenId), "RaderedShardNFT: RaderedShardNFT get of nonexistent token");
        return _shardDetails[tokenId].isDiscovered;
    }

    // getRaderedShardLocation
    function getRaderedShardLocation(uint256 tokenId) public view returns(RaderedUtils.Location memory){
        require(_exists(tokenId), "RaderedShardNFT: RaderedShardNFT get of nonexistent token");
        return _shardDetails[tokenId].location;
    }

    // getRaderedNFTIdentifier
    function getRaderedNFTIdentifier(uint256 tokenId) public view returns(uint256){
        require(_exists(tokenId), "RaderedShardNFT: RaderedShardNFT get of nonexistent token");
        return _shardDetails[tokenId].hunkId;
    }

    // set shard as unlocked
    function setRaderedShardUnlocked(uint256 tokenId) public {
        require(_exists(tokenId), "RaderedShardNFT: RaderedShardNFT set of nonexistent token");
        require(!_shardDetails[tokenId].isDiscovered, "RaderedShardNFT: RaderedShardNFT is already unlocked");
        _shardDetails[tokenId].isDiscovered = true;
        _shardsDiscoverd.increment();
    }
}