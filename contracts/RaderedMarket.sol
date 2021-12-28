//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* RaderedConsolidation
* 
* @dev This contract is the contract to discover RaderedShardNFTs via thier assigned location
*      
*/

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

import './RaderedShardNFT.sol';
import './RaderedHunkNFT.sol';
import './RaderedUtils.sol';

contract RaderedMarket is ReentrancyGuard{

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokenSold;

    /**
    * RaderedNFTContractAddress 
    * this is the address of the RaderedNFT contract
    * contracts/RaderedNFT.sol
     */
    address raderedNFTContractAddress;

    /**
    * RaderedShardNFTContractAddress 
    * this is the address of the RaderedShardNFT contract
    * contracts/RaderedConsolidation.sol
     */
    address raderedShardNFTContractAddress;

    address payable owner;

    uint256 listingFee = 0.04 ether;

    constructor () {
        owner = payable(msg.sender);
    }

    struct MarketToken {
        uint itemId;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool isShard;
    }

    mapping(uint256 => MarketToken) private idToMarketToken;

    event MarketTokenMinted(
        uint indexed itemId,
        uint256 indexed tokenId,
        address indexed tokenAddress, 
        address seller, 
        address owner, 
        uint256 price,
        bool sold,
        bool isShard
    );

    // get the listing price
    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function mintMarketToken( address tokenAddress, uint tokenId, uint price ) public payable nonReentrant {
        // require price is greater than 0
        require(price > 0, "Price must be greater than 0");
        // reqiure value equals to the listing fee
        require(msg.value == listingFee, "Price must equal to listing fee");

        _tokenIds.increment();
        uint itemId = _tokenIds.current();

        idToMarketToken[itemId] = MarketToken(
            itemId,
            tokenAddress,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            true
        );

        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);

        emit MarketTokenMinted(
            itemId,
            tokenId,
            tokenAddress, 
            msg.sender, 
            address(0), 
            price,
            false,
            true
        );
    }

    function createMarketSale(address nftContract, uint itemId) public payable nonReentrant {
        uint price = idToMarketToken[itemId].price;
        uint tokenId = idToMarketToken[itemId].tokenId;

        // verify price is eqaul to to the msg.value
        require(price == msg.value, "Price must equal to msg.value");

        idToMarketToken[itemId].seller.transfer(msg.value);

        IERC721(nftContract).transferFrom(address(this), msg.sender,  tokenId);

        idToMarketToken[itemId].owner = payable(msg.sender);
        idToMarketToken[itemId].sold = true;
        _tokenSold.increment();

        payable(owner).transfer(listingFee);
    }

    // list all the market tokens
    function listAllMarketTokens() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            result[i] = idToMarketToken[i].itemId;
        }
        return result;
    }

    // list all non-sold market tokens
    function fetchAllMarketTokensNotSold() public view returns (MarketToken[] memory) {
        MarketToken[] memory result = new MarketToken[]( _tokenIds.current() - _tokenSold.current());
        uint256 count = 0;
        for (uint i = 0; i < _tokenIds.current(); i++) {
            if (idToMarketToken[i + 1].owner == address(0)) {
                result[count] = idToMarketToken[i + 1];
                count++;
            }
        }
        return result;
    }

    // return nft that user has purchased
    function fetchUserTokens() public view returns (MarketToken[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 count = 0;
        uint currentIndex = 0;

        // get all the tokens that belong to user
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketToken[i + 1].owner == msg.sender) {
                count++;
            }
        }

        MarketToken[] memory result = new MarketToken[](count);

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketToken[i + 1].owner == msg.sender) {
                uint currentId = idToMarketToken[i + 1].itemId;
                result[currentIndex] = idToMarketToken[currentId];
                currentIndex++;
            }
        }

        return result;
    }

}