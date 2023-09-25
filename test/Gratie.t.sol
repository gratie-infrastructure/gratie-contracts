// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";
import "../contracts/Gratie.sol";
import "../contracts/MockERC20.sol";
import "../contracts/ProxyAdmin.sol";
import "../contracts/RewardToken.sol";
import "../contracts/BusinessNFTs.sol";
import "../contracts/ServiceProviderNFTs.sol";

contract GratieTest is Test {
    Gratie public gratie;
    USDCMock public usdcContract;
    ProxyAdmin public proxyAdmin;
    RewardToken public rewardToken;
    BusinessNFT public businessNft;
    ServiceProviderNFT public serviceProviderNft;
    TransparentUpgradeableProxy public transparentUpgradeableProxy;

    struct BusinessNftTier {
        string name;
        string ipfsMetadataLink;
        uint256 usdcPrice;
        uint256 freeUsersCount;
        uint256 usdcPerAdditionalUser;
        uint256 platformFee;
        bool isActive;
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

    struct BusinessData {
        string name;
        string email;
        string nftMetadataURI;
        uint256 businessNftTier;
    }

    struct Payment {
        address method;
        uint256 amount;
    }

    function setUp() public {
        gratie = new Gratie();
        usdcContract = new USDCMock();
        proxyAdmin = new ProxyAdmin(address(500));
        rewardToken = new RewardToken();
        businessNft = new BusinessNFT();
        serviceProviderNft = new ServiceProviderNFT();

        BusinessNftTier[] memory _businessNftTier = new BusinessNftTier[](1);

        _businessNftTier[0].name = "Test";
        _businessNftTier[0].ipfsMetadataLink = "ipfs://something";
        _businessNftTier[0].usdcPrice = 30;
        _businessNftTier[0].freeUsersCount = 1;
        _businessNftTier[0].usdcPerAdditionalUser = 5;
        _businessNftTier[0].platformFee = 2;
        _businessNftTier[0].isActive = true;

        address[] memory gratiePlatformAdmins = new address[](1);
        gratiePlatformAdmins[0] = address(1000);

        address[] memory paymentMethods = new address[](2);
        paymentMethods[0] = address(usdcContract);
        paymentMethods[1] = address(0);

        InitData memory _initData = InitData({
            domainName: "gratie.com",
            domainVersion: "v1",
            platformFeeReceiver: address(700),
            businessNFTs: address(businessNft),
            serviceProviderNFTs: address(serviceProviderNft),
            rewardTokenImplementation: address(rewardToken),
            defaultAdminAddress: address(777),
            usdcContractAddress: address(usdcContract),
            paymentMethods: paymentMethods,
            gratiePlatformAdmins: gratiePlatformAdmins,
            businessNftTiers: _businessNftTier
        });

        transparentUpgradeableProxy = new TransparentUpgradeableProxy(
            address(gratie),
            address(proxyAdmin),
            abi.encodeWithSignature(
                "initialize((string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[]))",
                _initData
            )
        );

        gratie = Gratie(address(transparentUpgradeableProxy));
        console.log("Gratie Address: ", address(gratie));

        // transparentUpgradeableProxy.initialize(_initData);
    }

    function testIsDomainNameIsSet() public {
        string memory _name = "gratie.com";
        bytes32 name = keccak256(abi.encodePacked(_name));
        bytes32 domain = keccak256(abi.encodePacked(gratie.domainName()));
        assertTrue(domain == name);
    }

    function testBusinessCanRegister() public {
        BusinessData memory _businessData = BusinessData({
            name: "Zoo",
            email: "Zoo@gratie.com",
            nftMetadataURI: "ipfs://zoodata/metadata.json",
            businessNftTier: 1
        });

        string[] memory _divisionNames = new string[](1);
        _divisionNames[0] = "Zoo1";

        string[] memory _divisionMetadataURIs = new string[](1);
        _divisionNames[0] = "ipfs://zoodata/metadata1.json";

        Payment memory _payment = Payment({method: address(0), amount: 1});

        gratie.registerBusiness{value: 1}(
            _businessData,
            _divisionNames,
            _divisionMetadataURIs,
            _payment
        );
    }
}
