module main

import os

struct Args {
	working_directory   string
	help                bool
	dry_run             bool
	force_scripts       bool
	dont_save_patchlist bool
	verbose             bool
}

fn pathed(path string) string {
	return os.expand_tilde_to_home(os.real_path(path))
}

fn get_args() Args {
	mut args := os.args.clone()
	args.delete(0)

	working_dir := if args.contains('-d') {
		pathed(args[args.index('-d') + 1])
	} else if args.contains('--dir') {
		pathed(args[args.index('--dir') + 1])
	} else {
		'.'
	}

	return Args{
		working_directory:   working_dir
		help:                args.contains('--help') || args.contains('-h')
		dry_run:             args.contains('--dry-run')
		force_scripts:       args.contains('--force-scripts')
		dont_save_patchlist: args.contains('--dont-save-patchlist')
		verbose:             args.contains('--verbose') || args.contains('-v')
	}
}
