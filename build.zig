const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "yuku",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const gen_unicode_id_table = b.addExecutable(.{
        .name = "generate-unicode-id-table",
        .root_module = b.createModule(.{
            .root_source_file = b.path("scripts/generate-unicode-id-tables.zig"),
            .target = b.graph.host,
            .optimize = b.standardOptimizeOption(.{
                .preferred_optimize_mode = std.builtin.OptimizeMode.ReleaseFast,
            }),
        }),
    });

    const run_gen_unicode_id_table = b.addRunArtifact(gen_unicode_id_table);
    const gen_unicode_id_table_step = b.step("generate-unicode-id-table", "Run unicode identifier table generation");
    gen_unicode_id_table_step.dependOn(&run_gen_unicode_id_table.step);
}
