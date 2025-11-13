const math = @import("../math.zig");
const spr = @import("../sprite.zig");
const time = @import("../time.zig");
const img = @import("../image.zig");


pub const Evil = struct {
    speed: f32 = 1.0,
    targt: ?*math.Vector2(f32) = null,
    sprite: spr.Sprite = .{ .pos = .{.x = 22, .y = 0 }, .texture = undefined },
    container: *spr.SpriteContainer = undefined,
    
    pub fn init(containter: *spr.SpriteContainer, position: math.Vector2(f32), speed: f32, texture:img.Assets) @This() {
        return .{
            .sprite = .{ .pos = position, .texture = texture },
            .speed = speed,
            .targt = null,
            .container = containter,
        };

    }
    
    pub fn checkKill(self: *const @This()) bool {
        if (self.targt) |targetPos| {
            return self.sprite.pos.distance(targetPos.*) < 0.8;
        }
        return false;
    }

    pub fn update(self: *@This()) void {
        if (self.targt) |targetPos| {
            self.sprite.pos = self.sprite.pos.moveTowards(targetPos, self.speed * time.deltaTime);
        }
    }
    
    pub fn kill(self: *@This()) void {
        self.container.remove(&self.sprite);
    }
};
