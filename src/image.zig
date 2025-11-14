const std = @import("std");
const draw = @import("draw.zig");
// const image_uris = [_][:0]const u8{
//     "evilbob",
//     "door",
//     "wall1",
//     "window",
//     "fence",
//     "wood",
//     "main_door_l",
//     "main_door_r",
//     "food_window",
//     "wood_door",
//     "playbtn",
//     "comic",
// };
// const image_uris = [_][:0]const u8{
// "evilbob",
// "wall1",
// "door",
// "window",
// "fence",
// "wood",
// "wood_door",
// "main_door_l",
// "main_door_r",
// "food_window",
// "comic",
// "playbtn",
// };
const image_uris = [_][:0]const u8{
    "evilbob",
    "test",
    "door",
    "wall1",
    "window",
    "fence",
    "wood",
    "main_door_l",
    "main_door_r",
    "food_window",
    "table_clean",
    "table_dirty",
    "wood_door",
    "dumpster",
    "toliet",
    "sink",
    "dumpster_finished",
    "safe_wall",
    "krabs_furn",
    "skybox",
    "kitchen_sink_clean",
    "kitchen_sink",
    "count_finish",
    "count",
    "playbtn",
    "tasks_btn",
    "task_bg",
    "win_bob",
    "trash_full",
    "trash",
    "grill",
    "sand",
    "comic",
};

pub const Image = struct {
    width: usize,
    height: usize,
    pixels: []const u32,
    pub fn deinit(self: *const Image, alloc: std.mem.Allocator) void {
        alloc.free(self.pixels);
    }
};

pub const Assets = blk: {
    var fields: [image_uris.len]std.builtin.Type.EnumField = undefined;

    for (image_uris, 0..) |name, i| {
        fields[i] = .{ .name = name, .value = i };
    }

    const enumInfo = std.builtin.Type.Enum{
        .tag_type = usize,
        .fields = &fields,
        .decls = &[0]std.builtin.Type.Declaration{},
        .is_exhaustive = false,
    };
    break:blk @Type(std.builtin.Type{ .@"enum" = enumInfo });
};

pub fn init() !void {
    fba = std.heap.FixedBufferAllocator.init(image_ptr_space[0..]); 
    image_cache = try std.ArrayList(*Image).initCapacity(std.heap.page_allocator, @typeInfo(Assets).@"enum".fields.len + 10);

    inline for(0..image_uris.len) |i| {
        draw.queueAny(preloadImage, .{std.heap.page_allocator, image_uris[i], i});
    }
    draw.waitForDraws();
}

inline fn preloadImage(alloc: std.mem.Allocator, comptime path: []const u8, id: usize) void {
    _ = loadImageFull(alloc, @embedFile(path), id) catch |err| {
        std.debug.panic("Couldnt preload {}", .{err});
    };
}

pub fn getImage(image_id: anytype) ?*Image {
    const idx = @as(usize, switch(@typeInfo(@TypeOf(image_id))) {
        .float => @intFromFloat(image_id),
        .int =>  @intCast(image_id),
        .@"enum" => @intFromEnum(image_id),
        else => return null
    });

    if (idx >= image_cache.items.len) {
        return null;
    }
    return image_cache.items[idx];
}

pub fn getDimensions(image_id: anytype) ? struct {width: usize, height: usize} {
    const img = getImage(image_id) orelse return null;
    return .{ .width = img.width, .height = img.height };
}

pub var image_cache:std.ArrayList(*Image) = undefined;
var image_cache_mutex:std.Thread.Mutex = .{};
var image_ptr_space: [ @typeInfo(Assets).@"enum".fields.len * @sizeOf(Image) * 2]u8 = undefined;
var fba:std.heap.FixedBufferAllocator = undefined;
pub inline fn loadImage(alloc: std.mem.Allocator, comptime path: []const u8) !usize { 
    return loadImageFull(alloc, std.fmt.comptimePrint("assets/{s}.tga", .{path}));
}

pub fn loadImageFile(alloc: std.mem.Allocator, path: []const u8,id: Assets) !usize {
     std.debug.print("path: {s}\n", .{path});
    if (image_cache.get(path)) |img| {
        return img;
    }

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const imagedata = try file.readToEndAlloc(alloc, 10 * 4024 * 4024); 
    defer alloc.free(imagedata);
    
    return loadImageFile(alloc, imagedata, id);
}

pub fn loadImageFull(alloc: std.mem.Allocator, image_data: []const u8, id: ?usize) !usize{
    if (image_data[2] != 2) return error.invalidformat;

    const width  = @as(u16, image_data[12]) | (@as(u16, image_data[13]) << 8);
    const height = @as(u16, image_data[14]) | (@as(u16, image_data[15]) << 8);
    const pixel_depth: u8 = image_data[16];
    const bpp: usize = pixel_depth / 8;
    const descriptor = image_data[17];
    const top_origin = ((descriptor >> 5) & 1) == 1;

    const id_len = image_data[0];
    const color_map_type = image_data[1];
    const color_map_len = @as(u16, image_data[5]) | (@as(u16, image_data[6]) << 8);
    const color_map_depth = image_data[7];
    var pixel_offset: usize = 18 + id_len;
    if (color_map_type == 1) {
        pixel_offset += @as(usize, color_map_len) * (color_map_depth / 8);
    }

    const pixel_data_len = @as(usize, width) * @as(usize, height) * bpp;
    const pixel_data = image_data[pixel_offset .. pixel_offset + pixel_data_len];

    var pixels = try alloc.alloc(u32, @as(usize, width) * @as(usize, height));

    var si: usize = 0;
    for(0..height) |y| {
        const dy = if (top_origin) y else (height - 1 - y);
        for(0..width) |x| {
            if (bpp == 4) {
                const bgra = std.mem.readInt(u32, pixel_data[si ..][0..4], .little);
                const b =  bgra        & 0xff;
                const g = (bgra >> 8)  & 0xff;
                const r = (bgra >> 16) & 0xff;
                const a = (bgra >> 24) & 0xff;
                pixels[dy * width + x] = (@as(u32, a) << 24)
                    | (@as(u32, r) << 16)
                    | (@as(u32, g) << 8)
                    |  @as(u32, b);
                si += 4;
            } else if (bpp == 3) {
                const b = pixel_data[si + 0];
                const g = pixel_data[si + 1];
                const r = pixel_data[si + 2];
                pixels[dy * width + x] = 0xff00_0000
                    | (@as(u32, r) << 16)
                    | (@as(u32, g) << 8)
                    |  @as(u32, b);
                si += 3;
            } else {
                return error.unsupportedpixeldepth;
            }
        }
    }

    const laimg = fba.threadSafeAllocator().create(Image) catch |err| {
        alloc.free(pixels);
        return err;
    };

    laimg.* = Image{
        .width = width,
        .height = height,
        .pixels = pixels,
    };

    image_cache_mutex.lock();
    defer image_cache_mutex.unlock();

    if (id) |the_id| {
        image_cache.resize(alloc, the_id + 1) catch |err| {
            laimg.deinit(alloc);
            return err;
        };
        if (the_id >= image_cache.items.len) {
            image_cache.insert(alloc, the_id, laimg) catch |err| {
                laimg.deinit(alloc);
                return err;
            };
        } else {
            // const old_img = image_cache.items[the_id];
            image_cache.items[the_id] = laimg;
            // old_img.deinit(alloc);
        }
        return the_id;
    }

    image_cache.append(std.heap.page_allocator, laimg) catch |err| {
        laimg.deinit(alloc);
        return err;
    };

    return image_cache.items.len - 1; 
}

