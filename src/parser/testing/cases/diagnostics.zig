const std = @import("std");
const parser = @import("parser");

const testing = std.testing;

fn expectRejected(source: []const u8, opts: parser.Options) !void {
    var tree = try parser.parse(testing.allocator, source, opts);
    defer tree.deinit();

    if (tree.diagnostics.items.len == 0) {
        std.debug.print("accepted with no diagnostics: {s}\n", .{source});
        return error.AcceptedWithoutDiagnostics;
    }
}

// `let`, `using`, `async` and `import` each decide between a declaration and
// an expression on one token of lookahead, and `await using` on two.
test "a lexical error behind a lookahead-driven keyword is reported" {
    const script = [_][]const u8{
        "function f() { let 1x; return 42; }",
        "let 1x;",
        "using 1x;",
        "async 1x;",
        "import 1x;",
        "for (let 1x; ; ) {}",
        "for (using 1x of xs) {}",
    };

    for (script) |source| {
        try expectRejected(source, .{ .source_type = .script, .lang = .js });
    }

    try expectRejected("await using 1x;", .{ .source_type = .module, .lang = .js });
}

// the same lookahead shape guards TypeScript declaration heads and the
// `<` of a type-argument list.
test "a lexical error behind a typescript lookahead is reported" {
    const sources = [_][]const u8{
        "declare 1x",
        "const enum 1x {}",
        "type 1x = 2",
        "abstract class 1x {}",
        "class C { readonly 1x: number }",
    };

    for (sources) |source| {
        try expectRejected(source, .{ .source_type = .module, .lang = .ts });
    }
}

// the positive space: valid programs that hit the same lookahead paths must
// keep parsing clean, so the fix cannot be a blanket "report something".
test "lookahead-driven keywords still parse cleanly when the next token is valid" {
    const sources = [_][]const u8{
        "let x = 1;",
        "let = 1;",
        "let.foo;",
        "let [a] = xs;",
        "using x = res;",
        "using;",
        "async () => 1;",
        "async;",
        "for (let x of xs) {}",
        "for (let in obj) {}",
    };

    for (sources) |source| {
        var tree = try parser.parse(testing.allocator, source, .{
            .source_type = .script,
            .lang = .js,
        });
        defer tree.deinit();

        if (tree.diagnostics.items.len != 0) {
            std.debug.print(
                "unexpected diagnostic for {s}: {s}\n",
                .{ source, tree.diagnostics.items[0].message },
            );
            return error.UnexpectedDiagnostic;
        }
    }
}

test "an initialized for-in or for-of head is rejected outside annex b" {
    const script = [_][]const u8{
        "for (let a = 1 in b);",
        "for (const a = 1 in b);",
        "for (var [a] = 1 in b);",
        "for (var {a} = 1 in b);",
        "for (var a = 1 of b);",
        "for (let a = 1 of b);",
        "for (const a = 1 of b);",
        "async function f() { for await (var a = 1 of b); }",
    };

    for (script) |source| {
        try expectRejected(source, .{ .source_type = .script, .lang = .js });
    }

    try expectRejected("for (var a = 1 in b);", .{ .source_type = .module, .lang = .js });
    try expectRejected("for (var a = 1 in b);", .{ .source_type = .script, .lang = .ts });
}

test "the annex b for-in head parses without a diagnostic" {
    var tree = try parser.parse(testing.allocator, "for (var a = 1 in b);", .{
        .source_type = .script,
        .lang = .js,
    });
    defer tree.deinit();

    try testing.expectEqual(@as(usize, 0), tree.diagnostics.items.len);
}
