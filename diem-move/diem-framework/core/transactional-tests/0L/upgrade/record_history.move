//! account: alice, 1000000, 0, validator
//! account: bob, 1000000, 0, validator

//# run --admin-script --signers DiemRoot DiemRoot
script {
  use DiemFramework::Upgrade;
  use Std::Vector;

  fun main(sender: signer) {
    let validators = Vector::empty<address>();
    Vector::push_back(&mut validators, @Alice);
    Vector::push_back(&mut validators, @Bob);

    Upgrade::record_history(&sender, 0, x"1234", *&validators, 200);
    
    let (upgraded_version, payload, voters, height) = Upgrade::retrieve_latest_history();
    assert!(upgraded_version == 0, 1);
    assert!(payload == x"1234", 1);
    assert!(Vector::compare(&voters, &validators), 1);
    assert!(height == 200, 1);
  }
}
// check: EXECUTED
