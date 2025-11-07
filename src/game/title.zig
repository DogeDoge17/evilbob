const draw = @import("../draw.zig");
const ui = @import("ui.zig");
const std = @import("std");

var playButton: ui.Element = undefined;

pub fn init() !void {
    playButton = .{
        .texture = try draw.img.loadImage(std.heap.page_allocator, "assets/playbtn.tga"),
        .x = 0,
        .y = 0,
        .height = 90,
        .width = 100,
    };
    std.debug.print("hello\n", .{});
}

pub fn deinit() void {

}

pub fn update() void {

}

pub fn render() void {
    playButton.render();
}
