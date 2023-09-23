// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";



contract RewardToken is ERC20Upgradeable {

    address public gratieContract;
    string public iconURI;

    modifier onlyGratieContract() {
        require(
            msg.sender == gratieContract,
            "Only Gratie Contract allowed!"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _iconURI,
        address _gratieContract
    ) external initializer {
        __ERC20_init(_name, _symbol);
        iconURI = _iconURI;
        gratieContract = _gratieContract;
    }

    function mint(
        address _receiver,
        uint256 _amount
    ) external onlyGratieContract {
        _mint(_receiver, _amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}
