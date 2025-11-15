const std = @import("std");
const evil = @import("evil.zig");
const spr = @import("../sprite.zig");
const math = @import("../math.zig");
const img = @import("../image.zig");
const audio = @import("../audio.zig");
const time = @import("../time.zig");
const renderer = @import("../render.zig");

pub const Bear5 = struct {
    ai:evil.Evil = undefined,
    warning: bool = false,
    deployed: bool = false,

    pub fn Init(containter: *spr.SpriteContainer, position: math.Vector2(f32), speed: f32, texture:img.Assets) @This() {
        var bear: @This() = .{ .ai = evil.Evil.init(containter, position, speed, texture), };
            
        bear.ai.sound_pool = &.{ .bear_5_theme, .bear_5_warning, };
        return bear;
    }
    
    pub fn update(self: *@This()) void {
        if (!self.deployed) return;

        self.ai.update();
        

        self.soundCheck();        
    }

    pub fn deinit(self: *@This()) void {
        self.ai.kill();

    }

    fn soundCheck(self: *@This()) void {

        if (self.ai.targt) |targetPos| {
            audio.Sound.setPosition(.bear_5_warning, targetPos.*);
            audio.Sound.setPosition(.bear_5_theme, targetPos.*);
        }
        if (audio.Sound.isPlaying(.bear_5_warning)) {
            self.warning = true;
            return;
        }
        self.warning = false;

        if(audio.Sound.isPlaying(.bear_5_theme)) return;
        audio.Sound.play(.bear_5_theme) catch {};
        audio.Sound.setLoop(.bear_5_theme, true);
    }

    pub fn deploy(self: *@This(), target: *math.Vector2(f32)) void {
        self.ai.setTarget(target);
        audio.Sound.play(.bear_5_warning) catch {};
        self.deployed = true;
    }

    var text_wiggle: math.Vector2(f32) = .{ .x = 0.5, .y = 0.5 };
    pub fn postRender(self: *@This()) void {
        if (!self.deployed) return;

        if(self.warning){ 
            text_wiggle.x += @cos(@as(f32, @floatFromInt(time.frame))) * time.gameTime * 20;
            text_wiggle.y += @sin(@as(f32, @floatFromInt(time.frame))) * time.gameTime * 20;
            const f_width = @as(f32, @floatFromInt(renderer.draw.width));
            const f_height = @as(f32, @floatFromInt(renderer.draw.height));

            const x = @as(usize, @intFromFloat(f_width / 2 - 50 + text_wiggle.x * 5));
            const y = @as(usize, @intFromFloat(f_height / 2 - 42 + text_wiggle.y * 5));

            renderer.the_font.renderString(0xFFFF0000, x, y, 32, "BEAR 5 IS COMING");
        }

        const new_a = @as(u8, @intFromFloat(math.perlin1D(@as(f32, @floatFromInt(time.frame)) * 0.02) * 255));
        std.debug.print("{} {} \n", .{new_a, time.frame});
        renderer.screen_tint = renderer.combineColors(new_a, 0, 0, 0);
        renderer.draw.waitForDraws();
        renderer.tintScreen();
    }
    
};
