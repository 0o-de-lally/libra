// Copyright (c) The Diem Core Contributors
// SPDX-License-Identifier: Apache-2.0

use diem_types::vm_status::{StatusCode, VMStatus};
use move_binary_format::{compatibility::Compatibility, normalized::Module, CompiledModule};
use move_bytecode_verifier::verify_module;
use move_command_line_common::files::{
    extension_equals, find_filenames, MOVE_COMPILED_EXTENSION, MOVE_ERROR_DESC_EXTENSION,
};
use move_compiler::compiled_unit::{CompiledUnit, NamedCompiledModule};
use move_core_types::language_storage::ModuleId;
use move_package::{BuildConfig, ModelConfig};
use std::{
    collections::BTreeMap,
    fs::{create_dir_all, remove_dir_all, File},
    io::{Read, Write},
    path::{Path, PathBuf},
};
use structopt::*;

//////// 0L ////////
// for Upgrade oracle
/// The output path under which staged files will be put
pub const STAGED_OUTPUT_PATH: &str = "staged";
/// The file name for the staged stdlib
pub const STAGED_STDLIB_NAME: &str = "stdlib";
/// The extension for staged files
pub const STAGED_EXTENSION: &str = "mv";

/// Options to configure the generation of a release.
#[derive(Debug, StructOpt, Clone)]
#[structopt(
    name = "Diem Frameworks",
    about = "Release CLI for Diem frameworks",
    author = "The Diem Core Contributors",
    rename_all = "kebab-case"
)]
pub struct ReleaseOptions {
    #[structopt(long = "no-check-linking-layout-compatibility")]
    pub check_layout_compatibility: bool,
    #[structopt(long = "no-build-docs")]
    pub build_docs: bool,
    #[structopt(long = "with-diagram")]
    pub with_diagram: bool,
    #[structopt(long = "no-script-builder")]
    pub script_builder: bool,
    #[structopt(long = "no-script-abi")]
    pub script_abis: bool,
    #[structopt(long = "no-errmap")]
    pub errmap: bool,
    #[structopt(long = "package", default_value = "DPN", parse(from_os_str))]
    pub package: PathBuf,
    #[structopt(long = "output", default_value = "current", parse(from_os_str))]
    pub output: PathBuf,
    //////// 0L ////////
    /// .help("generate test/stdlib.mv for upgrade oracle")
    #[structopt(long = "create-upgrade-payload")]
    pub create_upgrade_payload: bool,
}

impl Default for ReleaseOptions {
    fn default() -> Self {
        Self {
            build_docs: true,
            package: PathBuf::from("DPN"),
            check_layout_compatibility: false,
            with_diagram: false,
            script_abis: true,
            script_builder: true,
            errmap: true,
            output: PathBuf::from("current"),
            create_upgrade_payload: true, //////// 0L ////////
        }
    }
}

impl ReleaseOptions {
    // TODO(0L): We need the files to end up in same package as the sources. Otherwise the rust bindings don't get created correctly.
    // when we try to change ouput paths we get a 
    // thread 'main' panicked at 'Failed to deserialize module bytecode: PartialVMError { major_status: BAD_MAGIC, sub_status: None, message: None, indices: [], offsets: [] }', diem-move/diem-framework/src/release.rs:260:53

    pub fn create_release(&self) {
        let output_path = self
            .package
            .join("releases")
            .join("artifacts")
            .join(&self.output);

        let mut old_module_apis = None;
        if !self.check_layout_compatibility {
            old_module_apis = extract_old_apis(&output_path);
        }

        if output_path.exists() {
            std::fs::remove_dir_all(&output_path).unwrap();
        }
        std::fs::create_dir_all(output_path.parent().unwrap()).unwrap();

        let build_config = move_package::BuildConfig {
            generate_docs: !self.build_docs,
            generate_abis: !self.script_abis,
            install_dir: Some(output_path.clone()),
            ..Default::default()
        };

        let package_path = Path::new(std::env!("CARGO_MANIFEST_DIR")).join(&self.package);

        // dbg!(&package_path);

        let compiled_package = build_config
            .clone()
            .compile_package(&package_path, &mut std::io::stdout())
            .unwrap();

        if !self.check_layout_compatibility {
            println!("Checking layout compatibility");
            if let Some(old_module_apis) = old_module_apis {
                let new_modules = compiled_package
                    .transitive_compiled_units()
                    .into_iter()
                    .filter_map(|unit| match unit {
                        CompiledUnit::Module(NamedCompiledModule { module, .. }) => Some(module),
                        CompiledUnit::Script(_) => None,
                    });
                check_api_compatibility(&old_module_apis, new_modules);
            }
        }

        if !self.errmap {
            println!("Generating error map");
            generate_error_map(&package_path, &output_path, build_config)
        }

        let legacy_abis = package_path.join("releases/legacy/script_abis");

        if !self.script_builder {
            println!("Generating script builders");
            generate_script_builder(
                &output_path.join("transaction_script_builder.rs"),
                &[&output_path, &legacy_abis],
            )
        }

        //////// 0L ////////
        if self.create_upgrade_payload {
            println!("Generating upgrade payload");
            
            self.create_upgrade_payload_fn(&self.package);
        }
    }

    //////// 0L ////////
    pub fn create_upgrade_payload_fn(&self, path: &PathBuf ) {

        let mut module_path = PathBuf::from(STAGED_OUTPUT_PATH);
        module_path.push(STAGED_STDLIB_NAME);
        module_path.set_extension(STAGED_EXTENSION);
        
        let path = path.join(module_path);
        // let mut module_path = PathBuf::from(STAGED_OUTPUT_PATH);
        // TODO: set the .0L path the right way.
        
        // println!("0L: module_path: {:?}", module_path.to_str().unwrap());
        // println!("0L: cwd: {:?}", std::env::current_dir().unwrap().to_str());
        let modules = crate::module_blobs();
        let bytes = bcs::to_bytes(&modules).unwrap();

        println!("0L: saving compiled stdlib to: {:?}", &path.to_str().unwrap());
        recreate_dir(&path.parent().unwrap());
        let mut module_file = File::create(path).unwrap();
        module_file.write(&bytes).unwrap();
    }
}

fn recreate_dir(dir_path: impl AsRef<Path>) {
    let dir_path = dir_path.as_ref();
    remove_dir_all(&dir_path).unwrap_or(());
    create_dir_all(&dir_path).unwrap();
}

fn generate_error_map(package_path: &Path, output_path: &Path, build_config: BuildConfig) {
    let mut errmap_path = output_path
        .join("error_description")
        .join("error_description");
    errmap_path.set_extension(MOVE_ERROR_DESC_EXTENSION);

    recreate_dir(&errmap_path.parent().unwrap());

    let errmap_options = move_errmapgen::ErrmapOptions {
        output_file: errmap_path.to_string_lossy().to_string(),
        ..Default::default()
    };

    let model = build_config
        .move_model_for_package(
            package_path,
            ModelConfig {
                target_filter: None,
                all_files_as_targets: true,
            },
        )
        .unwrap();

    let mut emapgen = move_errmapgen::ErrmapGen::new(&model, &errmap_options);
    emapgen.gen();
    emapgen.save_result();
}

fn generate_script_builder(output_path: impl AsRef<Path>, abi_paths: &[&Path]) {
    let output_path = output_path.as_ref();

    let abis: Vec<_> = abi_paths
        .iter()
        .flat_map(|path| {
            transaction_builder_generator::read_abis(&[path])
                .unwrap_or_else(|_| panic!("Failed to read ABIs at {}", path.to_string_lossy()))
        })
        .collect();

    {
        let mut file = std::fs::File::create(output_path)
            .expect("Failed to open file for Rust script build generation");
        transaction_builder_generator::rust::output(&mut file, &abis, /* local types */ true)
            .expect("Failed to generate Rust builders for Diem");
    }

    std::process::Command::new("rustfmt")
        .arg("--config")
        .arg("imports_granularity=crate")
        .arg(output_path)
        .status()
        .expect("Failed to run rustfmt on generated code");
}

fn extract_old_apis(package_path: impl AsRef<Path>) -> Option<BTreeMap<ModuleId, Module>> {
    let modules_path = package_path.as_ref();

    if !modules_path.is_dir() {
        eprintln!(
            "Warning: failed to extract old module APIs -- path \"{}\" is not a directory",
            modules_path.to_string_lossy()
        );
        return None;
    }
    let mut old_module_apis = BTreeMap::new();
    let files = find_filenames(&[modules_path], |p| {
        extension_equals(p, MOVE_COMPILED_EXTENSION)
    })
    .unwrap();
    for f in files {
        let mut bytes = Vec::new();
        File::open(&f)
            .expect("Failed to open module bytecode file")
            .read_to_end(&mut bytes)
            .expect("Failed to read module bytecode file");
        let m = CompiledModule::deserialize(&bytes)
        .expect(&format!("Failed to deserialize module bytecode: {:?}", &f));
        old_module_apis.insert(m.self_id(), Module::new(&m));
    }
    Some(old_module_apis)
}

fn check_api_compatibility<I>(old: &BTreeMap<ModuleId, Module>, new: I)
where
    I: IntoIterator<Item = CompiledModule>,
{
    let mut is_linking_layout_compatible = true;
    for module in new.into_iter() {
        // extract new linking/layout API and check compatibility with old
        let new_module_id = module.self_id();
        if let Some(old_api) = old.get(&new_module_id) {
            let new_api = Module::new(&module);
            let compatibility = Compatibility::check(old_api, &new_api);
            if is_linking_layout_compatible && !compatibility.is_fully_compatible() {
                println!("Found linking/layout-incompatible change:");
                is_linking_layout_compatible = false
            }
            if !compatibility.struct_and_function_linking {
                eprintln!("Linking API for structs/functions of module {} has changed. Need to redeploy all dependent modules.", new_module_id.name())
            }
            if !compatibility.struct_layout {
                eprintln!("Layout API for structs of module {} has changed. Need to do a data migration of published structs", new_module_id.name())
            }
        }
    }
}

//////// 0L ////////
// Update stdlib with a byte string, used as part of the upgrade oracle
pub fn import_stdlib(lib_bytes: &Vec<u8>) -> Result<Vec<CompiledModule>, Box<dyn std::error::Error>> {
    // set as empty array if err occurred
    let modules : Vec<CompiledModule> = bcs::from_bytes::<Vec<Vec<u8>>>(lib_bytes)?
        .into_iter()
        .filter_map(|bytes| CompiledModule::deserialize(&bytes).ok())
        .collect();

    // verify the compiled module
    let mut verified_modules = vec![];
    for module in modules {
        verify_module(&module)
        .map_err(|_| VMStatus::Error(StatusCode::CODE_DESERIALIZATION_ERROR))?;

        // TODO: Do we still need to run dependency checker?
        // DependencyChecker::verify_module(&module, &verified_modules)
        //     .expect("stdlib module dependency failed to verify");
        verified_modules.push(module)
    }
    Ok(verified_modules)
}

