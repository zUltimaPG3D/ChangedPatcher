module vruby

pub enum RubyValueType {
	ruby_t_none = C.RUBY_T_NONE

	ruby_t_object   = C.RUBY_T_OBJECT
	ruby_t_class    = C.RUBY_T_CLASS
	ruby_t_module   = C.RUBY_T_MODULE
	ruby_t_float    = C.RUBY_T_FLOAT
	ruby_t_string   = C.RUBY_T_STRING
	ruby_t_regexp   = C.RUBY_T_REGEXP
	ruby_t_array    = C.RUBY_T_ARRAY
	ruby_t_hash     = C.RUBY_T_HASH
	ruby_t_struct   = C.RUBY_T_STRUCT
	ruby_t_bignum   = C.RUBY_T_BIGNUM
	ruby_t_file     = C.RUBY_T_FILE
	ruby_t_data     = C.RUBY_T_DATA
	ruby_t_match    = C.RUBY_T_MATCH
	ruby_t_complex  = C.RUBY_T_COMPLEX
	ruby_t_rational = C.RUBY_T_RATIONAL

	ruby_t_nil    = C.RUBY_T_NIL
	ruby_t_true   = C.RUBY_T_TRUE
	ruby_t_false  = C.RUBY_T_FALSE
	ruby_t_symbol = C.RUBY_T_SYMBOL
	ruby_t_fixnum = C.RUBY_T_FIXNUM
	ruby_t_undef  = C.RUBY_T_UNDEF

	ruby_t_imemo  = C.RUBY_T_IMEMO
	ruby_t_node   = C.RUBY_T_NODE
	ruby_t_iclass = C.RUBY_T_ICLASS
	ruby_t_zombie = C.RUBY_T_ZOMBIE
	ruby_t_moved  = C.RUBY_T_MOVED

	ruby_t_mask = C.RUBY_T_MASK
}

pub fn (val RubyValueType) int() int {
	return int(val)
}

fn C.TYPE(VALUE) int

pub fn type_of(obj VALUE) int {
	return C.TYPE(obj)
}
