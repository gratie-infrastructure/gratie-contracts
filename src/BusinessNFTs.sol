// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";


contract BusinessNFT is ERC721URIStorageUpgradeable {

    address public gratieContract;
    uint256 public totalSupply;

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
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
    }

    function setGratieContract(address _gratieContract) external reinitializer(2) {
        gratieContract = _gratieContract;
    }

    function mint(
        address _receiver,
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyGratieContract {
        ++totalSupply;
        _safeMint(_receiver, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }


    function mintBatch(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) external onlyGratieContract {
        require(
            _receivers.length == _tokenIds.length &&
            _receivers.length == _tokenURIs.length,
            "Invalid array lengths!"
        );
        totalSupply += _tokenIds.length;
        for(uint256 i; i<_receivers.length;) {
            _safeMint(_receivers[i], _tokenIds[i]);
            _setTokenURI(_tokenIds[i], _tokenURIs[i]);
            unchecked { ++i; }
        }
    }
}
