const parser = @import("parser.zig");
const dialect = @import("dialect");

pub const parse = parser.parse;
pub const Options = parser.Options;
pub const CommentMode = parser.CommentMode;

pub const ast = @import("ast.zig");

pub const traverser = @import("traverser/root.zig");
pub const semantic = @import("semantic/root.zig");
pub const codegen = @import("codegen/root.zig");
pub const dialect_enabled = dialect.enabled;
pub const dialect_schema = dialect.schema;

test {
    _ = codegen;
}
