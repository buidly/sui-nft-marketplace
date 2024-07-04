#[test_only]
module nft_marketplace::nft_marketplace_tests {
    use nft_marketplace::old::{ Self, Sword };

    #[test]
    fun test_sword_transactions() {
        use sui::test_scenario;

        // Create test addresses representing users
        let initial_owner = @0xCAFE;
        let final_owner = @0xFACE;

        // First transaction executed by initial owner to create the sword
        let mut scenario = test_scenario::begin(initial_owner);
        {
            // Create the sword and transfer it to the initial owner
            let sword = old::sword_create(42, 7, scenario.ctx());
            transfer::public_transfer(sword, initial_owner);
        };

        // Second transaction executed by the initial sword owner
        scenario.next_tx(initial_owner);
        {
            // Extract the sword owned by the initial owner
            let sword = scenario.take_from_sender<Sword>();
            // Transfer the sword to the final owner
            transfer::public_transfer(sword, final_owner);
        };

        // Third transaction executed by the final sword owner
        scenario.next_tx(final_owner);
        {
            // Extract the sword owned by the final owner
            let sword = scenario.take_from_sender<Sword>();
            // Verify that the sword has expected properties
            assert!(sword.magic() == 42 && sword.strength() == 7, 1);
            // Return the sword to the object pool (it cannot be simply "dropped")
            scenario.return_to_sender(sword)
        };
        scenario.end();
    }
}
