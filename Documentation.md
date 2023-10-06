# Gratie Documentation

> To interact with the contract, the address of the proxy and the abi of Gratie contract should be used.

## Functions/Endpoints

This section describes functions/endpoints provided by the Gratie contract, what they do, the arguments they require and their return value or event emission (if any).

### Write Functions/Endpoints and Examples

1. Registering an/a enterprise/company: (registerBusiness).

   ```ts
   // endpoint structure
   registerBusiness(
       businessData: Object,                // Business information
       _divisionNames: String[],            // Business division names
       _divisionMetadataURIs: String[],     // Business division metadata uris
       _payment: Object                     // Business registration payment info
   ): Promise<ContractTransaction>

   // example code: Register a business with the following details
   const businessData = {
       name: "Business name",
       email: "Business@gmail.com",
       nftMetadataURI: "ipfs://business/metadata.json",
       businessNftTier: 1
   };

   const _divisionnames = ["division1", "division2"...];
   const _divisionmetadatauris = ["ipfs://division1/metadata.json", "ipfs://division2/metadata.json"...];

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

2. Generate reward tokens: (generateRewardTokens) Generate reward tokens with given information for a Business.

   - NB: Only Registered Business can call this endpoint

   ```ts
   // endpoint structure
   generateRewardToken(
       _data: Object,                   // Reward campaign information
       _tokenName: String,              // Reward token name
       _tokenSymbol: String,            // Reward token symbol
       _tokenIconURL: String            // Reward token Icon url
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

3. Business can start reward distribution: (startRewardDistribution) Start reward token distribution campaign, which allows service providers to claim reward tokens.

   - NB: Only Registered Business that has generated reward tokens can call this enpoint

   ```ts
   // endpoint structure
   startRewardDistribution(
       _businessID: Number,             // Business ID, gotten from registration
       _percentageToDistribute: Number  // Percentage of reward tokens to distribute
   ): Promise<ContractTransaction>

   //<------------ Contract call ------------->
   // Assuming businessID = 1 and the business wishes to distribute just 10% of the reward tokens
   await GratieContract.startRewardDistribution(1, 10);

   ```

   On successful execution, this call emits the `RewardDistributionCreated` event.

4. Register Service Provider: (registerServiceProvider) Register service providers for a business using their addresses.

   - NB: Only Registered Business can call this endpoint

   ```ts
    // endpoint structure
    registerServiceProvider(
        _businessID: Number,            // Business ID, gotten from registration
        _divisionID: Number,            // Division ID
        _serviceProviders: Address[]    // Addresses of service providers to regsiter
    ): Promise<ContractTransaction>

    //<----------- Contract call ------------->
    // Assuming businessID = 1 and DivisionID = 1, and 2 Service providers
    await GratieContract.registerServiceProvider(1, 1, ["0xe95bddbc1c6ffbffe75ef51db3cbd6b10db3cb3b", "0xff9c4ffad59becf7ec0ade9a50cf4a51dacf9c67"]);
   ```

   On successful execution, this call emits the `ServiceProvidersRegistered` event.

5. Remove/Deregister Service Provider: (removeServiceProvider) Remove/Deregister a service provider from a business.

   - NB: Only Registered Business can call this endpoint

   ```ts
   // endpoint structure
   removeServiceProvider(
        _businessID: Number,
        _divisionID: Number,
        _serviceProviders: Address[]    // Addresses of service providers to remove
   ): Promise<ContractTransaction>

   //<----------- Contract call -------------->
   // Assuming there are 2 service providers for business 1 at divison 1
   await GratieContract.removeServiceProvider(1, 1, ["0xe95bddbc1c6ffbffe75ef51db3cbd6b10db3cb3b"]);
   ```

   On successful execution, this call emits the `ServiceProvidersRemoved` event.

6. Claim Reward Tokens: (claimRewardTokens) Allow registered service provider to claim rewards.

   - NB: Only registered service provider for a business can claim rewards

   ```ts
   // endpoint structure
   claimRewardTokens(
       _businessID: Number,            // ID of Business to claim rewards from
       _distributionNo: Number,        // Distribution Number, this is the third value in the `RewardDistributionCreatred` event (from startRewardDistribution())
   ): Promise<ContractTransaction>

   //<--------- Contract call -------------->
   // Assuming Business ID = 1 and Distribution No = 1 (based on RewardDistribuionCreated Event)
   await GratieContract.claimRewardTokens(1, 1);
   ```

   On successful execution, this call emits the `RewardTokensClaimed` event.

7. Add Business NFT Tiers to Gratie: (addBussinessNftTiers) Add more Business NFT Tiers to the existing Business NFT Tiers on the Gratie contract

   - NB: Only owner of Gratie contract can add new tiers

   ```ts
   // endpoint structure
   addBusinessNftTiers(
       _tiers: BusinesNftTier[]        // Business NFT Tiers to add
   ): Promise<ContractTransaction>

   //<-------- Contract call -------------->
   const _tiers = [
       {
           name: "Tier Name",
           ipfsMetadataLink: "Tier metadata link",
           usdcPrice: 50,
           freeUsersCount: 10,
           usdcPerAdditionalUser: 5,
           platformFee: 2;
           isActive: true
       },
       ...
   ];

   await GratieContract.addBusinessNftTiers(_tiers);
   ```

   On successful execution, this call emits the `BusinessNftTierAdded` event.

8. Register Business through Gratie Contract Owner: (registerBusinessByOwner) Register a business.

   - NB: Only owner of Gratie contract can call this endpoint

   ```ts
   registerBusinessByOwner(
       _to: Address,                   // Address to give ownership of this business
       _name: String,                  // Name of Business
       _email: String,                 // Email Address of Business
       _nftMetadataURI: String,        // Metadata URI for the Business
       _businessNftTier: Number,       // NFT Tier to assign to Business
       _divisionNames: String[],       // Division names to create for Business
       _divisionMetadataURIs: String[] // Division metadata uris for the Division names
   ): Promise<ContractTransaction>

   //<---------- Contract call -------------->
   const _divisionnames = ["division1", "division2"...];
   const _divisionmetadatauris = ["ipfs://division1/metadata.json", "ipfs://division2/metadata.json"...];

   await GratieContract.registerBusinessByOwner("0xd84caadc1c6ffbffe75ef51db3cbd6b10db3cb3b", "Pseudo", "Pseudo@email.com", "ipfs://pseudo/metadata.json", 1, _divisionnames, _divisionMetadataURIs);
   ```
