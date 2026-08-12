const std = @import("std");

pub fn Decision(comptime T: type) type {
    std.debug.assert(@sizeOf(T) <= @sizeOf(u64));
    std.debug.assert(@alignOf(T) <= @alignOf(u64));
    return union(enum) {
        unhandled,
        handled: T,
    };
}

pub const Hook = enum(u8) {
    statement_at_code_block,
    statement_at_control_flow,
    expression_at_code_block,
    expression_at_control_flow,
    lazy_assignment_pattern,
    function_body_starts,
    function_body,
    for_of_tail,
    binding_pattern,
    module_specifier,
    can_start_binding,
    jsx_element_after_open,
    jsx_names_match,
    jsx_text_boundary,
    jsx_text_value,
    jsx_child_at_code_block,
    jsx_child_at_control_flow,
    jsx_element_name,
    validate_jsx_element_name,
};

/// Dependency-free reflected field roles. Dialect schemas use these wrappers
/// instead of borrowing parser AST types or relying on field-name conventions.
pub const FieldRole = enum(u8) {
    scalar_u32,
    node_ref,
    optional_node_ref,
    node_list,
    string_slice,
    overlay_host,
};

/// Dialect-neutral lexical behavior attached to reflected record payloads.
pub const ScopeRole = enum(u8) { none, block };

fn Word(comptime role: FieldRole) type {
    return packed struct(u32) {
        raw: u32,
        pub const dialect_role = role;
        pub inline fn init(value: u32) @This() {
            return .{ .raw = value };
        }
    };
}

pub const ScalarU32 = Word(.scalar_u32);
pub const NodeRef = Word(.node_ref);
pub const OptionalNodeRef = Word(.optional_node_ref);
pub const OverlayHost = Word(.overlay_host);
pub const NodeList = extern struct {
    start: u32,
    len: u32,
    pub const dialect_role = FieldRole.node_list;
};
pub const StringSlice = extern struct {
    start: u32,
    end: u32,
    pub const dialect_role = FieldRole.string_slice;
};

comptime {
    std.debug.assert(@typeInfo(Hook).@"enum".fields.len == 19);
    std.debug.assert(@sizeOf(Hook) == 1);
    std.debug.assert(@typeInfo(FieldRole).@"enum".fields.len == 6);
    std.debug.assert(@sizeOf(FieldRole) == 1);
    std.debug.assert(@typeInfo(ScopeRole).@"enum".fields.len == 2);
    std.debug.assert(@sizeOf(ScopeRole) == 1);
}
