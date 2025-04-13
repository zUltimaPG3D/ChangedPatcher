module main

import os
import ruby

fn script_path(name string) string {
	return './ruby_scripts/${name}'
}

fn read_script(name string) string {
	return os.read_file(script_path(name)) or { 'puts "Error while loading ${name}: ${err}"' }
}

fn protected_marshal_load(data ruby.VALUE) ruby.VALUE {
	marshal := ruby.get_const(C.rb_cObject, 'Marshal')
	return C.rb_funcall(marshal, C.rb_intern('load'.str), 1, data)
}

fn uncompress(data []u8) ruby.VALUE {
	zlib := ruby.get_const(C.rb_cObject, "Zlib")
	inflater := ruby.get_const(zlib, "Inflate")
	uncompressed := C.rb_funcall(inflater, C.rb_intern("inflate".str), 1, ruby.bytestr(data));
	return uncompressed
}

fn compress(data []u8) ruby.VALUE {
	zlib := ruby.get_const(C.rb_cObject, "Zlib")
	deflater := ruby.get_const(zlib, "Deflate")
	compressed := C.rb_funcall(deflater, C.rb_intern("deflate".str), 1, ruby.bytestr(data));
	return compressed
}

fn define_rpg_types() {
	ruby.run(script_path('rpg/table.rb'))
	ruby.run(script_path('rpg/rpg_types.rb'))
}

fn get_game_title() string {
	success := ruby.run(script_path('get_game_title.rb'))

	if !success {
		println('-- FAILED WHILE GETTING GAME TITLE!')
		println('Most likely an issue with your Ruby version. See error above.')
		exit(0)
	}

	game_title := ruby.get_global('\$game_title')

	return game_title.as_vstr()
}

fn update_rgss_scripts(scripts RGSS_Scripts) {
	mut arr := ruby.new_arr()

	for script in scripts.scripts {
		name := ruby.new_str(script.name)
		mut len := ruby.VALUE(unsafe { nil })

		if script.write_mystery_number_as_string {
			len = ruby.new_str(script.mystery_number.str())
		} else {
			len = ruby.new_int(script.mystery_number)
		}

		code := compress(script.code.bytes())

		mut script_arr := ruby.new_arr()
		script_arr.push(len)
		script_arr.push(name)
		script_arr.push(code)

		arr.push(script_arr.obj)
	}

	ruby.set_global('\$RGSS_SCRIPTS', arr.obj)
}

fn parse_scripts() ?RGSS_Scripts {
	ruby.run(script_path('parse_scripts.rb'))

	mut rgss_scripts := RGSS_Scripts{}

	scripts := ruby.get_global('\$RGSS_SCRIPTS')
	is_array := ruby.check_type(scripts, .ruby_t_array)

	if !is_array {
		println('Scripts data isn\'t an array!')
		return none
	}
		
	arr := scripts.as_array()

	for elem in arr {
		is_elem_arr := elem.is_a(.ruby_t_array)

		if !is_elem_arr {
			continue
		}

		elem_arr := elem.as_array()

		mut temp_script := Script{}

		mystery_number := elem_arr.at(0)

		if mystery_number.is_a(.ruby_t_fixnum) {
			temp_script.mystery_number = mystery_number.as_int()
		} else if mystery_number.is_a(.ruby_t_string) {
			temp_script.mystery_number = mystery_number.as_vstr().i32()
			temp_script.write_mystery_number_as_string = true
		} else {
			temp_script.mystery_number = 0
		}

		temp_script.name = elem_arr.at(1).as_vstr()

		mut code_bytes := []u8{}
		bytes := elem_arr.at(2).as_array()

		for byt in bytes {
			code_bytes << byt.as_u8()
		}

		temp_script.code = uncompress(code_bytes).as_vstr()

		rgss_scripts.scripts << temp_script
	}

	return rgss_scripts
}

fn marshaled_scripts(scripts RGSS_Scripts) {
	update_rgss_scripts(scripts)
	ruby.run(script_path('marshal_to_temp.rb'))
}