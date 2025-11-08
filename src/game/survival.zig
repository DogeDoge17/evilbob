const renderer = @import("../render.zig");
const draw = @import("../draw.zig"); 
const evil = @import("evil.zig");
const player = @import("player.zig");
const spr = @import("../sprite.zig");
const img = @import("../image.zig");
const std = @import("std");

var camera: renderer.Camera = .{
    .dir = .{ .x = -1, .y = 0 },
    .plane = .{ .x = 0, .y = 0.95 },
    .position = .{ .x = 4, .y = 4 }
};

var bop:evil.Evil = undefined;
// var bop = evil.Evil{
//     .pos = .{ .x = 20.5, .y = 11.5 },
//     .speed = 1.0,
//     .targt = null,
//     .sprite = .{
//         .pos = .{ .x = 20.5, .y = 11.5 },
//         .texture = undefined,
//     },
// };


var evilBoob: img.Image = undefined;

pub fn init() !void {
    renderer.cam = &camera;
    player.cam = &camera;

    evilBoob = img.loadImage(std.heap.page_allocator, "assets/evilbob.tga") catch |err| {
        std.debug.panic("Failed to load evilbob.tga: {}\n", .{err});
    };
    bop = evil.Evil.init(renderer.curr_sprites, .{ .x = 0.5, .y = 0.5 }, 2, &evilBoob);
    bop.targt = &player.cam.position;
    renderer.curr_sprites.add(&bop.sprite) catch |err| {
            @import("std").debug.panic("Failed to add evil sprite {}", .{err});
    };

    // bop.sprite.texture = &renderer.textureMap[1];
    // renderer.curr_sprites.add(&bop.sprite) catch |err| {
    //     return err;
    // };
}

pub fn deinit() void {
    
}

pub fn update() void {
    player.update();
    bop.update();

    if (bop.checkKill()) { @import("../scene.zig").loadScene(@import("title.zig")); return; }
}

pub fn render() void {
    draw.waitForDraws();
    renderer.render(); 
}
