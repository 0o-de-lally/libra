//# init  --validators Alice Bob Dave CommunityA

// Alice is a validator and has a slow wallet. She makes an autopay instruction
// but we first need to make sure she has enough unlocked.

//# run --admin-script --signers DiemRoot CommunityA
script {
    use DiemFramework::DonorDirected;
    use Std::Vector;
    use DiemFramework::DiemAccount;

    fun main(_dr: signer, sponsor: signer) {
      DonorDirected::init_donor_directed(&sponsor, @Alice, @Bob, @Dave, 2);
      DonorDirected::finalize_init(&sponsor);
      let list = DonorDirected::get_root_registry();
      assert!(Vector::length(&list) == 1, 7357001);
      assert!(DiemAccount::is_init_cumu_tracking(@CommunityA), 7357002);

    }
}
// check: EXECUTED

// alice commits to paying CommunityA 5% of her worth per epoch
//# run --admin-script --signers DiemRoot Alice
script {
  use DiemFramework::AutoPay;
  use Std::Signer;

  fun main(_dr: signer, sender: signer) {
    let sender = &sender;
    AutoPay::enable_autopay(sender);
    assert!(AutoPay::is_enabled(Signer::address_of(sender)), 0);
    
    // instruction type percent of balance
    AutoPay::create_instruction(
      sender,
      1, // UID
      0, // percent of balance type
      @CommunityA,
      2, // until epoch two
      500 // 5 percent
    );

    let (type, payee, end_epoch, percentage) = AutoPay::query_instruction(
      Signer::address_of(sender), 1
    );
    assert!(type == 0, 735701);
    assert!(payee == @CommunityA, 735702);
    assert!(end_epoch == 2, 735703);
    assert!(percentage == 500, 735704);
  }
}

//# run --admin-script --signers DiemRoot CommunityA
script {
    // use DiemFramework::DonorDirected;
    // use Std::Vector;
    use DiemFramework::DiemAccount;
    use DiemFramework::GAS::GAS;
    use DiemFramework::AutoPay;
    // use DiemFramework::Debug::print;

    fun main(dr: signer, _sponsor: signer) {
      let starting_balance_alice = DiemAccount::balance<GAS>(@Alice);
      let starting_balance_comm = DiemAccount::balance<GAS>(@CommunityA);

      // print(&starting_balance);
      // make sure there's enough in the unlocked slow wallet to pay.
      DiemAccount::slow_wallet_epoch_drip(&dr,1000000);
      // assert!(ending_balance == 10000000, 735705);
      AutoPay::process_autopay(&dr);


      let ending_balance_alice = DiemAccount::balance<GAS>(@Alice);
      let ending_balance_comm = DiemAccount::balance<GAS>(@CommunityA);

      // print(&ending_balance);
      
      assert!(starting_balance_alice > ending_balance_alice, 735706);
      assert!(ending_balance_comm > starting_balance_comm, 735707);

      assert!(ending_balance_alice == 9500001, 735708);

    }
}
// check: EXECUTED

