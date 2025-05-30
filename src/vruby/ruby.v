module vruby

import arrays

pub type VALUE = u64
pub type ID = u64
pub type ARGS = &u64

type ProtectedFn = fn (VALUE) VALUE

type MethodFn = fn (int, ARGS, VALUE) VALUE

pub fn (argv ARGS) as_array(argc int) []VALUE {
	return unsafe { arrays.carray_to_varray[VALUE](argv, argc) }
}

// Main functionality
fn C.ruby_init()
fn C.ruby_init_loadpath()
fn C.ruby_cleanup(int) int

// Execution
fn C.rb_load_protect(VALUE, int, &int) VALUE
fn C.rb_eval_string_protect(&char, &int) VALUE
fn C.rb_require(&char) VALUE
fn C.rb_protect(ProtectedFn, VALUE, &int) VALUE

// Exceptions
fn C.rb_errinfo() VALUE
fn C.rb_set_errinfo(VALUE)

// Reflection
fn C.rb_class_name(VALUE) VALUE
fn C.CLASS_OF(VALUE) VALUE
fn C.ID2SYM(ID) VALUE
fn C.rb_funcall(VALUE, ID, int, ...VALUE) VALUE
fn C.rb_funcallv(VALUE, ID, int, ARGS) VALUE
fn C.rb_funcallv_public(VALUE, ID, int, ARGS) VALUE
fn C.rb_intern(&char) ID
fn C.rb_inspect(VALUE) VALUE
fn C.rb_respond_to(VALUE, ID) int

// Constants
fn C.rb_const_get(VALUE, ID) VALUE

// Type definitions
fn C.rb_define_module(&char) VALUE
fn C.rb_define_class(&char, VALUE) VALUE
fn C.rb_define_class_under(VALUE, &char, VALUE) VALUE
fn C.rb_define_module_under(VALUE, &char) VALUE

// Methods
fn C.rb_define_attr(VALUE, &char, int, int)
fn C.rb_define_method(VALUE, &char, MethodFn, int)
fn C.rb_define_module_function(VALUE, &char, MethodFn, int)
fn C.rb_define_singleton_method(VALUE, &char, MethodFn, int)

// Global Variables
fn C.rb_gv_get(&char) VALUE
fn C.rb_gv_set(&char, VALUE) VALUE

// Instance Variables
fn C.rb_ivar_get(VALUE, ID) VALUE
fn C.rb_ivar_set(VALUE, ID, VALUE) VALUE

// String
fn C.rb_str_new_cstr(&char) VALUE
fn C.rb_str_new(&char, int) VALUE
fn C.StringValueCStr(VALUE) &char
fn C.RSTRING_LEN(VALUE) int
fn C.RSTRING_PTR(VALUE) &char

// Array
fn C.rb_ary_new() VALUE
fn C.rb_ary_new_from_values(i64, ARGS) VALUE
fn C.rb_ary_entry(VALUE, int) VALUE
fn C.rb_ary_push(VALUE, VALUE) VALUE
fn C.rb_ary_join(VALUE, VALUE) VALUE
fn C.rb_ary_reverse(VALUE) VALUE
fn C.rb_ary_includes(VALUE, VALUE) VALUE
fn C.RARRAY_LEN(VALUE) int

// Integer/Fixnum
fn C.INT2NUM(int) VALUE
fn C.FIX2INT(VALUE) int

// Objects
fn C.rb_class_new_instance(int, ARGS, VALUE) VALUE
fn C.rb_singleton_class(VALUE) VALUE

// Marshal
fn C.rb_marshal_dump(VALUE, VALUE) VALUE
fn C.rb_marshal_load(VALUE) VALUE

// IO
fn C.rb_io_close(VALUE) VALUE
fn C.rb_io_write(VALUE, VALUE) VALUE

// File
fn C.rb_file_open(&char, &char) VALUE
