// Copyright (c) The Libra Core Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::account_config::constants::CORE_CODE_ADDRESS;
use move_core_types::{identifier::Identifier, language_storage::ModuleId};
use once_cell::sync::Lazy;

pub const ACCOUNT_MODULE_NAME: &str = "LibraAccount";

// Account
pub static ACCOUNT_MODULE_IDENTIFIER: Lazy<Identifier> =
    Lazy::new(|| Identifier::new("LibraAccount").unwrap());

/// The ModuleId for the Account module.
pub static ACCOUNT_MODULE: Lazy<ModuleId> =
    Lazy::new(|| ModuleId::new(CORE_CODE_ADDRESS, ACCOUNT_MODULE_IDENTIFIER.clone()));
