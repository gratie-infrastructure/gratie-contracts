# Gratie Documentation

> To interact with the contract, the address of the proxy and the abi of Gratie contract should be used.

## Functions/Endpoints

This section describes functions/endpoints provided by the Gratie contract, what they do, the arguments they require and their return value or event emission (if any).

### Write Functions/Endpoints and Examples

1. Registering an/a enterprise/company: (registerBusiness)

   ```ts
   // endpoint structure
   registerBusiness(
       businessData: Object,
       _divisionNames: String[],
       _divisionMetadataURIs: String[],
       _payment: Object
   ): Promise<ContractTransaction>

   // example code: Register a business with the following details
   const businessData = {
       name: "Business name",
       email: "Business@gmail.com",
       nftMetadataURI: "ipfs://business/metadata.json",
       businessNftTier: 1
   };

   const _divisionNames = ["Division1", "Division2"...];
   const _divisionMetadataURIs = ["ipfs://Division1/metadata.json", "ipfs://Division2/metadata.json"...];

   // payment can be of two types, ether or an erc20 token.
   const _payment = {
       method: ethers.constants.AddressZero, // when the business wishes to pay in ethers
       method: erc20_contract_address // when the user wishes to pay in erc20 tokens (NOTE: any token can be used)
       amount: 1 // amount to pay in ether or ERC20 token
   }

   //<---------- Contact call ------------->
   // If method is a zero address
   await GratieContract.registerBusiness(businessData, _divisionNames, _divisionMetadataURIs, _payment, { value: _payment.amount});
   // If method is an erc20 contract address
   // approve gratie to spend payment amount and make contract call
   await erc20.approve(gratieAddress, _payment.amount);
   await GratieContract.registerBusiness(businessData, _divisionNamesm, _divisionMetadataURIs, _payment);
   ```

   On successful execution, this call emits the `BusinessRegistered` event.

2. Business can generate reward tokens: (generateRewardTokens)

   ```ts
   // endpoint structure
   generateRewardToken(
       _data: Object,
       _tokenName: String,
       _tokenSymbol: String,
       _tokenIconURL: String
   ): Promise<ContractTransaction>

   // example code: Generate reward tokens for a business
   const _data = {
       businessId: 1,
       amount: 50000000,
       lockInPercentage: 10,
       mintNonce: 1
   };

   //<------------- Contract call ------------->
   await GratieContract.generateRewardTokens(_data, "Business1Token", "B1T", "ipfs://Business1Token/metadata.json");
   ```

   On successful execution, this call emits the `RewardTokensGenerated` event.

3. Business can start reward distribution: (startRewardDistribution)

   ```ts
   // endpoint structure
   startRewardDistribution(
       _businessID: Number,
       _percentageToDistribute: Number
   ): Promise<ContractTransaction>

   //<------------ Contract call ------------->
   // Assuming businessID = 1 and the business wishes to distribute just 10% of the reward tokens
   await GratieContract.startRewardDistribution(1, 10);

   ```

   On successful execution, this call emits the `RewardDistributionCreated` event.

4.
