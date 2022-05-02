//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Testing Libraries

import "./libs/strings.sol";
import "./libs/Float.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Test {
    using Strings for *;
    using strings for *;
    using Float for Float.float;

    // uint256[3] memory floatExample;

    function test() public view returns (bool) {
        console.log("Hello World");
        return true;
    }

    function add(string memory a, string memory b) public view returns (string memory) {
        Float.float memory answ = Float.add(Float.stringToFloat(a), Float.stringToFloat(b));
        console.log(a);
        console.log("+");
        console.log(b);
        console.log(answ._string);
        return ' ';
    }

    function sub(string memory a, string memory b) public view returns (string memory) {
        Float.float memory answ = Float.sub(Float.stringToFloat(a), Float.stringToFloat(b));
        console.log(a);
        console.log("-");
        console.log(b);
        console.log(answ._string);
        return ' ';
    }

    function multiply(string memory a, string memory b) public view returns (string memory) {
        Float.float memory answ = Float.multiply(Float.stringToFloat(a), Float.stringToFloat(b));
        console.log(a);
        console.log("*");
        console.log(b);
        console.log(answ._string);
        return ' ';
    }

    function DivideBy2(string memory a) public view returns (string memory) {
        Float.float memory answ = Float.multiply(Float.stringToFloat(a),  
            Float.float({
                _value: [uint256(1), uint256(0), uint256(5000000)], 
                _string: '0.5000000', 
                _uint: uint256(5000000),
                _decimal: 7, 
                _decimal_string: '5000000',
                _is_negative: false
            })
        );
        console.log(a);
        console.log(" / 2");
        console.log(answ._string);
        return ' ';
    }

    function isGreaterThan(string memory a, string memory b) public view returns (bool) {
        bool answ = (Float.stringToFloat(a)).isGreaterThan(Float.stringToFloat(b));
        console.log(a);
        console.log(">");
        console.log(b);
        console.log(' ');
        return answ;
    }

    function isLessThan(string memory a, string memory b) public view returns (bool) {
        bool answ = (Float.stringToFloat(a)).isLessThan(Float.stringToFloat(b));
        console.log(a);
        console.log("<");
        console.log(b);
        console.log(' ');
        return answ;
    }
    
}