//# init --validators Alice Bob Carol Dave Eve

// This tests consensus Case 2.
// ALICE is a validator.
// DID validate successfully.
// DID NOT mine above the threshold for the epoch. 

//# block --proposer Alice --time 1 --round 0

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::DiemAccount;
    use DiemFramework::GAS::GAS;
    use DiemFramework::ValidatorConfig;

    fun main(dr: signer, _account: signer) {        
        // tranfer enough coins to operators
        let oper_alice = ValidatorConfig::get_operator(@Alice);
        let oper_bob = ValidatorConfig::get_operator(@Bob);
        let oper_carol = ValidatorConfig::get_operator(@Carol);
        let oper_dave = ValidatorConfig::get_operator(@Dave);
        let oper_eve = ValidatorConfig::get_operator(@Eve);
        DiemAccount::vm_make_payment_no_limit<GAS>(
            @Alice, oper_alice, 50009, x"", x"", &dr
        );
        DiemAccount::vm_make_payment_no_limit<GAS>(
            @Bob, oper_bob, 50009, x"", x"", &dr
        );
        DiemAccount::vm_make_payment_no_limit<GAS>(
            @Carol, oper_carol, 50009, x"", x"", &dr
        );
        DiemAccount::vm_make_payment_no_limit<GAS>(
            @Dave, oper_dave, 50009, x"", x"", &dr
        );
        DiemAccount::vm_make_payment_no_limit<GAS>(
            @Eve, oper_eve, 50009, x"", x"", &dr
        );
    }
}
//check: EXECUTED

//# run --admin-script --signers DiemRoot Bob
script {
    use DiemFramework::DiemSystem;
    use DiemFramework::TowerState;
    use DiemFramework::NodeWeight;
    use DiemFramework::GAS::GAS;
    use DiemFramework::DiemAccount;

    fun main(_dr: signer, _account: signer) {
        // Tests on initial size of validators 
        assert!(DiemSystem::validator_set_size() == 5, 7357000180101);
        assert!(DiemSystem::is_validator(@Bob), 7357000180102);
        assert!(DiemSystem::is_validator(@Eve), 7357000180103);
        assert!(TowerState::test_helper_get_height(@Bob) == 0, 7357000180104);

        //// NO MINING ////

        assert!(DiemAccount::balance<GAS>(@Bob) == 9949991, 7357000180106);
        assert!(NodeWeight::proof_of_weight(@Bob) == 0, 7357000180107);  
        assert!(TowerState::test_helper_get_height(@Bob) == 0, 7357000180108);
    }
}
// check: EXECUTED

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use Std::Vector;
    use DiemFramework::Stats;
    // use DiemFramework::FullnodeState;
    // This is the the epoch boundary.
    fun main(vm: signer, _account: signer) {
        // This is not an onboarding case, steady state.
        // FullnodeState::test_set_fullnode_fixtures(&vm, @Bob, 0, 0, 0, 200, 200, 1000000);

        let voters = Vector::empty<address>();
        Vector::push_back<address>(&mut voters, @Alice);
        Vector::push_back<address>(&mut voters, @Bob);
        Vector::push_back<address>(&mut voters, @Carol);
        Vector::push_back<address>(&mut voters, @Dave);
        Vector::push_back<address>(&mut voters, @Eve);

        //// NOTE: BOB DOES NOT MINE

        // Overwrite the statistics to mock that all have been validating.
        let i = 1;
        while (i < 16) {
            // Mock the validator doing work for 15 blocks, and stats being updated.
            Stats::process_set_votes(&vm, &voters);
            i = i + 1;
        };
    }
}

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::Cases;
    
    fun main(vm: signer, _:signer) {
        // We are in a new epoch.
        // Check Bob is in the the correct case during reconfigure
        assert!(Cases::get_case(&vm, @Bob, 0, 15) == 2, 7357000180109);
    }
}

//////////////////////////////////////////////
///// Trigger reconfiguration at 61 seconds ////
//# block --proposer Alice --time 61000000 --round 15

///// TEST RECONFIGURATION IS HAPPENING ////
// check: NewEpochEvent
//////////////////////////////////////////////

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::DiemSystem;
    use DiemFramework::NodeWeight;
    use DiemFramework::GAS::GAS;
    use DiemFramework::DiemAccount;
    use DiemFramework::TowerState;

    fun main(_dr: signer, _account: signer) {
        // We are in a new epoch.

        // Check the validator set is at expected size
        // case 2 does not reject Alice.
        assert!(DiemSystem::validator_set_size() == 5, 7357000180110);
        assert!(DiemSystem::is_validator(@Bob), 7357000180111);
        
        //case 2 does not get rewards.
        assert!(DiemAccount::balance<GAS>(@Bob) == 9949991, 7357000180112);

        //case 2 does not increment weight.
        assert!(NodeWeight::proof_of_weight(@Bob) == 0, 7357000180113);

        //case 2 does not increment epochs_validating and mining.
        assert!(TowerState::get_epochs_compliant(@Bob) == 0, 7357000180114);
    }
}