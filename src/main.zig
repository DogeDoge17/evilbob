const minifb = @import("minifb");
const draw = @import("draw.zig");
const std = @import("std");
const input = @import("input.zig");
const image = @import("image.zig");
const render = @import("render.zig");

const screenWidth = 800;
const screenHeight = 600;

fn windowResizeCallback(window: *minifb.cWindow, width: i32, height: i32) callconv(.c) void {
    std.debug.print("Window resized to {}x{}\n", .{width, height});
    _ = minifb.c.mfb_set_viewport_best_fit(window, @as(c_uint, @intCast(screenWidth)), @as(c_uint, @intCast(screenHeight)));
}

pub fn main() !void {
    // const evilboob = try image.loadImage(std.heap.page_allocator, "assets/evilbob.tga");
    const skybox = try image.loadImage(std.heap.page_allocator, "assets/awesome-skybox.tga");

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
    
    var time: i64 = 0;
    var oldTime: i64 = 0;
    var frame:u32 = 0;
    while (true) {
        oldTime = time;
        time = std.time.milliTimestamp();
        const deltaTime: f32 = @as(f32, @floatFromInt(time - oldTime)) / 1000.0;
        std.debug.print("{}\r", .{ 1.0 / deltaTime});
        
        input.update(frame);

        const moveSpeed = deltaTime * 5;
        const rotationSpeed = deltaTime * 3;

        if(input.getKey(.S)) {
            if(render.getMapTileSafe(cam.position.x - cam.dir.x * moveSpeed, cam.position.y) orelse 0 == 0)
                cam.position.x -= cam.dir.x * moveSpeed;
            if (render.getMapTileSafe(cam.position.x, cam.position.y - cam.dir.y * moveSpeed) orelse 0 == 0)
                cam.position.y -= cam.dir.y * moveSpeed;
        } else if(input.getKey(.W)) {
            if(render.getMapTileSafe(cam.position.x + cam.dir.x * moveSpeed, cam.position.y) orelse 0 == 0)
                cam.position.x += cam.dir.x * moveSpeed;
            if (render.getMapTileSafe(cam.position.x, cam.position.y + cam.dir.y * moveSpeed) orelse 0 == 0)
                cam.position.y += cam.dir.y * moveSpeed;
        }
        if (input.getKey(.D)) {
            // if (cam.position.x >= 4)
                // cam.position.x -= 4;
            const oldDirX = cam.dir.x;
            cam.dir.x = cam.dir.x * @cos(-rotationSpeed) - cam.dir.y * @sin(-rotationSpeed);
            cam.dir.y = oldDirX * @sin(-rotationSpeed) + cam.dir.y * @cos(-rotationSpeed);
            const oldPlaneX = cam.plane.x;
            cam.plane.x = cam.plane.x * @cos(-rotationSpeed) - cam.plane.y * @sin(-rotationSpeed);
            cam.plane.y = oldPlaneX * @sin(-rotationSpeed) + cam.plane.y * @cos(-rotationSpeed);

        } else if(input.getKey(.A)) {
             const oldDirX = cam.dir.x;
            cam.dir.x = cam.dir.x * @cos(rotationSpeed) - cam.dir.y * @sin(rotationSpeed);
            cam.dir.y = oldDirX * @sin(rotationSpeed) + cam.dir.y * @cos(rotationSpeed);
            const oldPlaneX = cam.plane.x;
            cam.plane.x = cam.plane.x * @cos(rotationSpeed) - cam.plane.y * @sin(rotationSpeed);
            cam.plane.y = oldPlaneX * @sin(rotationSpeed) + cam.plane.y * @cos(rotationSpeed);
        }

        // @memset(buffer, minifb.argb(255, frame, 32, 67));
        // @memset(buffer, minifb.argb(255, 0, 0, 0));

        draw.queueBlit(&skybox, 0, 0, screenWidth, screenHeight);
        draw.waitForDraws();
         // draw.queueSolidVLine(minifb.argb(255, frame, 32, 67), (frame + i) % screenWidth, 0, screenHeight);

        // draw.queueBlit(&evilboob, @as(usize, @intFromFloat(cam.position.x)), @as(usize, @intFromFloat(cam.position.y)), 56, 56);
        // draw.waitForDraws();
        render.render();
        draw.waitForDraws();

        const state = window.updateEx(buffer, screenWidth, screenHeight);
        // _ = window.setViewportBestFit(screenWidth, screenHeight);
        if (state < 0) {
            break;
        }

        frame = frame +% 1;
        if ( !window.waitSync()) break;
    }
}
