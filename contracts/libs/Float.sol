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
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
 
library Float {

    using strings for *;
    using Strings for *;
    

    struct float {
        uint256[3] _value; // default: [1, 0, 0] meaning 0.0
        string _string; 
        uint256 _decimal; 
        string _decimal_string; 
        uint256 _uint;
        bool _is_negative;
    }

    uint constant decimal = 7; // the decimal places of the number
    string constant zeros = '0000000'; // number of zeros to pad decimal part with

    /**
    *
    * @dev converts a string float like "-1.2345" to a float struct
    * param string memory _string the string to convert
    * returns float memory
    */
    function stringToFloat(string memory _floatStr) public pure returns (float memory) {
        strings.slice memory strSlice = _floatStr.toSlice();
        uint256[3] memory _result;

        // check if the strings begins with a '-' meaning negative
        if(strSlice.startsWith("-".toSlice())) {
            _result[0] = 0; // set sign to 0 which is negative
            strSlice.beyond("-".toSlice()); // remove the '-' from the string
        }else {
            _result[0] = 1; // set sign to 1 which is positive if no '-' is found
        }

        bool is_decimal = strSlice.contains(".".toSlice()); // check if the string contains a decimal point

        if(is_decimal)
        {
            // if the string contains a decimal point, then we need to split the string into two parts and convert them to uint256 from string
            _result[1] = uint256(_stringToNumber(strSlice.split(".".toSlice()).toString())); 

            // check if the decimal point is not greater than the specified 'decimal' decimal places NT: 18 decimal places is the maximum number of decimal places allowed
            require(strSlice.len() <= decimal, "float must be 18 or less decimal places");

            // pad the decimal part with zeros to make it 18 decimal places if it is less than the specified 'decimal' decimal places
            _result[2] = uint256(_stringToNumber(strSlice.toString())) * 10**(decimal - strSlice.len());
        }
        else
        {
            // if the string does not contain a decimal point, then we need to convert the string to uint256 from string
            _result[1] = uint256(_stringToNumber(strSlice.toString()));

            // set the decimal part to 0 padded to the specified 'decimal' decimal places
            _result[2] = uint256(_stringToNumber(zeros));
        }

        return float({
            _value: _result, 
            _string: _floatStr, 
            _uint: ((_result[1] * 10**decimal) + _result[2]),
            _decimal: decimal, 
            _decimal_string: is_decimal ? strSlice.toString() : zeros, // if the string does not contain a decimal point, then we need to pad the decimal part with zeros
            _is_negative: _result[0] == 0
        });
    }

    /**
    * make method to add two floats using the array method so [0, 1, 8345] + [0, 1, 2345] = [0, 3, 069] where the first element is the sign
    * if the sign is 0, then treat the number as a negative number, and if the sign is 1, then treat the number as a positive number
    *  make sure to account for carry over of values from the decimals and integers
    */


    /**
    *   @dev multiply two floats object and get back a float object of the result
    *   eg: float("-1.2345") * float("1.4690") = float("-2.099")
    *
    *   param float memory _float1 the first float object to multiply
    *   param float memory _float2 the second float object to multiply
    *   returns float memory
    */
    function multiply(float memory _float1, float memory _float2) public pure returns (float memory) {
        uint256[3] memory _result;

        // if the signs are different, then the result is negative and the sign is 0 else the result is positive and the sign is 1
        if((_float1._value[0] == 0 && _float2._value[0] == 0) || (_float1._value[0] == 1 && _float2._value[0] == 1)) {
            _result[0] = 1;
        }
        else {
            _result[0] = 0;
        }

        // multiply the integers part by the decimal places and add the decimals together to denote the integer represntation of the number
        // then multiply them together to get the result in the form of a integer
        uint256 ans = ((_float1._value[1] * 10**decimal) + _float1._value[2]) * ((_float2._value[1] * 10**decimal) + _float2._value[2]);

        // get the integer part of the result by dividing the integer by the decimal places
        _result[1] = uint256(ans) / (10**decimal * 10**decimal);

        // turn the whole integer into a slice (string)
        strings.slice memory strSlice = (Strings.toString(ans)).toSlice();

        // get the decimal part by removing the integer part from the whole integer string
        strSlice.beyond(Strings.toString(_result[1]).toSlice());

        // trim the decimal part to the specified 'decimal' decimal places
        bytes memory strBytes = bytes(strSlice.toString());
        bytes memory decimalResult = new bytes(decimal);
        for(uint i = 0; i < decimal; i++) {
            decimalResult[i-0] = strBytes[i];
        }

        // add all parts including the decimal point "." to get the final string (without the sign)
        string memory stringFloat = (((Strings.toString(_result[1]).toSlice()).concat(".".toSlice())).toSlice()).concat((string(decimalResult).toSlice()));

        // add the negative sign "-" if the number is negative
        if(_result[0] == 0) {
            stringFloat = "-".toSlice().concat(stringFloat.toSlice());
        }

        // convert the decimal part to a uint256 from string
        _result[2] = uint256(_stringToNumber(string(decimalResult)));

        // return the result
        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: string(decimalResult),
            _string: stringFloat,
            _uint: ans,
            _is_negative: _result[0] == 0
        });
    }

    /**
    * @dev get the absolute value of a float object
    * eg: float("-1.2345") = float("1.2345")
    * param float memory _float the float object to get the absolute value of
    * returns float memory
     */
    function abs(float memory _float) public pure returns (float memory) {
        uint256[3] memory _result = _float._value;
        _result[0] = 1;
        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: _float._decimal_string,
            _string: _float._string,
            _uint: _float._uint,
            _is_negative: false
        });
    }

    /**
    * @dev add two floats object and get back a float object of the result
    *  eg: float("-1.2345") + float("1.4690") = float("-0.7000")
    * param float memory _float1 the first float object to add
    * param float memory _float2 the second float object to add
    * returns float memory
     */
    function add(float memory _float1, float memory _float2) public pure returns (float memory)
    {
        uint256[3] memory _result;
        uint256 ans;
        bool _is_negative;

        // if the signs are the same then the two numbers are added together
        if((_float1._is_negative && _float2._is_negative) || (!_float1._is_negative && !_float2._is_negative)) 
        {
            // the sign of the number is now equals the sign of the either of the numbers
            _result[0] = _float1._value[0];
            _is_negative = _float1._is_negative;

            // add the numbers together as integers
            ans = _float1._uint + _float2._uint;
        }
        // if the signs are different then the numbers have to be subtracted
        else if(_float1._is_negative && !_float2._is_negative) 
        {
            // if the absolute value of the first number which is negative is greater than the absolute value of the second number then the result is negative
            // else the result is positive and the sign is 0
            if(isGreaterThan(abs(_float1), _float2))
            {
                _result[0] = 0;
                _is_negative = true;

                // subtract the second number from the first number as integers
                ans = _float1._uint - _float2._uint;
            }
            else
            {
                _result[0] = 1;
                _is_negative = false;

                // subtract the first number from the second number as integers
                ans = _float2._uint - _float1._uint;
            }
        }
        else if(!_float1._is_negative && _float2._is_negative) 
        {
            // if the absolute value of the first number which is positive is greater than the absolute value of the second number then the result is negative
            // else the result is positive and the sign is 0
            if(isGreaterThan(abs(_float2), _float1))
            {
                _result[0] = 0;
                _is_negative = true;
                ans = _float2._uint - _float1._uint;
            }
            else
            {
                _result[0] = 1;
                _is_negative = false;
                ans = _float1._uint - _float2._uint;
            }
        }

        // get the integer part of the result by dividing the integer by the decimal places
        _result[1] = uint256(ans) / 10**decimal;

        // turn the whole integer into a slice (string)
        strings.slice memory strSlice = (Strings.toString(ans)).toSlice();

        // get the decimal part by removing the integer part from the whole integer string
        strSlice.beyond(Strings.toString(_result[1]).toSlice());

        // trim the decimal part to the specified 'decimal' decimal places
        bytes memory strBytes = bytes(strSlice.toString());
        bytes memory decimalResult = new bytes(decimal);
        for(uint i = 0; i < decimal; i++) {
            decimalResult[i-0] = strBytes[i];
        }

        // add all parts including the decimal point "." to get the final string (without the sign)
        string memory stringFloat = (((Strings.toString(_result[1]).toSlice()).concat(".".toSlice())).toSlice()).concat((string(decimalResult).toSlice()));

        // add the negative sign "-" if the number is negative
        if(_result[0] == 0) {
            stringFloat = "-".toSlice().concat(stringFloat.toSlice());
        }

        // convert the decimal part to a uint256 from string
        _result[2] = uint256(_stringToNumber(string(decimalResult)));

        // return the result
        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: string(decimalResult),
            _string: stringFloat,
            _uint: ans,
            _is_negative: _result[0] == 0
        });
    }

    function sub(float memory _float1, float memory _float2) public pure returns (float memory)
    {
        uint256[3] memory _result;
        uint256 ans;
        bool _is_negative;

        // if the signs are both negative then the number to be subtracted is added to the number to be subtracted from i.e (-5) - (-2) = -3
        if(_float1._is_negative && _float2._is_negative)
        {
            // if the absolute value of the first number is greater than the absolute value of the second number then the result is negative i.e (-5) - (-2) = -3
            // else the result is positive and the sign is 0
            if(isGreaterThan(abs(_float1), abs(_float2)))
            {
                _result[0] = 0;
                _is_negative = true;
                ans = _float1._uint - _float2._uint;
            }
            else
            {
                _result[0] = 1;
                _is_negative = false;
                ans = _float2._uint - _float1._uint;
            }
        }
        // if both float have the same positve sign then the are subtracted from each other normally
        else if(!_float1._is_negative && !_float2._is_negative)
        {
            if(isGreaterThan((_float2), (_float1)))
            {   
                _result[0] = 0;
                _is_negative = true;
                ans = _float2._uint - _float1._uint;
            }
            else
            {
                _result[0] = 1;
                _is_negative = false;
                ans = _float1._uint - _float2._uint;
            }
        }        
        else if(_float1._is_negative && !_float2._is_negative) 
        {
            _result[0] = 0;
            _is_negative = true;
            ans = _float1._uint + _float2._uint;
        }
        else if(!_float1._is_negative && _float2._is_negative) 
        {
            _result[0] = 1;
            _is_negative = false;
            ans = _float2._uint + _float1._uint;
        }

        // get the integer part of the result by dividing the integer by the decimal places
        _result[1] = uint256(ans) / 10**decimal;

        // turn the whole integer into a slice (string)
        strings.slice memory strSlice = (Strings.toString(ans)).toSlice();

        // get the decimal part by removing the integer part from the whole integer string
        strSlice.beyond(Strings.toString(_result[1]).toSlice());

        // trim the decimal part to the specified 'decimal' decimal places
        bytes memory strBytes = bytes(strSlice.toString());
        bytes memory decimalResult = new bytes(decimal);

        for(uint i = 0; i < decimal; i++) {
            if (i >= strBytes.length) {
                decimalResult[i] = '0';
            }else{
                decimalResult[i] = strBytes[i];
            }
        }

        // add all parts including the decimal point "." to get the final string (without the sign)
        string memory stringFloat = (((Strings.toString(_result[1]).toSlice()).concat(".".toSlice())).toSlice()).concat((string(decimalResult).toSlice()));

        // add the negative sign "-" if the number is negative
        if(_result[0] == 0) {
            stringFloat = "-".toSlice().concat(stringFloat.toSlice());
        }

        // convert the decimal part to a uint256 from string
        _result[2] = uint256(_stringToNumber(string(decimalResult)));

        // return the result
        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: string(decimalResult),
            _string: stringFloat,
            _uint: ans,
            _is_negative: _result[0] == 0
        });
    }

    // round up number to the nearest integer
    function roundUp(float memory _float) public pure returns (float memory)
    {
        uint256[3] memory _result;
        bool _is_greater_or_equal_5000000000000 = (_float._value[2] * 10**decimal >= (5 * 10**decimal));

        _result[0] = _float._value[0];
        _result[1] = _float._value[1];
        _result[2] = 0 * 10**decimal;

        // if the decimal part is greater than 5000000000000 then the number is rounded up to the next integer
        if(_is_greater_or_equal_5000000000000)
        {
            _result[1] = _float._value[1] + 1;
        }

        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: string('0'),
            _string: (((Strings.toString(_result[1]).toSlice()).concat(".".toSlice())).toSlice()).concat((string('0').toSlice())),
            _uint: _float._value[1] * 10**decimal,
            _is_negative: _result[0] == 0
        });
    }

    // ceil function
    function ceil(float memory _float) public pure returns (float memory)
    {
        uint256[3] memory _result;

        _result[0] = _float._value[0];
        _result[2] = 0 * 10**decimal;
        _result[1] = _float._value[1] + 1;

        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: string('0'),
            _string: (((Strings.toString(_result[1]).toSlice()).concat(".".toSlice())).toSlice()).concat((string('0').toSlice())),
            _uint: _float._value[1] * 10**decimal,
            _is_negative: _result[0] == 0
        });
    }

    // floor function
    function floor(float memory _float) public pure returns (float memory)
    {
        uint256[3] memory _result;

        _result[0] = _float._value[0];
        _result[2] = 0 * 10**decimal;
        _result[1] = _float._value[1];

        return float({
            _value: _result, 
            _decimal: decimal, 
            _decimal_string: string('0'),
            _string: (((Strings.toString(_result[1]).toSlice()).concat(".".toSlice())).toSlice()).concat((string('0').toSlice())),
            _uint: _float._value[1] * 10**decimal,
            _is_negative: _result[0] == 0
        });
    }
    
    // check if floats are equal
    function isEqual(float memory _float1, float memory _float2) public pure returns (bool)
    {
        // if signs are the same
        if((_float1._value[0] == _float2._value[0]) && (_float1._value[1] == _float2._value[1]) && (_float1._value[2] == _float2._value[2]))
        {
            return true;
        }

        return false;
    }

    // check if the first float is greater than the second float using the array method .........isLessThan
    // so [0, 1, 8345] > [0, 1, 2345] taking into account the sign which is the first element
    function isLessThan(float memory _float1, float memory _float2) public pure returns (bool) {
        if (_float1._value[0] == 0 && _float2._value[0] == 1) {
            return true;
        }
        if (_float1._value[0] == 1 && _float2._value[0] == 0) {
            return false;
        }
        if (_float1._value[0] == 0 && _float2._value[0] == 0) {

            if(_float1._value[1] == _float2._value[1]) {
                if(_float1._value[2] > _float2._value[2]) {
                    return true;
                }
                return false;
            }

            if (_float1._value[1] > _float2._value[1]) {
                return true;
            } else {
                return false;
            }
        }

        if (_float1._value[0] == 1 && _float2._value[0] == 1) {

            if(_float1._value[1] == _float2._value[1]) {
                if(_float1._value[2] < _float2._value[2]) {
                    return true;
                }
                return false;
            }

            if (_float1._value[1] < _float2._value[1]) {
                return true;
            } else {
                return false;
            }
        }

        return false;
    }

    // check if the first float is less than the second float using the array method  ......isGreaterThan
    // so [0, 1, 8345] < [0, 1, 2345] taking into account the sign which is the first element
    function isGreaterThan(float memory _float1, float memory _float2) public pure returns (bool) {
        if (_float1._value[0] == 0 && _float2._value[0] == 1) {
            return false;
        }
        if (_float1._value[0] == 1 && _float2._value[0] == 0) {
            return true;
        }

        if (_float1._value[0] == 0 && _float2._value[0] == 0) {
            if(_float1._value[1] == _float2._value[1]) {
                if(_float1._value[2] < _float2._value[2]) {
                    return true;
                }
                return false;
            }

            if (_float1._value[1] < _float2._value[1]) {
                return true;
            } else {
                return false;
            }
        }

        if (_float1._value[0] == 1 && _float2._value[0] == 1) {
            if(_float1._value[1] == _float2._value[1]) {
                if(_float1._value[2] > _float2._value[2]) {
                    return true;
                }
                return false;
            }

            if (_float1._value[1] > _float2._value[1]) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    // greater than or equal to
    function isGreaterOrEquals(float memory _float1, float memory _float2) public pure returns (bool) {
        return isGreaterThan(_float1, _float2) || isEqual(_float1, _float2);
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