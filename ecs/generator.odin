package ecs

import "core:fmt"

import "core:mem"
import vmem "core:mem/virtual"
import "core:odin/ast"
import "core:odin/parser"
import "core:os"

Ecs_Error :: enum u32 {
	InvalidSyntax,
}

ecs_error_strings := [Ecs_Error]string {
	.InvalidSyntax = "ecs.Ecs_Error.InvalidSyntax: the odin file being parsed has invalid syntax",
}

Error :: union #shared_nil {
	Ecs_Error,
	os.Error,
	vmem.Allocator_Error,
}

error_string :: proc(err: Error) -> string {
	switch e in err {
	case Ecs_Error:
		return ecs_error_strings[e]
	case os.Error:
		return os.error_string(e)
	case vmem.Allocator_Error:
		return fmt.tprintf("%s", e) // convert enum to string
	case:
		return "unknown error"
	}

	return ""
}

init :: proc(paths: ..string) -> Error {
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
		p: parser.Parser
		file: ast.File
		file.src = string(os.read_entire_file_from_file(f, context.allocator) or_return)
		file.fullpath = paths[i]
		file.derived = &file

		if !parser.parse_file(&p, &file) do return Ecs_Error.InvalidSyntax

		walk_ast(&file)
	}

	for system in systems {
		fmt.println(system)
	}

	return nil
}

systems: map[string](struct{})

walk_ast :: proc(file: ^ast.File) {
	visitor := ast.Visitor {
		visit = proc(v: ^ast.Visitor, node: ^ast.Node) -> ^ast.Visitor {
			process_node(node)
			return v
		},
	}

	ast.walk(&visitor, file)
}

process_node :: proc(node: ^ast.Node) {
	if node == nil do return

	#partial switch derived in node.derived {
	case ^ast.Value_Decl:
		if !has_attribute(derived.attributes, "system") do return

		if len(derived.values) != 1 do panic("@(system) only works on single declarations")

		type, is_proc := derived.values[0].derived.(^ast.Proc_Lit)
		if !is_proc do panic("@(system) only works on procs")

		systems[derived.names[0].derived.(^ast.Ident).name] = {}
	}
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
