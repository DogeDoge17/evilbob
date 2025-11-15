const math = @import("../math.zig");
const spr = @import("../sprite.zig");
const time = @import("../time.zig");
const img = @import("../image.zig");
const audio = @import("../audio.zig");
const std = @import("std");

const sounds = [3]audio.Assets{
    .sponge_walk,
    .im_evil_fella,
    .im_evil_spongebob,
};

pub const Evil = struct {
    speed: f32 = 0.75,
    targt: ?*math.Vector2(f32) = null,
    sprite: spr.Sprite = .{ .pos = .{.x = 22, .y = 0 }, .texture = undefined },
    container: *spr.SpriteContainer = undefined,
    talk_timer:f32 = 4,
    talk_rnd: std.Random.DefaultPrng = undefined,
    
    pub fn init(containter: *spr.SpriteContainer, position: math.Vector2(f32), speed: f32, texture:img.Assets) @This() {
        audio.Sound.setLoop(.sponge_walk, true);
        audio.Sound.play(.sponge_walk) catch {};

        return .{
            .sprite = .{ .pos = position, .texture = texture },
            .speed = speed,
            .targt = null,
            .container = containter,
            .talk_rnd = std.Random.DefaultPrng.init(blk: {
                var seed: u64 = undefined;
                std.posix.getrandom(std.mem.asBytes(&seed)) catch { seed = 10; } ;
                break :blk seed;
            }),
        };
    }
    
    pub fn checkKill(self: *const @This()) bool {
        if (self.targt) |targetPos| {
            return self.sprite.pos.distance(targetPos.*) < 0.8;
        }
        return false;
    }

    pub fn moveSound(self: *@This()) void {
        for(sounds) |sound| {
            audio.Sound.setPosition(sound, self.sprite.pos);
        } 
    }

    pub fn update(self: *@This()) void {
        if (self.targt) |targetPos| {
            self.sprite.pos = self.sprite.pos.moveTowards(targetPos, self.speed * time.gameTime);
            self.moveSound();
        }

        self.talk_timer -= time.gameTime;
        if (self.talk_timer <= 0 and self.talk_rnd.random().intRangeAtMost(u8, 0, 4) == 2) {
            audio.Sound.play(sounds[self.talk_rnd.random().intRangeAtMost(usize, 1, 2)]) catch {};
            self.talk_timer = 8;
        }
    }
    
    pub fn kill(self: *@This()) void {
        self.container.remove(&self.sprite);
        audio.Sound.stop(.sponge_walk);
    }
};
