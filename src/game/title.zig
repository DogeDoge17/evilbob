const draw = @import("../draw.zig");
const ui = @import("ui.zig");
const std = @import("std");
const scene_manager = @import("../scene.zig");
const input = @import("../input.zig");

var playButton: ui.Element = undefined;

pub fn init() !void {
    playButton = .{
        .texture = try draw.img.loadImage(std.heap.page_allocator, "assets/playbtn.tga"),
        .pos = .{ .x = 350, .y = 200 },
        .height = 90,
        .width = 100,
    };
    std.debug.print("hello\n", .{});
}

pub fn deinit() void {

}

pub fn update() void {
    // std.debug.print("{} {}\r", .{input.getMouseXA(i32), input.getMouseYA(i32)});
    if(playButton.clicked()) {
        std.debug.print("NOOOO\n", .{});
        scene_manager.loadScene(@import("survival.zig")); 
        return;
    }

    if(playButton.hovered()){
        std.debug.print("eh!\n", .{});
    }
}

pub fn render() void {
    playButton.render();
}
