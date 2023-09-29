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

    address public DefaultAdminAddress = address(10);
    address public PlatformAdminAddress = address(11);
    address public PlatformFeeReceiver = address(12);
    address public orignailGratie;

    // struct BusinessNftTier {
    //     string name;
    //     string ipfsMetadataLink;
    //     uint256 usdcPrice;
    //     uint256 freeUsersCount;
    //     uint256 usdcPerAdditionalUser;
    //     uint256 platformFee;
    //     bool isActive;
    // }
    //
    // struct InitData {
    //     string domainName;
    //     string domainVersion;
    //     address platformFeeReceiver;
    //     address businessNFTs;
    //     address serviceProviderNFTs;
    //     address rewardTokenImplementation;
    //     address defaultAdminAddress;
    //     address usdcContractAddress;
    //     address[] paymentMethods;
    //     address[] gratiePlatformAdmins;
    //     BusinessNftTier[] businessNftTiers;
    // }

    function setUp() public {
        gratie = new Gratie();
        orignailGratie = address(gratie);
        usdcContract = new USDCMock();
        proxyAdmin = new ProxyAdmin(address(500));
        rewardToken = new RewardToken();
        businessNft = new BusinessNFT();
        serviceProviderNft = new ServiceProviderNFT(address(gratie));

        Gratie.BusinessNftTier[]
            memory _businessNftTier = new Gratie.BusinessNftTier[](1);

        _businessNftTier[0].name = "Test";
        _businessNftTier[0].ipfsMetadataLink = "ipfs://something";
        _businessNftTier[0].usdcPrice = 30;
        _businessNftTier[0].freeUsersCount = 1;
        _businessNftTier[0].usdcPerAdditionalUser = 5;
        _businessNftTier[0].platformFee = 2;
        _businessNftTier[0].isActive = true;

        address[] memory gratiePlatformAdmins = new address[](1);
        gratiePlatformAdmins[0] = PlatformAdminAddress;

        address[] memory paymentMethods = new address[](2);
        paymentMethods[0] = address(usdcContract);
        paymentMethods[1] = address(0);

        Gratie.InitData memory _initData = Gratie.InitData({
            domainName: "gratie.com",
            domainVersion: "v1",
            platformFeeReceiver: address(PlatformFeeReceiver),
            businessNFTs: address(businessNft),
            serviceProviderNFTs: address(serviceProviderNft),
            rewardTokenImplementation: address(rewardToken),
            defaultAdminAddress: address(DefaultAdminAddress),
            usdcContractAddress: address(usdcContract),
            paymentMethods: paymentMethods,
            gratiePlatformAdmins: gratiePlatformAdmins,
            businessNftTiers: _businessNftTier
        });

        console.log(
            "Proxy contract Before: ",
            address(transparentUpgradeableProxy)
        );
        transparentUpgradeableProxy = new TransparentUpgradeableProxy(
            address(gratie),
            address(proxyAdmin),
            abi.encodeWithSignature(
                "initialize((string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[]))",
                _initData
            )
        );

        console.log(
            "Proxy contract After: ",
            address(transparentUpgradeableProxy)
        );
        console.log("Gratie Address Before: ", address(gratie));
        gratie = Gratie(address(transparentUpgradeableProxy));
        console.log("Gratie Address: ", address(gratie));

        // businessNft.initialize("GratieBusinessNFT", "GBN", address(gratie));

        // transparentUpgradeableProxy.initialize(_initData);
    }

    // function testCanSetGratieAddressInBusinessNFT() public {
    //     // businessNft.setGratieContract(address(gratie));
    //     console.log(
    //         "BusinessNFT: GratieContract = ",
    //         businessNft.gratieContract()
    //     );
    //     // assertTrue(businessNft.gratieContract() == address(gratie));
    // }
    //
    // function testIsDomainNameIsSet() public {
    //     testCanSetGratieAddressInBusinessNFT();
    //
    //     string memory _name = "gratie.com";
    //     bytes32 name = keccak256(abi.encodePacked(_name));
    //     bytes32 domain = keccak256(abi.encodePacked(gratie.domainName()));
    //     assertTrue(domain == name);
    // }

    // function testCanMintToken() public {
    //     startHoax(address(orignailGratie));
    //     businessNft.mint(address(111), 1, "https://something");
    //     vm.stopPrank();
    //
    //     console.log("BusinessNFT count: ", businessNft.balanceOf(address(111)));
    // }

    function BusinessCanRegister() public {
        // testIsDomainNameIsSet();

        (string memory _name, string memory _ipfs, , , , , ) = gratie
            .businessNftTiers(1);
        console.log("NFTTiers: ", _name);

        startHoax(address(111));
        vm.deal(address(businessNft), 1 ether);
        vm.deal(address(gratie), 1 ether);
        Gratie.BusinessData memory _businessData = Gratie.BusinessData({
            name: "Zoo",
            email: "Zoo@gratie.com",
            nftMetadataURI: "ipfs://zoodata/metadata.json",
            businessNftTier: 1
        });

        string[] memory _divisionNames = new string[](1);
        _divisionNames[0] = "Zoo1";

        string[] memory _divisionMetadataURIs = new string[](1);
        _divisionMetadataURIs[0] = "ipfs://zoodata/metadata1.json";

        Gratie.Payment memory _payment = Gratie.Payment({
            method: address(0),
            amount: 1
        });

        // vm.prank(DefaultAdminAddress);
        gratie.registerBusiness{value: 1}(
            _businessData,
            _divisionNames,
            _divisionMetadataURIs,
            _payment
        );
        vm.stopPrank();

        console.log("Who actually called: ", businessNft.whoCalled());
        console.log("BusinessNFT count: ", businessNft.balanceOf(address(111)));
        console.log("Gratie count: ", businessNft.balanceOf(address(gratie)));
    }

    function BusinessCanGenerateRewardTokens() public {
        vm.prank(address(111));
        Gratie.RewardTokenMint memory _rewardMint = Gratie.RewardTokenMint({
            businessId: 1,
            amount: 50000,
            lockInPercentage: 1,
            mintNonce: 1
        });

        gratie.generateRewardTokens(
            _rewardMint,
            "Zoo",
            "ZOO",
            "ipfs://metadata.png"
        );

        console.log(
            "Reward token balance: ",
            rewardToken.balanceOf(address(111))
        );
        console.log(
            "Reward token balance (gratie): ",
            rewardToken.balanceOf(address(gratie))
        );
    }

    function testThatBusinessRecievedNFT() public {
        BusinessCanRegister();
        // BusinessCanGenerateRewardTokens();
        console.log("BusinessNFT count: ", businessNft.balanceOf(address(111)));
        console.log("Gratie count: ", businessNft.balanceOf(address(gratie)));
    }
}
