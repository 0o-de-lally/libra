//# init --validators Alice

// Tests the prologue reconfigures based on wall clock

//# block --proposer Alice --time 1 --round 1

//////////////////////////////////////////////
///// Trigger reconfiguration at 61 seconds ////
//# block --proposer Alice --time 61000000 --round 15

///// TEST RECONFIGURATION IS HAPPENING ////
// check: NewEpochEvent
//////////////////////////////////////////////