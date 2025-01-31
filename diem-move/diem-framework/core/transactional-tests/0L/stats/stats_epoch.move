//# init --validators Alice Bob Carol Dave

// Case 1: Validators are compliant. 
// This test is to check if validators are present after the first epoch.
// Here EPOCH-LENGTH = 15 Blocks.
// NOTE: This test will fail with Staging and Production Constants, only for Debug - due to epoch length.

//# block --proposer Alice --time 1 --round 0

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::Stats;

    // Assumes an epoch changed at round 15
    fun main(vm: signer, _: signer) {
      let vm = &vm;
      //proposals
      assert!(Stats::node_current_props(vm, @Alice) == 1, 0);
      assert!(Stats::node_current_props(vm, @Bob) == 0, 0);
      //votes
      assert!(Stats::node_current_votes(vm, @Alice) == 0, 0);
      assert!(Stats::node_current_votes(vm, @Bob) == 0, 0);

    }
}
// check: EXECUTED

///////// ADD A NEW PROPOSAL /////
//# block --proposer Alice --time 2 --round 0


//# run --admin-script --signers DiemRoot DiemRoot
script {
    use Std::Vector;
    use DiemFramework::Stats;
    // This is the the epoch boundary.
    fun main(vm: signer, _: signer) {
      let vm = &vm;

      assert!(Stats::node_current_props(vm, @Alice) == 2, 735700001);
      assert!(Stats::node_current_props(vm, @Bob) == 0, 735700002);
      assert!(Stats::node_current_votes(vm, @Alice) == 0, 735700003);
      assert!(Stats::node_current_votes(vm, @Bob) == 0, 735700004);

      let voters = Vector::empty<address>();
      Vector::push_back<address>(&mut voters, @Alice);
      Vector::push_back<address>(&mut voters, @Bob);
      Vector::push_back<address>(&mut voters, @Carol);
      Vector::push_back<address>(&mut voters, @Dave);

        // Overwrite the statistics to mock that all have been validating.
        let i = 1;
        while (i < 16) {
            // Mock the validator doing work for 15 blocks, and stats being updated.
            Stats::process_set_votes(vm, &voters);
            i = i + 1;
        };

      assert!(Stats::node_above_thresh(vm, @Alice, 0, 15), 735700005);
      assert!(Stats::node_above_thresh(vm, @Bob, 0, 15), 735700006);
      assert!(Stats::node_above_thresh(vm, @Carol, 0, 15), 735700007);
      assert!(Stats::node_above_thresh(vm, @Dave, 0, 15), 735700008);

      assert!(Stats::network_density(vm, 0, 15) == 4, 735700009);
    }
}
// check: EXECUTED

//////////////////////////////////////////////
///// Trigger reconfiguration at 61 seconds ////
//# block --proposer Alice --time 61000000 --round 15

///// TEST RECONFIGURATION IS HAPPENING ////
// check: NewEpochEvent
//////////////////////////////////////////////


//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::Stats;
    // use Std::Vector;
    fun main(vm: signer, _: signer) {
      let vm = &vm;
      // Testing that reconfigure reset the counter for current epoch.
      assert!(!Stats::node_above_thresh(vm, @Alice, 16, 17), 735700010);

      // should reset alice's count
      assert!(Stats::node_current_props(vm, @Alice) == 0, 735700011);
      assert!(Stats::node_current_props(vm, @Bob) == 0, 735700012);
      assert!(Stats::node_current_votes(vm, @Alice) == 0, 735700013);
      assert!(Stats::node_current_votes(vm, @Bob) == 0, 735700014);
    }
}
// check: EXECUTED
