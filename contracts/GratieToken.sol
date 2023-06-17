// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract GratieToken is ERC20Upgradeable, OwnableUpgradeable {

    string public iconURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _iconURI,
        uint256 _supply
    ) external initializer {
        iconURI = _iconURI;
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _supply);
    }

    function mint(
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        _mint(_receiver, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
