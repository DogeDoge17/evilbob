const minifb = @import("minifb");
const draw = @import("draw.zig");
const std = @import("std");
const input = @import("input.zig");

const screenWidth = 800;
const screenHeight = 600;

fn keyboardCallback(window: *minifb.cWindow, key: minifb.Key, mod: minifb.KeyMod, isPressed: bool) callconv(.c) void {
    _ = window;
    _ = mod;
    
    if(key == minifb.Key.Up and isPressed) {
        repeats += 1;
    } else if(key == minifb.Key.Down and isPressed) {
        if (repeats > 0) {
            repeats -= 1;
        }
    }
}

var repeats:usize = screenWidth;
pub fn main() !void {
    const cpu_count = try std.Thread.getCpuCount();
    std.debug.print("Logical cores: {}\n", .{cpu_count});
    _ = input.GetKeyDown(.A);
    _ = input.GetKey(.A);
    _ = input.GetKeyUp(.A);

    var window = minifb.Window.openEx("Evilbopb", screenWidth, screenHeight, .resizable) catch |err| {
        std.debug.print("Failed to open window: {}\n", .{err});
        return err;
    };
     
    window.onKeyboard(keyboardCallback);
    input.initHooks(&window);

    const buffer: []u32 = try std.heap.page_allocator.alloc(u32, screenWidth * screenHeight);
    defer std.heap.page_allocator.free(buffer);
    try draw.initThreading();
    draw.setBuffer(buffer, screenWidth, screenHeight);
    
    var frame:u32 = 0;
    while (true) {
        std.debug.print("FRAME {}\n", .{frame});
        input.update(frame);

        if(input.GetKeyUp(.Space)){
            std.debug.print("hi\n", .{});
        }

        // const singleStart = std.time.nanoTimestamp();
        for(0..repeats) |i| {
            draw.drawSolidVLine(minifb.argb(255, frame, 32, 67), (frame + i) % screenWidth, 0, screenHeight);
        }
        // const singleEnd = std.time.nanoTimestamp();

        // const multiStart = std.time.nanoTimestamp();
        for(0..repeats) |i| {
            draw.queueSolidVLine(minifb.argb(255, frame, 32, 67), (frame + i) % screenWidth, 0, screenHeight);
        }
        draw.waitForDraws();
        // const multiEnd = std.time.nanoTimestamp();

        // std.debug.print("{s}\t {d}ms | {d}ms\t{d} steps\n", .{ 
        //     if (singleEnd - singleStart < multiEnd - multiStart) "Single" else "Multi",
        //     (singleEnd - singleStart),
        //     multiEnd - multiStart,
        //     repeats
        // });

        

        draw.waitForDraws();
        const state = window.updateEx(buffer, screenWidth, screenHeight);
        if (state < 0) {
            break;
        }
        std.debug.print("{} - Begining waitSync()\n", .{frame});
        if ( !window.waitSync()) break;
        std.debug.print("{} - starting sleep\n", .{frame});
        std.Thread.sleep(std.time.ns_per_s  * 2);
        frame = frame +% 1;
    }
}
