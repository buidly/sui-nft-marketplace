module nft_marketplace::nft_marketplace {

    // Part 1: These imports are provided by default
    // use sui::object::{Self, UID};
    // use sui::transfer;
    // use sui::tx_context::{Self, TxContext};

    use std::debug;
    use std::string::{Self, utf8};

    use sui::bag;
    use sui::balance::Balance;
    use sui::coin::{Self, Coin};
    use sui::display;
    use sui::dynamic_object_field as dof;
    use sui::event;
    use sui::package;
    use sui::sui::SUI;
    use sui::url::{Self, Url};

    // This is the only dependency you need for events.
    // Use this dependency to get a type wrapper for UTF-8 strings
    // For publishing NFT
    // For displaying NFT image
    // === Errors ===

    const EInvalidAmount: u64 = 0;
    const EInvalidNft: u64 = 1;
    const EInvalidOwner: u64 = 2;

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

    // public struct Listing<phantom T: key + store> has key {
    public struct Listing has key {
        id: UID,
        price: u64,
        owner: address,
        // nft: T: key + store - dynamic field to still have NFT accesible by id
    }

    public struct Bid has key {
        id: UID,
        nft_id: ID,
        balance: Balance<SUI>,
        owner: address,
    }

    public struct Marketplace has key {
        id: UID,
        listings: vector<ID>,
        listings_index: bag::Bag,
        // K: ID, V: index in listings
        bids: vector<ID>,
        bids_index: bag::Bag,
        // K: ID, V: index in bids
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
            listings: vector[],
            listings_index: bag::new(ctx),
            bids: vector[],
            bids_index: bag::new(ctx),
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

        debug::print(&nft);

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

        let mut listing = Listing {
            id: object::new(ctx),
            price,
            owner: sender,
        };

        event::emit(ListingCreated {
            object_id: object::id(&listing),
            nft_id: object::id(&nft),
            creator: sender,
            price: listing.price,
        });

        dof::add(&mut listing.id, b"nft", nft);

        let index = marketplace.listings.length();

        marketplace.listings.push_back(object::id(&listing));
        marketplace.listings_index.add(object::id(&listing), index);

        transfer::share_object(listing);
    }

    public fun cancel_listing<N: key + store>(
        marketplace: &mut Marketplace,
        mut listing: Listing,
        ctx: &mut TxContext
    ): N {
        let sender = ctx.sender();

        assert!(listing.owner == sender, EInvalidOwner);

        let nft: N = dof::remove(&mut listing.id, b"nft");

        let Listing { id, owner, price } = listing;

        event::emit(ListingCancelled {
            object_id: id.uid_to_inner(),
            nft_id: object::id(&nft),
            creator: owner,
            price,
        });

        remove_listing(marketplace, &id);

        id.delete();

        nft
    }

    public fun buy<N: key + store>(
        marketplace: &mut Marketplace,
        mut listing: Listing,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ): N {
        let nft: N = dof::remove(&mut listing.id, b"nft");

        let Listing { id, owner, price } = listing;

        assert!(coin.value() == price, EInvalidAmount);

        event::emit(Buy {
            object_id: id.uid_to_inner(),
            nft_id: object::id(&nft),
            creator: owner,
            buyer: ctx.sender(),
            price,
        });

        remove_listing(marketplace, &id);

        transfer::public_transfer(coin, owner);

        id.delete();

        nft
    }

    public fun place_bid(marketplace: &mut Marketplace, nft_id: ID, coin: Coin<SUI>, ctx: &mut TxContext) {
        let sender = ctx.sender();

        let bid = Bid {
            id: object::new(ctx),
            nft_id,
            balance: coin.into_balance(),
            owner: sender
        };

        event::emit(BidCreated {
            object_id: object::id(&bid),
            nft_id,
            price: bid.balance.value(),
            creator: sender,
        });

        let index = marketplace.bids.length();

        marketplace.bids.push_back(object::id(&bid));
        marketplace.bids_index.add(object::id(&bid), index);

        transfer::share_object(bid);
    }

    public fun cancel_bid(marketplace: &mut Marketplace, bid: Bid, ctx: &mut TxContext): Coin<SUI> {
        let sender = ctx.sender();

        assert!(bid.owner == sender, EInvalidOwner);

        let Bid { id, nft_id, balance, owner } = bid;

        event::emit(BidCancelled {
            object_id: id.uid_to_inner(),
            nft_id,
            creator: owner,
            price: balance.value(),
        });

        remove_bid(marketplace, &id);

        id.delete();

        coin::from_balance(balance, ctx)
    }

    public fun accept_bid<N: key + store>(
        marketplace: &mut Marketplace,
        bid: Bid,
        nft: N,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let Bid { id, nft_id, balance, owner } = bid;

        assert!(nft_id == object::id(&nft), EInvalidNft);

        event::emit(AcceptBid {
            object_id: id.uid_to_inner(),
            nft_id: object::id(&nft),
            creator: owner,
            seller: ctx.sender(),
            price: balance.value(),
        });

        remove_bid(marketplace, &id);

        transfer::public_transfer(nft, owner);

        id.delete();

        coin::from_balance(balance, ctx)
    }

    // === Private Functions ===

    fun remove_listing(marketplace: &mut Marketplace, id: &UID) {
        let index = marketplace.listings_index.remove(id.uid_to_inner());

        marketplace.listings.swap_remove(index);

        let new_len = marketplace.listings.length();

        // Update index of swapped element
        if (new_len > 0 && new_len != index) {
            let moved_nft = marketplace.listings.borrow(index);

            // Workaround to clone ID...
            let new_id: ID = object::id_from_bytes(moved_nft.id_to_bytes());

            // Remove first then re-add with correct value
            let _: u64 = marketplace.listings_index.remove(new_id);
            marketplace.listings_index.add(new_id, index);
        };
    }

    fun remove_bid(marketplace: &mut Marketplace, id: &UID) {
        let index = marketplace.bids_index.remove(id.uid_to_inner());

        marketplace.bids.swap_remove(index);

        let new_len = marketplace.bids.length();

        // Update index of swapped element
        if (new_len > 0 && new_len != index) {
            let moved_nft = marketplace.bids.borrow(index);

            // Workaround to clone ID...
            let new_id: ID = object::id_from_bytes(moved_nft.id_to_bytes());

            // Remove first then re-add with correct value
            let _: u64 = marketplace.bids_index.remove(new_id);
            marketplace.bids_index.add(new_id, index);
        };
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

            assert_eq(marketplace.listings, vector[]);
            assert!(marketplace.listings_index.is_empty(), 1);
            assert_eq(marketplace.bids, vector[]);
            assert!(marketplace.bids_index.is_empty(), 1);

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

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);
        };

        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            assert!(marketplace_id.is_some(), 1);

            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.listings_index.length(), 1);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        {
            let mut listing_id = test_scenario::most_recent_id_shared<Listing>();
            assert!(listing_id.is_some(), 1);

            let listing: Listing = scenario.take_shared_by_id(listing_id.extract());

            assert_eq(listing.owner, initial_owner);
            assert_eq(listing.price, 10);

            let nft: &TestnetNFT = dof::borrow(&listing.id, b"nft");

            assert!(nft.name() == string::utf8(b"Name"), 1);
            assert!(nft.description() == string::utf8(b"Description"), 1);
            assert!(nft.url() == url::new_unsafe_from_bytes(b"url"), 1);
            assert!(nft.creator() == initial_owner, 1);

            test_scenario::return_shared(listing);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidOwner)]
    fun test_cancel_listing_error() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Cancel listing error
        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut listing_id = test_scenario::most_recent_id_shared<Listing>();
            assert!(listing_id.is_some(), 1);

            let listing: Listing = scenario.take_shared_by_id(listing_id.extract());

            // Can not cancel the listing since it is not the owner
            let nft: TestnetNFT = cancel_listing(&mut marketplace, listing, scenario.ctx());

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

        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);
        };

        // Place listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Cancel listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut listing_id = test_scenario::most_recent_id_shared<Listing>();
            assert!(listing_id.is_some(), 1);

            let listing: Listing = scenario.take_shared_by_id(listing_id.extract());

            let nft: TestnetNFT = cancel_listing(&mut marketplace, listing, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, initial_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    fun test_cancel_listing_multiple_first() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_owner = @0xFAFE;

        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);

            let nft = mint_to_sender(b"Name 2", b"Description 2", b"url 2", scenario.ctx());
            transfer::public_transfer(nft, other_owner);
        };

        // Place listing 1
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Place listing 2
        scenario.next_tx(other_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 20, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Get id of 1st listing before listing 2 transaction is finished
        let mut listing1_id = test_scenario::most_recent_id_shared<Listing>();
        assert!(listing1_id.is_some(), 1);

        // Cancel listing 1
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut listing2_id = test_scenario::most_recent_id_shared<Listing>();

            let listing: Listing = scenario.take_shared_by_id(listing1_id.extract());

            let nft: TestnetNFT = cancel_listing(&mut marketplace, listing, scenario.ctx());

            // Assert deleted correctly and indexes updated correctly
            assert_eq(marketplace.listings.length(), 1);
            assert!(marketplace.listings.borrow(0) == listing2_id.borrow(), 1);
            assert_eq(marketplace.listings_index.length(), 1);
            assert!(marketplace.listings_index.borrow(listing2_id.extract()) == 0, 1);

            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, initial_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    fun test_cancel_listing_multiple_last() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_owner = @0xFAFE;

        // Init first
        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);

            let nft = mint_to_sender(b"Name 2", b"Description 2", b"url 2", scenario.ctx());
            transfer::public_transfer(nft, other_owner);
        };

        // Place listing 1
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Place listing 2
        scenario.next_tx(other_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 20, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Get id of 1st listing before listing 2 transaction is finished
        let mut listing1_id = test_scenario::most_recent_id_shared<Listing>();
        assert!(listing1_id.is_some(), 1);

        // Cancel listing 2
        scenario.next_tx(other_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut listing2_id = test_scenario::most_recent_id_shared<Listing>();

            let listing: Listing = scenario.take_shared_by_id(listing2_id.extract());

            let nft: TestnetNFT = cancel_listing(&mut marketplace, listing, scenario.ctx());

            // Assert deleted correctly and indexes updated correctly
            assert_eq(marketplace.listings.length(), 1);
            assert!(marketplace.listings.borrow(0) == listing1_id.borrow(), 1);
            assert_eq(marketplace.listings_index.length(), 1);
            assert!(marketplace.listings_index.borrow(listing1_id.extract()) == 0, 1);

            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(nft, other_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidAmount)]
    fun test_buy_error() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_account = @0xFAFE;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);

            let coin = coin::mint_for_testing<SUI>(50, scenario.ctx());
            transfer::public_transfer(coin, other_account);
        };

        // Create listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            assert!(marketplace_id.is_some(), 1);

            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.listings_index.length(), 1);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Buy with error
        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            assert!(marketplace_id.is_some(), 1);

            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let mut listing_id = test_scenario::most_recent_id_shared<Listing>();
            assert!(listing_id.is_some(), 1);

            let listing: Listing = scenario.take_shared_by_id(listing_id.extract());
            let coin = scenario.take_from_sender<Coin<SUI>>();

            let nft: TestnetNFT = buy(&mut marketplace, listing, coin, scenario.ctx());

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

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);

            let coin = coin::mint_for_testing<SUI>(10, scenario.ctx());
            transfer::public_transfer(coin, other_account);
        };

        // Create listing
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            assert!(marketplace_id.is_some(), 1);

            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            place_listing(&mut marketplace, nft, 10, scenario.ctx());

            assert_eq(marketplace.listings.length(), 1);
            assert_eq(marketplace.listings_index.length(), 1);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Do buy
        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            assert!(marketplace_id.is_some(), 1);

            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());
            let mut listing_id = test_scenario::most_recent_id_shared<Listing>();
            assert!(listing_id.is_some(), 1);

            let listing: Listing = scenario.take_shared_by_id(listing_id.extract());
            let coin = scenario.take_from_sender<Coin<SUI>>();

            let nft: TestnetNFT = buy(&mut marketplace, listing, coin, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

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

        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        {
            let mut bid_id = test_scenario::most_recent_id_shared<Bid>();
            assert!(bid_id.is_some(), 1);

            let bid: Bid = scenario.take_shared_by_id(bid_id.extract());

            assert_eq(bid.nft_id, nft_id);
            assert_eq(bid.owner, other_account);
            assert_eq(bid.balance.value(), 10000000);

            test_scenario::return_shared(bid);
        };

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidOwner)]
    fun test_cancel_bid_error() {
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

        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Cancel bid error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut bid_id = test_scenario::most_recent_id_shared<Bid>();
            assert!(bid_id.is_some(), 1);

            let bid: Bid = scenario.take_shared_by_id(bid_id.extract());

            // Can not cancel the listing since it is not the owner
            let coin: Coin<SUI> = cancel_bid(&mut marketplace, bid, scenario.ctx());

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

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Cancel bid
        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut bid_id = test_scenario::most_recent_id_shared<Bid>();
            assert!(bid_id.is_some(), 1);

            let bid: Bid = scenario.take_shared_by_id(bid_id.extract());

            // Can not cancel the listing since it is not the owner
            let coin: Coin<SUI> = cancel_bid(&mut marketplace, bid, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, other_account);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    fun test_cancel_bid_multiple_first() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_owner = @0xFAFE;

        let nft_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place bid 1
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Place bid 2
        scenario.next_tx(other_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Get id of 1st bid before listing 2 transaction is finished
        let mut bid1_id = test_scenario::most_recent_id_shared<Bid>();
        assert!(bid1_id.is_some(), 1);

        // Cancel bid 1
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut bid2_id = test_scenario::most_recent_id_shared<Bid>();

            let bid: Bid = scenario.take_shared_by_id(bid1_id.extract());

            let coin: Coin<SUI> = cancel_bid(&mut marketplace, bid, scenario.ctx());

            // Assert deleted correctly and indexes updated correctly
            assert_eq(marketplace.bids.length(), 1);
            assert!(marketplace.bids.borrow(0) == bid2_id.borrow(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert!(marketplace.bids_index.borrow(bid2_id.extract()) == 0, 1);

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, initial_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    fun test_cancel_bid_multiple_second() {
        use sui::test_scenario;
        use sui::test_utils::assert_eq;

        let initial_owner = @0xCAFE;
        let other_owner = @0xFAFE;

        let nft_id: ID;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Place bid 1
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Place bid 2
        scenario.next_tx(other_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            test_scenario::return_shared(marketplace);
        };

        // Get id of 1st bid before listing 2 transaction is finished
        let mut bid1_id = test_scenario::most_recent_id_shared<Bid>();
        assert!(bid1_id.is_some(), 1);

        // Cancel bid 2
        scenario.next_tx(other_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut bid2_id = test_scenario::most_recent_id_shared<Bid>();

            let bid: Bid = scenario.take_shared_by_id(bid2_id.extract());

            let coin: Coin<SUI> = cancel_bid(&mut marketplace, bid, scenario.ctx());

            // Assert deleted correctly and indexes updated correctly
            assert_eq(marketplace.bids.length(), 1);
            assert!(marketplace.bids.borrow(0) == bid1_id.borrow(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert!(marketplace.bids_index.borrow(bid1_id.extract()) == 0, 1);

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
            transfer::public_transfer(coin, other_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EInvalidNft)]
    fun test_accept_bid_error() {
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

            // Mint another nft which will be sent instead
            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);
        };

        // Create bid
        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Accept with error
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut bid_id = test_scenario::most_recent_id_shared<Bid>();
            assert!(bid_id.is_some(), 1);

            let bid: Bid = scenario.take_shared_by_id(bid_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            let coin: Coin<SUI> = accept_bid(&mut marketplace, bid, nft, scenario.ctx());

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

        let mut scenario = test_scenario::begin(initial_owner);
        {
            init(NFT_MARKETPLACE {}, scenario.ctx());

            let nft = mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());

            nft_id = object::id(&nft);

            transfer::public_transfer(nft, initial_owner);
        };

        // Create bid
        scenario.next_tx(other_account);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let coin = coin::mint_for_testing<SUI>(10000000, scenario.ctx());

            place_bid(&mut marketplace, nft_id, coin, scenario.ctx());

            assert_eq(marketplace.bids.length(), 1);
            assert_eq(marketplace.bids_index.length(), 1);
            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);

            test_scenario::return_shared(marketplace);
        };

        // Accept
        scenario.next_tx(initial_owner);
        {
            let mut marketplace_id = test_scenario::most_recent_id_shared<Marketplace>();
            let mut marketplace: Marketplace = scenario.take_shared_by_id(marketplace_id.extract());

            let mut bid_id = test_scenario::most_recent_id_shared<Bid>();
            assert!(bid_id.is_some(), 1);

            let bid: Bid = scenario.take_shared_by_id(bid_id.extract());
            let nft = scenario.take_from_sender<TestnetNFT>();

            let coin: Coin<SUI> = accept_bid(&mut marketplace, bid, nft, scenario.ctx());

            assert_eq(marketplace.listings.length(), 0);
            assert_eq(marketplace.listings_index.length(), 0);
            assert_eq(marketplace.bids.length(), 0);
            assert_eq(marketplace.bids_index.length(), 0);

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
