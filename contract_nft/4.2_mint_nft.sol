pragma ton-solidity >= 0.50;
pragma AbiHeader expire;

/// @title Mint_NFT
/// @author morq000

// This is class that describes you smart contract.
contract mint_nft {
    
    // Constructor with pubkeys check
    constructor() public {
        require(tvm.pubkey() != 0, 101);       
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
    }

    // Structure with token fields description
    struct nftServiceSubscription {
        string name;
        uint price;
        uint16 category_id;
        bool is_for_sale;
    }

    // Token storage
    nftServiceSubscription[] subscriptions;

    // Token to Owner mapping
    mapping (uint=>uint) tokenToOwner;


    // Function for NFT creation
    function createNft(string name, uint16 category_id) public
    {
        tvm.accept();

        // Check that token name is unique
        bool is_unique = true;
        for (uint256 index = 0; index < subscriptions.length; index++) {
            if (subscriptions[index].name == name)
            {
                is_unique = false;
            } 
        }
        require(is_unique, 155, "NFT with this name already exists");

        // Create new token and add to storage
        // By default new token has price of 0 and is_for_sale = false. Can be changed with separate function
        subscriptions.push(nftServiceSubscription(name, 0, category_id, false));

        // Create key that will be Token ID
        uint tokenIdFromArrayPosition = subscriptions.length - 1;

        // Add new key-value pair
        tokenToOwner[tokenIdFromArrayPosition] = msg.pubkey();
    }


    // getter function to return owner pubkey by Token ID
    function getTokenOwner(uint tokenId) public view returns (uint)
    {
        return tokenToOwner[tokenId];
    }


    // Getter function to return token info by token ID
    function getTokenInfo(uint tokenId) public view 
        returns (string name, uint price, uint16 category_id, bool is_for_sale)
    {
        // Get token info from tokens array by it's ID (position)
        name = subscriptions[tokenId].name;
        price = subscriptions[tokenId].price;
        category_id = subscriptions[tokenId].category_id;
        is_for_sale = subscriptions[tokenId].is_for_sale;

    }

    // Function to change token price, available only to owner
    function setForSale(uint tokenId, uint price) public
    {
        // Check if function caller is token owner
        require(msg.pubkey()==tokenToOwner[tokenId], 103, "Only token owner can set token for sale");
        
        tvm.accept();
        subscriptions[tokenId].price = price;
        subscriptions[tokenId].is_for_sale = true;
    }
    
}
