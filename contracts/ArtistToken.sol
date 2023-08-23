//pragma solidity ^0.8.0;
//
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//
//contract ArtistToken is ERC20 {
//    constructor(uint256 initialSupply) ERC20("ArtistToken", "ETB") {
//        _mint(msg.sender, initialSupply * 10**uint256(decimals()));
//    }
//}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ArtistToken is ERC20 {
    address public entertaBlock;

    constructor(uint256 initialSupply) ERC20("ArtistToken", "ETB") {
        _mint(msg.sender, initialSupply * 10**uint256(decimals()));
    }

    function setEntertaBlock(address _entertaBlock) external {
        require(_entertaBlock != address(0), "Invalid address");
        entertaBlock = _entertaBlock;
    }
}

