const std = @import("std");
pub const img = @import("image.zig");
const math = @import("math.zig");

/// Accessing the buffer is not thread safe
pub var buffer: []u32 = &[_]u32{};
var columnMutex: []std.Thread.Mutex = &[_]std.Thread.Mutex{};
pub var width: usize = 0;
pub var height: usize = 0;

var threadPool: std.Thread.Pool = undefined;
var waitGroup: std.Thread.WaitGroup = undefined;

pub fn initThreading() !void {
    try std.Thread.Pool.init(&threadPool, .{
        .allocator = std.heap.c_allocator,
        .n_jobs = null,
        .track_ids = true,
        .stack_size = 2024 * 2024,
    });
    waitGroup.reset();
}

pub const fragment_shader = *const fn(pixel: u32, args: program_args) u32;
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
    
    if(columnMutex.len != 0) {
        std.heap.c_allocator.free(columnMutex);
    }

    columnMutex = std.heap.c_allocator.alloc(std.Thread.Mutex, width) catch |err| {
        std.debug.panic("Failed to allocate memory {}", .{err});
    };
    for (columnMutex) |*mutex| {
        mutex.* = std.Thread.Mutex{};
    }
}

pub inline fn queueAny(comptime func: anytype, args: anytype) void {
    threadPool.spawnWg(&waitGroup, func, args);
}

pub inline fn queueSolidVLine(color: u32, x: usize, y: usize, end: usize) void {
    threadPool.spawnWg(&waitGroup, drawSolidVLine, .{color, x, y, end});
}

pub inline fn queueTexSVLine(src_col: []const u32, shader: program, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    threadPool.spawnWg(&waitGroup, drawTexSVLine, .{src_col, shader, x, y, destHeight, srcHeight});
}
pub inline fn queueTexBVLine(src_col: []const u32, color:u32, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    threadPool.spawnWg(&waitGroup, drawTexBVLine, .{src_col, color, x, y, destHeight, srcHeight});
}

pub fn drawSolidVLine(color: u32, x: usize, y: usize, end: usize) void {
    if (x >= width or y >= height) return;
    const yEnd = @min(end, height);
    if (y >= yEnd) return;

    columnMutex[x].lock();
    defer columnMutex[x].unlock();

    var idx = y * width + x;
    for (y..yEnd) |_| {
        buffer[idx] = color;
        idx += width;
    }
}

pub inline fn queueBlit(src: *const img.Image, color: u32, x: usize, y: usize, destWidth: usize, destHeight: usize) void {
    threadPool.spawnWg(&waitGroup, _tBlit, .{src, color, x, y, destWidth, destHeight});
}

pub inline fn queueBlitR(texture: *const img.Image, color: u32, dest: math.Rectangle(usize), src: math.Rectangle(usize)) void {
    threadPool.spawnWg(&waitGroup, _tBlitR, .{texture, color, dest, src});
}

pub inline fn queueBlitS(texture: *const img.Image, shader: program, dest: math.Rectangle(usize), src: ?math.Rectangle(usize)) void {
    threadPool.spawnWg(&waitGroup, _tBlitS, .{texture, shader, dest, src});
}

fn _tBlit(src: *const img.Image, color: u32, x: usize, y: usize, destWidth: usize, destHeight: usize) void {
    if (destWidth == 0 or destHeight == 0) return;
    const sw = src.width;
    const sh = src.height;
    const tw = sh;

    for (0..destWidth) |dx| {
        const xu = (dx * tw) / destWidth;
        const row_index = sh - 1 - xu;
        const row = src.pixels[row_index * sw .. (row_index + 1) * sw];

        threadPool.spawnWg(&waitGroup, drawTexBVLine,.{row, color, x + dx, y,destHeight, sw});
    }
}
pub fn _tBlitR(texture: *const img.Image, color: u32, dest: math.Rectangle(usize), src: math.Rectangle(usize)) void {
    if (dest.width == 0 or dest.height == 0 or src.width == 0 or src.height == 0) return;

    const sw = texture.width;
    const sh = texture.height;

    const orig_w = sh; 
    const orig_h = sw;

    const src_x0 = src.x;
    const src_y0 = src.y;
    var src_x1 = src.x + src.width;
    var src_y1 = src.y + src.height;

    if (src_x0 >= orig_w or src_y0 >= orig_h) return;
    if (src_x1 > orig_w) src_x1 = orig_w;
    if (src_y1 > orig_h) src_y1 = orig_h;
    if (src_x1 <= src_x0 or src_y1 <= src_y0) return;

    const crop_w = src_x1 - src_x0;
    const crop_h = src_y1 - src_y0;
    for (0..dest.width) |dx| {
        const u = src_x0 + (dx * crop_w) / dest.width;
        const row_index = sh - 1 - u; 
        const full_row = texture.pixels[row_index * sw .. (row_index + 1) * sw];
        const row_slice = full_row[src_y0 .. src_y1];

        threadPool.spawnWg(&waitGroup, drawTexBVLine, .{row_slice, color, dest.x + dx, dest.y, dest.height, crop_h});
    }
}

pub fn _tBlitS(texture: *const img.Image, shader: program, dest: math.Rectangle(usize), src: ?math.Rectangle(usize)) void {
    const src_rect = src orelse math.Rectangle(usize){
        .x = 0,
        .y = 0,
        .width = texture.height,
        .height = texture.width,
    };

    if (dest.width == 0 or dest.height == 0 or src_rect.width == 0 or src_rect.height == 0) return;

    const sw = texture.width;
    const sh = texture.height;

    const orig_w = sh; 
    const orig_h = sw;

    const src_x0 = src_rect.x;
    const src_y0 = src_rect.y;
    var src_x1 = src_rect.x + src_rect.width;
    var src_y1 = src_rect.y + src_rect.height;

    if (src_x0 >= orig_w or src_y0 >= orig_h) return;
    if (src_x1 > orig_w) src_x1 = orig_w;
    if (src_y1 > orig_h) src_y1 = orig_h;
    if (src_x1 <= src_x0 or src_y1 <= src_y0) return;

    const crop_w = src_x1 - src_x0;
    const crop_h = src_y1 - src_y0;
    for (0..dest.width) |dx| {
        const u = src_x0 + (dx * crop_w) / dest.width;
        const row_index = sh - 1 - u; 
        const full_row = texture.pixels[row_index * sw .. (row_index + 1) * sw];
        const row_slice = full_row[src_y0 .. src_y1];

        threadPool.spawnWg(&waitGroup, drawTexSVLine, .{row_slice, shader, dest.x + dx, dest.y, dest.height, crop_h});
    }
}
pub fn blitS(texture: *const img.Image, shader: program, dest: math.Rectangle(usize), src: math.Rectangle(usize)) void {
    if (dest.width == 0 or dest.height == 0 or src.width == 0 or src.height == 0) return;

    const sw = texture.width;
    const sh = texture.height;

    const orig_w = sh; 
    const orig_h = sw;

    const src_x0 = src.x;
    const src_y0 = src.y;
    var src_x1 = src.x + src.width;
    var src_y1 = src.y + src.height;

    if (src_x0 >= orig_w or src_y0 >= orig_h) return;
    if (src_x1 > orig_w) src_x1 = orig_w;
    if (src_y1 > orig_h) src_y1 = orig_h;
    if (src_x1 <= src_x0 or src_y1 <= src_y0) return;

    const crop_w = src_x1 - src_x0;
    const crop_h = src_y1 - src_y0;
    for (0..dest.width) |dx| {
        const u = src_x0 + (dx * crop_w) / dest.width;
        const row_index = sh - 1 - u; 
        const full_row = texture.pixels[row_index * sw .. (row_index + 1) * sw];
        const row_slice = full_row[src_y0 .. src_y1];

        drawTexSVLine(row_slice, shader, dest.x + dx, dest.y, dest.height, crop_h);
    }
}


/// Crops then blits an image onto the framebuffer
pub fn blitR(texture: *const img.Image, color: u32, dest: math.Rectangle(usize), src: math.Rectangle(usize)) void {
    if (dest.width == 0 or dest.height == 0 or src.width == 0 or src.height == 0) return;

    const sw = texture.width;
    const sh = texture.height;

    const orig_w = sh; 
    const orig_h = sw;

    const src_x0 = src.x;
    const src_y0 = src.y;
    var src_x1 = src.x + src.width;
    var src_y1 = src.y + src.height;

    if (src_x0 >= orig_w or src_y0 >= orig_h) return;
    if (src_x1 > orig_w) src_x1 = orig_w;
    if (src_y1 > orig_h) src_y1 = orig_h;
    if (src_x1 <= src_x0 or src_y1 <= src_y0) return;

    const crop_w = src_x1 - src_x0;
    const crop_h = src_y1 - src_y0;
    for (0..dest.width) |dx| {
        const u = src_x0 + (dx * crop_w) / dest.width;
        const row_index = sh - 1 - u; 
        const full_row = texture.pixels[row_index * sw .. (row_index + 1) * sw];
        const row_slice = full_row[src_y0 .. src_y1];

        drawTexBVLine(row_slice, color, dest.x + dx, dest.y, dest.height, crop_h);
    }
}

/// Blits an image onto the framebuffer
pub fn blit(src: *const img.Image, color: u32, x: usize, y: usize, destWidth: usize, destHeight: usize) void {
    if (destWidth == 0 or destHeight == 0) return;
    const sw = src.width;
    const sh = src.height;
    const tw = sh;

    for (0..destWidth) |dx| {
        const xu = (dx * tw) / destWidth;
        const row_index = sh - 1 - xu;
        const row = src.pixels[row_index * sw .. (row_index + 1) * sw];

        drawTexBVLine(row, color, x + dx, y, destHeight, sw);
    }
}

/// Draws a vertical line with texture mapping and alpha blending
pub inline fn drawTexBVLine(src_col: []const u32, color: u32, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    if (x >= width or y >= height or destHeight == 0 or srcHeight == 0) return;
    columnMutex[x].lock();
    defer columnMutex[x].unlock();
    
    for(0..destHeight) |dy| {
        const sy = (dy * srcHeight) / destHeight;
        const pixel = modulate(src_col[sy], color);
        const idx = (y + dy) * width + x;

        if (idx >= buffer.len) return;
        buffer[idx] = blendOver(buffer[idx], pixel);
    }
}

/// Draws a vertical line with texture mapping and color modulation
pub inline fn drawTexCVLine(src_col: []const u32, color: u32, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    if (x >= width or y >= height or destHeight == 0 or srcHeight == 0) return;
    if (y + destHeight > height) return;
    columnMutex[x].lock();
    defer columnMutex[x].unlock();

    for(0..destHeight) |dy| {
        const sy = (dy * srcHeight) / destHeight;
        const pixel = src_col[sy];
        const idx = (y + dy) * width + x;

        buffer[idx] = pixel * color;
    }
}

/// Draws a vertical line with texture mapping and a fragment shader
pub inline fn drawTexSVLine(src_col: []const u32, shader: program, x: usize, y: usize, destHeight: usize, srcHeight: usize) void {
    if (x >= width or y >= height or destHeight == 0 or srcHeight == 0 or src_col.len == 0) return;
    columnMutex[x].lock();
    defer columnMutex[x].unlock();

    for(0..destHeight) |dy| {
        const sy = (dy * srcHeight) / destHeight;
        const pixel = src_col[sy];
        const idx = (y + dy) * width + x;

        if (idx >= buffer.len) return;
        buffer[idx] = shader.fragment(pixel, shader.args);
    }
}

/// Alpha blends src over dsr
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

inline fn modulate(src: u32, tint: u32) u32 {
    const sa = (src >> 24) & 0xff;
    const sr = (src >> 16) & 0xff;
    const sg = (src >> 8) & 0xff;
    const sb = src & 0xff;

    const ta = (tint >> 24) & 0xff;
    const tr = (tint >> 16) & 0xff;
    const tg = (tint >> 8) & 0xff;
    const tb = tint & 0xff;

    // Modulate RGB, preserve src alpha
    const a = (sa * ta) / 255;
    const r = (sr * tr) / 255;
    const g = (sg * tg) / 255;
    const b = (sb * tb) / 255;
    return (a << 24) | (r << 16) | (g << 8) | b;
}
// probably could be done better with rangees on the x or somthing but idk
pub inline fn waitForDraws() void {
    waitGroup.wait();
    waitGroup.reset();
}
