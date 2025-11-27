const std = @import("std");

fn addAssets(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    var dir = try std.fs.cwd().openDir("assets",.{ .iterate = true }); 
    var assets = try std.ArrayList(struct { []const u8, []const u8 }).initCapacity(b.allocator, 16);
    defer assets.deinit(b.allocator);
    var walker = dir.iterate();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.endsWith(u8, entry.name, ".png")) continue; 


        const file_name = entry.name;
        const path = try std.fmt.allocPrint(b.allocator, "assets/{s}", .{file_name});

        const name = blk: {
            if (std.mem.endsWith(u8, entry.name, ".fntdat"))
            break :blk path["assets/".len..];
            break :blk path["assets/".len..std.mem.lastIndexOf(u8, path, ".") orelse file_name.len];
        };
        try assets.append(b.allocator, .{ path, name });
    }

    for (assets.items) |asset| {
        const path, const name = asset;
        // std.debug.print("Adding asset: {s} as {s}\n", .{path, name});
        exe.root_module.addAnonymousImport(name, .{ .root_source_file = b.path(path) });
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("evilbob", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "evilbob",
        .use_llvm = false,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "evilbob", .module = mod },
            },
            .link_libc = true,
        }),
    });

    const miniaudio_dep = b.dependency("miniaudio_c", .{ .target = target, .optimize = optimize });
    const miniaudio_lib = b.addLibrary(.{
        .name = "miniaudio",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    miniaudio_lib.addCSourceFile(.{ .file = miniaudio_dep.path("miniaudio.c"), .flags = &.{"-fno-sanitize=undefined"} });
    const miniaudio_translated = b.addTranslateC(.{
        .root_source_file = miniaudio_dep.path("miniaudio.h"),
        .target = target,
        .optimize = optimize,
    });

    const minifb_dep = b.dependency("zig_minifb", .{.target = target, .optimize = optimize });
    const minifb = minifb_dep.module("minifb");
    exe.root_module.addImport("minifb", minifb);
    exe.root_module.addImport("miniaudio_c", miniaudio_translated.createModule());
    exe.root_module.addIncludePath(b.path("src"));
    exe.root_module.addEmbedPath(b.path("assets"));
    exe.linkLibrary(miniaudio_lib);
    
    addAssets(b, exe) catch |err| {
        std.debug.panic("Failed to add assets: {}\n", .{err});
    };

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
