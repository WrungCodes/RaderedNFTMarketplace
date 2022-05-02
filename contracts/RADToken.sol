// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
* @title RadToken
* This token is used for all payments in the Rad project. (Universe and MarketPlace)
*/
contract RADToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Radverse Token", "RAD") {
        _mint(msg.sender, initialSupply);
    }
}