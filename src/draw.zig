const std = @import("std");
pub const img = @import("image.zig");

/// Accessing the buffer is not thread safe
pub var buffer: []u32 = &[_]u32{};
pub var width: usize = 0;
pub var height: usize = 0;

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

const ScaleDirection = enum(u8) {
    up,
    down
};

// fragment shader function pointer
pub const fragment_shader = *const fn(tex: u32, args: program_args) u32;

pub const program = struct {
    fragment: fragment_shader,
    args: program_args,
};

pub const program_args = struct {
    u1: u32 = 0,
    u2: u32 = 0,
    u3: u32 = 0,
    f1: f32 = 0,
    f2: f32 = 0,
    f3: f32 = 0,
    i1: i32 = 0,
    i2: i32 = 0,
    i3: i32 = 0,   
};

pub inline fn setBuffer(newBuffer: []u32, newWidth: usize, newHeight:usize) void {
    buffer = newBuffer;
    width = newWidth;
    height = newHeight;
}

pub inline fn queueSolidVLine(color: u32, x: usize, y: usize, end: usize) void {
    threadPool.spawnWg(&waitGroup, drawSolidVLine, .{color, x, y, end});
}

pub inline fn queueTexSVLine(src_col: []const u32, shader: program, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    threadPool.spawnWg(&waitGroup, drawTexSVLine, .{src_col, shader, x, y, destHeight, srcHeight});
}
pub inline fn queueTexBVLine(src_col: []const u32, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    threadPool.spawnWg(&waitGroup, drawTexBVLine, .{src_col, x, y, destHeight, srcHeight});
}

pub fn drawSolidVLine(color: u32, x: usize, y: usize, end: usize) void {
    if (x >= width or y >= height) return;
    var idx = y * width + x;
    const yEnd = @min(end, height);
    for (y..yEnd) |_| {
        buffer[idx] = color;
        idx += width;
    }
}

pub inline fn queueBlit(src: *const img.Image, x: usize, y: usize, destWidth: usize, destHeight: usize) void {
    threadPool.spawnWg(&waitGroup, _tBlit, .{src, x, y, destWidth, destHeight});
}

fn _tBlit(src: *const img.Image, x: usize, y: usize, destWidth: usize, destHeight: usize) void {
    if (destWidth == 0 or destHeight == 0) return;
    const sw = src.width;
    const sh = src.height;
    const tw = sh;

    for (0..destWidth) |dx| {
        const xu = (dx * tw) / destWidth;
        const row_index = sh - 1 - xu;
        const row = src.pixels[row_index * sw .. (row_index + 1) * sw];

        threadPool.spawnWg(&waitGroup, drawTexBVLine,.{row,x + dx, y,destHeight, sw});
    }
}

pub fn blit(src: *const img.Image, x: usize, y: usize, destWidth: usize, destHeight: usize) void {
    if (destWidth == 0 or destHeight == 0) return;
    const sw = src.width;
    const sh = src.height;
    const tw = sh;

    for (0..destWidth) |dx| {
        const xu = (dx * tw) / destWidth;
        const row_index = sh - 1 - xu;
        const row = src.pixels[row_index * sw .. (row_index + 1) * sw];

        drawTexBVLine(row,x + dx, y,destHeight, sw);
    }
}

pub inline fn drawTexBVLine(src_col: []const u32, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    for(0..destHeight) |dy| {
        const sy = (dy * srcHeight) / destHeight;
        const pixel = src_col[sy];
        const idx = (y + dy) * width + x;

        buffer[idx] = blendOver(buffer[idx], pixel);
    }
}

pub inline fn drawTexCVLine(src_col: []const u32, color: u32, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    for(0..destHeight) |dy| {
        const sy = (dy * srcHeight) / destHeight;
        const pixel = src_col[sy];
        const idx = (y + dy) * width + x;

        buffer[idx] = pixel * color;
    }
}

pub inline fn drawTexSVLine(src_col: []const u32, shader: program, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    if (destHeight == 0 or srcHeight == 0 or src_col.len == 0) return;

    for(0..destHeight) |dy| {
        const sy = (dy * srcHeight) / destHeight;
        const pixel = src_col[sy];
        const idx = (y + dy) * width + x;

        buffer[idx] = shader.fragment(pixel, shader.args);
    }
}

inline fn blendOver(dst: u32, src: u32) u32 {
    const sa: u32 = src >> 24;
    if (sa == 0) return dst;
    if (sa == 255) return src;

    const sr: u32 = (src >> 16) & 0xff;
    const sg: u32 = (src >>  8) & 0xff;
    const sb: u32 =  src & 0xff;

    const dr: u32 = (dst >> 16) & 0xff;
    const dg: u32 = (dst >>  8) & 0xff;
    const db: u32 = dst & 0xff;
    const da: u32 = dst >> 24;

    const inv: u32 = 255 - sa;

    const r: u32 = (sr * sa + dr * inv + 127) / 255;
    const g: u32 = (sg * sa + dg * inv + 127) / 255;
    const b: u32 = (sb * sa + db * inv + 127) / 255;
    const a: u32 = (sa + da * inv + 127) / 255;

    return (a << 24) | (r << 16) | (g << 8) | b;
}

pub inline fn waitForDraws() void {
    waitGroup.wait();
    waitGroup.reset();
}
