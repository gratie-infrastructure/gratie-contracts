// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BusinessNFT is ERC721URIStorageUpgradeable, OwnableUpgradeable {
    address public gratieContract;
    uint256 public totalSupply;

    event Minted(
        address reciever,
        uint256 tokenId,
        string metadataURI,
        string name
    );

    modifier onlyGratieContract() {
        require(msg.sender == gratieContract, "Only Gratie Contract allowed!");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(
        string calldata _name,
        string calldata _symbol
    ) external initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
    }

    function setGratieContract(
        address _gratieContract
    ) external reinitializer(2) {
        gratieContract = _gratieContract;
    }

    function mint(
        address _receiver,
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyOwner {
        ++totalSupply;
        _safeMint(_receiver, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        emit Minted(_receiver, totalSupply, _tokenURI, name());
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
        for (uint256 i; i < _receivers.length; ) {
            _safeMint(_receivers[i], _tokenIds[i]);
            _setTokenURI(_tokenIds[i], _tokenURIs[i]);
            unchecked {
                ++i;
            }
        }
    }
}
