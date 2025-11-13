const renderer = @import("../render.zig");
const draw = @import("../draw.zig"); 
const evil = @import("evil.zig");
const player = @import("player.zig");
const spr = @import("../sprite.zig");
const img = @import("../image.zig");
const std = @import("std");

var camera: renderer.Camera = undefined;
var bop:evil.Evil = undefined;
var evilBoob: img.Assets = .evilbob;


pub fn init() !void {
    camera = .{
        .dir = .{ .x = 0, .y = -1 },
        .plane = .{ .x = -1, .y = 0 },
        .position = .{ .x = 13, .y = 31 }
    };

    renderer.cam = &camera;
    player.cam = &camera;

    // evilBoob = img.loadImage(std.heap.page_allocator, "evilbob") catch |err| {
    //     std.debug.panic("Failed to load evilbob.tga: {}\n", .{err});
    // };
    bop = evil.Evil.init(renderer.curr_sprites, .{ .x = 0.5, .y = 0.5 }, 2, evilBoob);
    bop.targt = &player.cam.position;
    renderer.curr_sprites.add(&bop.sprite) catch |err| {
            @import("std").debug.panic("Failed to add evil sprite {}", .{err});
    };

    player.init();
}

pub fn deinit() void {
        
}

pub fn update() void {
    player.update();
    bop.update();

    if (bop.checkKill()) { @import("../scene.zig").loadScene(@import("jumpscare.zig")); return; }
}

pub fn render() void {
    draw.waitForDraws();
    renderer.render(); 
}


pub fn postRender() void {}
