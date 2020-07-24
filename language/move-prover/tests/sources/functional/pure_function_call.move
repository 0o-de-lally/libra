module TestPureFun {
    use 0x1::CoreAddresses;
    use 0x1::Signer;

    resource struct T {
        x: u64,
    }

    public fun init(lr_account: &signer): bool {
        assert(Signer::address_of(lr_account) == 0xA550C18, 0);
        move_to(lr_account, T { x: 0 });
        false
    }

    spec fun init {
        aborts_if Signer::spec_address_of(lr_account) != CoreAddresses::LIBRA_ROOT_ADDRESS();
        aborts_if exists<T>(Signer::spec_address_of(lr_account));
        ensures lr_x() == 0;
    }

    public fun get_x(addr: address): u64 acquires T {
        *&borrow_global<T>(addr).x
    }

    public fun get_x_plus_one(addr: address): u64 acquires T {
        get_x(addr) + 1
    }

    public fun increment_x(addr: address) acquires T {
        let t = borrow_global_mut<T>(addr);
        t.x = t.x + 1;
    }

    spec fun increment_x {
        ensures get_x(addr) == old(get_x(addr)) + 1;
        ensures get_x(addr) == old(get_x_plus_one(addr));
    }

    spec module {
        define lr_x(): u64 {
            get_x(CoreAddresses::LIBRA_ROOT_ADDRESS())
        }
    }

}
