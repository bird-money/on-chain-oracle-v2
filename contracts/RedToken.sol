pragma solidity 0.6.12;

// © 2020 Bird Money
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RedToken is ERC20("Red Token", "RED") {
    constructor() public {
        _mint(msg.sender, 10000 ether);
    }
}

// make video of hours given
// how to make erc20 change title