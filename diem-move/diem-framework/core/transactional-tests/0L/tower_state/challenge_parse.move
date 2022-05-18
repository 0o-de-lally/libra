//# init --validators DummyPreventsGenesisReload
//#      --addresses Bob=0x4b7653f6566a52c9b496f245628a69a0
//#      --private-keys Bob=f5fd1521bd82454a9834ef977c389a0201f9525b11520334842ab73d2dcbf8b7

//// Old syntax for reference, delete it after fixing this test
//! account: dummy-prevents-genesis-reload, 100000 ,0, validator
//! account: bob, 10000000GAS

// todo: fix this first: native_extract_address_from_challenge()
// https://github.com/OLSF/move-0L/blob/v6/language/move-stdlib/src/natives/ol_vdf.rs

//# run --admin-script --signers DiemRoot Bob
script {
    use DiemFramework::TowerState;
    fun main() {
        // First 32 bytes (64 hex characters) make up the auth_key. Of this,
        // the first 16 bytes (32 hex characters) make up the auth_key pefix
        // the last 16 bytes of the auth_key make up the account address
        // The native function implemented in Rust parses this and gives out the
        // address. This is then confirmed in the the TowerState module (move-space)
        // to be the same address as the one passed in

        let challenge = x"232fb6ae7221c853232fb6ae7221c853000000000000000000000000deadbeef";
        let new_account_address = @0x000000000000000000000000deadbeef;

        // Parse key and check
        TowerState::first_challenge_includes_address(new_account_address, &challenge);
        // Note: There is a assert statement in this function already
        // which checks to confim that the parsed address and new_account_address
        // the same. Execution of this guarantees that the test of the native
        // function passed.

        challenge = x"232fb6ae7221c853232fb6ae7221c853000000000000000000000000deadbeef00000000000000000000000000000000000000000000000000000000000000000000000000004f6c20746573746e6574640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070726f74657374732072616765206163726f737320416d6572696361";

        let new_account_address = @0x000000000000000000000000deadbeef;
        TowerState::first_challenge_includes_address(new_account_address, &challenge);
    }
}
// check: EXECUTED


//# run --admin-script --signers DiemRoot Bob
script {
    use DiemFramework::TowerState;

    fun main() {
        // Another key whose parsing will fail because it's too short.
        let challenge = x"7005110127";
        let new_account_address = @0x000000000000000000000000deadbeef;

        // Parse key and check
        TowerState::first_challenge_includes_address(new_account_address, &challenge);
    }
}
// check: ABORTED