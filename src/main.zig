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

    std.debug.print("Window resized to {}x{} {} {}\n", .{width, height, input.mx_offset, input.my_offset});
}
pub fn main() !void {
    const evilboob = try image.loadImage(std.heap.page_allocator, "assets/evilbob.tga");
    // const testSpr = try image.loadImage(std.heap.page_allocator, "assets/test.tga");
    defer evilboob.deinit(std.heap.page_allocator);
    const skybox = try image.loadImage(std.heap.page_allocator, "assets/awesome-skybox.tga");
    defer skybox.deinit(std.heap.page_allocator);
    render.textureMap = [5]image.Image{ skybox, evilboob, skybox, evilboob, evilboob };

    sceneManager.loadScene(@import("game/title.zig"));

    var theContainer = sprite.SpriteContainer{
        .sprites = std.AutoArrayHashMap(usize, *sprite.Sprite).init(std.heap.page_allocator),
    };
    render.curr_sprites = &theContainer;

    var evilSprite = sprite.Sprite{
        .pos = .{ .x = 5.5, .y = 5.5 },
        .texture = &evilboob,
    };
    try theContainer.add(&evilSprite);

    var font = try render.Font.load(std.heap.page_allocator, "assets/comic");
    defer font.deinit(std.heap.page_allocator);

    var window = minifb.Window.openEx("Evilbopb", screenWidth, screenHeight, .resizable) catch |err| {
        std.debug.print("Failed to open window: {}\n", .{err});
        return err;
    };
     
    var cam: render.Camera = .{ 
        .dir = .{ .x = -1, .y = 0 }, 
        .plane = .{ .x = 0, .y = 0.95 }, 
        .position = .{ .x = 4, .y = 4}
    }; 
    render.cam = &cam;

    window.onResize(windowResizeCallback);
    try input.initInput(&window, std.heap.page_allocator);

    const buffer: []u32 = try std.heap.page_allocator.alloc(u32, screenWidth * screenHeight);
    defer std.heap.page_allocator.free(buffer);
    try draw.initThreading();
    draw.setBuffer(buffer, screenWidth, screenHeight);
   
    try title.init();

    while (true) {
        time.update(); 
        input.update(time.frame);

        sceneManager.update();

        draw.waitForDraws();
        @memset(buffer, minifb.argb(255, 0, 0, 0));

        draw.waitForDraws();
        sceneManager.render();

        draw.waitForDraws();
        try font.renderStringF(minifb.argb(255, 255, 255, 255), 0, screenHeight-20, 12, "FPS: {d:.2}", .{time.fps});
        try font.renderStringF(minifb.argb(255, 255, 255, 255), 0, 0, 12, "({}, {})", .{input.getMouseXA(i32), input.getMouseYA(i32)});


        draw.waitForDraws(); // always wait before submitting
        if (window.updateEx(buffer, screenWidth, screenHeight) < 0) { break; }
        if ( !window.waitSync()) break;
    }
}
