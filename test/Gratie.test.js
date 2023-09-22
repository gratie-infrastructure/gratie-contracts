const ethers = require("hardhat").ethers;
const expect = require("chai").expect;
const utils = require("ethers").utils;

describe("Gratie Contract", () => {
  it("Should deploy the proxy and implementation contract", async () => {
    const [owner, paymentMethod, feeReciever, platformAdmin, defaultAdmin] =
      await ethers.getSigners();

    const BusinessNFT = await ethers.getContractFactory("BusinessNFT");
    const businessNft = await BusinessNFT.deploy();
    businessNft.deployed();

    const ServiceProviderNFT = await ethers.getContractFactory(
      "ServiceProviderNFT"
    );
    const serviceProviderNFT = await ServiceProviderNFT.deploy();
    serviceProviderNFT.deployed();

    const USDC = await ethers.getContractFactory("USDCMock");
    const usdc = await USDC.deploy();
    usdc.deployed();

    const RewardToken = await ethers.getContractFactory("RewardToken");
    const rewardToken = await RewardToken.deploy();
    rewardToken.deployed();

    const initData = {
      domainName: "gratie.com",
      domainVersion: "v1",
      platformFeeReciever: feeReciever.address,
      businessNFTs: businessNft.address,
      serviceProviderNFTs: serviceProviderNFT.address,
      rewardTokenImplementation: rewardToken.address,
      defaultAdminAddress: owner.address,
      usdcContractAddress: usdc.address,
      paymentMethods: [paymentMethod.address],
      gratiePlatformAdmins: [platformAdmin.address],
      businessNftTiers: [
        {
          name: "Test",
          ipfsMetadataLink: "ipfs://something",
          usdcPrice: utils.parseUnits("30", 18),
          feeUsersCount: utils.parseUnits("1", 18),
          usdcPerAdditionalUser: utils.parseUnits("5", 18),
          platformFee: utils.parseUnits("0.2", 18),
          isActive: true,
        },
      ],
    };

    const gratieInterface = new ethers.utils.Interface([
      "function initialize(tuple(string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[]))",
    ]);

    const encodedData = gratieInterface.encodeFunctionData(
      "initialize((string,string,address,address,address,address,address,address,address[],address[],(string,string,uint256,uint256,uint256,uint256,bool)[]))",
      [initData]
    );
    const GratieContract = await ethers.getContractFactory("Gratie");
    const gratie = await GratieContract.deploy();
    gratie.deployed();

    const ProxyAdmin = await ethers.getContractFactory("ProxyAdmin");
    const proxyAdmin = await ProxyAdmin.deploy();
    proxyAdmin.deployed();

    const TransparencyContract = await ethers.getContractFactory(
      "TransparentUpgradeableProxy"
    );
    const transparencyContract = await TransparencyContract.deploy(
      gratie.address,
      proxyAdmin.address,
      encodedData
    );
    transparencyContract.deployed();

    console.log(transparencyContract.address);
  });
});
