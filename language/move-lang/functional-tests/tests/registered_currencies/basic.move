//! account: alice
script {
    use 0x1::RegisteredCurrencies;
    fun main(account: &signer) {
        RegisteredCurrencies::initialize(account);
    }
}
// check: ABORTED
// check: 0
//! new-transaction
//! sender: libraroot
script {
    use 0x1::RegisteredCurrencies;
    fun main(account: &signer) {
        RegisteredCurrencies::initialize(account);
    }
}
// check: ABORTED
// check: 0
