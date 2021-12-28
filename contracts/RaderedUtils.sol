//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* RaderedCreation
* 
* @dev This contract is the contract to create and mint RaderedShardNFTs and RaderedNFTs
*      
*/

import "./libs/strings.sol";
import "./libs/Float.sol";

library RaderedUtils {

    struct Hunk {
        uint256 hunkId;
        string uri;
        bool isUnlocked;
    }

    struct ShardAndURI {
        Shard shard;
        string uri;
    }

    struct Shard {
        uint256 shardId;
        uint256 hunkId;
        Location location;
        bool isDiscovered;
        uint price;
    }

    struct Location {
        Float.float minLat;
        Float.float minLong;
        Float.float maxLat;
        Float.float maxLong;
    }

    using strings for *;
    using Float for Float.float;

    function _splitWordsToArray(string memory stringToSplit, string memory delimeter) public pure returns(string[] memory){                                              
        strings.slice memory s = stringToSplit.toSlice();                
        strings.slice memory delim = delimeter.toSlice();

        string[] memory parts = new string[](s.count(delim));                  
        for (uint i = 0; i < parts.length; i++) {                              
           parts[i] = s.split(delim).toString();                               
        }

        return parts;                                                                  
    }

    function _addStrings(string memory s1, string memory s2) public pure returns(string memory) {
        string memory s = s1.toSlice().concat(s2.toSlice());
        return s;
    }

    function _checkIfPositionIsWithinLocation(string memory lat, string memory long, Location memory location) public pure returns(bool) {

        if(
            (
                Float.isLessThan(Float.stringToFloat(lat), location.maxLat)
                && Float.isGreaterThan(Float.stringToFloat(lat), location.minLat)
            )
            &&
            (
                Float.isLessThan(Float.stringToFloat(long), location.maxLong) 
                && Float.isGreaterThan(Float.stringToFloat(long), location.minLong)
            )
        )
        {
            return true;
        }

        return false;
    }
}