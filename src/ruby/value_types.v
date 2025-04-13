module ruby

pub enum RubyValueType {
    ruby_t_none     = C.RUBY_T_NONE /**< Non-object (sweeped etc.) */

    ruby_t_object   = C.RUBY_T_OBJECT /**< @see struct ::RObject */
    ruby_t_class    = C.RUBY_T_CLASS /**< @see struct ::RClass and ::rb_cClass */
    ruby_t_module   = C.RUBY_T_MODULE /**< @see struct ::RClass and ::rb_cModule */
    ruby_t_float    = C.RUBY_T_FLOAT /**< @see struct ::RFloat */
    ruby_t_string   = C.RUBY_T_STRING /**< @see struct ::RString */
    ruby_t_regexp   = C.RUBY_T_REGEXP /**< @see struct ::RRegexp */
    ruby_t_array    = C.RUBY_T_ARRAY /**< @see struct ::RArray */
    ruby_t_hash     = C.RUBY_T_HASH /**< @see struct ::RHash */
    ruby_t_struct   = C.RUBY_T_STRUCT /**< @see struct ::RStruct */
    ruby_t_bignum   = C.RUBY_T_BIGNUM /**< @see struct ::RBignum */
    ruby_t_file     = C.RUBY_T_FILE /**< @see struct ::RFile */
    ruby_t_data     = C.RUBY_T_DATA /**< @see struct ::RTypedData */
    ruby_t_match    = C.RUBY_T_MATCH /**< @see struct ::RMatch */
    ruby_t_complex  = C.RUBY_T_COMPLEX /**< @see struct ::RComplex */
    ruby_t_rational = C.RUBY_T_RATIONAL /**< @see struct ::RRational */

    ruby_t_nil      = C.RUBY_T_NIL /**< @see ::RUBY_Qnil */
    ruby_t_true     = C.RUBY_T_TRUE /**< @see ::RUBY_Qfalse */
    ruby_t_false    = C.RUBY_T_FALSE /**< @see ::RUBY_Qtrue */
    ruby_t_symbol   = C.RUBY_T_SYMBOL /**< @see struct ::RSymbol */
    ruby_t_fixnum   = C.RUBY_T_FIXNUM /**< Integers formerly known as Fixnums. */
    ruby_t_undef    = C.RUBY_T_UNDEF /**< @see ::RUBY_Qundef */

    ruby_t_imemo    = C.RUBY_T_IMEMO /**< @see struct ::RIMemo */
    ruby_t_node     = C.RUBY_T_NODE /**< @see struct ::RNode */
    ruby_t_iclass   = C.RUBY_T_ICLASS /**< Hidden classes known as IClasses. */
    ruby_t_zombie   = C.RUBY_T_ZOMBIE /**< @see struct ::RZombie */
    ruby_t_moved    = C.RUBY_T_MOVED /**< @see struct ::RMoved */

    ruby_t_mask     = C.RUBY_T_MASK
}

pub fn (val RubyValueType) int() int {
    return int(val)
}

fn C.TYPE(VALUE) int

pub fn type_of(obj VALUE) int {
	return C.TYPE(obj)
}