#!/usr/bin/env -S v run

import term

mut ridk := false

$if windows {
	print('ridk... ')
	check_ridk := execute('ridk')
	if check_ridk.exit_code != 0 {
		println(term.red('no'))
	} else {
		println(term.green('yes'))
		ridk = true
	}
}

if ridk {
	print('enabling rubyinstaller development kit... ')
	ridk_enable := execute('ridk enable')
	if ridk_enable.exit_code != 0 {
		println(term.red('no'))
		return
	} else {
		println(term.green('yes'))
	}
}

print('ruby installed... ')
check_ruby := execute('ruby -v')
if check_ruby.exit_code != 0 {
	println(term.red('no'))
	return
}

version := execute("ruby -e 'puts RUBY_VERSION'").output.trim_space()

println('${term.green('yes')} (${version})')

headers_one := execute('ruby -rrbconfig -e \'puts RbConfig::CONFIG["rubyhdrdir"]\'').output.trim_space()
headers_two := execute('ruby -rrbconfig -e \'puts RbConfig::CONFIG["rubyarchhdrdir"]\'').output.trim_space()

mut libraries := ''
$if windows {
	l1 := execute('ruby -rrbconfig -e \'puts RbConfig::CONFIG["libdir"]\'').output.trim_space()
	l2 := '-Wl,-rpath,${l1}'
	l3 := execute('ruby -rrbconfig -e \'puts RbConfig::CONFIG["LIBRUBYARG"]\'').output.trim_space()
	libraries = '${l2} -L${l1} ${l3}'
} $else {
	libraries = execute('ruby -rrbconfig -e \'puts RbConfig::CONFIG["LIBRUBYARG"]\'').output.trim_space()
}

write_file('src/vruby/_autogen_includes.v', '// AUTOMATICALLY GENERATED - DO NOT PUSH TO REPOSITORY OR EDIT UNLESS YOU KNOW WHAT YOU\'RE DOING\n\nmodule vruby\n\n#flag -I${headers_one}\n#flag -I${headers_two}\n#flag ${libraries}\n\n#include <ruby.h>')!
