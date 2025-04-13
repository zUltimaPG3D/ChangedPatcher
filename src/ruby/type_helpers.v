module ruby

pub fn (obj VALUE) class_name() string {
	klass := C.rb_class_name(C.CLASS_OF(obj));
	class_name := to_str(klass)
	return class_name
}

pub fn (obj VALUE) is_a(typ RubyValueType) bool {
	return type_of(obj) == typ.int()
}

pub fn (obj VALUE) as_array() RArray {
	mut arr := RArray{obj: obj}
	arr.init()
	return arr
}

pub fn (obj VALUE) as_cstr() &char {
	return C.StringValueCStr(obj)
}

pub fn (obj VALUE) as_vstr() string {
	return unsafe { obj.as_cstr().vstring() }
}

pub fn (obj VALUE) as_int() int {
	return C.FIX2INT(obj)
}

pub fn (obj VALUE) as_u8() u8 {
	return u8(obj.as_int())
}