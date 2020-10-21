// ALICE is CASE 1
//! account: alice, 1, 0, validator

// BOB is CASE 2
//! account: bob, 1, 0, validator

// BOB is CASE 3
//! account: carol, 1, 0, validator

// BOB is CASE 4
//! account: dave, 1, 0, validator

//! new-transaction
//! sender: alice
script {
    use 0x1::MinerState;
    fun main(sender: &signer) {
      //NOTE: Alice is Case 1, she validates and mines. Setting up mining.
        MinerState::test_helper_mock_mining(sender, 5);

    }
}
//check: EXECUTED


//! new-transaction
//! sender: carol
script {
    use 0x1::MinerState;
    fun main(sender: &signer) {
      //NOTE: Carol is Case 3, she mines but does not validate. Setting up mining.
        MinerState::test_helper_mock_mining(sender, 5);

    }
}
//check: EXECUTED

//! new-transaction
//! sender: libraroot
script {
  // 
  // use 0x1::Subsidy;
  use 0x1::Vector;
  use 0x1::Stats;
  // use 0x1::Debug::print;
  use 0x1::GAS::GAS;
  use 0x1::LibraAccount;
  use 0x1::Cases;

  fun main(vm: &signer) {
    // check the case of a network density of 4 active validators.

    let validators = Vector::singleton<address>({{alice}});
    Vector::push_back(&mut validators, {{bob}});

    // create mock validator stats for full epoch
    let i = 0;
    while (i < 16) {
      Stats::process_set_votes(vm, &validators);
      i = i + 1;
    };

    assert(LibraAccount::balance<GAS>({{alice}}) == 1, 7357190102011000);
    assert(LibraAccount::balance<GAS>({{bob}}) == 1, 7357190102021000);
    assert(LibraAccount::balance<GAS>({{carol}}) == 1, 7357190102031000);
    assert(LibraAccount::balance<GAS>({{dave}}) == 1, 7357190102041000);

    assert(Cases::get_case(vm, {{alice}}) == 1, 7357190102051000);
    assert(Cases::get_case(vm, {{bob}}) == 2, 7357190102061000);
    assert(Cases::get_case(vm, {{carol}}) == 3, 7357190102071000);
    assert(Cases::get_case(vm, {{dave}}) == 4, 7357190102081000);
  }
}
// check: EXECUTED


//! new-transaction
//! sender: libraroot
script {
    use 0x1::LibraAccount;
    use 0x1::GAS::GAS;
    use 0x1::Subsidy;
    use 0x1::TransactionFee;
    use 0x1::Libra;

    fun main(vm: &signer) {
        let coin = Libra::mint<GAS>(vm, 1000);
        TransactionFee::pay_fee(coin);
        let bal = TransactionFee::get_amount_to_distribute(vm);
        assert(bal == 1000, 7357190103011000);

        Subsidy::process_fees(vm);

        assert(LibraAccount::balance<GAS>({{alice}}) == 1001, 7357190103021000);
        assert(LibraAccount::balance<GAS>({{bob}}) == 1, 7357190103031000);
        assert(LibraAccount::balance<GAS>({{carol}}) == 1, 7357190103031000);
        assert(LibraAccount::balance<GAS>({{dave}}) == 1, 7357190103031000);
    }
}
// check: EXECUTED