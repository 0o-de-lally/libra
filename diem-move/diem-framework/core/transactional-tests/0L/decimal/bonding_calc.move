//# init --validators Alice

//# run --admin-script --signers DiemRoot DiemRoot
script {
  use DiemFramework::DemoBonding;

  fun main(_dr: signer, _: signer) {
    let add_to_reserve = 300;
    let reserve = 100;
    let supply = 1;
    let res = DemoBonding::deposit_calc(add_to_reserve, reserve, supply);
    assert!(res == 2, 73501);

    let add_to_reserve = 10;
    let reserve = 100;
    let supply = 10000;
    let res = DemoBonding::deposit_calc(add_to_reserve, reserve, supply);
    assert!(res == 10488, 73502);
  }
}