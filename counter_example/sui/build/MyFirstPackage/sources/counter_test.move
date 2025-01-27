// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This example demonstrates a basic use of a shared object.
/// Rules:
/// - anyone can create and share a counter
/// - everyone can increment a counter by 1
/// - the owner of the counter can reset it to any value
module my_first_package::counter {
    use sui::transfer;
    use sui::id::VersionedID;
    use sui::tx_context::{Self, TxContext};

    /// A shared counter.
    struct Counter has key {
        id: VersionedID,
        owner: address,
        value: u64
    }

    public fun owner(counter: &Counter): address {
        counter.owner
    }

    public fun value(counter: &Counter): u64 {
        counter.value
    }

    /// Create and share a Counter object.
    public entry fun create(ctx: &mut TxContext) {
        transfer::share_object(Counter {
            id: tx_context::new_id(ctx),
            owner: tx_context::sender(ctx),
            value: 0
        })
    }

    /// Increment a counter by 1.
    public entry fun increment(counter: &mut Counter) {
        counter.value = counter.value + 1;
    }

    /// Set value (only runnable by the Counter owner)
    public entry fun set_value(counter: &mut Counter, value: u64, ctx: &mut TxContext) {
        assert!(counter.owner == tx_context::sender(ctx), 0);
        counter.value = value;
    }

    /// Assert a value for the counter.
    public entry fun assert_value(counter: &Counter, value: u64) {
        assert!(counter.value == value, 0)
    }
}

#[test_only]
module my_first_package::counter_test {
    use sui::test_scenario;
    use my_first_package::counter;

    #[test]
    fun test_counter() {
        let owner = @0xC0FFEE;
        let user1 = @0xA1;

        let scenario = &mut test_scenario::begin(&user1);

        test_scenario::next_tx(scenario, &owner);
        {
            counter::create(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, &user1);
        {
            let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
            let counter = test_scenario::borrow_mut(&mut counter_wrapper);

            assert!(counter::owner(counter) == owner, 0);
            assert!(counter::value(counter) == 0, 1);

            counter::increment(counter);
            counter::increment(counter);
            counter::increment(counter);
            test_scenario::return_shared(scenario, counter_wrapper);
        };

        test_scenario::next_tx(scenario, &owner);
        {
            let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
            let counter = test_scenario::borrow_mut(&mut counter_wrapper);

            assert!(counter::owner(counter) == owner, 0);
            assert!(counter::value(counter) == 3, 1);

            counter::set_value(counter, 100, test_scenario::ctx(scenario));

            test_scenario::return_shared(scenario, counter_wrapper);
        };

        test_scenario::next_tx(scenario, &user1);
        {
            let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
            let counter = test_scenario::borrow_mut(&mut counter_wrapper);

            assert!(counter::owner(counter) == owner, 0);
            assert!(counter::value(counter) == 100, 1);

            counter::increment(counter);

            assert!(counter::value(counter) == 101, 2);

            test_scenario::return_shared(scenario, counter_wrapper);
        };
    }
}

// module my_first_package::counter {
//     use sui::transfer;
//     use sui::object::{Self, Info};
//     use sui::tx_context::{Self, TxContext};

//     struct Counter has key {
//         info: Info,
//         owner: address,
//         value: u64
//     }

//     public fun get_owner(counter: &Counter): address {
//         counter.owner
//     }

//     public fun get_value(counter: &Counter): u64 {
//         counter.value
//     }

//     // constructor
//     public entry fun create(ctx: &mut TxContext) {
//         transfer::share_object(Counter {
//             info: object::new(ctx),
//             owner: tx_context::sender(ctx),
//             value: 5
//         })
//     }

//     public entry fun increment(counter: &mut Counter) {
//         counter.value = counter.value + 1;
//     }

//     // only runnable by the Counter owner
//     public entry fun set_value(counter: &mut Counter, value: u64, ctx: &mut TxContext) {
//         assert!(
//             counter.owner == tx_context::sender(ctx),
//             1
//         );
//         counter.value = value;
//     }

//     public entry fun assert_value(counter: &mut Counter, value: u64) {
//         assert!(
//             counter.value == value,
//             1
//         )
//     }
// }

// #[test_only]
// module my_first_package::counter_test {
//     use sui::test_scenario;
//     use my_first_package::counter;

//     #[test]
//     fun test_counter() {
//         let owner = @0xC0FFEE;
//         let user1 = @0xA1;
//         let scenario = &mut test_scenario::begin(&user1);

//         test_scenario::next_tx(scenario, &owner);
//         {
//             counter::create(test_scenario::ctx(scenario));
//         };

//         test_scenario::next_tx(scenario, &user1);
//         {
//             let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
//             let counter = test_scenario::borrow_mut(&mut counter_wrapper);

//             assert!(
//                 counter::owner(counter) == owner,
//                 0
//             );

//             assert!(
//                 counter::value(counter) == 0,
//                 1
//             );

//             counter::increment(counter);
//             counter::increment(counter);
//             counter::increment(counter);
//             test_scenario::return_shared(scenario, counter_wrapper);
//         }
//     }
// }