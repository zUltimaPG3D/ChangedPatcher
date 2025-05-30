module vruby

pub type RValue = RArray | VALUE | string | bool | int | u64 | []RValue

pub fn (obj VALUE) self_name() string {
	klass := C.rb_class_name(obj)
	class_name := klass.as_vstr()
	return class_name
}

pub fn (obj VALUE) class_name() string {
	return C.CLASS_OF(obj).self_name()
}

pub fn (obj VALUE) is_a(typ RubyValueType) bool {
	return type_of(obj) == typ.int()
}

pub fn (obj VALUE) get_type() RubyValueType {
	return RubyValueType.from(C.TYPE(obj)) or { RubyValueType.ruby_t_none }
}

pub fn (obj VALUE) inspect() string {
	return C.rb_inspect(obj).as_vstr()
}

pub fn (obj VALUE) as_array() RArray {
	mut arr := RArray{
		obj: obj
	}
	arr.init()
	return arr
}

pub fn (obj VALUE) str_len() int {
	return C.RSTRING_LEN(obj)
}

pub fn (obj VALUE) as_cstr() &char {
	return C.RSTRING_PTR(obj)
}

pub fn (obj VALUE) as_vstr() string {
	return unsafe { obj.as_cstr().vstring().clone() }
}

pub fn (obj VALUE) as_int() int {
	return C.FIX2INT(obj)
}

pub fn (obj VALUE) as_u8() u8 {
	return u8(obj.as_int())
}

pub fn (obj VALUE) as_bool() bool {
	return obj.is_a(.ruby_t_true)
}

fn internal_call(args VALUE) VALUE {
	args_arr := args.as_array()

	obj := args_arr.get(0)
	name := args_arr.get(1).as_cstr()
	fun_args_value := args_arr.get(2).as_array()

	name_id := C.rb_intern(name)

	if fun_args_value.len == 0 {
		val := C.rb_funcall(obj, name_id, 0)
		return val
	} else {
		mut fun_args := []VALUE{}
		for arg in fun_args_value {
			fun_args << arg
		}

		val := C.rb_funcallv(obj, name_id, fun_args.len, fun_args.data)
		return val
	}
}

pub fn (obj VALUE) call(name string, args ...RValue) VALUE {
	return protected(internal_call, obj, name, new_arr_from_args(...args)) or {
		panic('.call("${name}", ...): ${err}')
	}
}

pub fn (obj VALUE) call2(name string, args ...RValue) !VALUE {
	return protected(internal_call, obj, name, new_arr_from_args(...args)) or {
		return error('.call("${name}", ...): ${err}')
	}
}

pub fn (obj VALUE) responds_to(name string) bool {
	return obj.responds_to_id(C.rb_intern(name.str))
}

pub fn (obj VALUE) responds_to_id(id ID) bool {
	respond_to := C.rb_respond_to(obj, id)
	return respond_to == 1
}

pub fn (obj VALUE) as_singleton() VALUE {
	return C.rb_singleton_class(obj)
}

fn internal_get_variable(args VALUE) VALUE {
	args_arr := args.as_array()

	obj := args_arr.get(0)
	name := args_arr.get(1).as_cstr()

	name_id := C.rb_intern(name)

	return C.rb_ivar_get(obj, name_id)
}

pub fn (obj VALUE) get_variable(name string) !VALUE {
	return protected(internal_get_variable, obj, name) or { return error('.${name}: ${err}') }
}

fn internal_set_variable(args VALUE) VALUE {
	args_arr := args.as_array()

	obj := args_arr.get(0)
	name := args_arr.get(1).as_cstr()
	val := args_arr.get(0)

	name_id := C.rb_intern(name)

	return C.rb_ivar_set(obj, name_id, val)
}

pub fn (obj VALUE) set_variable(name string, value RValue) !VALUE {
	return protected(internal_get_variable, obj, name, value.as_value()) or {
		return error('.${name}=: ${err}')
	}
}

pub fn (obj RValue) as_value() VALUE {
	match obj {
		VALUE { return obj }
		RArray { return obj.obj }
		string { return new_str(obj) }
		bool { return new_bool(obj) }
		int { return new_int(obj) }
		u64 { return VALUE(obj) }
		[]RValue { return new_arr_from_args(...obj).obj }
	}
}

pub fn (obj RValue) inspect() string {
	return obj.as_value().inspect()
}

pub fn (id ID) as_sym() VALUE {
	return C.ID2SYM(id)
}
