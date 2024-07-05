#[test_only]
module nft_marketplace::nft_marketplace_tests {
    use std::string;

    use sui::test_utils::assert_eq;
    use sui::url;

    use nft_marketplace::nft_marketplace::{ Self, TestnetNFT};

    #[test]
    fun test_mint_to_sender() {
        use sui::test_scenario;

        let initial_owner = @0xCAFE;

        let mut scenario = test_scenario::begin(initial_owner);
        {
            let nft = nft_marketplace::mint_to_sender(b"Name", b"Description", b"url", scenario.ctx());
            transfer::public_transfer(nft, initial_owner);
        };

        let effects = scenario.next_tx(initial_owner);
        assert_eq(effects.num_user_events(), 1); // 1 event emitted

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
