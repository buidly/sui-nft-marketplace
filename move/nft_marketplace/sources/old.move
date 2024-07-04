module nft_marketplace::old {
    use std::debug;

    // This is the only dependency you need for events.
    use sui::event;

    // Use this dependency to get a type wrapper for UTF-8 strings
    use std::string::{Self};


    // === Errors ===

    const ESwordStrengthExceeded: u64 = 0;

    // ====== Events ======

    public struct SwordCreated has copy, drop {
        id: ID
    }

    // === Structs ===

    public struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
    }

    public struct Forge has key {
        id: UID,
        swords_created: u64,
    }

    // === Public-View Functions ===

    fun init(ctx: &mut TxContext) {
        let admin = Forge {
            id: object::new(ctx),
            swords_created: 0,
        };

        // Transfer the forge object to the module/package publisher
        transfer::transfer(admin, ctx.sender());
    }

    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public fun swords_created(self: &Forge): u64 {
        self.swords_created
    }

    // === Entrypoints  ===

    public fun sword_create(magic: u64, strength: u64, ctx: &mut TxContext): Sword {
        assert!(strength < 10, ESwordStrengthExceeded);

        let id = object::new(ctx);

        // Emit the event using future object's ID.
        event::emit(SwordCreated { id: object::uid_to_inner(&id) });

        Sword {
            id,
            magic: magic,
            strength: strength,
        }
    }

    public fun new_sword(
        forge: &mut Forge,
        magic: u64,
        strength: u64,
        ctx: &mut TxContext,
        // name_bytes: vector<u8>
    ): Sword {
        let test_string = string::utf8(b"testing");
        debug::print(&test_string);

        debug::print(forge);
        forge.swords_created = forge.swords_created + 1;
        debug::print(forge);
        Sword {
            id: object::new(ctx),
            magic: magic,
            strength: strength,
        }
    }

    // === Test Functions ===

    #[test]
    fun test_module_init() {
        use sui::test_scenario;

        // Create test addresses representing users
        let admin = @0xAD;
        let initial_owner = @0xCAFE;

        // First transaction to emulate module initialization
        let mut scenario = test_scenario::begin(admin);
        {
            init(scenario.ctx());
        };

        // Second transaction to check if the forge has been created
        // and has initial value of zero swords created
        scenario.next_tx(admin);
        {
            // Extract the Forge object
            let forge = scenario.take_from_sender<Forge>();
            // Verify number of created swords
            assert!(forge.swords_created() == 0, 1);
            // Return the Forge object to the object pool
            scenario.return_to_sender(forge);
        };

        // Third transaction executed by admin to create the sword
        scenario.next_tx(admin);
        {
            let mut forge = scenario.take_from_sender<Forge>();
            // Create the sword and transfer it to the initial owner
            let sword = forge.new_sword(42, 7, scenario.ctx());
            transfer::public_transfer(sword, initial_owner);
            scenario.return_to_sender(forge);
        };
        scenario.end();
    }

    #[test]
    fun test_sword_create() {
        // Create a dummy TxContext for testing
        let mut ctx = tx_context::dummy();

        // Create a sword
        let sword = Sword {
            id: object::new(&mut ctx),
            magic: 42,
            strength: 7,
        };

        // Check if accessor functions return correct values
        assert!(sword.magic() == 42 && sword.strength() == 7, 1);

        let dummy_address = @0xCAFE;
        transfer::public_transfer(sword, dummy_address);
    }
}
