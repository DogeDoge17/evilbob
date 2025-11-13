const minifb = @import("minifb");
const draw = @import("draw.zig");
const std = @import("std");
const input = @import("input.zig");
const image = @import("image.zig");
const render = @import("render.zig");
const sprite = @import("sprite.zig");
const title = @import("game/title.zig");
const sceneManager = @import("scene.zig");
const time = @import("time.zig");
const math = @import("math.zig");
const audio = @import("audio.zig");

const screenWidth = 800;
const screenHeight = 600;

fn windowResizeCallback(window: *minifb.cWindow, width: i32, height: i32) callconv(.c) void {
    const w = @as(f32, @floatFromInt(width));
    const h = @as(f32, @floatFromInt(height));

    const screenAspectRatio = @as(f32, screenWidth) / @as(f32, screenHeight);
    const contentAspectRatio = w / h;
    if (contentAspectRatio > screenAspectRatio) {
        const newWidth = h * screenAspectRatio;
        const offsetX = (w - newWidth) / 2;

        _ = minifb.c.mfb_set_viewport_best_fit(window, @as(c_uint, @intCast(screenWidth)), @as(c_uint, @intCast(screenHeight)));
        input.mx_offset = @as(i32, @intFromFloat(offsetX));
        input.my_offset = 0;
    } else {
        const newHeight = w / screenAspectRatio;
        const offsetY =  (h - newHeight) / 2;

        _ = minifb.c.mfb_set_viewport_best_fit(window, @as(c_uint, @intCast(screenWidth)), @as(c_uint, @intCast(screenHeight)));
        input.mx_offset = 0;
        input.my_offset = @as(i32, @intFromFloat(offsetY));        
    }

    input.mx_multiplier = @as(f32, screenWidth) / (w - @as(f32, @floatFromInt(input.mx_offset)) * 2);
    input.my_multiplier = @as(f32, screenHeight) / (h - @as(f32, @floatFromInt(input.my_offset)) * 2);

    std.debug.print("Window resized to {}x{} {} {}\n", .{width, height, input.mx_offset, input.my_offset});
}
pub fn main() !void {
    var window = minifb.Window.openEx("Evilbopb", screenWidth, screenHeight, .resizable) catch |err| {
        std.debug.print("Failed to open window: {}\n", .{err});
        return err;
    };
    window.onResize(windowResizeCallback);

    try input.initInput(&window, std.heap.page_allocator);
    try draw.initThreading();
    try image.init();
    audio.init();

    const buffer: []u32 = try std.heap.page_allocator.alloc(u32, screenWidth * screenHeight);
    defer std.heap.page_allocator.free(buffer);
    draw.setBuffer(buffer, screenWidth, screenHeight);

    render.tiles = .{
        .{ .t_type = .AR, .texture = null, .solid = false },
        .{ .t_type = .WL, .texture = .wall1, },
        .{ .t_type = .DR, .texture = .door, .solid = false },
        .{ .t_type = .WN, .texture = .window, },
        .{ .t_type = .FW, .texture = .food_window, },
        .{ .t_type = .FN, .texture = .fence, },
        .{ .t_type = .WD, .texture = .wood, },
        .{ .t_type = .KK, .texture = .wood, .directional = true, .e_texture = .wood, .w_texture =  .wall1},
        .{ .t_type = .KD, .texture = .door,.solid = false, .directional = true, .e_texture = .wood_door, .w_texture =  .door},
        .{ .t_type = .D1, .texture = .main_door_l, .solid = false  },
        .{ .t_type = .D2, .texture = .main_door_r, .solid = false  },
    };
    var cam: render.Camera = .{ 
        .dir = .{ .x = -1, .y = 0 }, 
        .plane = .{ .x = 0, .y = 0.95 }, 
        .position = .{ .x = 4, .y = 4}
    }; 
    render.cam = &cam;

    render.the_font = try render.Font.load(std.heap.page_allocator);

    var theContainer = sprite.SpriteContainer{
        .sprites = std.AutoArrayHashMap(usize, *sprite.Sprite).init(std.heap.page_allocator),
    };
    render.curr_sprites = &theContainer;

    sceneManager.loadScene(@import("game/title.zig"));
    while (true) {
        time.update(); 
        input.update(time.frame);

        sceneManager.update();

        draw.waitForDraws();
        @memset(buffer, minifb.argb(255, 0, 0, 0));

        draw.waitForDraws();
        sceneManager.render();

        draw.waitForDraws();
        sceneManager.postRender();


        draw.waitForDraws();
        try render.the_font.renderStringF(minifb.argb(255, 255, 0, 0), 0, screenHeight-20, 12, "FPS: {d:.2}", .{time.fps});

        draw.waitForDraws(); // always wait before submitting
        if (window.updateEx(buffer, screenWidth, screenHeight) < 0) { break; }
        if ( !window.waitSync()) break;
    }
}
