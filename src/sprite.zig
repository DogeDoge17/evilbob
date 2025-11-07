const img = @import("image.zig");
const std = @import("std");

pub const Sprite = struct {
    x: f32,
    y: f32,
    texture: *const img.Image,  // index into your texture array
    id: usize = 0,
    order: usize = 0,
    dist: f32 = 0
};

var ids: usize = 0;
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
