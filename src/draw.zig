const std = @import("std");

/// Accessing the buffer is not thread safe
pub var buffer: []u32 = &[_]u32{};
var width: usize = 0;
var height: usize = 0;

var threadPool: std.Thread.Pool = undefined;
var waitGroup: std.Thread.WaitGroup = undefined;

pub fn initThreading() !void {
    try std.Thread.Pool.init(&threadPool, .{
        .allocator = std.heap.c_allocator,
        .n_jobs = null,
        .track_ids = false,
        .stack_size = 2024 * 2024,
    });
    waitGroup.reset();
}

pub fn setBuffer(newBuffer: []u32, newWidth: usize, newHeight:usize) void {
    buffer = newBuffer;
    width = newWidth;
    height = newHeight;
}

pub fn queueSolidVLine(color: u32, x: usize, y: usize, len: usize) void {
    threadPool.spawnWg(&waitGroup, drawSolidVLine, .{color, x, y, len});
}

pub fn drawSolidVLine(color: u32, x: usize, y: usize, len: usize) void {
    if (x >= width) return;
    var idx = y * width + x;
    const yEnd = @min(y + len, height);
    for (y..yEnd) |_| {
        buffer[idx] = color;
        idx += width;
    }
}

pub fn waitForDraws() void {
    waitGroup.wait();
    waitGroup.reset();
}
