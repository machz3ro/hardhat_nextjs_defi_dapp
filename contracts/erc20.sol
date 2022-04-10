//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract OwaneToken is ERC20 {
    constructor() ERC20("Owane", "OWA") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
