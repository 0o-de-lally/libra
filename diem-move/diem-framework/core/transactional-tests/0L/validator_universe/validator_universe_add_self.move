// Adding new validator epoch info
//! account: alice, 100000 ,0, validator
//! account: eve, 100000

//! new-transaction
//! sender: diemroot
script{
use DiemFramework::ValidatorUniverse;
use DiemFramework::Vector;
// use DiemFramework::TestFixtures;
// use DiemFramework::DiemAccount;

fun main(vm: signer) {
    let len = Vector::length<address>(
        &ValidatorUniverse::get_eligible_validators(&vm)
    );
    assert!(len == 1, 73570);
}
}
// check: EXECUTED

//! new-transaction
//! sender: eve
script{
use DiemFramework::ValidatorUniverse;
use DiemFramework::TestFixtures;
use DiemFramework::TowerState;
// use DiemFramework::FullnodeState;

fun main(eve_sig: signer) {
    let eve_sig = &eve_sig;
    TowerState::init_miner_state(
        eve_sig,
        &TestFixtures::easy_chal(),
        &TestFixtures::easy_sol(),
        TestFixtures::easy_difficulty(), // difficulty
        TestFixtures::security(), // security
    );
    // FullnodeState::init(eve_sig);

    TowerState::test_helper_mock_mining(eve_sig, 5);
    ValidatorUniverse::add_self(eve_sig);
}
}
// check: EXECUTED

//! new-transaction
//! sender: diemroot
script{
    use DiemFramework::Vector;
    use DiemFramework::ValidatorUniverse;

    fun main(vm: signer) {
        let len = Vector::length<address>(
            &ValidatorUniverse::get_eligible_validators(&vm
        ));
        assert!(len == 2, 73570);
    }
}
// check: EXECUTED
