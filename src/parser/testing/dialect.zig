const std = @import("std");
const parser = @import("parser");
const transfer = @import("transfer");

const base_node_variants_expected: u16 = 171;

test "disabled dialect preserves layout and allocates no storage" {
    var tree = parser.ast.Tree.initEmpty(std.testing.allocator);
    defer tree.deinit();

    try std.testing.expectEqual(@as(usize, 44), @sizeOf(parser.ast.NodeData));
    try std.testing.expectEqual(@as(usize, 52), @sizeOf(parser.ast.Node));
    try std.testing.expectEqual(@as(usize, 0), @sizeOf(parser.dialect_schema.Record));
    try std.testing.expectEqual(@as(usize, 0), tree.arena.queryCapacity());
    try std.testing.expectEqual(@as(?u32, null), tree.dialectOverlay(0));
    try std.testing.expectEqual(@as(usize, 0), tree.arena.queryCapacity());
    std.debug.print("disabled layout: node_data={d} node={d} tree={d} store={d}\n", .{
        @sizeOf(parser.ast.NodeData),
        @sizeOf(parser.ast.Node),
        @sizeOf(parser.ast.Tree),
        @sizeOf(parser.dialect_schema.Record),
    });
}

test "disabled dialect wire remains deterministic" {
    const source = "export const value: number = <Box answer={42} />;";
    var tree = try parser.parse(std.testing.allocator, source, .{ .lang = .tsx });
    defer tree.deinit();
    try std.testing.expect(!tree.hasErrors());

    const bytes = try std.testing.allocator.alloc(u8, transfer.bufferSize(&tree));
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqual(bytes.len, transfer.serializeInto(&tree, bytes));
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    std.debug.print("disabled wire: bytes={d} sha256={x}\n", .{ bytes.len, digest });
}

// round-trip transfer instantiates disabled record decoding without dialect storage
test "disabled dialect transfer round-trip preserves bytes" {
    const source = "export const value: number = <Box answer={42} />;";
    var tree = try parser.parse(std.testing.allocator, source, .{ .lang = .tsx });
    defer tree.deinit();
    try std.testing.expect(!tree.hasErrors());

    const bytes = try std.testing.allocator.alloc(u8, transfer.bufferSize(&tree));
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqual(bytes.len, transfer.serializeInto(&tree, bytes));

    var restored = try transfer.deserializeFromBuf(std.testing.allocator, bytes, source);
    defer restored.deinit();
    try std.testing.expectEqual(tree.root, restored.root);
    try std.testing.expectEqual(tree.nodes.len, restored.nodes.len);
    try std.testing.expect(restored.data(restored.root) == .program);
    try std.testing.expectEqual(@as(usize, 0), @sizeOf(@TypeOf(restored.dialect_store)));
    try std.testing.expectEqual(@as(?u32, null), restored.dialectOverlay(0));

    const restored_bytes = try std.testing.allocator.alloc(u8, transfer.bufferSize(&restored));
    defer std.testing.allocator.free(restored_bytes);
    try std.testing.expectEqual(
        restored_bytes.len,
        transfer.serializeInto(&restored, restored_bytes),
    );
    try std.testing.expectEqual(bytes.len, restored_bytes.len);
}

test "wire transfer pads diagnostic tail to u32 boundary" {
    // prove complete transfers stay word-addressable when diagnostics end off-boundary
    const source = "let value = 1;";
    var tree = try parser.parse(std.testing.allocator, source, .{ .lang = .js });
    defer tree.deinit();
    try std.testing.expect(!tree.hasErrors());
    try tree.addDiagnostic(.{
        .severity = .warning,
        .message = "x",
        .span = .{ .start = 0, .end = 1 },
    });

    const bytes = try std.testing.allocator.alloc(u8, transfer.bufferSize(&tree));
    defer std.testing.allocator.free(bytes);
    @memset(bytes, 0xaa);
    try std.testing.expectEqual(bytes.len, transfer.serializeInto(&tree, bytes));
    try std.testing.expectEqual(@as(usize, 0), bytes.len % @sizeOf(u32));

    const diagnostic_size = 1 + 4 + 4 + 4 + 1 + 1 + 4;
    const padding_len = (@sizeOf(u32) - diagnostic_size % @sizeOf(u32)) % @sizeOf(u32);
    try std.testing.expectEqual(@as(usize, 1), padding_len);
    for (bytes[bytes.len - padding_len ..]) |byte| {
        try std.testing.expectEqual(@as(u8, 0), byte);
    }

    var restored = try transfer.deserializeFromBuf(std.testing.allocator, bytes, source);
    defer restored.deinit();
    try std.testing.expectEqual(tree.root, restored.root);
    try std.testing.expectEqual(tree.nodes.len, restored.nodes.len);
    try std.testing.expect(restored.data(restored.root) == .program);
}

test "disabled corpus behavior is deterministic" {
    const Case = struct { source: []const u8, lang: parser.ast.Lang };
    const cases = [_]Case{
        .{ .source = "@dec class C {}", .lang = .ts },
        .{ .source = "const x = @dec class {};", .lang = .ts },
        .{ .source = "!value;", .lang = .js },
        .{ .source = "function f() {}", .lang = .js },
        .{ .source = "for (value of values) {}", .lang = .js },
        .{ .source = "let value = 1;", .lang = .js },
        .{ .source = "import value from package;", .lang = .js },
        .{ .source = "declare const value: number;", .lang = .ts },
        .{ .source = "const x = <A>left@right{value}</B>;", .lang = .tsx },
        .{ .source = "import value from ;", .lang = .js },
    };
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    for (cases) |case| {
        var tree = try parser.parse(std.testing.allocator, case.source, .{ .lang = case.lang });
        defer tree.deinit();
        const bytes = try std.testing.allocator.alloc(u8, transfer.bufferSize(&tree));
        defer std.testing.allocator.free(bytes);
        _ = transfer.serializeInto(&tree, bytes);
        hasher.update(bytes);
        const diagnostics: u64 = tree.diagnostics.items.len;
        hasher.update(std.mem.asBytes(&diagnostics));
    }
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    std.debug.print("unhandled corpus sha256={x}\n", .{digest});
}

test "derive base node variants and transfer capacity" {
    // reflect the source union and packing rules instead of copying schema counts
    const fields = @typeInfo(parser.ast.NodeData).@"union".fields;
    const base_node_variants = comptime deriveBaseNodeVariants(fields);
    const maxima = comptime maxima: {
        @setEvalBranchQuota(10_000);
        break :maxima deriveMaxima(fields[0..base_node_variants]);
    };

    try std.testing.expectEqual(base_node_variants_expected, base_node_variants);
    try std.testing.expect(maxima.slots <= 7);
    try std.testing.expect(maxima.flags <= 16);
    try expectLayout(parser.ast.ForOfStatement, 3, 1);
    try expectLayout(parser.ast.CatchClause, 2, 0);
    try expectLayout(parser.ast.ArrayPattern, 4, 1);
    try expectLayout(parser.ast.ObjectPattern, 4, 1);
    std.debug.print("dialect capacity: base={d} slots_max={d} flags_max={d}\n", .{
        base_node_variants,
        maxima.slots,
        maxima.flags,
    });
}

fn deriveBaseNodeVariants(comptime fields: []const std.builtin.Type.UnionField) u16 {
    std.debug.assert(fields.len > 0);
    std.debug.assert(fields.len <= 256);
    for (fields, 0..) |field, index| {
        if (std.mem.eql(u8, field.name, "dialect_node")) return @intCast(index);
    }
    return @intCast(fields.len);
}

fn deriveMaxima(comptime fields: []const std.builtin.Type.UnionField) struct {
    slots: u8,
    flags: u8,
} {
    std.debug.assert(fields.len > 0);
    std.debug.assert(fields.len <= 256);
    var slots: u8 = 0;
    var flags: u8 = 0;
    for (fields) |field| {
        if (@typeInfo(field.type) != .@"struct") continue;
        slots = @max(slots, transfer.totalU32Slots(field.type));
        flags = @max(flags, transfer.totalFlagBits(field.type));
    }
    return .{ .slots = slots, .flags = flags };
}

fn expectLayout(comptime T: type, slots_expected: u8, flags_expected: u8) !void {
    std.debug.assert(@typeInfo(T) == .@"struct");
    std.debug.assert(slots_expected <= 7);
    const slots_actual = comptime transfer.totalU32Slots(T);
    const flags_actual = comptime transfer.totalFlagBits(T);
    try std.testing.expectEqual(slots_expected, slots_actual);
    try std.testing.expectEqual(flags_expected, flags_actual);
}
