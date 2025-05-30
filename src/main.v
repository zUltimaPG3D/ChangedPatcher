module main

import os
import vruby
import compress.szip
import term
import toml
import net.http
import vrgss

struct Patch {
	path string
pub mut:
	valid             bool
	already_installed bool

	cfg        toml.Doc
	name       string
	id         string
	patch_type string

	original_allowed   bool
	special_allowed    bool
	unofficial_allowed bool

	use_mkxp bool
}

struct State {
pub mut:
	patched map[string][]u8
	scripts RGSS_Scripts
}

fn main() {
	args := get_args()
	if args.help {
		println('usage: ChangedPatcher [-h|--help] [--keep-temp] [--dry-run] [--force-scripts] [--dont-save-patchlist] [-d|--dir PATH]')
		println('')
		println('  -h --help             | Prints this message and exits')
		println("  --dry-run             | Doesn't actually write to the game archive")
		println("  --force-scripts       | Forces script processing as if an installed patch/library edits scripts even if it doesn't")
		println("  --dont-save-patchlist | Doesn't save the patchlist to the game archive, so you can install multiple patches at once")
		println('  -d --dir              | Sets the working directory to the given PATH, defaults to the current execution directory')
		println('  -v --verbose          | Logs more processing steps and internal information')
		println('')
		println('example: ChangedPatcher -d "~/.steam/steam/steamapps/common/Changed/"')
		exit(0)
	}

	wd_exists := os.exists(args.working_directory) && os.is_dir(args.working_directory)

	if !wd_exists {
		println(args.working_directory)
		eprintln(term.bg_red(" The working directory argument you passed doesn't exist! "))
		exit(1)
	}

	println('Initializing Ruby...')
	vruby.initialize()
	vruby.require('zlib')
	define_rpg_types()

	mut state := &State{}
	mut patches := []Patch{}

	if !args.verbose {
		term.clear_previous_line()
	}

	// Initialize RGSSAD archive

	archive_path := os.join_path(args.working_directory, 'Game.rgss2a')

	if args.verbose {
		println('Searching for Game.rgss2a at path: ${archive_path}')
	}

	archive_exists := os.exists(archive_path)

	if !archive_exists {
		eprintln('No ${term.bg_red(' Game.rgss2a ')} file found in the current working directory!')
		exit(0)
	}

	println(term.bg_green(' Game.rgss2a found! '))

	mut archive := vrgss.RGSS2A{}

	if args.verbose {
		println('Initializing RGSS2A archive...')
	}

	archive.initialize(archive_path)

	if !archive.valid() {
		eprintln('The archive file ${term.bg_red(' Game.rgss2a ')} is invalid!')
		exit(1)
	}

	if args.verbose {
		println('Parsing RGSS2A archive...')
	}

	archive.parse()

	// Get game title from System.rvdata

	println('Determining game title...')

	system_entry := archive.get_entry('Data/System.rvdata') or {
		eprintln('The archive file has no ${term.bg_red(' Data/System.rvdata ')} file!')
		exit(1)
	}

	if args.verbose {
		println('Reading System.rvdata')
	}

	entry := archive.read_entry(system_entry)
	game_title := get_game_title(entry, args.verbose)

	if !args.verbose {
		term.clear_previous_line()
	}

	println('Game name: ${term.highlight_command(game_title)}')

	// Check for Data/patchlist.txt

	println('Checking if the game has been previously patched...')

	mut has_patchlist := true
	mut installed_patches := []string{}
	mut patchlist_content := ''

	if args.verbose {
		println('Checking for Data/patchlist.txt')
	}

	patchlist_entry := archive.get_entry('Data/patchlist.txt') or {
		has_patchlist = false
		vrgss.Entry{}
	}

	if !args.verbose {
		term.clear_previous_line()
	}

	if has_patchlist {
		patchlist_content = archive.read_entry(patchlist_entry).bytestr()
		installed_patches = patchlist_content.split('\n')

		println('Status: ${term.bg_green(' Patched ')}')
	} else {
		println('Status: ${term.bg_green(' Unpatched ')}')
	}

	// Load all local patches

	println('Looking for patches...')

	paths := os.ls('./patches') or { [] }
	if paths.len == 0 {
		eprintln('No patches found inside the ${term.bg_red(' patches ')} folder!')
		exit(0)
	}

	for path in paths {
		p := os.join_path('./patches', path)

		if !os.is_file(p) {
			if args.verbose {
				println('Adding patch at ${p} to potential patch list')
			}

			patches << Patch{
				path: p
			}
			continue
		} else {
			if os.file_ext(path) == '.zip' {
				if args.verbose {
					println('Found .zip file: extracting ${p}')
				}

				xp := p.all_before_last(os.file_ext(path))

				os.mkdir(xp) or {
					spaced1 := term.highlight_command(path)
					spaced2 := term.highlight_command(xp)

					eprintln('Failed to extract ${spaced1} to ${spaced2}: ${term.bg_red(err.str())}')
					continue
				}

				szip.extract_zip_to_dir(p, xp) or {
					spaced1 := term.highlight_command(path)
					spaced2 := term.highlight_command(xp)

					eprintln('Failed to extract ${spaced1} to ${spaced2}: ${term.bg_red(err.str())}')
					continue
				}

				os.rename(p, os.join_path('./patches', '${path}.done')) or { continue }

				patches << Patch{
					path: xp
				}
				continue
			}
		}
	}

	if !args.verbose {
		term.clear_previous_line()
	}
	println('')

	has_patch_installed := installed_patches.filter(it.starts_with('patch:')).len != 0

	for i, mut patch in patches {
		config_path := os.join_path(patch.path, 'config.toml')
		config_exists := os.exists(config_path)

		if args.verbose {
			println('Checking for config at ${config_path}')
		}

		if !config_exists {
			if args.verbose {
				println("The config.toml file doesn't exist, skipping.")
			}
			continue
		}

		patch.cfg = toml.parse_file(config_path) or {
			spaced := term.bg_red(' ${patch.path} ')
			eprintln('Skipping ${spaced} because of error while reading config: ${term.bg_red(err.str())}')
			patches.delete(i)
			continue
		}

		patch.name = patch.cfg.value('patch.name').string()
		patch.id = patch.cfg.value('patch.id').string()
		patch.patch_type = patch.cfg.value('patch.type').string().to_lower()

		if patch.patch_type != 'patch' && patch.patch_type != 'library' {
			patches.delete(i)
			continue
		}

		patch.original_allowed = patch.cfg.value('target.original').default_to(true).bool()
		patch.special_allowed = patch.cfg.value('target.special').default_to(true).bool()
		patch.unofficial_allowed = patch.cfg.value('target.unofficial').default_to(true).bool()

		patch.use_mkxp = patch.cfg.value('runtime.use_mkxp').default_to(false).bool()

		patch.valid = (patch.original_allowed && game_title == 'Changed')
			|| (patch.special_allowed && game_title == 'Changed-special')
			|| (patch.unofficial_allowed && game_title != 'Changed'
			&& game_title != 'Changed-special')
		patch.already_installed = installed_patches.contains('${patch.patch_type}:${patch.id}')

		if patch.already_installed {
			spaced_name := term.bg_red(' ${patch.name} (already installed) ')
			println('(${i + 1}) Found ${patch.patch_type}: ${spaced_name}')
		} else {
			if has_patch_installed && patch.patch_type == 'patch' {
				spaced_name := term.bg_red(' ${patch.name} (locked) ')
				println('(${i + 1}) Found ${patch.patch_type}: ${spaced_name}')
			} else {
				if patch.valid {
					spaced_name := term.highlight_command('${patch.name}')
					println('(${i + 1}) Found ${patch.patch_type}: ${spaced_name}')
				} else {
					spaced_name := term.bg_red(' ${patch.name} (incompatible with "${game_title}") ')
					println('(${i + 1}) Found ${patch.patch_type}: ${spaced_name}')
				}
			}
		}
	}

	println('')

	chosen_idx := os.input('Pick a patch (1...${patches.len}): ').i32()

	if chosen_idx < 1 || chosen_idx > patches.len {
		println('Exiting')
		exit(0)
	}

	// Validate the patch first

	if !args.verbose {
		term.clear_previous_line()
	}

	chosen_patch := patches[chosen_idx - 1]
	if !chosen_patch.valid {
		spaced_name := term.bg_red(' "${chosen_patch.name}" ')
		spaced_title := term.highlight_command('"${game_title}"')

		eprintln('The patch ${spaced_name} doesn\'t support ${spaced_title}!')
		exit(0)
	}

	if chosen_patch.already_installed {
		spaced_name := term.bg_red(' "${chosen_patch.name}" ')

		eprintln('The patch ${spaced_name} is already installed!')
		exit(0)
	}

	if has_patch_installed && chosen_patch.patch_type == 'patch' {
		eprintln("You can't patch the game twice!")
		exit(0)
	}

	// Install the chosen patch

	patch_name := term.highlight_command('"${chosen_patch.name}"')
	println('Installing the ${patch_name} patch...')

	bkp_path := os.join_path(args.working_directory, 'Game.rgss2a.bkp')
	bkp_exists := os.exists(bkp_path)

	if !bkp_exists {
		if args.verbose {
			println("Backing up the game archive because a backup doesn't already exist...")
		}

		os.cp(archive_path, bkp_path) or {
			eprintln('Failed to back up the game archive: ${term.bg_red(err.str())}')
		}
	}

	scripts_path := os.join_path(chosen_patch.path, 'Scripts')
	patch_has_custom_scripts := os.exists(scripts_path)

	if args.verbose {
		println('Checking for custom scripts...')
	}

	if patch_has_custom_scripts || args.force_scripts {
		if args.verbose {
			println('Patch has scripts! Inserting/replacing...')
		}

		scripts_entry := archive.get_entry('Data/Scripts.rvdata') or {
			eprintln('The archive file has no ${term.bg_red(' Data/Scripts.rvdata ')} file!')
			exit(1)
		}

		scripts_data := archive.read_entry(scripts_entry)
		state.scripts = parse_scripts(scripts_data) or {
			eprintln('Failed to parse Scripts.rvdata! ${term.bg_red(err.str())}')
			exit(1)
		}

		os.walk(scripts_path, fn [mut state, chosen_patch] (p string) {
			file_name := os.file_name(p).all_before_last(os.file_ext(p))
			file_contents := os.read_file(p) or { return }

			if chosen_patch.patch_type == 'patch' {
				state.scripts.add_or_replace(file_name, file_contents)
			} else if chosen_patch.patch_type == 'library' {
				if !state.scripts.has(file_name) {
					state.scripts.add_or_replace(file_name, file_contents)
				} else {
					script_name := term.highlight_command(file_name)
					println('Skipping script ${script_name} in library because it\'s a builtin script.')
				}
			}
		})
	}

	if args.verbose {
		println('Preparing archive...')
	}

	archive.prepare()

	if args.verbose {
		println('Done preparing archive.')
	}

	mut new_archive := vrgss.RGSS2A{}

	assets_path := os.join_path(chosen_patch.path, 'PatchedAssets')

	if args.verbose {
		println('Checking for patched assets...')
	}

	os.walk(assets_path, fn [args, mut state, assets_path, chosen_patch, mut archive] (p string) {
		less_path := p.all_after_first(assets_path + os.path_separator)
		file_bytes := os.read_bytes(p) or {
			eprintln('Failed to read file ${p}: ${term.bg_red(err.str())}')
			exit(1)
		}

		if chosen_patch.patch_type == 'patch' {
			if args.verbose {
				println('Directly patching ${vrgss.fix_name(less_path)}')
			}

			state.patched[vrgss.fix_name(less_path)] = file_bytes
		} else if chosen_patch.patch_type == 'library' {
			if archive.has_entry(vrgss.fix_name(less_path)) {
				println('Skipping file ${less_path} in library because it\'s a builtin asset.')
			} else {
				if args.verbose {
					println('Directly patching ${vrgss.fix_name(less_path)}')
				}

				state.patched[vrgss.fix_name(less_path)] = file_bytes
			}
		}
	})

	new_str := (patchlist_content + '\n${chosen_patch.patch_type}:${chosen_patch.id}').trim_space().bytes()

	if !args.dont_save_patchlist {
		if args.verbose {
			println('Setting Data/patchlist.txt to: ${new_str}')
		}

		state.patched['Data/patchlist.txt'] = new_str
	}

	if patch_has_custom_scripts || args.force_scripts {
		if args.verbose {
			println('Marshaling scripts...')
		}

		state.patched[vrgss.fix_name('Data/Scripts.rvdata')] = marshaled_scripts(state.scripts)
	}

	// First pass
	for ent in archive.entries {
		if ent.name in state.patched {
			new_archive.entries << vrgss.Entry{
				name: vrgss.fix_name(ent.name)
				data: state.patched[ent.name]
			}
		} else {
			new_archive.entries << vrgss.Entry{
				name: vrgss.fix_name(ent.name)
				data: ent.data
			}
		}
	}

	// Second pass
	for new_file, data in state.patched {
		if !new_archive.has_entry(new_file) {
			new_archive.entries << vrgss.Entry{
				name: vrgss.fix_name(new_file)
				data: data
			}
		}
	}

	if !args.dry_run {
		new_archive.write(archive_path)
	}

	println('Done patching!')

	if chosen_patch.use_mkxp {
		has_mkxp_already := os.exists('./mkxp.json')
		has_mkxp_zip := os.exists('./mkxp.zip')

		if !has_mkxp_already {
			if !args.verbose {
				term.clear_previous_line()
			}
			println(term.bg_cyan(term.bright_white(' INFO: This patch recommends (or requires) the MKXP-Z runtime. Do you want to download it? ')))
			println(term.bg_cyan(term.bright_white(' INFO: (this will install both the Linux version and the Windows version) ')))
			println('')

			install := os.input('[y/n] (default y): ').trim_space().to_lower() != 'n'

			if install {
				if !has_mkxp_zip {
					resp := http.fetch(
						url:    'https://github.com/zUltimaPG3D/ChangedPatcher/releases/download/lib-mkxp/mkxp.zip'
						method: .get
					) or {
						eprintln('Failed to download mkxp.zip: ${term.bg_red(err.str())}')
						exit(1)
					}
					os.write_file_array('./mkxp.zip', resp.body.bytes()) or {
						eprintln('Failed to save mkxp.zip: ${term.bg_red(err.str())}')
						exit(1)
					}
				}

				if !args.dry_run {
					szip.extract_zip_to_dir('./mkxp.zip', args.working_directory) or {
						spaced1 := term.highlight_command('./mkxp.zip')
						spaced2 := term.highlight_command('args.working_directory')

						eprintln('Failed to extract ${spaced1} to ${spaced2}: ${term.bg_red(err.str())}')
					}
				}
			}

			println('Done patching!')
		}
	}

	vruby.cleanup()
}
