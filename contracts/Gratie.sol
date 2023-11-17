// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./BusinessNFTs.sol";
import "./ServiceProviderNFTs.sol";

interface IERC20Mintable is IERC20Upgradeable {
    function mint(address _receiver, uint256 _amount) external;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _iconURI,
        address _gratieContract
    ) external;
}

interface IERC721 is IERC721Upgradeable {
    function mint(
        address _receiver,
        uint256 _tokenId,
        string memory _tokenURI
    ) external;

    function mintBatch(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenURIs
    ) external;
}

interface IERC1155 is IERC1155Upgradeable {
    function mint(
        address _receiver,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function mintBatch(
        address[] calldata _receivers,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) external;

    function burn(address _from, uint256 _id, uint256 _amount) external;
}

contract Gratie is
    AccessControlUpgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    string public domainName;
    string public domainVersion;

    address public platformFeeReceiver;
    BusinessNFT public businessNFTs;
    BusinessNFT public businessNFT;
    ServiceProviderNFT public serviceProviderNFTs;
    address public serviceProviderNFT;
    IERC20Upgradeable public usdc;
    address public rewardTokenImplementation;

    uint256 public totalBusinessNftTiers;
    uint256 public totalBusinesses;
    uint256 public totalDivisions;

    bytes32 public constant GRATIE_PLATFORM_ADMIN =
        keccak256("GRATIE_PLATFORM_ADMIN");

    bytes32 private constant _REWARD_MINT_TYPEHASH =
        keccak256(
            "RewardTokenMint(uint256 businessId,uint256 amount,uint256 lockInPercentage,uint256 mintNonce)"
        );

    bytes32 public constant _PAYMENT_TYPEHASH =
        keccak256(
            "Payment(address method,uint256 amount,uint256 tierID,address buyer)"
        );

    struct Payment {
        address method;
        uint256 amount;
    }

    struct BusinessNftTier {
        string name;
        string ipfsMetadataLink;
        uint256 usdcPrice;
        uint256 freeUsersCount;
        uint256 usdcPerAdditionalUser;
        uint256 platformFee;
        bool isActive;
    }

    struct ServiceProviderDivision {
        string name;
        string ipfsMetadataLink;
        uint256 serviceProviderNftID;
        uint256 serviceProvidersInDivision;
    }

    struct Business {
        string name;
        string email;
        address rewardToken;
        uint256 businessId;
        uint256 businessNftTier;
        uint256 businessValuation;
        uint256 tokenDistribution;
        uint256 divisionsInBusiness;
        uint256 totalServiceProviders;
        mapping(uint256 => ServiceProviderDivision) serviceProviderDivisions;
    }

    struct RewardTokenMint {
        uint256 businessId;
        uint256 amount;
        uint256 lockInPercentage;
        uint256 mintNonce;
    }

    struct RewardTokenDistribution {
        uint256 totalServiceProviders;
        uint256 tokensPerProvider;
        uint256 startTimestamp;
        uint256 percentageToDistribute;
        uint256 availableRewardTokens;
        uint256 claimsDone;
    }

    struct BusinessData {
        string name;
        string email;
        string nftMetadataURI;
        uint256 businessNftTier;
        uint256 valuation;
        uint256 tokenDistribution;
    }

    struct InitData {
        string domainName;
        string domainVersion;
        address platformFeeReceiver;
        address businessNFTs;
        address serviceProviderNFTs;
        address rewardTokenImplementation;
        address defaultAdminAddress;
        address usdcContractAddress;
        address[] paymentMethods;
        address[] gratiePlatformAdmins;
        BusinessNftTier[] businessNftTiers;
    }

    mapping(uint256 => BusinessNftTier) public businessNftTiers;
    mapping(address => Business) public businesses;
    mapping(uint256 => uint256) public divisionNftIdToBusinessNftId;
    mapping(uint256 => uint256) public rewardTokenMints;

    mapping(uint256 => uint256) public rewardTokensAvailable;
    mapping(uint256 => uint256) public rewardTokensDistributed;
    mapping(uint256 => mapping(address => uint256))
        public serviceProviderRegisteredAt;
    mapping(uint256 => uint256) public rewardDistributionsCreated;
    mapping(uint256 => mapping(uint256 => RewardTokenDistribution))
        public rewardDistributions;
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        public hasClaimedRewards;
    mapping(address => bool) public isValidPaymentMethod;

    // modifiers
    modifier isPlatformAdmin() {
        bool allowed = hasRole(GRATIE_PLATFORM_ADMIN, msg.sender);
        require(allowed, "Only Admin is Allowed!");
        _;
    }

    modifier isDefaultAdmin() {
        bool allowed = hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(allowed, "Only Business is Allowed!");
        _;
    }

    // Events
    event BusinessNftTierAdded(
        address indexed by,
        uint256 indexed tierID,
        BusinessNftTier tier,
        uint256 timestamp
    );

    event BusinessNftTiersActivated(
        address indexed by,
        uint256[] ids,
        uint256 timestamp
    );

    event BusinessNftTiersDeactivated(
        address indexed by,
        uint256[] ids,
        uint256 timestamp
    );

    event BusinessRegistered(
        address indexed by,
        uint256 indexed businessID,
        uint256 indexed businessNftTier,
        string name,
        string email,
        uint256 divisionsCreated,
        ServiceProviderDivision[] divisions,
        string paymentMethod,
        uint256 paymentAmount,
        uint256 timestamp
    );

    event BusinessRegisteredByOwner(
        address indexed by,
        uint256 indexed businessID,
        uint256 indexed businessNftTier,
        address to,
        string name,
        string email,
        uint256 divisionsCreated,
        ServiceProviderDivision[] divisions,
        uint256 timestamp
    );

    event ServiceProviderDivisionAdded(
        address indexed by,
        uint256 indexed businessID,
        uint256 indexed serviceProviderNftID,
        uint256 divisionNumber,
        string name,
        string ipfsMetadataLink,
        uint256 timestamp
    );

    event ServiceProvidersRegistered(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed divisionId,
        address[] addresses,
        uint256 usdcPlatformFeePaid,
        uint256 timestamp
    );

    event ServiceProvidersRemoved(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed divisionId,
        address[] addresses,
        uint256 timestamp
    );

    event RewardTokensGenerated(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed mintNonce,
        address rewardToken,
        uint256 amount,
        uint256 lockInPercentage,
        uint256 totalSupply,
        string tokenName,
        string tokenSymbol,
        string tokenIconURL,
        uint256 timestamp
    );

    event RewardDistributionCreated(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed distributionNo,
        uint256 totalServiceProviders,
        uint256 percentageToDistribute,
        uint256 availableRewardTokens,
        uint256 tokensPerProvider,
        uint256 startTimestamp
    );

    event RewardTokensClaimed(
        address indexed by,
        uint256 indexed businessId,
        uint256 indexed distributionNo,
        address rewardToken,
        uint256 amount,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(InitData memory _initData) external initializer {
        __Ownable_init();
        __EIP712_init(_initData.domainName, _initData.domainVersion);
        _grantRole(DEFAULT_ADMIN_ROLE, _initData.defaultAdminAddress);

        domainName = _initData.domainName;
        domainVersion = _initData.domainVersion;
        platformFeeReceiver = _initData.platformFeeReceiver;
        businessNFTs = BusinessNFT(_initData.businessNFTs);
        businessNFTs.initialize("Gratie Business NFTs", "GBN");
        serviceProviderNFTs = ServiceProviderNFT(_initData.serviceProviderNFTs);
        serviceProviderNFTs.initialize("Gratie Service Provider NFTs", "GSPN");
        usdc = IERC20Upgradeable(_initData.usdcContractAddress);
        rewardTokenImplementation = _initData.rewardTokenImplementation;

        for (uint256 i; i < _initData.gratiePlatformAdmins.length; i++) {
            _grantRole(
                GRATIE_PLATFORM_ADMIN,
                _initData.gratiePlatformAdmins[i]
            );
        }

        for (uint256 i; i < _initData.paymentMethods.length; i++) {
            isValidPaymentMethod[_initData.paymentMethods[i]] = true;
        }

        _addBusinessNftTiers(_initData.businessNftTiers);
    }

    function addBusinessNftTiers(
        BusinessNftTier[] memory _tiers
    ) external onlyOwner {
        _addBusinessNftTiers(_tiers);
    }

    function registerBusiness(
        BusinessData memory _businessData,
        string[] memory _divisionNames,
        string[] memory _divisionMetadataURIs,
        Payment memory _payment
    ) external payable {
        require(
            _businessData.businessNftTier > 0 &&
                _businessData.businessNftTier <= totalBusinessNftTiers,
            "Invalid Business NFT Tier!"
        );
        require(
            isValidPaymentMethod[_payment.method],
            "Invalid Payment Method!"
        );

        require(businessNFTs.balanceOf(msg.sender) == 0, "Already a business!");

        if (_payment.method == address(0)) {
            require(msg.value == _payment.amount, "Invalid ether sent!");
        } else {
            require(msg.value == 0, "Ether sent with ERC-20 purchase!");
        }

        BusinessNftTier memory tierData = businessNftTiers[
            _businessData.businessNftTier
        ];

        require(tierData.isActive, "Inactive business nft tier!");

        Business storage business = businesses[msg.sender];
        business.name = _businessData.name;
        business.email = _businessData.email;
        business.businessId = ++totalBusinesses;
        business.businessNftTier = _businessData.businessNftTier;
        business.businessValuation = 0;
        business.tokenDistribution = 0;
        ServiceProviderDivision[] memory _divisions = _addDivisionsInBusiness(
            msg.sender,
            totalBusinesses,
            _divisionNames,
            _divisionMetadataURIs
        );

        // Transfer payment value from msg.sender to platform fee receiver.
        if (_payment.method == address(0) && _payment.amount > 0) {
            sendValue(platformFeeReceiver, _payment.amount);
        }

        if (_payment.method != address(0) && _payment.amount > 0) {
            IERC20Upgradeable(_payment.method).transferFrom(
                msg.sender,
                platformFeeReceiver,
                _payment.amount
            );
        }

        // Mint ERC-721 NFT
        // address(businessNFT).call(
        //     abi.encodeWithSignature(
        //         "mint(address, uint256, string)",
        //         address(msg.sender),
        //         totalBusinesses,
        //         _businessData.nftMetadataURI
        //     )
        // );
        // require(success, "Minting failed");

        businessNFTs.mint(
            msg.sender,
            totalBusinesses,
            _businessData.nftMetadataURI
        );

        emit BusinessRegistered(
            msg.sender,
            totalBusinesses,
            _businessData.businessNftTier,
            _businessData.name,
            _businessData.email,
            _divisionNames.length,
            _divisions,
            "USDC",
            tierData.usdcPrice,
            block.timestamp
        );
    }

    function registerBusinessByOwner(
        address _to,
        string memory _name,
        string memory _email,
        string memory _nftMetadataURI,
        uint256 _businessNftTier,
        uint256 _businessValuation,
        uint256 _tokenDistribution,
        string[] memory _divisionNames,
        string[] memory _divisionMetadataURIs
    ) external onlyOwner {
        require(businessNFTs.balanceOf(_to) == 0, "Already a business!");
        require(
            _businessNftTier > 0 && _businessNftTier <= totalBusinessNftTiers,
            "Invalid Business NFT Tier!"
        );
        BusinessNftTier memory tierData = businessNftTiers[_businessNftTier];

        require(tierData.isActive, "Inactive business nft tier!");

        Business storage business = businesses[_to];
        business.name = _name;
        business.email = _email;
        business.businessNftTier = _businessNftTier;
        business.businessValuation = _businessValuation;
        business.tokenDistribution = _tokenDistribution;

        ServiceProviderDivision[] memory _divisions = _addDivisionsInBusiness(
            _to,
            totalBusinesses,
            _divisionNames,
            _divisionMetadataURIs
        );

        // Mint ERC-721 NFT
        businessNFTs.mint(_to, totalBusinesses, _nftMetadataURI);

        emit BusinessRegisteredByOwner(
            msg.sender,
            totalBusinesses,
            _businessNftTier,
            _to,
            _name,
            _email,
            _divisionNames.length,
            _divisions,
            block.timestamp
        );
    }

    function addCompanyValuation(
        uint256 _businessID,
        uint256 _businessValuation,
        uint256 _tokenDistribution
    ) external {
        require(
            businessNFTs.ownerOf(_businessID) == msg.sender,
            "Not the Business NFT Owner"
        );

        businesses[msg.sender].businessValuation = _businessValuation;
        businesses[msg.sender].tokenDistribution = _tokenDistribution;
    }

    function addDivisionsInBusiness(
        uint256 _businessID,
        string[] memory _divisionNames,
        string[] memory _divisionMetadataURIs
    ) external {
        require(
            businessNFTs.ownerOf(_businessID) == msg.sender,
            "Not the Business NFT Owner!"
        );
        _addDivisionsInBusiness(
            msg.sender,
            _businessID,
            _divisionNames,
            _divisionMetadataURIs
        );
    }

    function registerServiceProviders(
        uint256 _businessID,
        uint256 _divisionID,
        address[] memory _serviceProviders
    ) external {
        require(
            _businessID > 0 && _businessID <= totalBusinesses,
            "Invalid business id!"
        );
        require(
            msg.sender == businessNFTs.ownerOf(_businessID),
            "Not the business nft owner!"
        );
        Business storage business = businesses[msg.sender];
        require(
            _divisionID > 0 && _divisionID <= business.divisionsInBusiness,
            "Invalid division id!"
        );
        business.totalServiceProviders += _serviceProviders.length;
        business
            .serviceProviderDivisions[_divisionID]
            .serviceProvidersInDivision += _serviceProviders.length;

        uint256 usdcAmount;
        BusinessNftTier memory tier = businessNftTiers[
            business.businessNftTier
        ];
        // Charge business if total service providers cross free users as specified in the nft tier.
        if (business.totalServiceProviders > tier.freeUsersCount) {
            if (
                business.totalServiceProviders - _serviceProviders.length >=
                tier.freeUsersCount
            ) {
                usdcAmount =
                    tier.usdcPerAdditionalUser *
                    _serviceProviders.length;
            } else {
                usdcAmount =
                    tier.usdcPerAdditionalUser *
                    (business.totalServiceProviders - tier.freeUsersCount);
            }
            IERC20Upgradeable(usdc).transferFrom(
                msg.sender,
                platformFeeReceiver,
                usdcAmount
            );
        }
        uint256 _tokenID = business
            .serviceProviderDivisions[_divisionID]
            .serviceProviderNftID;

        for (uint256 i; i < _serviceProviders.length; ) {
            require(
                serviceProviderNFTs.balanceOf(_serviceProviders[i], _tokenID) ==
                    0,
                "Already a service provider!"
            );
            serviceProviderNFTs.mint(_serviceProviders[i], _tokenID, 1);
            serviceProviderRegisteredAt[_businessID][
                _serviceProviders[i]
            ] = block.timestamp;
            unchecked {
                ++i;
            }
        }

        emit ServiceProvidersRegistered(
            msg.sender,
            _businessID,
            _divisionID,
            _serviceProviders,
            usdcAmount,
            block.timestamp
        );
    }

    function removeServiceProviders(
        uint256 _businessID,
        uint256 _divisionID,
        address[] memory _serviceProviders
    ) external {
        require(
            _businessID > 0 && _businessID <= totalBusinesses,
            "Invalid business id!"
        );
        require(
            msg.sender == businessNFTs.ownerOf(_businessID),
            "Not the business nft owner!"
        );
        Business storage business = businesses[msg.sender];
        require(
            _divisionID > 0 && _divisionID <= business.divisionsInBusiness,
            "Invalid division id!"
        );

        businesses[msg.sender].totalServiceProviders -= _serviceProviders
            .length;
        businesses[msg.sender]
            .serviceProviderDivisions[_divisionID]
            .serviceProvidersInDivision -= _serviceProviders.length;

        uint256 _nftId = businesses[msg.sender]
            .serviceProviderDivisions[_divisionID]
            .serviceProviderNftID;
        for (uint256 i; i < _serviceProviders.length; ) {
            require(
                serviceProviderNFTs.balanceOf(_serviceProviders[i], _nftId) > 0,
                "Not a service provider!"
            );
            serviceProviderRegisteredAt[_businessID][_serviceProviders[i]] = 0;
            serviceProviderNFTs.burn(_serviceProviders[i], _nftId, 1);
            unchecked {
                ++i;
            }
        }

        emit ServiceProvidersRemoved(
            msg.sender,
            _businessID,
            _divisionID,
            _serviceProviders,
            block.timestamp
        );
    }

    function generateRewardTokens(
        RewardTokenMint memory _data,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenIconURL
    ) external {
        require(
            msg.sender == businessNFTs.ownerOf(_data.businessId),
            "Not the business owner!"
        );
        require(
            _data.mintNonce == ++rewardTokenMints[_data.businessId],
            "Invalid mint nonce!"
        );
        require(_data.lockInPercentage <= 10000, "Invalid lock in percentage!");

        address rewardToken = businesses[msg.sender].rewardToken;
        if (rewardToken == address(0)) {
            rewardToken = ClonesUpgradeable.clone(rewardTokenImplementation);
            IERC20Mintable(rewardToken).initialize(
                _tokenName,
                _tokenSymbol,
                _tokenIconURL,
                address(this)
            );
            businesses[msg.sender].rewardToken = rewardToken;
        }

        uint256 platformFee = (businessNftTiers[
            businesses[msg.sender].businessNftTier
        ].platformFee * _data.amount) / 10000;
        uint256 lockInAmount = (_data.lockInPercentage * _data.amount) / 10000;
        rewardTokensAvailable[_data.businessId] += lockInAmount;

        IERC20Mintable(rewardToken).mint(address(this), lockInAmount);
        IERC20Mintable(rewardToken).mint(owner(), platformFee);
        IERC20Mintable(rewardToken).mint(
            msg.sender,
            _data.amount - platformFee - lockInAmount
        );

        emit RewardTokensGenerated(
            msg.sender,
            _data.businessId,
            _data.mintNonce,
            rewardToken,
            _data.amount,
            _data.lockInPercentage,
            IERC20Mintable(rewardToken).totalSupply(),
            _tokenName,
            _tokenSymbol,
            _tokenIconURL,
            block.timestamp
        );
    }

    function startRewardDistribution(
        uint256 _businessID,
        uint256 _percentageToDistribute
    ) external {
        require(
            msg.sender == businessNFTs.ownerOf(_businessID),
            "Not the business owner!"
        );
        require(
            _percentageToDistribute > 0 && _percentageToDistribute <= 10000,
            "Invalid distribution percentage!"
        );
        require(
            rewardTokensAvailable[_businessID] > 0,
            "No reward tokens available to distribute!"
        );
        uint256 tokensPerProvider = (_percentageToDistribute *
            rewardTokensAvailable[_businessID]) /
            (10000 * businesses[msg.sender].totalServiceProviders);

        rewardDistributions[_businessID][
            ++rewardDistributionsCreated[_businessID]
        ] = RewardTokenDistribution(
            businesses[msg.sender].totalServiceProviders,
            tokensPerProvider,
            block.timestamp,
            _percentageToDistribute,
            rewardTokensAvailable[_businessID],
            0
        );
        emit RewardDistributionCreated(
            msg.sender,
            _businessID,
            rewardDistributionsCreated[_businessID],
            businesses[msg.sender].totalServiceProviders,
            _percentageToDistribute,
            rewardTokensAvailable[_businessID],
            tokensPerProvider,
            block.timestamp
        );
    }

    function claimRewardTokens(
        address _businessOwner,
        uint256 _businessID,
        uint256 _distributionNo
    ) external {
        require(
            _businessID > 0 && _businessID <= totalBusinesses,
            "Invalid business id!"
        );
        RewardTokenDistribution storage _distribution = rewardDistributions[
            _businessID
        ][_distributionNo];
        require(_distribution.startTimestamp != 0, "Invalid distribution no!");
        require(
            serviceProviderRegisteredAt[_businessID][msg.sender] > 0 &&
                serviceProviderRegisteredAt[_businessID][msg.sender] <=
                _distribution.startTimestamp,
            "Not eligible for this distribution!"
        );
        require(
            hasClaimedRewards[msg.sender][_businessID][_distributionNo] ==
                false,
            "Already Claimed!"
        );

        rewardTokensAvailable[_businessID] -= _distribution.tokensPerProvider;
        rewardTokensDistributed[_businessID] += _distribution.tokensPerProvider;
        hasClaimedRewards[msg.sender][_businessID][_distributionNo] = true;
        _distribution.claimsDone += 1;

        IERC20Upgradeable(businesses[_businessOwner].rewardToken).transfer(
            msg.sender,
            _distribution.tokensPerProvider
        );

        emit RewardTokensClaimed(
            msg.sender,
            _businessID,
            _distributionNo,
            businesses[_businessOwner].rewardToken,
            _distribution.tokensPerProvider,
            block.timestamp
        );
    }

    function _addBusinessNftTiers(BusinessNftTier[] memory _tiers) private {
        for (uint256 i; i < _tiers.length; ) {
            unchecked {
                businessNftTiers[++totalBusinessNftTiers] = _tiers[i];
                emit BusinessNftTierAdded(
                    msg.sender,
                    totalBusinessNftTiers,
                    _tiers[i],
                    block.timestamp
                );
                ++i;
            }
        }
    }

    function _addDivisionsInBusiness(
        address _businessOwner,
        uint256 _businessID,
        string[] memory _divisionNames,
        string[] memory _divisionMetadataURIs
    ) private returns (ServiceProviderDivision[] memory) {
        require(
            _divisionNames.length == _divisionMetadataURIs.length,
            "Invalid arrays!"
        );

        ServiceProviderDivision[]
            memory _divisions = new ServiceProviderDivision[](
                _divisionNames.length
            );
        for (uint256 i; i < _divisionNames.length; ) {
            unchecked {
                Business storage business = businesses[_businessOwner];
                ServiceProviderDivision
                    memory _newDivision = ServiceProviderDivision(
                        _divisionNames[i],
                        _divisionMetadataURIs[i],
                        ++totalDivisions,
                        0
                    );
                _divisions[i] = _newDivision;

                business.serviceProviderDivisions[
                    ++business.divisionsInBusiness
                ] = _newDivision;
                divisionNftIdToBusinessNftId[totalDivisions] = _businessID;
                // Set Metadata URI
                //  serviceProviderNFT.call(
                //     abi.encodeWithSignature(
                //         "setTokenURI(uint256, string)",
                //         totalDivisions,
                //         _divisionMetadataURIs[i]
                //     )
                // );

                serviceProviderNFTs.setTokenURI(
                    totalDivisions,
                    _divisionMetadataURIs[i]
                );

                emit ServiceProviderDivisionAdded(
                    msg.sender,
                    _businessID,
                    totalDivisions,
                    business.divisionsInBusiness,
                    _divisionNames[i],
                    _divisionMetadataURIs[i],
                    block.timestamp
                );
                ++i;
            }
        }
        return _divisions;
    }

    function sendValue(address recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient matic balance!");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "MATIC payment failed!");
    }

    function _getMintSigner(
        RewardTokenMint memory _data,
        bytes memory _signature
    ) private view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _REWARD_MINT_TYPEHASH,
                    _data.businessId,
                    _data.amount,
                    _data.lockInPercentage,
                    _data.mintNonce
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, _signature);
    }

    function _getPaymentSigner(
        Payment memory _payment,
        bytes memory _signature,
        uint256 _tierID
    ) private view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _PAYMENT_TYPEHASH,
                    _payment.method,
                    _payment.amount,
                    _tierID,
                    msg.sender
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, _signature);
    }

    // function grantAdminRole(address _address, bool _status) public isAdmin {
    //     adminAddresses[_address] = _status;
    // }
    //
    // function changeBusinessStatus(address _address) public isAdmin {
    //     require(!approvedBusinesses[_address], "Business already registered!");
    //     approvedBusinesses[_address] = true;
    // }
}
