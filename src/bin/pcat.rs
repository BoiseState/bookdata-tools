#[macro_use]
extern crate structopt;
extern crate indicatif;

use structopt::StructOpt;

use std::io;
use std::fs::File;
use std::path::PathBuf;
use indicatif::{ProgressBar, ProgressStyle};

const PB_STYLE: &'static str = "{prefix}: {elapsed_precise} {bar} {percent}% {bytes}/{total_bytes} (eta: {eta})";

/// Concatenate one or more files with a progress bar
#[derive(StructOpt, Debug)]
#[structopt(name="pcat")]
struct Opt {
  /// Input file
  #[structopt(name = "FILE", parse(from_os_str))]
  infiles: Vec<PathBuf>
}

fn main() {
  let opt = Opt::from_args();
  let stdout = io::stdout();
  let mut out = stdout.lock();

  for inf in opt.infiles {
    let inf = inf.as_path();
    let fstr = inf.to_str().unwrap();
    let fs = File::open(inf).expect(&format!("{}: cannot open file", fstr));
    let pb = ProgressBar::new(fs.metadata().unwrap().len());
    pb.set_style(ProgressStyle::default_bar().template(PB_STYLE));
    pb.set_prefix(fstr);
    let mut pbr = pb.wrap_read(fs);
    io::copy(&mut pbr, &mut out).expect(&format!("{}: copy error", fstr));
  }
}