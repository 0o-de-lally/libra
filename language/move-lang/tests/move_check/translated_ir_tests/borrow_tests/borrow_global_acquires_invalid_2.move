module A {
    use 0x0::Signer;
    resource struct T1 {v: u64}
    resource struct T2 {v: u64}

    public fun test1(account: &signer) acquires T1, T2 {
        let x = borrow_global_mut<T1>(Signer::address_of(account));
        acquires_t2(account);
        acquires_t1(account);
        move x;
    }

    public fun test2(account: &signer) acquires T1, T2 {
        let x = borrow_global_mut<T1>(Signer::address_of(account));
        acquires_t2(account);
        acquires_t1(account);
        move x;
    }

    public fun test3(account: &signer) acquires T1, T2 {
        let x = borrow_global_mut<T1>(Signer::address_of(account));
        acquires_t1(account);
        move x;
        acquires_t2(account);
    }

    fun acquires_t1(account: &signer) acquires T1 {
        T1 { v: _ } = move_from<T1>(Signer::address_of(account));
    }

    fun acquires_t2(account: &signer) acquires T2 {
        T2 { v: _ } = move_from<T2>(Signer::address_of(account));
    }

}
