@[has_globals]
module main

import vruby
import arrays

fn uncompress(data vruby.VALUE) vruby.VALUE {
	zlib := vruby.get_const(vruby.get_object_type(), 'Zlib')
	inflater := vruby.get_const(zlib, 'Inflate')
	uncompressed := inflater.call('inflate', data)

	return uncompressed
}

fn compress(data vruby.VALUE) vruby.VALUE {
	zlib := vruby.get_const(vruby.get_object_type(), 'Zlib')
	deflater := vruby.get_const(zlib, 'Deflate')
	compressed := deflater.call('deflate', data)

	return compressed
}

__global table_class vruby.RClass

fn table_s_load(argc int, argv vruby.ARGS, self vruby.VALUE) vruby.VALUE {
	// No need to actually parse the data
	obj := table_class.call_static('new')
	return obj
}

fn define_rpg_types() {
	// Table
	table_class = vruby.RClass.new('Table')

	table_class.define_field('xsize', .reader)
	table_class.define_field('ysize', .reader)
	table_class.define_field('zsize', .reader)

	table_class.define_singleton_method('_load', table_s_load)
	// RPG:: module
	rpg_module := vruby.RModule.new('RPG')

	system := vruby.RClass.under('System', rpg_module)
	vruby.RClass.under('Vehicle', system)
	vruby.RClass.under('TestBattler', system)
	vruby.RClass.under('Terms', system)

	vruby.RClass.under('BGM', rpg_module)
	vruby.RClass.under('ME', rpg_module)
	vruby.RClass.under('SE', rpg_module)
}

fn get_game_title(sys_bytes []u8, verbose bool) string {
	if verbose {
		println('Parsing System.rvdata')
	}

	sys_str := vruby.bytestr(sys_bytes)

	if verbose {
		println('Passing bytes to Marshal.load')
	}

	loaded := vruby.marshal_load(vruby.RValue(sys_str)) or { panic(err) }

	if verbose {
		println('Getting @game_title variable off System')
	}

	loaded_title := loaded.get_variable('@game_title') or { panic(err) }
	return loaded_title.as_vstr()
}

fn (scripts RGSS_Scripts) data() vruby.VALUE {
	mut arr := vruby.new_arr()

	for script in scripts.scripts {
		name := vruby.new_str(script.name)
		mut len := vruby.VALUE(0)

		if script.write_mystery_number_as_string {
			len = vruby.new_str(script.mystery_number.str())
		} else {
			len = vruby.new_int(script.mystery_number)
		}

		code := compress(vruby.new_str(script.code))

		mut script_arr := vruby.new_arr()
		script_arr.push(len)
		script_arr.push(name)
		script_arr.push(code)

		arr.push(script_arr.obj)
	}

	return arr.obj
}

fn parse_scripts(scripts_bytes []u8) ?RGSS_Scripts {
	scripts_str := vruby.bytestr(scripts_bytes)
	scripts := vruby.marshal_load(vruby.RValue(scripts_str)) or { panic(err) }

	mut rgss_scripts := RGSS_Scripts{}

	is_array := vruby.check_type(scripts, .ruby_t_array)

	if !is_array {
		println("Scripts data isn't an array!")
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

		mystery_number := elem_arr.get(0)

		if mystery_number.is_a(.ruby_t_fixnum) {
			temp_script.mystery_number = mystery_number.as_int()
		} else if mystery_number.is_a(.ruby_t_string) {
			temp_script.mystery_number = mystery_number.as_vstr().i32()
			temp_script.write_mystery_number_as_string = true
		} else {
			temp_script.mystery_number = 0
		}

		temp_script.name = elem_arr.get(1).as_vstr()
		temp_script.code = uncompress(elem_arr.get(2)).as_vstr()

		rgss_scripts.scripts << temp_script
	}

	return rgss_scripts
}

fn marshaled_scripts(scripts RGSS_Scripts) []u8 {
	data := scripts.data()
	dumped := vruby.marshal_dump(data)

	dumped_len := dumped.str_len()
	dumped_str := dumped.as_cstr()

	return unsafe { arrays.carray_to_varray[u8](dumped_str, dumped_len) }
}
