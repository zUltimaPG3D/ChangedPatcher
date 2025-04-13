module ruby

pub struct RArray {
pub:
	obj VALUE
mut:
	idx int
pub mut:
	len int
}

pub fn (mut arr RArray) init() {
	arr.len = arr.len()
}

pub fn (arr RArray) len() int {
	return C.RARRAY_LEN(arr.obj)
}

pub fn (arr RArray) at(idx int) VALUE {
	return C.rb_ary_entry(arr.obj, idx)
}

pub fn (mut arr RArray) push(element VALUE) VALUE {
	arr.len += 1
	return C.rb_ary_push(arr.obj, element)
}

pub fn (mut iter RArray) next() ?VALUE {
    if iter.idx >= iter.len {
        return none
    }
    defer {
        iter.idx++
    }
    return iter.at(iter.idx)
}

pub fn new_arr() RArray {
	mut arr := RArray{obj: C.rb_ary_new()}
	arr.init()
	return arr
}