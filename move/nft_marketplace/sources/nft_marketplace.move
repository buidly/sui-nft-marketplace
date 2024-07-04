module nft_marketplace::nft_marketplace {

    // Part 1: These imports are provided by default
    // use sui::object::{Self, UID};
    // use sui::transfer;
    // use sui::tx_context::{Self, TxContext};

    use std::debug;

    // This is the only dependency you need for events.
    use sui::event;
    use sui::sui::SUI;

    // Use this dependency to get a type wrapper for UTF-8 strings
    use std::string::{Self, utf8};
    use sui::url::{Self, Url};
    use sui::package; // For publishing NFT
    use sui::display; // For displaying NFT image
    use sui::coin::{Self, Coin};
    use sui::balance::{Balance};

    // === Errors ===

    const EInvalidAmount: u64 = 0;
    const EInvalidNft: u64 = 1;

    // ====== Events ======

    public struct NFTMinted has copy, drop {
        object_id: ID,
        creator: address,
        name: string::String,
    }

    // === Structs ===

    public struct TestnetNFT has key, store {
        id: UID,
        name: string::String,
        description: string::String,
        url: Url,
        creator: address,
    }

    public struct Listing has key {
        id: UID,
        nft: TestnetNFT,
        price: u64,
        owner: address,
    }

    public struct Bid has key {
        id: UID,
        nft_id: ID,
        balance: Balance<SUI>,
        owner: address,
    }

    // resource struct Bid {
    //     nft: &TestnetNFT,
    //     price: u64,
    //     bidder: address,
    // }
    //
    // resource struct Ask {
    //     nft: &TestnetNFT,
    //     price: u64,
    //     seller: address,
    // }

    // For displaying NFT image
    public struct NFT_MARKETPLACE has drop {}

    // Part 3: Module initializer to be executed when this module is published

    fun init(otw: NFT_MARKETPLACE, ctx: &mut TxContext) {
        let keys = vector[
            utf8(b"name"),
            utf8(b"description"),
            utf8(b"url"),
        ];

        let values = vector[
            utf8(b"{name}"),
            utf8(b"{description}"),
            utf8(b"{url}"),
        ];

        // Claim the publisher
        let publisher = package::claim(otw, ctx);

        let mut display = display::new_with_fields<TestnetNFT>(
            &publisher, keys, values, ctx
        );

        display::update_version(&mut display);

        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(display, ctx.sender());
    }

    // === Public-View Functions ===

    /// Get the NFT's `name`
    public fun name(nft: &TestnetNFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &TestnetNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &TestnetNFT): &Url {
        &nft.url
    }

    // === Entrypoints  ===

    #[allow(lint(self_transfer))]
    /// Create a new TestnetNFT
    public fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();
        let nft = TestnetNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            creator: sender,
        };

        debug::print(&nft);

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::public_transfer(nft, sender);
    }

    /// Permanently delete `nft`
    public fun burn(nft: TestnetNFT) {
        let TestnetNFT { id, name: _, description: _, url: _, creator: _ } = nft;
        id.delete()
    }

    public fun place_listing(nft: TestnetNFT, price: u64, ctx: &mut TxContext) {
        let sender = ctx.sender();

        let listing = Listing {
            id: object::new(ctx),
            nft,
            price,
            owner: sender,
        };

        transfer::share_object(listing);
    }

    #[allow(lint(self_transfer))]
    public fun buy(listing: Listing, coin: Coin<SUI>, ctx: &mut TxContext) {
        let Listing { id, nft, owner, price } = listing;

        assert!(coin.balance().value() == price, EInvalidAmount);

        transfer::public_transfer(coin, owner);
        transfer::public_transfer(nft, ctx.sender());

        id.delete();
    }

    public fun place_bid(nft: &TestnetNFT, coin: Coin<SUI>, ctx: &mut TxContext) {
        let sender = ctx.sender();

        let bid = Bid {
            id: object::new(ctx),
            nft_id: object::id(nft),
            balance: coin.into_balance(),
            owner: sender
        };

        transfer::share_object(bid);
    }

    #[allow(lint(self_transfer))]
    public fun accept_bid(bid: Bid, nft: TestnetNFT, ctx: &mut TxContext) {
        let Bid { id, nft_id, balance, owner } = bid;

        assert!(nft_id == object::id(&nft), EInvalidNft);

        transfer::public_transfer(nft, owner);
        transfer::public_transfer(coin::from_balance(balance, ctx), ctx.sender());

        id.delete();
    }

    // === Test Functions ===

    // TODO
}
