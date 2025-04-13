module ruby

pub type VALUE = u64
type ID = u64

type ProtectedFn = fn (VALUE) VALUE

fn C.ruby_init()
fn C.rb_require(&char) VALUE
fn C.ruby_init_loadpath()
fn C.rb_load_protect(VALUE, int, &int) VALUE
fn C.rb_eval_string_protect(&char, &int) VALUE
fn C.ruby_cleanup(int) int
fn C.rb_errinfo() VALUE
fn C.rb_set_errinfo(VALUE) 
fn C.rb_str_new_cstr(&char) VALUE
fn C.rb_class_name(VALUE) VALUE
fn C.rb_funcall(VALUE, ID, int, ... voidptr) VALUE
fn C.rb_intern(&char) ID
fn C.CLASS_OF(VALUE) VALUE
fn C.StringValueCStr(VALUE) &char
fn C.rb_gv_get(&char) VALUE
fn C.rb_gv_set(&char, VALUE) VALUE
fn C.rb_ary_entry(VALUE, int) VALUE
fn C.rb_str_new(&char, int) VALUE
fn C.rb_const_get(VALUE, ID) VALUE
fn C.rb_protect(ProtectedFn, VALUE, &int) VALUE
fn C.rb_define_module(&char) VALUE
fn C.rb_define_class_under(VALUE, &char, VALUE) VALUE
fn C.rb_ary_new() VALUE
fn C.rb_ary_push(VALUE, VALUE) VALUE
fn C.INT2NUM(int) VALUE

fn C.RARRAY_LEN(VALUE) int
fn C.FIX2INT(VALUE) int