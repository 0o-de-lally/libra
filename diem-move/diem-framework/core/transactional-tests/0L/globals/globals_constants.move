//# init --validators Alice

//# run --admin-script --signers DiemRoot DiemRoot
script {
    use DiemFramework::Globals;
    use DiemFramework::Testnet;
    use DiemFramework::DiemSystem;

    fun main() {
        assert!(DiemSystem::is_validator(@Alice) == true, 98);

        let len = Globals::get_epoch_length();
        let set = DiemSystem::validator_set_size();
        
        assert!(set == 1u64, 73570001);

        if (Testnet::is_testnet()){
            assert!(len == 60u64, 73570001);
        } else {
            assert!(len == 196992u64, 73570001);
        }
    }
}
// check: EXECUTED