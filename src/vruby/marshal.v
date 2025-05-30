module vruby

type RIO = VALUE | File
type RIO2 = RValue | File

fn (rio RIO) as_value() VALUE {
	match rio {
		VALUE { return rio }
		File { return rio.obj }
	}
}

fn (rio RIO2) as_value() VALUE {
	match rio {
		RValue { return rio.as_value() }
		File { return rio.obj }
	}
}

pub fn marshal_dump(value RValue) VALUE {
	return C.rb_marshal_dump(value.as_value(), get_nil())
}

pub fn marshal_dump_to(value RValue, io RIO) VALUE {
	return C.rb_marshal_dump(value.as_value(), io.as_value())
}

fn internal_load(args VALUE) VALUE {
	args_arr := args.as_array()

	value := args_arr.get(0)

	return C.rb_marshal_load(value)
}

pub fn marshal_load(value RIO2) !VALUE {
	return protected(internal_load, value.as_value()) or {
		return error('Marshal.load(...): ${err}')
	}
}
