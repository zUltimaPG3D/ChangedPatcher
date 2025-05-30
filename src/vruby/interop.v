module vruby

pub fn initialize() {
	C.ruby_init()
	C.ruby_init_loadpath()
}

pub fn cleanup() int {
	return C.ruby_cleanup(0)
}

pub fn require(feature string) bool {
	return C.rb_require(feature.str).as_bool()
}

pub fn get_global(name string) VALUE {
	return C.rb_gv_get(name.str)
}

pub fn set_global(name string, obj VALUE) VALUE {
	return C.rb_gv_set(name.str, obj)
}

fn run_protect(name string) int {
	mut state := 0
	script := C.rb_str_new_cstr(name.str)
	C.rb_load_protect(script, 0, &state)

	return state
}

fn handle_exception() string {
	err := C.rb_errinfo()

	klass := C.rb_class_name(C.CLASS_OF(err))
	message := C.rb_funcall(err, C.rb_intern('message'.str), 0)
	class_name := klass.as_vstr()
	message_str := message.as_vstr()

	println('Caught "${class_name}": ${message_str}')
	C.rb_set_errinfo(C.Qnil)

	return 'Ruby exception caught "${class_name}": ${message_str}'
}

pub fn protected(callback ProtectedFn, args ...RValue) !VALUE {
	state := 0
	args_val := new_arr_from_args(...args)
	result := C.rb_protect(callback, args_val.obj, &state)

	if state != 0 {
		return error(handle_exception())
	}

	return result
}

pub fn run(name string) !bool {
	state := run_protect(name)

	if state != 0 {
		return error(handle_exception())
	}

	return state == 0
}

pub fn eval(code string) !int {
	mut state := 0
	ret := C.rb_eval_string_protect(code.str, state)

	if state != 0 {
		return error(handle_exception())
	}

	return ret
}

pub fn check_type(obj VALUE, type RubyValueType) bool {
	return type_of(obj) == type.int()
}

pub fn bytestr(bytes []u8) VALUE {
	return C.rb_str_new(bytes.bytestr().str, bytes.len)
}

pub fn get_const(type VALUE, name string) VALUE {
	return C.rb_const_get(type, C.rb_intern(name.str))
}

pub fn get_nil() VALUE {
	return C.Qnil
}

pub fn get_object_type() VALUE {
	return C.rb_cObject
}

pub fn new_id(str string) ID {
	return C.rb_intern(str.str)
}

pub fn new_str(str string) VALUE {
	return C.rb_str_new_cstr(str.str)
}

pub fn new_cstr(str &char) VALUE {
	return C.rb_str_new_cstr(str)
}

pub fn new_int(integer int) VALUE {
	return C.INT2NUM(integer)
}

pub fn new_bool(boolean bool) VALUE {
	return if boolean == true { C.Qtrue } else { C.Qfalse }
}
