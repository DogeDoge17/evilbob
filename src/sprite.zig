const img = @import("image.zig");
const std = @import("std");
const math = @import("math.zig");


// boat: 12,11
// table1: 20, 15
// table2: 16 15
// table3: 18 18
// table4: 8 18
// table5: 10 15
// table6: 7 14
// table7: 5 17
// 
// trash: 6.5 9
// sink 2: 5.5 9
// toilet 1: 6.5 5
// toilet 2: 5.5 5
//
// grill: 12.5 9
// bug sink: 10 7
//
// trash: 15 6.5
// dumpster: 14 4
//

/// An image to be rendered in 3D space
pub const Sprite = struct {
    pos: math.Vector2(f32),
    texture: img.Assets, 
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

    pub fn createSprite(self: *@This(), allocator:std.mem.Allocator, pos: math.Vector2(f32), texture: img.Assets) !*Sprite {
        const sprite = try allocator.create(Sprite);
        sprite.* = Sprite{
            .pos = pos,
            .texture = texture,
            .id = ids,
        };

        try self.add(sprite);
        ids += 1;
        return sprite;
    }

    pub fn reset(self: *@This()) void {
        self.sprites.clearAndFree();
        ids = 0;
    }

    pub fn remove(self: *@This(), sprite: *Sprite) void {
        _ = self.sprites.orderedRemove(sprite.id);
    }

    pub inline fn getSprites(self: *@This()) []*Sprite {
        return self.sprites.values();
    }
};
