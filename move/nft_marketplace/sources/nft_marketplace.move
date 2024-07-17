module nft_marketplace::nft_marketplace {

    // Part 1: These imports are provided by default
    // use sui::object::{Self, UID};
    // use sui::transfer;
    // use sui::tx_context::{Self, TxContext};

    use std::string::{Self, utf8};

    use sui::balance::Balance;
    use sui::coin::{Self, Coin};
    use sui::display;
    use sui::dynamic_object_field as dof;
    use sui::event;
    use sui::package;
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::url::{Self, Url};

    // This is the only dependency you need for events.
    // Use this dependency to get a type wrapper for UTF-8 strings
    // For publishing NFT
    // For displaying NFT image
    // === Errors ===

    const EInvalidAmount: u64 = 0;
    const EInvalidNft: u64 = 1;
    const EInvalidOwner: u64 = 2;
    const EListingNotFoundForNFTId: u64 = 3;
    const EBidNotFoundForNFTId: u64 = 4;

    // ====== Events ======

    public struct MarketplaceInit has copy, drop {
        object_id: ID,
    }

    public struct NFTMinted has copy, drop {
        object_id: ID,
        creator: address,
        name: string::String,
    }

    public struct ListingCreated has copy, drop {
        object_id: ID,
        nft_id: ID,
        creator: address,
        price: u64,
    }

    public struct ListingCancelled has copy, drop {
        object_id: ID,
        nft_id: ID,
        creator: address,
        price: u64,
    }

    public struct Buy has copy, drop {
        object_id: ID,
        nft_id: ID,
        creator: address,
        buyer: address,
        price: u64,
    }

    public struct BidCreated has copy, drop {
        object_id: ID,
        nft_id: ID,
        creator: address,
        price: u64,
    }

    public struct BidCancelled has copy, drop {
        object_id: ID,
        nft_id: ID,
        creator: address,
        price: u64,
    }

    public struct AcceptBid has copy, drop {
        object_id: ID,
        nft_id: ID,
        creator: address,
        seller: address,
        price: u64,
    }

    // === Structs ===

    public struct TestnetNFT has key, store {
        id: UID,
        name: string::String,
        description: string::String,
        url: Url,
        creator: address,
    }

    public struct Listing has key, store {
        id: UID,
        price: u64,
        owner: address,
        nft_id: ID
    }

    public struct Bid has key, store {
        id: UID,
        nft_id: ID,
        balance: Balance<SUI>,
        owner: address,
    }

    public struct Marketplace has key {
        id: UID,
        listings: Table<ID, Listing>,
        bids: Table<ID, vector<Bid>>,
    }

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

        let marketplace = Marketplace {
            id: object::new(ctx),
            listings: table::new<ID, Listing>(ctx),
            bids: table::new<ID, vector<Bid>>(ctx),
        };

        event::emit(MarketplaceInit {
            object_id: object::id(&marketplace),
        });

        transfer::share_object(marketplace);
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

    /// Get the NFT's `creator`
    public fun creator(nft: &TestnetNFT): &address {
        &nft.creator
    }

    // === Entrypoints  ===

    /// Create a new TestnetNFT
    public fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ): TestnetNFT {
        let sender = ctx.sender();
        let nft = TestnetNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url),
            creator: sender,
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        nft
    }

    /// Permanently delete `nft`
    public fun burn(nft: TestnetNFT) {
        let TestnetNFT { id, name: _, description: _, url: _, creator: _ } = nft;
        id.delete()
    }

    public fun place_listing<N: key + store>(marketplace: &mut Marketplace, nft: N, price: u64, ctx: &mut TxContext) {
        let sender = ctx.sender();
        let nft_id = object::id(&nft);
        let listing = Listing {
            id: object::new(ctx),
            price,
            owner: sender,
            nft_id
        };

        event::emit(ListingCreated {
            object_id: object::id(&listing),
            nft_id,
            creator: sender,
            price: listing.price,
        });

        dof::add(&mut marketplace.id, nft_id, nft);

        marketplace.listings.add<ID, Listing>(nft_id, listing);
    }

    public fun cancel_listing<N: key + store>(
        marketplace: &mut Marketplace,
        nft_id: ID,
        ctx: &mut TxContext
    ): N {
        let sender = ctx.sender();
        assert!(marketplace.listings.contains<ID, Listing>(nft_id), EListingNotFoundForNFTId);

        let listing = marketplace.listings.remove<ID, Listing>(nft_id);
        assert!(listing.owner == sender, EInvalidOwner);

        let nft: N = dof::remove(&mut marketplace.id, nft_id);

        let Listing { id, owner, price, nft_id: _ } = listing;

        event::emit(ListingCancelled {
            object_id: id.uid_to_inner(),
            nft_id,
            creator: owner,
            price,
        });

        id.delete();

        nft
    }

    public fun buy<N: key + store>(
        marketplace: &mut Marketplace,
        nft_id: ID,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ): N {
        assert!(dof::exists_(&marketplace.id, nft_id), EInvalidNft);
        let nft: N = dof::remove(&mut marketplace.id, nft_id);

        let listing = marketplace.listings.remove<ID, Listing>(nft_id);
        let Listing { id, owner, price, nft_id: _ } = listing;

        assert!(coin.value() == price, EInvalidAmount);

        event::emit(Buy {
            object_id: id.uid_to_inner(),
            nft_id: object::id(&nft),
            creator: owner,
            buyer: ctx.sender(),
            price,
        });

        transfer::public_transfer(coin, owner);

        id.delete();

        nft
    }

    public fun place_bid(marketplace: &mut Marketplace, nft_id: ID, coin: Coin<SUI>, ctx: &mut TxContext): ID {
        assert!(dof::exists_(&marketplace.id, nft_id), EInvalidNft);

        let sender = ctx.sender();

        let bid = Bid {
            id: object::new(ctx),
            nft_id,
            balance: coin.into_balance(),
            owner: sender
        };

        let bid_id = object::id(&bid);

        event::emit(BidCreated {
            object_id: bid_id,
            nft_id,
            price: bid.balance.value(),
            creator: sender,
        });

        if (marketplace.bids.contains(nft_id)) {
            let elements = marketplace.bids.borrow_mut(nft_id);
            elements.push_back(bid);
        } else {
            marketplace.bids.add<ID, vector<Bid>>(nft_id, vector::singleton(bid));
        };

        bid_id
    }

    public fun cancel_bid(marketplace: &mut Marketplace, nft_id: ID, bid_id: ID, ctx: &mut TxContext): Coin<SUI> {
        let bid = get_and_remove_bid(marketplace, nft_id, bid_id);

        let sender = ctx.sender();
        assert!(bid.owner == sender, EInvalidOwner);

        let Bid { id, nft_id, balance, owner } = bid;

        event::emit(BidCancelled {
            object_id: id.uid_to_inner(),
            nft_id,
            creator: owner,
            price: balance.value(),
        });

        id.delete();

        coin::from_balance(balance, ctx)
    }

    public fun accept_bid<N: key + store>(
        marketplace: &mut Marketplace,
        nft_id: ID,
        bid_id: ID,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let sender = ctx.sender();
        // if NFT exists then listing must exist for sure
        assert!(dof::exists_(&marketplace.id, nft_id), EInvalidNft);
        let listing = marketplace.listings.remove<ID, Listing>(nft_id);
        assert!(listing.owner == sender, EInvalidOwner);

        let nft: N = dof::remove(&mut marketplace.id, nft_id);

        let Listing { id: listing_id, owner: _, price: _, nft_id: _ } = listing;

        let bid = get_and_remove_bid(marketplace, nft_id, bid_id);

        let Bid { id, nft_id: _, balance, owner } = bid;

        event::emit(AcceptBid {
            object_id: id.uid_to_inner(),
            nft_id: object::id(&nft),
            creator: owner,
            seller: ctx.sender(),
            price: balance.value(),
        });

        transfer::public_transfer(nft, owner);

        id.delete();
        listing_id.delete();

        coin::from_balance(balance, ctx)
    }

    // === Private Functions ===

    fun get_and_remove_bid(marketplace: &mut Marketplace, nft_id: ID, bid_id: ID): Bid {
        assert!(marketplace.bids.contains<ID, vector<Bid>>(nft_id), EBidNotFoundForNFTId);
        let bids = marketplace.bids.borrow_mut<ID, vector<Bid>>(nft_id);

        let mut bid: Option<Bid> = option::none();
        let length = bids.length();
        let mut i = 0;
        while (i < length) {
            if (object::id(bids.borrow(i)) == bid_id) {
                bid.destroy_none();
                bid = option::some(bids.swap_remove(i));

                break
            };

            i = i + 1;
        };

        assert!(bid.is_some(), EBidNotFoundForNFTId);

        if (bids.is_empty()) {
            let v = marketplace.bids.remove<ID, vector<Bid>>(nft_id);
            v.destroy_empty();
        };

        bid.destroy_some()
    }

    // === Test Functions ===

    #[test]
    fun test_module_init() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;
        use sui::display::Display;
        use sui::package::Publisher;
        use std::ascii;

        let admin = @0xAD;

        let mut scenario = test_scenario::begin(admin);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());
        };

        scenario.next_tx(admin);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            assert!(marketplace_id.is_some(), 1);

            let marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            assert!(marketplace.listings.is_empty());
            assert!(marketplace.bids.is_empty());

            test_scenario::return_shared(marketplace);

            let display = scenario.take_from_sender<Display<TestnetNFT>>();
            assert_eq(display.version(), 1);
            scenario.return_to_sender(display);

            let publisher = scenario.take_from_sender<Publisher>();
            assert!(publisher.published_module() == ascii::string(b"nft_marketplace"), 1);
            scenario.return_to_sender(publisher);
        };
        scenario.end();
    }

    #[test]
    fun test_place_listing() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;

        let nft_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            nft_id = object::id(&nft);
            transfer::public_transfer(nft, initial_owner);
        };

        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        {
            let marketplace = scenario.take_shared<Marketplace>();
            let listing: &Listing = marketplace.listings.borrow<ID, Listing>(nft_id);

            assert_eq(listing.owner, initial_owner);
            assert_eq(listing.price, 10);

            let nft: &TestnetNFT = dof::borrow<ID, TestnetNFT>(&marketplace.id, nft_id);

            assert!(nft.name() == string::utf8(b"Name"), 1);
            assert!(nft.description() == string::utf8(b"Description"), 1);
            assert!(nft.url() == url::new_unsafe_from_bytes(b"url"), 1);
            assert!(nft.creator() == initial_owner, 1);
            test_scenario::return_shared(marketplace);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EListingNotFoundForNFTId)]
    fun test_cancel_listing_error_not_found() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;
        let nft_id: ID = object::id_from_address(@0xAAAA);

        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());
        };

        // Cancel listing error
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            // Can not cancel the listing since it does not exist
            let nft: TestnetNFT = cancel_listing(&mut marketplace, nft_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, other_account);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidOwner)]
    fun test_cancel_listing_error_owner() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;
        let nft_id: ID;

        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            nft_id = object::id(&nft);
            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Cancel listing error
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            // Can not cancel the listing since it is not the owner
            let nft: TestnetNFT = cancel_listing(&mut marketplace, nft_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, other_account);
        };

        scenario.end();
    }

    #[test]
    fun test_cancel_listing() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let nft_id: ID;


        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            nft_id = object::id(&nft);
            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Cancel listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let nft: TestnetNFT = cancel_listing(&mut marketplace, nft_id, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, initial_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNft)]
    fun test_buy_error_nft() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;
        let nft_id: ID = object::id_from_address(@0xAAAA);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let coin = coin::mint_for_testing<SUI>(50, scenario.ctx());
            transfer::public_transfer(coin, other_account);
        };

        // Buy with error
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = scenario.take_from_sender<Coin<SUI>>();

            let nft: TestnetNFT = buy(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, other_account);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidAmount)]
    fun test_buy_error_amount() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            nft_id = object::id(&nft);
            transfer::public_transfer(nft, initial_owner);

            let coin = coin::mint_for_testing<SUI>(50, scenario.ctx());
            transfer::public_transfer(coin, other_account);
        };

        // Create listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Buy with error
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = scenario.take_from_sender<Coin<SUI>>();

            let nft: TestnetNFT = buy(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, other_account);
        };

        scenario.end();
    }

    #[test]
    fun test_buy() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;
        let nft_id;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            nft_id = object::id(&nft);
            transfer::public_transfer(nft, initial_owner);

            let coin = coin::mint_for_testing<SUI>(10, scenario.ctx());
            transfer::public_transfer(coin, other_account);
        };

        // Place listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Do buy
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = scenario.take_from_sender<Coin<SUI>>();
            let nft: TestnetNFT = buy(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, other_account);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        // Owner got initial coin
        {
            let coin = scenario.take_from_sender<Coin<SUI>>();

            assert_eq(coin.value(), 10);

            scenario.return_to_sender(coin);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNft)]
    fun test_place_bid_error_nft() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;
        let nft_id: ID = object::id_from_address(@0xAAAA);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());
        };

        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        scenario.end();
    }

    #[test]
    fun test_place_bid() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Create first bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        {
            let marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let bids: &vector<Bid> = marketplace.bids.borrow<ID, vector<Bid>>(nft_id);

            assert_eq(bids.length(), 1);

            let bid: &Bid = bids.borrow(0);

            assert_eq(bid.nft_id, nft_id);
            assert_eq(bid.owner, other_account);
            assert_eq(bid.balance.value(), 10000000);

            test_scenario::return_shared(marketplace);
        };

        // Create second bid same nft
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(20000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1); // length stays the same
            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        // Bid gets added to vector under Table
        {
            let marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let bids: &vector<Bid> = marketplace.bids.borrow<ID, vector<Bid>>(nft_id);

            assert_eq(bids.length(), 2);

            let bid: &Bid = bids.borrow(0);

            assert_eq(bid.nft_id, nft_id);
            assert_eq(bid.owner, other_account);
            assert_eq(bid.balance.value(), 10000000);

            let bid: &Bid = bids.borrow(1);

            assert_eq(bid.nft_id, nft_id);
            assert_eq(bid.owner, other_account);
            assert_eq(bid.balance.value(), 20000000);

            test_scenario::return_shared(marketplace);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EBidNotFoundForNFTId)]
    fun test_cancel_bid_error_no_nft_bids() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;

        let nft_id: ID;
        let bid_id: ID = object::id_from_address(@0xAAAA);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Cancel bid error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EBidNotFoundForNFTId)]
    fun test_cancel_bid_error_invalid_id() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id: ID;
        let bid_id: ID = object::id_from_address(@0xAAAA);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Create bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            let _ = place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        // Cancel bid error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidOwner)]
    fun test_cancel_bid_error_owner() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id: ID;
        let bid_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Create bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            bid_id = place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        // Cancel bid error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    fun test_cancel_bid() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id: ID;
        let bid1_id: ID;
        let bid2_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Create first bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            bid1_id = place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        // Create second bid same nft
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(20000000, scenario.ctx());

            bid2_id = place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1); // length stays the same
            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.borrow(nft_id).length(), 2);

            test_scenario::return_shared(marketplace);
        };

        // Cancel first bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            // Can not cancel the listing since it is not the owner
            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid1_id, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 1); // length still remains
            assert_eq(marketplace.bids.borrow(nft_id).length(), 1);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, other_account);
        };

        // Cancel second bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            // Can not cancel the listing since it is not the owner
            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid2_id, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, other_account);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNft)]
    fun test_accept_bid_error_no_listing() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;

        let nft_id: ID = object::id_from_address(@0xAAAA);
        let bid_id: ID = object::id_from_address(@0xBBBB);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());
        };

        // Accept with error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = accept_bid<TestnetNFT>(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidOwner)]
    fun test_accept_bid_error_not_owner() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_owner = @0xFAFE;

        let nft_id: ID;
        let bid_id: ID = object::id_from_address(@0xBBBB);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Accept with error
        scenario.next_tx(other_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = accept_bid<TestnetNFT>(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EBidNotFoundForNFTId)]
    fun test_accept_bid_error_no_nft_bids() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;

        let nft_id: ID;
        let bid_id: ID = object::id_from_address(@0xAAAA);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Accept bid error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EBidNotFoundForNFTId)]
    fun test_accept_bid_error_invalid_id() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id: ID;
        let bid_id: ID = object::id_from_address(@0xAAAA);

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing first
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Create bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            let _ = place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        // Cancel bid error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            // Can not cancel the bid since bid_id is incorrect
            let coin: Coin<SUI> = cancel_bid(&mut marketplace, nft_id, bid_id, scenario.ctx());

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        scenario.end();
    }

    #[test]
    fun test_accept_bid() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let nft_id: ID;
        let bid_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        // Create bid
        scenario.next_tx(other_account);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();
            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            bid_id = place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);

            test_scenario::return_shared(marketplace);
        };

        // Accept
        scenario.next_tx(initial_owner);
        {
            let mut marketplace: Marketplace = scenario.take_shared<Marketplace>();

            let coin: Coin<SUI> = accept_bid<TestnetNFT>(&mut marketplace, nft_id, bid_id, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.bids.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        let effects = scenario.next_tx(other_account);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        // Other account got initial nft
        {
            let nft = scenario.take_from_sender<TestnetNFT>();

            assert!(nft.name() == string::utf8(b"Name"), 1);
            assert!(nft.description() == string::utf8(b"Description"), 1);
            assert!(nft.url() == url::new_unsafe_from_bytes(b"url"), 1);
            assert!(nft.creator() == initial_owner, 1);

            scenario.return_to_sender(nft);
        };

        scenario.end();
    }
}
