const draw = @import("draw.zig");
const minifb = @import("minifb");
const math = @import("math.zig");
const img = @import("image.zig");
const std = @import("std");
const sprite = @import("sprite.zig");

pub const Camera = struct {
    position: math.Vector2(f32),
    dir: math.Vector2(f32),
    plane: math.Vector2(f32),
};
pub var cam: *Camera = undefined;

pub const mapWidth = @as(f64, worldMap[0].len); const umapWidth = mapWidth.len;
pub const mapHeight = @as(f64, worldMap.len); const umapHeight = worldMap.len;

pub const worldMap = [_][24]u32{
  .{1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
  .{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1},
  .{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
  .{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};
var zBuffer: [800]f32 = undefined;
pub var textureMap: [5]img.Image = undefined;

pub var curr_sprites: *sprite.SpriteContainer = undefined;

// pub var sprites: [1] *const sprite.Sprite = undefined;
// pub var sprite_order: [1] usize = undefined;
// pub var sprite_dist: [1] f32 = undefined;
//
// pub const worldMap = [_][10]u32{
//   .{0,0,0,0,0,0,0,0,0,0,},  
//   .{0,0,1,1,1,1,1,1,0,0,},  
//   .{0,0,1,0,0,0,0,1,0,0,},  
//   .{0,0,1,0,0,0,0,1,0,0,},  
//   .{0,0,1,0,0,0,0,1,0,0,},  
//   .{0,0,1,1,0,1,1,1,0,0,},  
//   .{0,0,0,0,0,0,0,0,0,0,},  
//   .{0,0,0,0,0,0,0,0,0,0,},  
//   .{0,0,0,0,0,0,0,0,0,0,},  
//   .{0,0,0,0,0,0,0,0,0,0,},  
//   .{0,0,0,0,0,0,0,0,0,0,},  
//   .{0,0,0,0,0,0,0,0,0,0,},  
// };

// pub const worldMap = [_]u32{
//     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0,1,
//     1,0,0,0,1,1,0,0,0,0,0,0,0,1,0,0,0,0,0,1,
//     1,0,0,0,1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,
//     1,0,0,0,1,1,0,0,0,0,1,1,1,1,0,0,0,0,0,1,
//     1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,1,
//     1,0,0,0,0,1,1,1,1,1,0,1,1,1,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,1,
//     1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
//     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
// };

test "what" {
    const hi: f32 = 10;
    const hello: usize = 10;
    _ = getMapTileSafe(hello, hello);
    std.log.warn("{}", .{@TypeOf(hi)});
    std.log.warn("{?}", .{getMapTileSafe(hi, hello + 3)});
}

/// function overloading if it was awesome
pub inline fn getMapTileSafe(x: anytype, y: anytype) ?u32 {
    const sameWidth = @as(@TypeOf(x), mapWidth);
    const sameHeight = @as(@TypeOf(y), mapHeight);

    if (x >= sameWidth or x < 0 or y >= sameHeight or y < 0)
        return null;

    const ux = @as(usize, switch(@typeInfo(@TypeOf(x))) {
        .float => @intFromFloat(x),
        .int =>  @intCast(x),
        else => return null
    });
    const uy = @as(usize, switch(@typeInfo(@TypeOf(y))) {
        .float => @intFromFloat(y),
        .int =>  @intCast(y),
        else => return null
    });

    return worldMap[uy][ux];
}

pub inline fn getMapTile(x: usize, y: usize) u32 {
    return worldMap[y][x];
}

pub fn render() void {
    draw.waitForDraws();
    renderWalls();

    draw.waitForDraws();
    renderSprites();
}

pub fn setWalls() void {
    
}

pub fn renderSprites() void {
    const w:f32 = @as(f32, @floatFromInt(draw.width));
    const h:f32 = @as(f32, @floatFromInt(draw.height));
    const sprites = curr_sprites.getSprites();

    // _ = minifb.c.mfb_set_viewport_best_fit(window, @as(c_uint, @intCast(screenWidth)), @as(c_uint, @intCast(screenHeight)));
    for (sprites, 0..) |spr, i| {
        sprites[i].order = i;
        const dx = spr.pos.x - cam.position.x;
        const dy = spr.pos.y - cam.position.y;
        sprites[i].dist = dx * dx + dy * dy;
    }
    
    for(0..sprites.len) |i| {
        for(i+1..sprites.len) |j| {
            if (sprites[sprites[i].order].dist < sprites[sprites[j].order].dist) {
                const tmp = sprites[i].order;
                sprites[i].order = sprites[j].order;
                sprites[j].order = tmp;
            }
        }
    }
    
    for (0..sprites.len) |i| {
        const ord = sprites[i].order;
        const spr = sprites[ord];
        
        const spriteX = spr.pos.x - cam.position.x;
        const spriteY = spr.pos.y - cam.position.y;
        
        const invDet = 1.0 / (cam.plane.x * cam.dir.y - cam.dir.x * cam.plane.y);
        const transformX = invDet * (cam.dir.y * spriteX - cam.dir.x * spriteY);
        const transformY = invDet * (-cam.plane.y * spriteX + cam.plane.x * spriteY);
        
        if (transformY <= 0) continue;
        
        const spriteScreenX:i32 = @as(i32, @intFromFloat((w / 2) * (1 + transformX / transformY)));
        
        const spriteHeight:i32 = @as(i32, @intFromFloat(@abs(h / transformY) / 2));
        const spriteWidthH:i32 = @as(i32, @intFromFloat(@abs(h / transformY) / 2));
        const spriteWidth:i32 = spriteWidthH * 2;
        
        var drawStartY:i32 = -spriteHeight + @as(i32, @intFromFloat(h / 2));
        if (drawStartY < 0) drawStartY = 0;
        var drawEndY:i32 = spriteHeight + @as(i32, @intFromFloat(h / 2));
        if (drawEndY >= @as(i32, @intFromFloat(h))) drawEndY = @as(i32, @intFromFloat(h)) - 1;
        
        var drawStartX:i32 = -spriteWidthH + spriteScreenX;
        if (drawStartX < 0) drawStartX = 0;
        var drawEndX:i32 = spriteWidthH + spriteScreenX;
        if (drawEndX >= @as(i32, @intFromFloat(w))) drawEndX = @as(i32, @intFromFloat(w)) - 1;
        
        var stripe:i32 = drawStartX;
        while (stripe < drawEndX) : (stripe += 1) {
            std.debug.print("tex width {} {} {}\n", .{spr.texture.width, spr.texture.height, spr.texture.pixels.len});
            const texX:usize = @as(usize, @intCast(@divFloor((stripe - (-spriteWidthH + spriteScreenX)) * @as(i32, @intCast(spr.texture.width)), spriteWidth)));
            
            if (transformY < zBuffer[@as(usize, @intCast(stripe))]) {
                const clampedTexX = @min(texX, spr.texture.height - 1);
                const row_index = spr.texture.height - 1 - clampedTexX;
                const row = spr.texture.pixels[row_index * spr.texture.width .. (row_index + 1) * spr.texture.width];
                
                draw.queueTexBVLine(
                    row,
                    0xFFFFFFFF,
                    @as(usize, @intCast(stripe)),
                    @as(usize, @intCast(drawStartY)),
                    @as(usize, @intCast(drawEndY - drawStartY)),
                    spr.texture.width
                );
            }
        }
    }
}
pub fn renderWalls() void {
    const w:f32 = @as(f32,@floatFromInt(draw.width));
    const h:f32 = @as(f32,@floatFromInt(draw.height));

    xLoop:
    for(0..draw.width) |x| {
        const cameraX:f32 = @as(f32, @floatFromInt(2 * x)) / w - 1;
        const rayDirX = cam.dir.x + cam.plane.x * cameraX;
        const rayDirY = cam.dir.y + cam.plane.y * cameraX;

        var mapX:i32 = @as(i32, @intFromFloat(cam.position.x));
        var mapY:i32 = @as(i32, @intFromFloat(cam.position.y));

        var sideDistX: f32 = 0;
        var sideDistY: f32 = 0;
        const deltaDistX = if (rayDirX == 0) 1e30 else @abs(1 / rayDirX);
        const deltaDistY = if (rayDirY == 0) 1e30 else @abs(1 / rayDirY);

        var perpWallDist: f32 = 0;
        var stepX: i32 = 0;
        var stepY: i32 = 0;

        var hit:i32 = 0;
        var side:i32 = 0;
        if(rayDirX < 0) {
            stepX = -1;
            sideDistX = (cam.position.x - @as(f32, @floatFromInt(mapX))) * deltaDistX;
        }
        else {
            stepX = 1;
            sideDistX = (@as(f32, @floatFromInt(mapX)) + 1.0 - cam.position.x) * deltaDistX;
        }
        if(rayDirY < 0) {
            stepY = -1;
            sideDistY = (cam.position.y - @as(f32, @floatFromInt(mapY))) * deltaDistY;
        }
        else {
            stepY = 1;
            sideDistY = (@as(f32, @floatFromInt(mapY)) + 1.0 - cam.position.y) * deltaDistY;
        }

        while(hit == 0) {
            if(sideDistX < sideDistY) {
                sideDistX += deltaDistX;
                mapX += stepX;
                side = 0;
            }
            else {
                sideDistY += deltaDistY;
                mapY += stepY;
                side = 1;
            }

            if (getMapTileSafe(mapX, mapY) orelse continue :xLoop > 0) hit = 1;
        }
        perpWallDist = if (side == 0) (sideDistX - deltaDistX) else (sideDistY - deltaDistY);
        zBuffer[x] = perpWallDist;

        const lineHeight:f32 = h / perpWallDist;
    
        const texNum: usize = @as(usize, @intCast((getMapTileSafe(mapX, mapY) orelse continue :xLoop) - 1));

        @setFloatMode(.optimized);
        const drawStartUnclamped:f32 = -lineHeight / 2 + h / 2;
        const drawEndUnclamped:f32 = lineHeight / 2 + h / 2;

        var drawStart:f32 = drawStartUnclamped;
        if(drawStart < 0) drawStart = 0;
        var drawEnd:f32 = drawEndUnclamped;
        if(drawEnd >= h) drawEnd = h - 1;

        const texStartOffset:f32 = if (drawStartUnclamped < 0) -drawStartUnclamped / lineHeight else  0;
        const texEndOffset:f32 = if (drawEndUnclamped >= h) (drawEndUnclamped - h + 1) / lineHeight else 0;

        const texStartY:usize = @as(usize, @intFromFloat(texStartOffset * @as(f32, @floatFromInt(textureMap[texNum].width))));
        const texHeight:usize = @as(usize, @intFromFloat((1.0 - texStartOffset - texEndOffset) * @as(f32, @floatFromInt(textureMap[texNum].width))));   

        var wallX:f32 = 0;
        if (side == 0) {
            wallX = cam.position.y + perpWallDist * rayDirY;
        } else {
            wallX = cam.position.x + perpWallDist * rayDirX;
        }
        wallX -= @floor(wallX);
        var texX: usize = @as(usize, @intFromFloat(wallX * @as(f32, @floatFromInt(textureMap[texNum].height))));
        if (texX >= textureMap[texNum].height) texX = textureMap[texNum].height - 1;

        const program = draw.program {
            .fragment = adjustBrightnessProgram,
            .args = .{
                .i1 = side,
            },
        };

        const clampedTexX = @min(texX, textureMap[texNum].height - 1);
        const row_index = textureMap[texNum].height - 1 - clampedTexX;
        const row = textureMap[texNum].pixels[row_index * textureMap[texNum].width .. (row_index + 1) * textureMap[texNum].width];
        draw.queueTexSVLine(
            row[texStartY .. texStartY + texHeight],
            program, 
            x,
            @as(usize, @intFromFloat(drawStart)),
            @as(usize, @intFromFloat(drawEnd)) - @as(usize, @intFromFloat(drawStart)) + 1,
            texHeight
        );
    }
}

fn adjustBrightnessProgram(color: u32, args: draw.program_args) u32 {
    if (args.i1 != 0)
        return color;

    @setFloatMode(.optimized);

    const brightness = 0.65;
    const gamma = 2.2;

    var r = @as(f64, @floatFromInt((color >> 16) & 0xff)) / 255.0;
    var g = @as(f64, @floatFromInt((color >> 8) & 0xff)) / 255.0;
    var b = @as(f64, @floatFromInt(color & 0xff)) / 255.0;

    r = std.math.pow(f64, r, gamma);
    g = std.math.pow(f64, g, gamma);
    b = std.math.pow(f64, b, gamma);

    r *= brightness;
    g *= brightness;
    b *= brightness;

    r = @min(1.0, r);
    g = @min(1.0, g);
    b = @min(1.0, b);

    r = std.math.pow(f64, r, 1.0 / gamma);
    g = std.math.pow(f64, g, 1.0 / gamma);
    b = std.math.pow(f64, b, 1.0 / gamma);

    return (0xff << 24)
        | (@as(u32, @intFromFloat(r * 255.0)) << 16)
        | (@as(u32, @intFromFloat(g * 255.0)) << 8)
        | (@as(u32, @intFromFloat(b * 255.0)));
}


const internal_string = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"; 
const default_font_size = 126;
pub const Font = struct {
    font_map: std.AutoHashMap(u8, LineChar),
    atlas: img.Image,
    line_seperation: f32 = default_font_size * 0.3,
    padding: i32 = 10,
    fmtBuff: std.heap.FixedBufferAllocator = undefined,

    pub fn load(allocator: std.mem.Allocator, path: []const u8) !Font {
        const fnt_path = try std.fmt.allocPrint(allocator, "{s}.fntdat", .{path});
        defer allocator.free(fnt_path);
        const texture_path = try std.fmt.allocPrint(allocator, "{s}.tga", .{path});
        defer allocator.free(texture_path);
        std.debug.print("Loading font from: {s} and {s}\n", .{fnt_path, texture_path});
        const atlas = try img.loadImage(allocator, texture_path);

        var font_file = try std.fs.cwd().openFile(fnt_path, .{});
        defer font_file.close();
        const font_data = try font_file.readToEndAlloc(allocator, 10 * 1024 * 1024);
        defer allocator.free(font_data);

        var font_map = std.AutoHashMap(u8, LineChar).init(allocator);

        var i: usize = 0;
        var wrap:i8 = 0;
        var wrappped_wraps: usize = 0;
        var line_char = LineChar {
            .xS = 0,
            .yS = 0,
            .width = 0,
            .height = 0,
            .x = 0,
        };

        while (i + 4 <= font_data.len) : (i += 4) {
            const b0 = font_data[i + 0];
            const b1 = font_data[i + 1];
            const b2 = font_data[i + 2];
            const b3 = font_data[i + 3];
            const number = @as(u32, b0) | (@as(u32, b1) << 8) | (@as(u32, b2) << 16) | (@as(u32, b3) << 24);

            switch(wrap) {
                0 => line_char.xS = @as(f32, @floatFromInt(number)),
                1 => line_char.yS = @as(f32, @floatFromInt(number)),
                2 => line_char.width = @as(f32, @floatFromInt(number)),
                3 => line_char.height = @as(f32, @floatFromInt(number)),
                4 => {
                    line_char.x = @as(f32, @floatFromInt(number));
                    
                    if(internal_string.len <= wrappped_wraps) break;

                    const char: u8 = internal_string[wrappped_wraps];
                    try font_map.put(char, line_char);
                    wrap = -1;
                    wrappped_wraps += 1;
                },
                else => { wrap = 0; },
            }

            wrap += 1;
        }

        return Font {
            .font_map = font_map,
            .atlas = atlas,
            .fmtBuff = std.heap.FixedBufferAllocator.init(try std.heap.c_allocator.alloc(u8, 256)),
        };
    }
    
    pub fn renderStringF(self: *@This(), color: u32, x: usize, y: usize, font_size: f32, comptime fmt: []const u8,  args: anytype ) !void {
        const text = std.fmt.allocPrint(self.fmtBuff.threadSafeAllocator(), fmt, args) catch {
            const needed_size = std.fmt.count(fmt, args) + 10;
            self.fmtBuff.buffer = try std.heap.c_allocator.realloc(self.fmtBuff.buffer, needed_size); 

            const text = try std.fmt.allocPrint(self.fmtBuff.threadSafeAllocator(), fmt, args);
            defer self.fmtBuff.reset();

            renderString(self, color, x, y, font_size, text);
            return;
        };
        defer self.fmtBuff.reset();
        renderString(self, color, x, y, font_size, text);
    }

    pub fn renderString(self: *@This(), color: u32, x: usize, y: usize, font_size: f32, text: []const u8) void {
        var char_offset: f32 = @as(f32, @floatFromInt(x));
        var line_offset: f32 = 0;
        var prev_char: LineChar = .{ .xS = 0, .yS = 0, .width = 0, .height = 0, .x = 0 };
        const font_percent: f32 = font_size / default_font_size;
        var max_char_offset: f32 = 0;
        
        for(text) |c| {
            if (c == '\r' or c == '\n') {
                max_char_offset = @max(max_char_offset, char_offset);
                char_offset = @as(f32, @floatFromInt(x));
                prev_char = .{ .xS = 0, .yS = 0, .width = 0, .height = 0, .x = 0 };
                line_offset += self.line_seperation;
                continue; 
            }
            const rec = self.font_map.get(c) orelse continue;

            char_offset += (prev_char.width - prev_char.x) * font_percent;
            const dest_rect = math.Rectangle(usize) {
                .x = @as(usize, @intFromFloat(char_offset)),
                .y = y + @as(usize, @intFromFloat(line_offset)),
                .width = @as(usize, @intFromFloat(rec.width * font_percent)),
                .height = @as(usize, @intFromFloat(rec.height * font_percent)),
            };

            const src_rect = math.Rectangle(usize) {
                .x = @as(usize, @intFromFloat(rec.xS)),
                .y = @as(usize, @intFromFloat(rec.yS)),
                .width = @as(usize, @intFromFloat(rec.width)),
                .height = @as(usize, @intFromFloat(rec.height)),
            };

            draw.queueBlitR(&self.atlas, color, dest_rect, src_rect);
            prev_char = rec;
        }
    }

    pub fn deinit(self: *Font, allocator: std.mem.Allocator) void {
        self.atlas.deinit(allocator);
        self.font_map.deinit();
        std.heap.c_allocator.free(self.fmtBuff.buffer);
    }
};

pub const LineChar = struct{
    xS: f32,
    yS: f32,
    width: f32,
    height: f32,
    x: f32,
};
