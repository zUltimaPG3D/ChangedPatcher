module vruby

pub struct RArray {
pub:
	obj VALUE
mut:
	idx int
pub mut:
	len int
}

fn (mut arr RArray) init() {
	arr.len = arr.len()
}

pub fn (arr RArray) len() int {
	return C.RARRAY_LEN(arr.obj)
}

pub fn (arr RArray) get(idx int) VALUE {
	return C.rb_ary_entry(arr.obj, idx)
}

pub fn (arr RArray) join(sep string) VALUE {
	return C.rb_ary_join(arr.obj, new_str(sep))
}

pub fn (arr RArray) reverse() {
	C.rb_ary_reverse(arr.obj)
}

pub fn (arr RArray) contains(obj VALUE) bool {
	includes := C.rb_ary_includes(arr.obj, obj)
	return includes.is_a(.ruby_t_true)
}

pub fn (mut arr RArray) push(element RValue) {
	arr.len += 1
	C.rb_ary_push(arr.obj, element.as_value())
}

pub fn (arr RArray) inspect() string {
	return arr.obj.inspect()
}

pub fn (mut iter RArray) next() ?VALUE {
	if iter.idx >= iter.len {
		return none
	}
	defer {
		iter.idx++
	}
	return iter.get(iter.idx)
}

pub fn new_arr() RArray {
	mut arr := RArray{
		obj: C.rb_ary_new()
	}
	arr.init()
	return arr
}

pub fn new_arr_from_args(values ...RValue) RArray {
	mut val_args := []VALUE{}
	for val in values {
		val_args << val.as_value()
	}

	mut arr := RArray{
		obj: C.rb_ary_new_from_values(val_args.len, val_args.data)
	}
	arr.init()
	return arr
}
