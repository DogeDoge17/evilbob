const std = @import("std");
const main = @import("main.zig");

var last_time: ?std.Io.Timestamp = null;

pub var frame: u32 = 0;
pub var deltaTime: f32 = 0;
pub var gameTime: f32 = 0;
pub var gameSpeed: f32 = 1;
pub var fps: f32 = 0;

pub fn update() void {
    if (last_time) |prev| {
        const elapsed = prev.untilNow(main.io, .awake);

        deltaTime = @as(f32, @floatFromInt(elapsed.toNanoseconds())) / 1_000_000_000.0;

        gameTime = deltaTime * gameSpeed;
        fps = if (deltaTime > 0) 1.0 / deltaTime else 0.0;
    }

    last_time = std.Io.Timestamp.now(main.io, .awake);
    frame +%= 1;
}
