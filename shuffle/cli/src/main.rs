// Copyright (c) The Diem Core Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::{
    shared::{get_home_path, normalized_network_name, Home, NetworkHome, LATEST_USERNAME},
    test::TestCommand,
};
use anyhow::{anyhow, Result};
use diem_types::{account_address::AccountAddress, chain_id::NamedChain};
use reqwest::Url;
use std::path::PathBuf;
use structopt::StructOpt;

use shuffle::{account, build, console, deploy, new, node, shared, test, transactions};

#[tokio::main]
pub async fn main() -> Result<()> {
    let command = Command::from_args();
    let home = Home::new(normalize_home_path(command.home_path).as_path())?;
    match command.subcommand {
        Subcommand::Network { add, url, name, chain } => {
          if add && url.is_some() && name.is_some() {
            // create a Network struct
            let u = url.expect("could not read URL");
            let net = shared::Network::new(name.expect("could not read name of network"), u.clone(), u, None, chain);
            home.add_network_toml(net)?;
          } else if add {
            println!("Error: Please provide a url and name for the network");
          };

          let net = home.read_networks_toml()?;
          println!("Networks:");
          
          net.networks.into_iter().for_each(|(name, cfg)| {
            println!("Name: {} Chain-Id: {}  Url: {}", name, cfg.get_chain_name(), cfg.get_dev_api_url().to_string());
          });

          println!("\nUse --add -h to see how to add a network. Or edit file manually at: {}", home.get_networks_path().parent().unwrap().join("Networks.toml").to_str().unwrap());
          Ok(())
        },
        Subcommand::New { blockchain, path } => new::handle(&home, blockchain, path),
        Subcommand::Node { genesis } => node::handle(&home, genesis),
        Subcommand::Build {
            project_path,
            network,
            address,
        } => build::handle(
            &shared::normalized_project_path(project_path)?,
            normalized_address(
                home.new_network_home(normalized_network_name(network).as_str()),
                address,
            )?,
        ),
        Subcommand::Deploy {
            project_path,
            network,
            mnem,
        } => {
            let name = normalized_network_name(network.clone()).to_owned();
            deploy::handle(
                &home.new_network_home(&name),
                &shared::normalized_project_path(project_path)?,
                shared::normalized_network_url(&home, network)?,
                home.read_networks_toml()?.get(&name)?.get_chain_name(),
                mnem,
            )
            .await
        }
        Subcommand::Account { root, network, mnem } => {
            account::handle(
                &home,
                root,
                home.get_network_struct_from_toml(normalized_network_name(network).as_str())?,
                mnem,
            )
            .await
        }
        Subcommand::Test { cmd } => test::handle(&home, cmd).await,
        Subcommand::Console {
            project_path,
            network,
            key_path,
            address,
        } => console::handle(
            &home,
            &shared::normalized_project_path(project_path)?,
            home.get_network_struct_from_toml(normalized_network_name(network.clone()).as_str())?,
            &normalized_key_path(
                home.new_network_home(normalized_network_name(network.clone()).as_str()),
                key_path,
            )?,
            normalized_address(
                home.new_network_home(normalized_network_name(network).as_str()),
                address,
            )?,
        ),
        Subcommand::Transactions {
            network,
            tail,
            address,
            raw,
        } => {
            transactions::handle(
                shared::normalized_network_url(&home, network.clone())?,
                unwrap_nested_boolean_option(tail),
                normalized_address(
                    home.new_network_home(normalized_network_name(network.clone()).as_str()),
                    address,
                )?,
                unwrap_nested_boolean_option(raw),
            )
            .await
        }
    }
}

#[derive(Debug, StructOpt)]
struct Command {
    #[structopt(long, global = true)]
    home_path: Option<PathBuf>,

    #[structopt(subcommand)]
    subcommand: Subcommand,
}

#[derive(Debug, StructOpt)]
#[structopt(name = "shuffle", about = "CLI frontend for Shuffle toolset")]
pub enum Subcommand {
    //////// 0L ////////
    #[structopt(about = "View, Add, or Remove networks which Shuffle connects to.")]
    Network {
        #[structopt(short, long)]
        add: bool,
        /// Url of API endpoint
        // for adding a network
        #[structopt(short, long)]
        url: Option<Url>,
        /// Name to give a network to be added
        #[structopt(short, long)]
        name: Option<String>,
        /// Optional chain id of the network, defaults to TESTING for local purposes. Use MAINNET for mainnet and testnet.
        #[structopt(short, long)]
        chain: Option<NamedChain>,
    },

    #[structopt(about = "Creates a new shuffle project for Move development")]
    New {
        #[structopt(short, long, default_value = new::DEFAULT_BLOCKCHAIN)]
        blockchain: String,

        /// Path to destination dir
        #[structopt(parse(from_os_str))]
        path: PathBuf,
    },
    #[structopt(about = "Runs a local devnet with prefunded accounts")]
    Node {
        #[structopt(short, long, help = "Move package directory to be used for genesis")]
        genesis: Option<String>,
    },
    #[structopt(about = "Compiles the Move package and generates typescript files")]
    Build {
        #[structopt(short, long)]
        project_path: Option<PathBuf>,

        #[structopt(short, long)]
        network: Option<String>,

        #[structopt(
            short,
            long,
            help = "Network specific address to be used for publishing with Named Address Sender"
        )]
        address: Option<String>,
    },
    #[structopt(about = "Publishes the main move package using the account as publisher")]
    Deploy {
        #[structopt(short, long)]
        project_path: Option<PathBuf>,

        #[structopt(short, long)]
        network: Option<String>,

        #[structopt(short, long)]
        mnem: bool,
    },
    Account {
        #[structopt(short, long, help = "Creates account from mint.key passed in by user")]
        root: Option<PathBuf>,

        #[structopt(short, long)]
        network: Option<String>,

        #[structopt(short, long)]
        mnem: bool,
    },
    #[structopt(about = "Starts a REPL for onchain inspection")]
    Console {
        #[structopt(short, long)]
        project_path: Option<PathBuf>,

        #[structopt(short, long)]
        network: Option<String>,

        #[structopt(short, long, requires("address"))]
        key_path: Option<PathBuf>,

        #[structopt(short, long, requires("key-path"))]
        address: Option<String>,
    },
    #[structopt(about = "Runs end to end .ts tests")]
    Test {
        #[structopt(subcommand)]
        cmd: TestCommand,
    },
    #[structopt(
        about = "Captures last 10 transactions and continuously polls for new transactions from the account"
    )]
    Transactions {
        #[structopt(short, long)]
        network: Option<String>,

        #[structopt(
            short,
            long,
            help = "Writes out transactions without pretty formatting"
        )]
        raw: Option<Option<bool>>,

        #[structopt(
            short,
            long,
            help = "Captures and polls transactions deployed from a given address"
        )]
        address: Option<String>,

        #[structopt(short, help = "Blocks and streams future transactions as they happen")]
        tail: Option<Option<bool>>,
    },
}

fn normalized_address(
    network_home: NetworkHome,
    account_address: Option<String>,
) -> Result<AccountAddress> {
    let normalized_string = match account_address {
        Some(input_address) => {
            if &input_address[0..2] != "0x" {
                "0x".to_owned() + &input_address
            } else {
                input_address
            }
        }
        None => network_home.address_for(LATEST_USERNAME)?.to_hex_literal(),
    };
    Ok(AccountAddress::from_hex_literal(
        normalized_string.as_str(),
    )?)
}

fn normalized_key_path(
    network_home: NetworkHome,
    diem_root_key_path: Option<PathBuf>,
) -> Result<PathBuf> {
    match diem_root_key_path {
        Some(key_path) => Ok(key_path),
        None => {
            if !network_home.get_accounts_path().is_dir() {
                return Err(anyhow!(
                    "An account hasn't been created yet! Run shuffle account first"
                ));
            }
            Ok(network_home.key_path_for(LATEST_USERNAME))
        }
    }
}

fn unwrap_nested_boolean_option(option: Option<Option<bool>>) -> bool {
    match option {
        Some(Some(val)) => val,
        Some(_val) => true,
        None => false,
    }
}

fn normalize_home_path(home_path: Option<PathBuf>) -> PathBuf {
    match home_path {
        Some(path) => path,
        None => get_home_path(),
    }
}
