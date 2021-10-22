//! `CreateAccount` subcommand

#![allow(clippy::never_loop)]

use abscissa_core::{Command, Options, Runnable};
use ol_types::{account::UserConfigs, config::TxType};
use crate::{entrypoint, submit_tx::{tx_params_wrapper, maybe_submit}};
use diem_types::transaction::TransactionPayload;
use diem_transaction_builder::stdlib as transaction_builder;
use std::{fs, path::PathBuf, process::exit};
use std::io::Read;
/// `CreateAccount` subcommand
#[derive(Command, Debug, Default, Options)]
pub struct CreateAccountCmd {
    #[options(short = "f", help = "path of account.json")]
    account_json_path: PathBuf,
}

pub fn create_user_account_script_function(account_json_path: &str) -> TransactionPayload {

    let mut json_string = String::new();
    let mut file = fs::File::open(account_json_path).expect("file should open read only");
    file.read_to_string(&mut json_string)
      .unwrap_or_else(|err| panic!("Error while reading file: [{}]", err));

    let user: UserConfigs = serde_json::from_str(&json_string).expect("could not parse json file");
    
    transaction_builder::encode_create_acc_user_script_function(
      user.block_zero.preimage.clone(),
      user.block_zero.proof.clone(),
      user.block_zero.difficulty(),
      user.block_zero.security(),
    )    
}

impl Runnable for CreateAccountCmd {    
    fn run(&self) {
        let entry_args = entrypoint::get_args();
        let account_json = self.account_json_path.to_str().unwrap();
        let tx_params = tx_params_wrapper(TxType::Mgmt).unwrap();

        match maybe_submit(
            create_user_account_script_function(account_json),
            &tx_params,
            entry_args.no_send,
            entry_args.save_path,
          ) {
            Err(e) => {
                println!(
                    "ERROR: could not submit account creation transaction, message: \n{:?}", 
                    &e
                );
                exit(1);
            },
            _ => {}
          }
    }
}