const img = @import("image.zig");
const std = @import("std");
const math = @import("math.zig");

/// An image to be rendered in 3D space
pub const Sprite = struct {
    pos: math.Vector2(f32),
    texture: *const img.Image, 
    id: usize = 0,
    order: usize = 0,
    dist: f32 = 0
};

var ids: usize = 0;
/// Houses the sprites for the rendered (maybe relocate)
pub const SpriteContainer = struct {
    sprites: std.AutoArrayHashMap(usize, *Sprite),

    pub fn add(self: *@This(), sprite: *Sprite) !void {
        try self.sprites.put(ids, sprite);
        ids += 1;
    }

    pub fn remove(self: *@This(), sprite: *Sprite) void {
        _ = self.sprites.orderedRemove(sprite.id);
    }

    pub inline fn getSprites(self: *@This()) []*Sprite {
        return self.sprites.values();
    }
};
