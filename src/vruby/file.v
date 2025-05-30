module vruby

pub struct File {
pub:
	obj VALUE
}

pub fn File.open(name string, mode string) !File {
	file := protected(internal_open, name, mode) or {
		return error('File.open("${name}", "${mode}"): ${err}')
	}

	return File{
		obj: file
	}
}

pub fn File.delete(name string) ! {
	protected(internal_delete, name) or { return error('File.delete("${name}"): ${err}') }
}

pub fn (file File) close() {
	C.rb_io_close(file.obj)
}

pub fn (file File) write_str(str string) !int {
	written_bytes := protected(internal_write, file.obj, str) or {
		return error('file.write_str("${str}"): ${err}')
	}

	return written_bytes
}

pub fn (file File) read_all() !VALUE {
	read := file.obj.call2('read') or { return error('file.read: ${err}') }

	return read
}

pub fn (file File) read(max_len int) !VALUE {
	read := file.obj.call2('read', max_len) or { return error('file.read: ${err}') }

	return read
}

fn internal_open(args VALUE) VALUE {
	args_arr := args.as_array()

	name := args_arr.get(0).as_cstr()
	mode := args_arr.get(1).as_cstr()

	return C.rb_file_open(name, mode)
}

fn internal_write(args VALUE) VALUE {
	args_arr := args.as_array()

	obj := args_arr.get(0)
	str := args_arr.get(1)

	return C.rb_io_write(obj, str)
}

fn internal_delete(args VALUE) VALUE {
	args_arr := args.as_array()

	name := args_arr.get(0)

	return get_const(get_object_type(), 'File').call('delete', name)
}
