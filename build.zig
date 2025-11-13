const std = @import("std");

fn addAssets(b: *std.Build, exe: *std.Build.Step.Compile) !void {
    // const assets = [_]struct { []const u8, []const u8 }{
    //     .{ "assets/sponge-walk.mp3", "sponge-walk" },
    //     .{ "assets/im-evil-fella.mp3", "im-evil-fella" },
    //     .{ "assets/im-evil-spongebob.mp3", "im-evil-spongebob" },
    //     .{ "assets/playbtn.tga", "playbtn" },
    //     .{ "assets/comic.tga", "comic_tga" },
    //     .{ "assets/comic.tga", "comic_tga" },
    //     .{ "assets/evilbob.tga", "evilbob" },
    //     .{ "assets/wall1.tga", "wall1" },
    //     .{ "assets/door.tga", "door" },
    //     .{ "assets/window.tga", "window" },
    //     .{ "assets/food-window.tga", "food_window" },
    //     .{ "assets/fence.tga", "fence" },
    //     .{ "assets/wood.tga", "wood" },
    //     .{ "assets/wood-door.tga", "wood_door" },
    //     .{ "assets/main-door-l.tga", "main_door_l" },
    //     .{ "assets/main-door-r.tga", "main_door_r"}, 
    // };   
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
        std.debug.print("Adding asset: {s} as {s}\n", .{path, name});
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
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "evilbob", .module = mod },
            },
        }),
    });
    const zaudio = b.dependency("zaudio", .{});

    const minifb_dep = b.dependency("zig_minifb", .{.target = target, .optimize = optimize });
    const minifb = minifb_dep.module("minifb");
    exe.root_module.addImport("minifb", minifb);
    exe.root_module.addIncludePath(b.path("src"));
    exe.root_module.addEmbedPath(b.path("assets"));
    exe.root_module.addImport("zaudio", zaudio.module("root"));
    exe.linkLibrary(zaudio.artifact("miniaudio"));
    exe.linkLibC();
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
