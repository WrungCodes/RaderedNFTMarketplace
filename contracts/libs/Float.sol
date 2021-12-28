// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.0;

    /**
    * this is a representation of a signed floating point number using arrays
    * there are in total three elements in the array
    *  - the first element represents the sign(negativity or positivity) of the number
    *      so it can be either 0 or 1, where 0 represents a positive number and 1 represents a negative number
    *  - the second element represents the integer part of the number
    *  - the third element represents the decimal part of the number
    
        uint256[3] memory float1;
        uint256[3] memory float2;
    */

import './strings.sol';

library Float {

    using strings for *;
    

    struct float {
        uint256[3] _value; // default: [1, 0, 0] meaning 0.0
    }

    // convert a string float like "-1.2345" to a [1, 1, 2345] array
    function stringToFloat(string memory _floatStr) public pure returns (float memory) {
        strings.slice memory strSlice = _floatStr.toSlice();
        uint _len = strSlice.len();

        strings.slice memory delim = "".toSlice();
        strings.slice[] memory _str = new strings.slice[](_len);

        for(uint i = 0; i < _str.length; i++) {
            _str[i] = strSlice.split(delim);
        }

        uint _ptr = 0;
        uint256[3] memory _result;
        
        if (_str[0].equals("-".toSlice())) {
            _result[0] = 1;
            _ptr = 1;
        }
        for (uint _i = _ptr; _i < _len; _i++) {
            if (_str[_i].equals(".".toSlice())) {
                _result[1] = 10 * _result[1] + uint256(_stringToNumber(_str[_i + 1].toString()));
                _i++;
            } else {
                _result[1] = 10 * _result[1] + uint256(_stringToNumber(_str[_i].toString()));
            }
        }
        for (uint _i = _ptr; _i < _len; _i++) {
            if (_str[_i].equals(".".toSlice())) {
                _ptr = _i + 1;
                break;
            }
        }
        for (uint _i = _ptr; _i < _len; _i++) {
            _result[2] = 10 * _result[2] + uint256(_stringToNumber(_str[_i].toString()));
        }

        return float({_value: _result});
    }

    /**
    * make method to add two floats using the array method so [0, 1, 8345] + [0, 1, 2345] = [0, 3, 069] where the first element is the sign
    * if the sign is 0, then treat the number as a negative number, and if the sign is 1, then treat the number as a positive number
    *  make sure to account for carry over of values from the decimals and integers
    */

    // check if the first float is greater than the second float using the array method 
    // so [0, 1, 8345] > [0, 1, 2345] taking into account the sign which is the first element
    function isGreaterThan(float memory _float1, float memory _float2) public pure returns (bool) {
        if (_float1._value[0] == 0 && _float2._value[0] == 1) {
            return false;
        }
        if (_float1._value[0] == 1 && _float2._value[0] == 0) {
            return true;
        }
        if (_float1._value[0] == 0 && _float2._value[0] == 0) {
            if (_float1._value[1] > _float2._value[1]) {
                return true;
            } else if (_float1._value[1] < _float2._value[1]) {
                return false;
            } else {
                if (_float1._value[2] > _float2._value[2]) {
                    return true;
                } else {
                    return false;
                }
            }
        }
        if (_float1._value[0] == 1 && _float2._value[0] == 1) {
            if (_float1._value[1] > _float2._value[1]) {
                return true;
            } else if (_float1._value[1] < _float2._value[1]) {
                return false;
            } else {
                if (_float1._value[2] > _float2._value[2]) {
                    return true;
                } else {
                    return false;
                }
            }
        }
        return false;
    }

    // check if the first float is less than the second float using the array method
    // so [0, 1, 8345] < [0, 1, 2345] taking into account the sign which is the first element
    function isLessThan(float memory _float1, float memory _float2) public pure returns (bool) {
        if (_float1._value[0] == 0 && _float2._value[0] == 1) {
            return true;
        }
        if (_float1._value[0] == 1 && _float2._value[0] == 0) {
            return false;
        }
        if (_float1._value[0] == 0 && _float2._value[0] == 0) {
            if (_float1._value[1] < _float2._value[1]) {
                return true;
            } else if (_float1._value[1] > _float2._value[1]) {
                return false;
            } else {
                if (_float1._value[2] < _float2._value[2]) {
                    return true;
                } else {
                    return false;
                }
            }
        }
        if (_float1._value[0] == 1 && _float2._value[0] == 1) {
            if (_float1._value[1] < _float2._value[1]) {
                return true;
            } else if (_float1._value[1] > _float2._value[1]) {
                return false;
            } else {
                if (_float1._value[2] < _float2._value[2]) {
                    return true;
                } else {
                    return false;
                }
            }
        }
        return false;
    }

    function _stringToNumber(string memory numString) public pure returns(uint) {
        uint  val=0;
        bytes   memory stringBytes = bytes(numString);
        for (uint  i =  0; i<stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
           uint jval = uval - uint(0x30);
   
           val +=  (uint(jval) * (10**(exp-1))); 
        }
      return val;
    }
}