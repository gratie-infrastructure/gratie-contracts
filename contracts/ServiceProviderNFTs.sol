// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";


contract ServiceProviderNFT is ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable {

    string public name;
    string public symbol;
    address public gratieContract;

    modifier onlyGratieContract() {
        require(
            msg.sender == gratieContract,
            "Only Gratie Contract allowed!"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        name = _name;
        symbol = _symbol;
    }
    
    function setGratieContract(address _gratieContract) external reinitializer(2) {
        gratieContract = _gratieContract;
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) external onlyGratieContract {
        _setURI(_tokenId, _tokenURI);
    }


    function mint(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyGratieContract {
        _mint(_receiver, _tokenId, _amount, "");
    }


    function mintBatch(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlyGratieContract {
        require(
            _receivers.length == _tokenIds.length,
            "Invalid array lengths!"
        );

        for(uint256 i; i<_receivers.length;) {
            _mint(_receivers[i], _tokenIds[i], _amounts[i], "");
            unchecked { ++i; }
        }
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override onlyGratieContract {
        super.safeTransferFrom(from, to, id, amount, data);
    }


    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyGratieContract {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }


    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external onlyGratieContract {
        _burn(_from, _id, _amount);
    }


    function burnBatch(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyGratieContract {
        _burnBatch(_from, _ids, _amounts);
    }


    function uri(uint256 _tokenId) public view virtual override(
        ERC1155Upgradeable,
        ERC1155URIStorageUpgradeable
    ) returns (string memory) {
        return ERC1155URIStorageUpgradeable.uri(_tokenId);
    }


    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        ERC1155SupplyUpgradeable._beforeTokenTransfer(
            _operator,
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
    }
}
