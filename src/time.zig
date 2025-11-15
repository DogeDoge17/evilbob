const std = @import("std");

var time: i64 = 0;
var oldTime: i64 = 0;
pub var frame:u32 = 0;
pub var deltaTime:f32 = 0;
pub var gameTime:f32 = 0;
pub var gameSpeed: f32 = 1;
pub var fps:f32 = 0;

pub fn update() void {
    oldTime = time;
    time = std.time.milliTimestamp();
    deltaTime = @as(f32, @floatFromInt(time - oldTime)) / 1000.0;   
    gameTime = deltaTime * gameSpeed;
    fps = 1.0 / deltaTime;
    frame = frame +% 1;
}
