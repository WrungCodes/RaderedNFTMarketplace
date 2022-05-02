//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
* Rad Universe
* 
* @dev This contract stores 3D objects (3D NFTs) in locations of the universe and creates/mints new 3D objects in locations in the universe
*  the functions includes:
*    - store 3D object in the universe
*    - create a new 3D object (NFTs) in a location (saving the object in IPFS)
*    - get all the 3D objects (NFTs) in the universe
*    - 
*/

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import "@openzeppelin/contracts/utils/Address.sol";

import "../libs/strings.sol";
import "../libs/Float.sol";

/**
 * @title Interface for contracts conforming to ERC-20
 */
interface ERC20Interface {
  function transferFrom(address from, address to, uint tokens) external returns (bool success);
  function balanceOf(address _owner) external view returns (uint balance);
}

contract Radverse is ERC721URIStorage {

    using Address for address;
    using Float for Float.float;   
    using Counters for Counters.Counter;

    uint256 public landFeeInUnitArea; // fee per unit area in wei
    uint256 public changeURIfee; // fee for changing URI on a Tile in wei

    address admin; // admin of the contract
    ERC20Interface public acceptedToken; // token used to buy land accepted by the contract

    /**
    * the struct that holds the information of a location in the universe
     */
    struct Rect {
        Float.float x1;
        Float.float y1;
        Float.float x2;
        Float.float y2;
    }

    Counters.Counter private _tileIds; // the tokenIds counter for the tiles

    /**
    * This 'Tile' object is used to represent each section/portion of the universe
     */
    struct Tile {
        uint256 id;
        Rect rect; // rect containing point of the tile
        string uri; // IPFS URI of the tile
        bool hasUri; // flag to indicate if the tile has an IPFS URI
    }

    /**
    * This event is emitted when a new tile is created
    */
    event TileCreated(
        uint256 tileId,
        Rect rect,
        string uri,
        bool hasUri,
        address indexed owner
    );

    /**
    * This event is emitted when a new URI is set for a tile (3D object is added to the universe)
    */
    event TileURIChanged(
        uint256 indexed tileId,
        Rect rect,
        string uri,
        bool hasUri,
        address indexed owner
    );

    /**
    * This event is emmitted when a new Land fee is set
    */
    event LandFeeChanged(
        uint256 prevFee,
        uint256 currentFee
    );

    /**
    * This event is emmitted when a new change URI fee is set
    */
    event ChangeURIfeeChanged(
        uint256 prevFee,
        uint256 currentFee
    );

    mapping(uint256 => Tile) private _tileArray; // the array of tiles

    constructor( 
        address _acceptedToken, 
        address _admin, 
        uint256 _landFeeInUnitArea, 
        uint256 _changeURIfee 
        ) ERC721('RadUniverse', 'RADUNIVERSE') 
    {
        require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
        acceptedToken = ERC20Interface(_acceptedToken);
        admin = _admin;

        landFeeInUnitArea = _landFeeInUnitArea;
        changeURIfee = _changeURIfee;

        // landFeeInUnitArea = 0;
        // changeURIfee = 0;

        // setLandFeePerUnitArea(_landFeeInUnitArea); // set the land fee
        // setChangeURIFee(_changeURIfee); // set the change URI fee
    }

    /**
    * @dev get a single tile by its id
    * @param tileId the fee per unit area
    * @return the tile
    */
    function _getTile(uint256 tileId) public view returns(Tile memory) {
        require(_exists(tileId), "Universe: RadUniverse Tile does not exist");
        return _tileArray[tileId];
    }

    /**
    * @dev get all tiles in the universe
    * @return Tile[] the array of tiles
    */
    function _getAllTiles() external view returns(Tile[] memory){
        Tile[] memory tiles = new Tile[](_tileIds.current());
        for(uint256 i = 0; i < _tileIds.current(); i++){
            tiles[i] = _tileArray[i + 1];
        }
        return tiles;
    }

    // get the total number of tiles in the universe
    function _getTotalTiles() external view returns(uint256){
        return _tileIds.current();
    }

    /**
    *   @dev get the tiles for a given owner
    */
    function _getAllTilesForAddress() external view returns(Tile[] memory){ 
        uint256 totalItemCount = _tileIds.current();
        uint256 count = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (ownerOf(i + 1) == msg.sender) {
                count++;
            }
        }

        Tile[] memory tiles = new Tile[](_tileIds.current());

        for (uint i = 0; i < totalItemCount; i++) {
            if (ownerOf(i + 1) == msg.sender) {
                tiles[currentIndex] = _tileArray[i + 1];
                currentIndex++;
            }
        }

        return tiles;
    }

    modifier onlyOwner() {
        require(msg.sender == address(this), "Only the owner can call this function");
        _;                             
    } 

    // function setLandFeePerUnitArea(uint256 _newFee) public onlyOwner {

    //     uint256 oldFee = landFeeInUnitArea;
    //     landFeeInUnitArea = _newFee;

    //     emit LandFeeChanged(oldFee, landFeeInUnitArea);
    // }

    // function setChangeURIFee(uint256 _newFee) public onlyOwner {

    //     uint256 oldFee = changeURIfee;
    //     changeURIfee = _newFee;

    //     emit ChangeURIfeeChanged(oldFee, changeURIfee);
    // }

    /**
    * @dev get the land fee per unit area
    * @return Float.float the fee per unit area
    */
    function _calculateUnitArea(Rect memory rect) public pure returns(Float.float memory) {
        return Float.multiply(
            Float.sub(
                (Float.add(rect.x1.multiply(rect.y2), rect.x2.multiply(rect.y1))), 
                (Float.add(rect.y1.multiply(rect.x2), rect.y2.multiply(rect.x1)))
            ),
            Float.float({
                _value: [uint256(1), uint256(0), uint256(5000000)], 
                _string: '0.5000000', 
                _uint: uint256(5000000),
                _decimal: 7, 
                _decimal_string: '5000000',
                _is_negative: false
            })
        );
    }

    // function _checkIfTileIsTakenCircle(
    //     Float.float memory lat_a, Float.float memory long_b, Float.float memory raduis_c, 
    //     Float.float memory lat_x, Float.float memory long_y, Float.float memory raduis_z
    // ) internal pure returns(bool) 
    // {
    //     Float.float memory distSq = Float.add(
    //         Float.multiply(Float.sub(lat_a, lat_x), Float.sub(lat_a, lat_x)), 
    //         Float.multiply(Float.sub(long_b, long_y), Float.sub(long_b, long_y))
    //     );

    //     Float.float memory radSumSq = Float.multiply(Float.add(raduis_c, raduis_z), Float.add(raduis_c, raduis_z));

    //     if(Float.isEqual(distSq, radSumSq)){ return true; }
    //     else if(Float.isGreaterThan(distSq, radSumSq)) { return false; }
    //     else { return true; }
    // }

    function _checkIfTileOverLap( Rect memory a, Rect memory b ) internal pure 
    {
        require(!(a.x1.isGreaterOrEquals(b.x2) || b.x1.isGreaterOrEquals(a.x2)), "Universe: Tile is invalid because there is a horizontal overlap on another Tile");
        require(!(a.y1.isGreaterOrEquals(b.y2) || b.y1.isGreaterOrEquals(a.y2)), "Universe: Tile is invalid because there is a vertical overlap on another Tile");
    }

    function _checkIfTileTouches( Rect memory a, Rect memory b ) internal pure 
    {
        require(!(a.x1.isGreaterThan(b.x2) || b.x1.isGreaterThan(a.x2)), "Universe: Tile is invalid because there is a horizontal touch on another Tile");
        require(!(a.y1.isGreaterThan(b.y2) || b.y1.isGreaterThan(a.y2)), "Universe: Tile is invalid because there is a vertical touch on another Tile");
    }

    function _checkIfTileIsValid(Rect memory rect) internal pure
    {
        require((rect.x1.isEqual(rect.x2) || rect.y1.isEqual(rect.y2)), "Universe: Tile is invalid because it is a line");
    }

    function mintToken(
        string memory tokenURI, 
        string memory _latitude_a, 
        string memory _longitude_a, 
        string memory _latitude_b, 
        string memory _longitude_b
        ) external returns(uint){
        
        Rect memory rect = Rect({
            x1: Float.stringToFloat(_latitude_a), 
            y1: Float.stringToFloat(_longitude_a), 
            x2: Float.stringToFloat(_latitude_b), 
            y2: Float.stringToFloat(_longitude_b) 
        });

        _checkIfTileIsValid(rect);

        // check if the location is already taken
        for(uint256 i = 0; i < _tileIds.current(); i++){
            Tile memory tile = _tileArray[i + 1];
            _checkIfTileOverLap(rect, tile.rect);
            _checkIfTileTouches(rect, tile.rect);
        }

        // area of tile round up to the nearest integer
        uint256 area = (_calculateUnitArea(rect).ceil())._value[1];

        // require area to be greater than 0
        require(area > 0, "Universe: Tile is invalid because the area is less than 0");

        // price of tile
        uint256 price = area * landFeeInUnitArea;

        // check if balance is enough
        require(acceptedToken.balanceOf(_msgSender()) >= price, "Universe: Not enough balance to mint a new Tile");

        // pay for the tile using the RAD acceppted token
        require(
            acceptedToken.transferFrom(_msgSender(), admin, price),
            "Universe: Transfering the payment of tile to the admin failed"
        );

        _tileIds.increment();
        uint256 newMintedTileId = _tileIds.current();

        _mint(msg.sender, newMintedTileId);
        _setTokenURI(newMintedTileId, tokenURI);

        bool _hasUri = bytes(tokenURI).length > 0 ? true : false;

        _tileArray[newMintedTileId] = Tile({
            id: newMintedTileId,
            rect: rect,
            uri: tokenURI,
            hasUri: _hasUri
        });

        emit TileCreated(newMintedTileId, rect, tokenURI, _hasUri, msg.sender);

        return newMintedTileId;
    }

    /**
        * @dev Function to set the token URI of a tile
        * description:  This function is used to set the token URI of a tile
                    first it checks if the tile is owned by the caller
                    it checks if the token URI is valid (not empty)
                    it checks if user has enough balance to pay for the token URI with the RAD accepted token
                    the user is charged for the token URI with the RAD accepted token
                    the token URI is set
                    the TileUpdated event is emitted.
        * @param _tileId The id of the tile
        * @param _tokenURI The token URI of the tile
        * returns the id of the tile
    */
    function setNewTokenURI(uint256 _tileId, string memory _tokenURI) external returns(uint) {
        require(msg.sender == ownerOf(_tileId), "Universe: Only the owner can set the token URI");

        require(_exists(_tileId), "Universe: RadUniverse Tile does not exist");
        require(bytes(_tokenURI).length > 0, "Universe: Token URI is invalid");

        // check if balance is enough
        require(acceptedToken.balanceOf(_msgSender()) >= changeURIfee, "Universe: Not enough balance to change tokenURI");

        // pay for the URI Change
        require(
            acceptedToken.transferFrom(_msgSender(), admin, changeURIfee),
            "Universe: Transfering the payment of URI change to the admin failed"
        );

        _setTokenURI(_tileId, _tokenURI);

        Tile memory tile = _tileArray[_tileId];
        tile.uri = _tokenURI;
        tile.hasUri = true;

        emit TileURIChanged(tile.id, tile.rect, _tokenURI, true, ownerOf(_tileId));

        return tile.id;
    }
}