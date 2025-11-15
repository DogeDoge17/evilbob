const math = @import("../math.zig");
const spr = @import("../sprite.zig");
const time = @import("../time.zig");
const img = @import("../image.zig");
const audio = @import("../audio.zig");
const std = @import("std");

pub const Evil = struct {
    speed: f32 = 0.75,
    targt: ?*math.Vector2(f32) = null,
    sprite: spr.Sprite = .{ .pos = .{.x = 22, .y = 0 }, .texture = undefined },
    container: *spr.SpriteContainer = undefined,
    talk_timer:f32 = 4,
    talk_rnd: std.Random.DefaultPrng = undefined,
    sound_pool: []const audio.Assets = &.{},
    idle_sounds: []const audio.Assets = &.{},
    
    pub fn init(containter: *spr.SpriteContainer, position: math.Vector2(f32), speed: f32, texture:img.Assets) @This() {
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
    
    pub fn setTarget(self: *@This(), target: *math.Vector2(f32)) void {
        self.targt = target;
        if(self.sound_pool.len == 0) return;
        audio.Sound.play(self.sound_pool[0]) catch {};
        audio.Sound.setLoop(self.sound_pool[0], true);
    }

    pub fn checkKill(self: *const @This()) bool {
        if (self.targt) |targetPos| {
            return self.sprite.pos.distance(targetPos.*) < 0.8;
        }
        return false;
    }

    pub fn moveSound(self: *@This()) void {
        for(self.sound_pool) |sound| {
            audio.Sound.setPosition(sound, self.sprite.pos);
        } 
    }

    pub fn update(self: *@This()) void {
        if (self.targt) |targetPos| {
            self.sprite.pos = self.sprite.pos.moveTowards(targetPos, self.speed * time.gameTime);
            self.moveSound();
        }

        self.talk_timer -= time.gameTime;
        if (self.talk_timer <= 0 and self.talk_rnd.random().intRangeAtMost(u8, 0, 4) == 2 and self.idle_sounds.len > 0) {
            audio.Sound.play(self.idle_sounds[self.talk_rnd.random().intRangeAtMost(usize, 0, self.idle_sounds.len - 1)]) catch {};
            self.talk_timer = 8;
        }
    }
    
    pub fn kill(self: *@This()) void {
        self.container.remove(&self.sprite);
        for(self.sound_pool) |sound| {
            audio.Sound.stop(sound);
        }
    }
};
