use std::env;
use std::path::PathBuf;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let output_file = PathBuf::from(&crate_dir)
        .parent()
        .unwrap()
        .join("include")
        .join("pillmom.h");

    cbindgen::generate(&crate_dir)
        .expect("Unable to generate bindings")
        .write_to_file(output_file);
}