const std = @import("std");
const renderer = @import("../render.zig");
const sprite = @import("../sprite.zig");
const time = @import("../time.zig");
const scene = @import("../scene.zig");

var camera: renderer.Camera = undefined;
var win_bob: *sprite.Sprite = undefined;
var skybox: *renderer.img.Image = undefined;
pub fn init() void {
    camera = .{
        .dir = .{ .x = 0, .y = -1 },
        .plane = .{ .x = -1, .y = 0 },
        .position = .{ .x = 13, .y = 33 }
    };
    progress = 0;
    velocity = 0.5;
    black_wait = 0.5;

    renderer.cam = &camera;

    skybox = renderer.img.image_cache.items[@as(usize, @intFromEnum(renderer.img.Assets.skybox))];

    renderer.curr_sprites.reset();
    win_bob = renderer.curr_sprites.createSprite(std.heap.page_allocator, .{ .x = 13, .y = 31 }, .win_bob) catch |err| {
        std.debug.panic("Failed to create win_bob sprite: {}\n", .{err});
    };
}

pub fn deinit() void {
    std.heap.page_allocator.destroy(win_bob);
}

const opacity_img: renderer.img.Image = .{
    .width = 1,
    .height = 1,
    .pixels = &opacity_pixel_storage,
};
var opacity_pixel_storage: [1]u32 = .{ 0x00000000 };



var progress: f32 = 0;
var velocity: f32 = 0.35;
var black_wait: f32 = 0.5;
pub fn update() void {
    if(renderer.extractColors(opacity_img.pixels[0])[0] >= 255) {
        black_wait -= time.deltaTime;
        if (black_wait <= 0) {
            scene.loadScene(@import("title.zig"));
        }
        return;
    }

    progress += time.deltaTime;
    
    camera.position.y += velocity * time.deltaTime;
    if (progress > 6 or camera.position.y > renderer.mapHeight - 1) {
        camera.position.y = renderer.mapHeight - 1;
    }

    if(progress > 4) {

        const argb = renderer.extractColors(opacity_img.pixels[0]);
        const pixel: *u32 = &opacity_pixel_storage[0];

        const fa = @as(f32, @floatFromInt(argb[0]));
        const newAlpha = @min(fa + 255 * time.deltaTime, 255);
            
        pixel.* = renderer.combineColors(
            @as(u8, @intFromFloat(newAlpha)), 
            argb[1],
            argb[2],
            argb[3],
        );
    }
    
    if (progress > 2) {
        velocity += 5.0 * time.deltaTime;
    }
}

pub fn render() void {
    renderer.draw.waitForDraws();
    @memcpy(renderer.draw.buffer, skybox.pixels);
    renderer.render(); 
    renderer.draw.blit(&opacity_img, 0xFFFFFFFF, 0, 0, renderer.draw.width, renderer.draw.height);
}

pub fn postRender() void {

}
