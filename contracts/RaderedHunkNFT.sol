//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* RaderedHunkNFT
* 
* @dev This contract is the contract for the combined RaderedShardNFTs to form this
*      this is just a basic NFT contract.
*/

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract RaderedHunkNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _unlockedTokensCount;

    /**
    * MarketPlaceContractAddress 
    * this is the address of the marketplace contract
    * contracts/RaderedMarket.sol
     */
    address marketPlaceContractAddress;

    /**
    * ConsolidationContractAddress 
    * this is the address of the Consolidation contract
    * contracts/RaderedConsolidation.sol
     */
    address consolidationContractAddress;

    // Required mapping for RaderedNFT unlocked status
    mapping(uint256 => bool) private _raderedUnlockedStatus;

    constructor(address _marketPlaceContractAddress, address _consolidationContractAddress) ERC721('RaderedHunk', 'RADHUNK') {
        marketPlaceContractAddress = _marketPlaceContractAddress;
        consolidationContractAddress = _consolidationContractAddress;
    }

    function mintToken(string memory tokenURI) external returns(uint){
        _tokenIds.increment();
        uint256 newMintedTokenId = _tokenIds.current();

        _mint(msg.sender, newMintedTokenId);
        _setTokenURI(newMintedTokenId, tokenURI);
        _setRaderedNFTUnlockedStatus(newMintedTokenId, false);
        
        setApprovalForAll(marketPlaceContractAddress, true);
        setApprovalForAll(consolidationContractAddress, true);

        return newMintedTokenId;
    }

    function _setRaderedNFTUnlockedStatus(uint256 tokenId, bool _isUnlocked) internal virtual {
        require(_exists(tokenId), "RaderedHunkNFT: RaderedIsUnlocked set of nonexistent token");
        require(!_raderedUnlockedStatus[tokenId], "RaderedHunkNFT: RaderedIsUnlocked already unlocked token");
        _raderedUnlockedStatus[tokenId] = _isUnlocked;
        _unlockedTokensCount.increment();
    }

    function _getRaderedNFTUnlockedStatus(uint256 tokenId) public view returns(bool) {
        require(_exists(tokenId), "RaderedHunkNFT: RaderedIsUnlocked set of nonexistent token");
        return _raderedUnlockedStatus[tokenId];
    }
}