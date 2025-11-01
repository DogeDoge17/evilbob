const draw = @import("draw.zig");
const minifb = @import("minifb");
const math = @import("math.zig");
const std = @import("std");

pub const Camera = struct {
    position: math.FVector2,
    dir: math.FVector2,
    plane: math.FVector2,
};

pub var cam: *Camera = undefined;

pub const mapWidth =@as(f64, worldMap[0].len);
const umapWidth = mapWidth.len;
pub const mapHeight = @as(f64, worldMap.len);
const umapHeight = worldMap.len;
// pub const worldMap = [_][24]u32{
//   .{1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,2,2,2,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
//   .{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,3,0,0,0,3,0,0,0,1},
//   .{1,0,0,0,0,0,2,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,2,2,0,2,2,0,0,0,0,3,0,3,0,3,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,0,0,0,0,5,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,0,4,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,0,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,4,4,4,4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
//   .{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
// };

pub const worldMap = [_][10]u32{
  .{0,0,0,0,0,0,0,0,0,0,},  
  .{0,0,1,1,1,1,1,1,0,0,},  
  .{0,0,1,0,0,0,0,1,0,0,},  
  .{0,0,1,0,0,0,0,1,0,0,},  
  .{0,0,1,0,0,0,0,1,0,0,},  
  .{0,0,1,1,0,1,1,1,0,0,},  
  .{0,0,0,0,0,0,0,0,0,0,},  
  .{0,0,0,0,0,0,0,0,0,0,},  
  .{0,0,0,0,0,0,0,0,0,0,},  
  .{0,0,0,0,0,0,0,0,0,0,},  
  .{0,0,0,0,0,0,0,0,0,0,},  
  .{0,0,0,0,0,0,0,0,0,0,},  
};

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

pub inline fn getMapTile(x: usize, y: usize) ?u32 {
    if (x > umapWidth or x < 0 or y > umapHeight or y < 0)
        return null;

    return worldMap[y][x];
}

pub fn render() void {
    renderWalls();
}

pub fn setWalls() void {
    
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
        
        const lineHeight:f32 = h / perpWallDist;
        var drawStart:f32 = -lineHeight / 2 + h / 2;
        if(drawStart < 0) drawStart = 0;
        var drawEnd:f32 = lineHeight / 2 + h / 2;
        if(drawEnd >= h) drawEnd = h - 1;

        var color:u32 = switch(getMapTileSafe(mapX, mapY) orelse continue :xLoop) {
            1 => 0xffff0000,
            2 => 0xff00ff00,
            3 => 0xff0000ff,
            4 => 0xffffffff,
            else => 0xffffff00,

        };

        if (side == 1) {
            const brightness: f64 = 0.65; 
            color = adjustBrightness(color, brightness);
        }

        draw.queueSolidVLine(color, x, @as(usize, @intFromFloat(drawStart)), @as(usize, @intFromFloat(drawEnd)));
    }
}


inline fn adjustBrightness(color: u32, brightness: f64) u32 {
    @setFloatMode(.optimized);
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
