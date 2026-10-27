package ecs

import "core:fmt"
import "core:mem"
import "core:odin/ast"
import "core:odin/parser"
import "core:os"

Ecs_Error :: enum {
	InvalidSyntax,
}

ecs_error_strings := [Ecs_Error]string {
	.InvalidSyntax = "ecs.Ecs_Error.InvalidSyntax: the odin file being parsed has invalid syntax",
}

Error :: union #shared_nil {
	Ecs_Error,
	os.Error,
	mem.Allocator_Error,
}

error_string :: proc(err: Error) -> string {
	switch e in err {
	case Ecs_Error:
		return ecs_error_strings[e]
	case os.Error:
		return os.error_string(e)
	case mem.Allocator_Error:
		return fmt.tprint(e)
	case:
		return "unknown error"
	}

	return ""
}

generate :: proc(paths: ..string) -> Error {
	context.allocator = context.temp_allocator

	files := make([dynamic](^os.File), 0, len(paths))

	total_size: i64 = 0
	for path in paths {
		file := os.open(path) or_return
		total_size += os.file_size(file) or_return

		append(&files, file)
	}

	defer {
		for file in files {
			os.close(file)
		}
	}

	for f, i in files {
		file_src := string(os.read_entire_file_from_file(f, context.allocator) or_return)

		p: parser.Parser
		file: ast.File
		file.src = file_src
		file.fullpath = paths[i]
		file.derived = &file

		if !parser.parse_file(&p, &file) do return Ecs_Error.InvalidSyntax

		walk_ast(&file, &file_src)
	}

	return nil
}

walk_ast :: proc(file: ^ast.File, file_src: ^string) {
	visitor := ast.Visitor {
		visit = proc(v: ^ast.Visitor, node: ^ast.Node) -> ^ast.Visitor {
			process_node(node, cast(^string)v.data)
			return v
		},
		data = file_src,
	}

	ast.walk(&visitor, file)
}

has_attribute :: proc(attributes: [dynamic]^ast.Attribute, name: string) -> bool {
	for attr in attributes {
		for elem in attr.elems {
			ident, is_ident := elem.derived.(^ast.Ident)
			if is_ident && ident.name == name {
				return true
			}
		}
	}

	return false
}

check_if_proc :: proc(value_decl: ^ast.Value_Decl) -> ^ast.Proc_Lit {
	if len(value_decl.values) != 1 {
		panic("@(system) only works on single declarations")
	}

	proc_lit, is_proc := value_decl.values[0].derived.(^ast.Proc_Lit)
	if !is_proc {
		panic("@(system) only works on procs")
	}

	proc_name := value_decl.names[0].derived.(^ast.Ident).name

	fmt.printf("%s: ", proc_name)

	return proc_lit
}

find_proc_query_param :: proc(proc_lit: ^ast.Proc_Lit) -> ^ast.Field {
	params := proc_lit.type.params.list

	query_param := params[0]
	if len(query_param.names) != 1 {
		panic("@(system) there must be only one query in a system")
	}

	fmt.printf("%s: ", query_param.names[0].derived.(^ast.Ident).name)

	return query_param
}

check_if_array_and_soa_tag :: proc(query_param: ^ast.Field) -> ^ast.Array_Type {
	array_type, is_array_type := query_param.type.derived.(^ast.Array_Type)
	if !is_array_type {
		panic("@(system) only works on procs with the first parameter as a query (#soa array)")
	}

	if array_type.tag == nil {
		panic("@(system) queries must be #soa arrays")
	}

	if array_type.tag.derived.(^ast.Basic_Directive).name != "soa" {
		panic("@(system) queries must be #soa arrays")
	}

	return array_type
}

get_component_names :: proc(struct_type: ^ast.Struct_Type, file_src: ^string) -> []string {
	query_components := struct_type.fields.list

	component_names: [dynamic]string

	for component in query_components {
		ptr_type, is_ptr_type := component.type.derived.(^ast.Pointer_Type) // ex: ^Position
		if !is_ptr_type {
			panic("@(system) queries must have the struct fields as pointers")
		}

		type := ptr_type.elem // ex: Position

		append(&component_names, file_src[type.pos.offset:type.end.offset])
	}

	return component_names[:]
}

process_node :: proc(node: ^ast.Node, file_src: ^string) {
	if node == nil do return

	#partial switch derived in node.derived {
	case ^ast.Value_Decl:
		if !has_attribute(derived.attributes, "system") {
			return
		}

		proc_lit := check_if_proc(derived)
		query_param := find_proc_query_param(proc_lit)

		fmt.println()

		// #soa guarantees the element type of the array is a sturct
		array_type := check_if_array_and_soa_tag(query_param)

		// tag_text := file_src[array_type.tag.pos.offset:array_type.tag.end.offset]
		// brackets_text := file_src[array_type.open.offset:array_type.close.offset + 1]

		// fmt.printf("%s %s ", tag_text, brackets_text)

		struct_type, is_struct := array_type.elem.derived.(^ast.Struct_Type)
		assert(is_struct)

		// fmt.printfln("%s", file_src[struct_type.pos.offset:struct_type.pos.offset + 8])

		component_names := get_component_names(struct_type, file_src)

		fmt.printfln("%v\n", component_names)
	}

	return
}
