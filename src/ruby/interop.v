module ruby

pub fn init() {
	C.ruby_init()
	C.ruby_init_loadpath()
	C.rb_require("zlib".str);
}

pub fn cleanup() int {
	return C.ruby_cleanup(0)
}

pub fn get_global(name string) VALUE {
	return C.rb_gv_get(name.str)
}

pub fn set_global(name string, obj VALUE) VALUE {
	return C.rb_gv_set(name.str, obj)
}

pub fn to_str(obj VALUE) string {
	return unsafe { C.StringValueCStr(obj).vstring() }
} 

fn run_protect(name string) int {
	mut state := 0
	script := C.rb_str_new_cstr(name.str)
	C.rb_load_protect(script, 0, &state)

	return state
}

pub fn run(name string) bool {
	state := run_protect(name)

	if state != 0 {
		err := C.rb_errinfo()

		klass := C.rb_class_name(C.CLASS_OF(err));
		message := C.rb_funcall(err, C.rb_intern("message".str), 0);

		class_name := to_str(klass)
		message_str := to_str(message)

		println('Caught "${class_name}": ${message_str}')
		C.rb_set_errinfo(C.Qnil)
	}

	return state == 0
}

pub fn eval(code string) int {
	mut state := 0
	ret := C.rb_eval_string_protect(code.str, state)

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

pub fn new_str(str string) VALUE {
	return C.rb_str_new_cstr(str.str)
}

pub fn new_int(integer int) VALUE {
	return C.INT2NUM(integer)
}