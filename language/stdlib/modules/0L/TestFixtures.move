/////////////////////////////////////////////////////////////////////////
// 0L Module
// TestFixtures
// Collection of vdf proofs for testing.
/////////////////////////////////////////////////////////////////////////

address 0x1 {
module TestFixtures{
  use 0x1::Testnet;

    // Here, I experiment with persistence for now
    // Committing some code that worked successfully
    // struct ProofFixture {
    //   challenge: vector<u8>,
    //   solution: vector<u8>
    // }

    // public fun alice(){
    //   // In the actual module, must assert that this is the sender is the association
    //   move_to_sender<State>(State{ hist: Vector::empty() });
    // }

    public fun easy_chal(): vector<u8> {
      assert(Testnet::is_testnet(), 130102014010);
      x"aa"
    }

    public fun easy_sol(): vector<u8>  {
      assert(Testnet::is_testnet(), 130102014010);
      x"001eef1120c0b13b46adae770d866308a5db6fdc1f408c6b8b6a7376e9146dc94586bdf1f84d276d5f65d1b1a7cec888706b680b5e19b248871915bb4319bbe13e7a2e222d28ef9e5e95d3709b46d88424c52140e1d48c1f123f2a1341448b9239e40509a604b1c54cc6c2750ae1255287308d7b2dd5353bae649d4b1bcb65154cffe2e189ec6960d5fa88eef4aa4f1c1939ce8b4808c379562a45ffcda8c502b9558c0999a595dddc02601e837634081977be9195345fae0e858b2cf402e03844ccda24977966ca41706e84c3bf4a841c3845c7bb519547b735cb5644fb0f8a78384827a098b3c80432a4db1135e3df70ade040444d67936b949bd17b68f64fde81000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
    }

    //FROM: libra/fixtures/block_0.json.stage.alice
    public fun alice_0_easy_chal(): vector<u8> {
      assert(Testnet::is_testnet(), 130102014010);
      x"91ffe0bce9806e599cd3565958ed0d3a0e7da4499fb75ccd30e6527761a55a06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304c20746573746e65746400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050726f74657374732072616765206163726f737320746865206e6174696f6e"
    }

    public fun alice_0_easy_sol(): vector<u8>  {
      assert(Testnet::is_testnet(), 130102014010);
      x"002081dc638812f346cd4b893e209cc0611ea3738116981b6c51ea0202dcea145ab8c3b473ed950a29cca0bb6273040f19ac2c307d147a56c832787cb1e57669a7e3821ef7576aac103c96bc8988855d82f21464ee0380f83aafe215313f3261983ee2c756922c2cf9af5d7ed8c7c00348e3792ed40fb96088ab979e8c5f336b6effeeac3e4c36d9245f4e4e73a7e754534f690e6c0033e10ea5bbeefb0c42fdd938b833057f65cfa72227333c4eeea13e584f4c1ef0d844cd1a57b06cee90538ec5e588fbe8052a29e53d741eabdfc55e5617524ddc403a9b8acb01894b83a3c262c088b963218156de818ce5bb067f16ef96b1bce5d5cdde7a706a048bd8369833000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
    }

        //FROM: libra/fixtures/block_1.json.stage.alice

    public fun alice_1_easy_chal(): vector<u8> {
      assert(Testnet::is_testnet(), 130102014010);
      x"c3de80a6d29ee233e8d12ff2bf65c67d0306ea16b46720dfa0829fa85e900701"
    }

    public fun alice_1_easy_sol(): vector<u8>  {
      assert(Testnet::is_testnet(), 130102014010);
      x"003b75d7f51101287bf2d6ac7ac8d1169a0e89f4bc5cebe36c612c6e6aab557ca2083cdf477f856657e62a6a1e2e26ed40521198e74cb7babeeb86e94ea1dd03388d3c9296a9cd073389fe09331ac59d085bfb78b5e52fc20d4df27f8f63853dd4ecfeee230e9aa4615433f8fcb783dd03d689c284575cf082a1783e99a44379de002ff2ea1f1e8915dc6b631ba6ce102542632df5f91320f4bc95e786e0d7c08d727245597da98d1b363750483897e859396b40b0b2a54a000a10a4000ddea250f667f8a782aa26bbc7490deb6efcf2af36749d55118e4122d904fc928f1fd256ea744316169b4f01c06094c133088b12e5f5fd692dce51124f3cab2206bda00355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
    }

  // // TODO: Replace with fixtures in libra/fixtures.
    public fun alice_0_hard_chal(): vector<u8> {
      assert(Testnet::is_testnet(), 130102014010);
      x"91ffe0bce9806e599cd3565958ed0d3a0e7da4499fb75ccd30e6527761a55a06000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000746573746e6574009f240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050726f74657374732072616765206163726f737320746865206e6174696f6e"
    }

    public fun alice_0_hard_sol(): vector<u8>  {
      assert(Testnet::is_testnet(), 130102014010);
      x"0057177684bb7bdc903dbda7747b69ae644357463f32e8f5992d68941db3024c15e4c6689ca1ec6a4661a0f88e8ab8a20b454f485b56a17cc4ca518cec5119a1b2e82ef66c36e692c7421ca68e6a98d53a64f6ff5e7fcaaa2c3b77c04d2a70386e310e7d4d791192e744fdbe3237a278c446747db2ed342fa3eb2e84c060c3e40affdaed7d471aa8e7c69f07fab73675802577741408c1daf5953c111cb90b1ea5262f40acd7db54feca7102b2e32576a997f0018df0df1ed508f4968ed87f2f174378cadc32c03f037aede53c4aa5cf22254b0114da49b63ba67b2b23aa599567f4e69f8f41ff30cd419e4b2f72bda15dc89eeb68661f704bbbdb8201292b0a493100007f2fa518ca6fc7fcadc3f1a0d42297f7a6d6e3c304bca3fe90cafc75b79bac5a053552b287fa47d4109561630bbe6b6c33d197f78d539845ea058db37757734462338dafe08ca8bc778a2a309968ef89c88cd12e4958701a94e36552da5abda4851fef7a75fe85432289a5350b4b43b6717240737f110c6dff291e5ba3eeb60000093c720dafce1325af11b8e531bd5db97eec1c633bd278e0b05ad783cc6d8042808cd08c6cbbf19cdbc61376b09dc57d60a947c58b5f9edd4d8fc3a25835946d97ecce061ca5c979e716709ac19a562c21429e8e757b9eb9a057cc2ebc31f19ed12b0db83f620fe1a8590cbdc029815fee988bba438b58452c30bb04f08faf"
    }
    public fun alice_1_hard_chal(): vector<u8> {
      assert(Testnet::is_testnet(), 130102014010);
      x"7ccfbe11759c6a348a09ebac903c312628cf89a971e73f1e0563930ab9271c69"
    }

    public fun alice_1_hard_sol(): vector<u8>  {
      assert(Testnet::is_testnet(), 130102014010);
      x"006408be2b99428c65d7a431a5e7a9e1657de1e8aae012274c43a744e3038a54a64cce4be427b64518b105f469d6c76eb7be7b2ee64acf5a786f2f2e7b7a3191f1c9ee0409a5780dfe9d979b48497abeab80cf985019363f83357ea64e57de3eb7c61411ea08467306ba7551317c871c8677e3af96d30fb1c33ffd5ce764e3dae4004c6930ef09561130b563b61cac4eb148a06c6d114a7531390edab64dbefeff99fd759ed32b0730a9a2a94fcb0032fc7740bab401a9af78f520150785d5093d38a020d330e875876d60e3aeaad7d10026a4a5fcc66553530b2ae6026c3ed8f3ff727cee3c0d2e96303594aa7a22df71cb8ac361ae687cc77ebae18e1b315a6e5d0001186b2b957c219389f3c4f7f3175332a0b3433ebff2f42a22d2a27b7615721d29ccded6a1a48171cb75b389cbbd5c1185d516e55578a3d0c343e643110eae5bfb244b783bc2ef394352f9c0d340df1397e594a553de0b4ae155eb1a0121ff9928f2318fa622bba08b9f9f21cc4294d58a70b5dd53b834b83fcc2f77d2729f03000001f0c19f6ee6000f09b39da694c6e1dd55bc365e298ec15fd863288565c8b0f06634d728b3e74443b5f365a3c14280795d41c921acbd67f25ee993d8fe2359545ef40191a193c2ff37df709a312573c904722753757cbbfc7b6f3c0cbfc7a21bcf72cec4bfccf640d4d93d1e4ceb54561e95b2cfaa4d964b32c7050ae097cb"
    }

    public fun eve_0_easy_chal(): vector<u8> {
      assert(Testnet::is_testnet(), 130102014010);
      x"f0e5b5ac5be816e87687b320273c815322172b8d4d5ccc8c13bca0981ef986ef000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304c20746573746e65746400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050726f74657374732072616765206163726f737320746865206e6174696f6e"
    }

    public fun eve_0_easy_sol(): vector<u8>  {
      assert(Testnet::is_testnet(), 130102014010);
      x"00315d0f4f2a515db441dc5044c094e46f6ad63eccfce5dff1d78d755aac62457aacc1028d7054bddefe6259c448c784683bd70ceff0b1e55b437b4381101ac820885a10516e8198e17ff5efa1548ee94416f0e5fea081bb7148b1be5f81f2c0492d3fe8d9a576ba3a777c3457e93aca54fc424b299b41e963e4695a48e2dbaac0ffe2c9f9ef9916e4a5a4d1209dff9547c713215083a4b7fd8b27539f3c3bbd3f62213172973c2a0029b5a496a36239dc3631498ca3fddc2cf36c2b26c05526e4b255ea4416390f8db42f28dc87bd7bd035a9e358b2a3385378086bf446da09c3c4b5697e3b97fbc33ab5ab924c57d3d1f20bcb3a777256ebc5ffd081482be54f2d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
    }
  }
}
