const std = @import("std");
const parser = @import("parser");

const testing = std.testing;

// loose parsing keeps the parent close available while preserving source boundaries
test "loose JSX parsing recovers a nested element closed by its parent" {
    const source = "const view = <div>{/* kept */}<span>text</div>;";

    var strict_tree = try parser.parse(testing.allocator, source, .{ .lang = .tsx });
    defer strict_tree.deinit();

    try testing.expectEqual(@as(usize, 1), strict_tree.diagnostics.items.len);
    try testing.expectEqualStrings(
        "Expected closing tag for '<span>' but found '</div>'",
        strict_tree.diagnostics.items[0].message,
    );

    var loose_tree = try parser.parse(testing.allocator, source, .{
        .lang = .tsx,
        .loose = true,
    });
    defer loose_tree.deinit();

    try testing.expectEqual(@as(usize, 0), loose_tree.diagnostics.items.len);
    try testing.expectEqual(@as(usize, 1), loose_tree.comments.len);
    try testing.expectEqual(@as(u32, 19), loose_tree.comments[0].span.start);
    try testing.expectEqual(@as(u32, 29), loose_tree.comments[0].span.end);

    var child: ?parser.ast.NodeIndex = null;
    var parent: ?parser.ast.NodeIndex = null;
    var index_value: u32 = 0;
    while (index_value < loose_tree.nodes.len) : (index_value += 1) {
        const index: parser.ast.NodeIndex = @enumFromInt(index_value);
        if (loose_tree.data(index) != .jsx_element) continue;

        const span = loose_tree.span(index);
        if (span.start == 30) child = index;
        if (span.start == 13) parent = index;
    }

    const child_index = child orelse return error.MissingRecoveredChild;
    const parent_index = parent orelse return error.MissingParent;
    try testing.expectEqual(@as(u32, 30), loose_tree.span(child_index).start);
    try testing.expectEqual(@as(u32, 40), loose_tree.span(child_index).end);
    try testing.expectEqual(
        parser.ast.NodeIndex.null,
        loose_tree.data(child_index).jsx_element.closing_element,
    );
    try testing.expect(loose_tree.data(parent_index).jsx_element.closing_element != .null);
    try testing.expectEqual(@as(u32, 46), loose_tree.span(parent_index).end);
}
