// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";


contract GratieToken is ERC20Upgradeable, OwnableUpgradeable {

    string public iconURI;
    uint256 public claimAmount;
    uint256 public claimLimit;
    mapping(address => uint256) public claims;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _iconURI,
        uint256 _supply,
        uint256 _claimAmount
    ) external initializer {
        iconURI = _iconURI;
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _supply - _claimAmount);
        _mint(address(this), _claimAmount);
        claimAmount = _claimAmount;
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

    function claim() external {
        require(
            claims[msg.sender] <= claimLimit,
            "Claim Limit reached!"
        );
        ++claims[msg.sender];
        transfer(msg.sender, claimAmount);
    }

    function updateClaimLimit(uint256 _claimLimit) external onlyOwner {
        claimLimit = _claimLimit;
    }
}
