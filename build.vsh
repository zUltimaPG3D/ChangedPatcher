#!/usr/bin/env -S v run

import term

fn vcmd(args string) int {
	return system('${quoted_path(@VEXE)} ${args}')
}

println('configuring...')
vcmd('run configure.vsh')

$if windows {
	println(term.bright_bg_yellow(term.black(' WARNING: Native Windows builds are most likely not functional and will be effectively useless! If you want to use this tool on Windows, use WSL! ')))
}

vcmd('. -cc gcc -gc none -o ChangedPatcher')
