const std = @import("std");

const imageUris = [_][:0]const u8{
    "evilbob",
};

pub const Image = struct {
    width: usize,
    height: usize,
    pixels: []const u32,
    pub fn deinit(self: *const Image, alloc: std.mem.Allocator) void {
        alloc.free(self.pixels);
    }
};
//
// fn sanitizeName(comptime name: []const u8) []const u8 {
//     var buf: [64]u8 = undefined;
//     var i: usize = 0;
//
//     for (name) |c| {
//         if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_') {
//             buf[i] = c;
//         } else {
//             buf[i] = '_';
//         }
//         i += 1;
//     }
//
//     return buf[0..i];
// }
// pub const Assets = blk: {
//
//     var fields: [imageUris.len]std.builtin.Type.EnumField = undefined;
//
//     for (imageUris, 0..) |name, i| {
//         fields[i] = .{ .name = name, .value = i };
//     }
//
//     const enumInfo = std.builtin.Type.Enum{
//         .tag_type = u32,
//         .fields = &fields,
//         .decls = &[0]std.builtin.Type.Declaration{},
//         .is_exhaustive = true,
//     };
//     break:blk @Type(std.builtin.Type{ .@"enum" = enumInfo });
// };
//
// pub var allim = loadImages(&imageUris);
// fn loadImages(comptime files: []const []const u8) [files.len]Image {
//     var images:[files.len]Image = undefined;
//
//     for(files, 0..) |file_name, i| {
//         const imageData = @embedFile("assets/" ++ file_name ++ ".tga");
//
//         if (imageData[2] != 2) @panic("WHAT IS THIS");
//
//         const width  = @as(u16, imageData[12]) | (@as(u16, imageData[13]) << 8);
//         const height = @as(u16, imageData[14]) | (@as(u16, imageData[15]) << 8);
//         const pixel_depth: u8 = imageData[16];
//         const bpp: usize = pixel_depth / 8;
//         const descriptor = imageData[17];
//         const top_origin = ((descriptor >> 5) & 1) == 1;
//         // @compileLog("width = ", width, ", height = ", height);
//
//         // const pixels: []u8 = [_]u8{0} ** (height * width);
//         // const pixels: [width * height]u8 = ([_]u8{0} ** (height * width));
//
//         // compute pixel data offset
//         const id_len = imageData[0];
//         const color_map_type = imageData[1];
//         const color_map_len = @as(u16, imageData[5]) | (@as(u16, imageData[6]) << 8);
//         const color_map_depth = imageData[7];
//         var pixel_offset: usize = 18 + id_len;
//         if (color_map_type == 1) {
//             pixel_offset += @as(usize, color_map_len) * (color_map_depth / 8);
//         }
//
//         const pixel_data_len = @as(usize, width) * @as(usize, height) * bpp;
//         const pixel_data = imageData[pixel_offset .. pixel_offset + pixel_data_len];
//
//         // one u32 per pixel (ARGB)
//         var pixels: [width * height]u32 = undefined;
//
//         var si: usize = 0;
//         var y: usize = 0;
//         @setEvalBranchQuota(100000000);
//         while (y < height) : (y += 1) {
//             const dy = if (top_origin) y else (height - 1 - y);
//             var x: usize = 0;
//             @setEvalBranchQuota(100000000);
//             while (x < width) : (x += 1) {
//                 if (bpp == 4) {
//                     // BGRA → ARGB
//                     const bgra = std.mem.readInt(u32, pixel_data[si .. si + 4], .little);
//                     const b =  bgra        & 0xFF;
//                     const g = (bgra >> 8)  & 0xFF;
//                     const r = (bgra >> 16) & 0xFF;
//                     const a = (bgra >> 24) & 0xFF;
//                     pixels[dy * width + x] = (@as(u32, a) << 24)
//                     | (@as(u32, r) << 16)
//                     | (@as(u32, g) << 8)
//                     |  @as(u32, b);
//                     si += 4;
//                 } else if (bpp == 3) {
//                     // BGR → ARGB
//                     const b = pixel_data[si + 0];
//                     const g = pixel_data[si + 1];
//                     const r = pixel_data[si + 2];
//                     pixels[dy * width + x] = 0xFF00_0000
//                     | (@as(u32, r) << 16)
//                     | (@as(u32, g) << 8)
//                     |  @as(u32, b);
//                     si += 3;
//                 } else {
//                     @panic("Unsupported pixel depth (expected 24 or 32)");
//                 }
//             }
//         }
//         // for (&pixels) |*p| {
//         //     p.* = 0;
//         // }
//
//         const image = Image{
//             .width = @as(u16,@intCast(width)),
//             .height = @as(u16,@intCast(height)),
//             .pixels = pixels,
//         };
//         images[i] = image;
//     }
//
//     return images;
// }
pub fn loadImage(alloc: std.mem.Allocator, path: []const u8) !Image {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const imagedata = try file.readToEndAlloc(alloc, 10 * 4024 * 4024); 
    defer alloc.free(imagedata);

    if (imagedata[2] != 2) return error.invalidformat;

    const width  = @as(u16, imagedata[12]) | (@as(u16, imagedata[13]) << 8);
    const height = @as(u16, imagedata[14]) | (@as(u16, imagedata[15]) << 8);
    const pixel_depth: u8 = imagedata[16];
    const bpp: usize = pixel_depth / 8;
    const descriptor = imagedata[17];
    const top_origin = ((descriptor >> 5) & 1) == 1;

    const id_len = imagedata[0];
    const color_map_type = imagedata[1];
    const color_map_len = @as(u16, imagedata[5]) | (@as(u16, imagedata[6]) << 8);
    const color_map_depth = imagedata[7];
    var pixel_offset: usize = 18 + id_len;
    if (color_map_type == 1) {
        pixel_offset += @as(usize, color_map_len) * (color_map_depth / 8);
    }

    const pixel_data_len = @as(usize, width) * @as(usize, height) * bpp;
    const pixel_data = imagedata[pixel_offset .. pixel_offset + pixel_data_len];

    var pixels = try alloc.alloc(u32, @as(usize, width) * @as(usize, height));

    var si: usize = 0;
    var y: usize = 0;
    while (y < height) : (y += 1) {
        const dy = if (top_origin) y else (height - 1 - y);
        var x: usize = 0;
        while (x < width) : (x += 1) {
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

    return Image{
        .width = width,
        .height = height,
        .pixels = pixels,
    };
}

