module vruby

pub struct RClass {
pub:
	parent RBase
	obj    VALUE
	name   string
}

pub struct RModule {
	RClass
}

pub enum RFieldAccessor {
	reader
	writer
	accessor
}

pub type RBase = RClass | RModule

fn value_class_name(obj VALUE) string {
	klass := C.rb_class_name(obj)
	class_name := klass.as_vstr()
	return class_name
}

// Class

pub fn RClass.new(name string) RClass {
	klass := C.rb_define_class(name.str, C.rb_cObject)
	return RClass{
		obj:  klass
		name: value_class_name(klass)
	}
}

pub fn RClass.under(name string, base RBase) RClass {
	klass := C.rb_define_class_under(base.obj, name.str, C.rb_cObject)
	return RClass{
		parent: base
		obj:    klass
		name:   value_class_name(klass)
	}
}

pub fn (obj RClass) real_name() string {
	klass := C.rb_class_name(obj.obj)
	class_name := klass.as_vstr()
	return class_name
}

pub fn (obj RClass) instance_of(init_args ...RValue) VALUE {
	mut usable_vars := []VALUE{len: init_args.len, cap: init_args.cap}
	for val in init_args {
		usable_vars << val.as_value()
	}
	return C.rb_class_new_instance(init_args.len, usable_vars.data, obj.obj)
}

pub fn (obj RClass) define_field(name string, settings RFieldAccessor) {
	reader := if settings == .reader || settings == .accessor { 1 } else { 0 }
	writer := if settings == .writer || settings == .accessor { 1 } else { 0 }

	C.rb_define_attr(obj.obj, name.str, reader, writer)
}

pub fn (obj RClass) define_method(name string, callback MethodFn) {
	C.rb_define_method(obj.obj, name.str, callback, -1)
}

pub fn (obj RClass) define_static_method(name string, callback MethodFn) {
	C.rb_define_module_function(obj.obj, name.str, callback, -1)
}

pub fn (obj RClass) define_singleton_method(name string, callback MethodFn) {
	C.rb_define_singleton_method(obj.obj, name.str, callback, -1)
}

fn internal_get_field(args VALUE) VALUE {
	args_arr := args.as_array()

	obj := args_arr.get(0)
	name := args_arr.get(1).as_cstr()

	val := C.rb_funcall(obj, C.rb_intern(name), 0)

	return val
}

fn internal_set_field(args VALUE) VALUE {
	args_arr := args.as_array()

	obj := args_arr.get(0)
	name := args_arr.get(1).as_cstr()
	value := args_arr.get(2)

	C.rb_funcall(obj, C.rb_intern(name), 1, value)

	return new_bool(true)
}

pub fn (obj RClass) get_field(name string) VALUE {
	return protected(internal_get_field, obj.obj, name) or {
		panic('${obj.name}.get_field("${name}"): ${err}')
	}
}

pub fn (obj RClass) set_field(name string, value VALUE) {
	protected(internal_set_field, obj.obj, '${name}=', value) or {
		panic('${obj.name}.set_field("${name}", ...): ${err}')
	}
}

pub fn (obj RClass) call(instance VALUE, name string, args ...RValue) VALUE {
	return instance.call(name, ...args)
}

pub fn (obj RClass) call_static(name string, args ...RValue) VALUE {
	return obj.obj.call(name, ...args)
}

// Module

pub fn RModule.new(name string) RModule {
	mod := C.rb_define_module(name.str)
	return RModule{
		obj:  mod
		name: value_class_name(mod)
	}
}

pub fn RModule.under(name string, base RBase) RModule {
	mod := C.rb_define_module_under(base.obj, name.str)
	return RModule{
		parent: base
		obj:    mod
		name:   value_class_name(mod)
	}
}

pub fn (obj RModule) define_method(name string, callback MethodFn) {
	C.rb_define_module_function(obj.obj, name.str, callback, -1)
}

pub fn (obj RModule) call(name string, args ...RValue) VALUE {
	return obj.obj.call(name, ...args)
}
