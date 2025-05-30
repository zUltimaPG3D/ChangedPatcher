module main

struct Script {
pub mut:
	mystery_number                 int
	name                           string
	code                           string
	write_mystery_number_as_string bool
}

struct RGSS_Scripts {
pub mut:
	scripts []Script
}

pub fn (mut scripts RGSS_Scripts) find(name string) ?Script {
	for script in scripts.scripts {
		if script.name == name {
			return script
		}
	}
	return none
}

pub fn (mut scripts RGSS_Scripts) has(name string) bool {
	scripts.find(name) or { return false }
	return true
}

pub fn (mut scripts RGSS_Scripts) replace_script(name string, code string) bool {
	if !scripts.has(name) {
		return false
	}

	for mut script in scripts.scripts {
		if script.name == name {
			script.code = code
			return true
		}
	}

	return false
}

pub fn (mut scripts RGSS_Scripts) add_script(name string, code string) {
	scripts.scripts << Script{
		mystery_number: code.len
		name:           name
		code:           code
	}
}

pub fn (mut scripts RGSS_Scripts) add_or_replace(name string, code string) {
	if !scripts.has(name) {
		scripts.add_script(name, code)
	} else {
		scripts.replace_script(name, code)
	}
}
