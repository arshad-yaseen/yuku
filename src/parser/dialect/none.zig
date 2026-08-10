const abi = @import("dialect_abi");

pub const enabled = false;
pub const hooks = [_]abi.Hook{};
pub const Record = schema.Record;
pub const Store = struct {};
pub const schema = struct {
    pub const record_count: u8 = 0;
    pub const Record = struct {};
};

comptime {
    if (enabled) @compileError("the disabled dialect cannot enable hooks");
    if (hooks.len != 0) @compileError("the disabled dialect cannot declare hooks");
}
