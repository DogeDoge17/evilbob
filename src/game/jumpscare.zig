const time = @import("../time.zig");
const scene = @import("../scene.zig");
const draw = @import("../draw.zig");
const image = @import("../image.zig");
const audio = @import("../audio.zig");

var scary:image.Assets = undefined;
var timer:f32 = 0;
var flip_timer:f32 = 0;
var program:draw.program = .{ .fragment = &inverse, .args = .{} };
fn inverse (pixel: u32, args: draw.program_args) u32 {
    if(args.u1 == 0)
        return pixel;

    const a = (pixel >> 24) & 0xFF;
    const r = 0xFF - ((pixel >> 16) & 0xFF);
    const g = 0xFF - ((pixel >> 8) & 0xFF);
    const b = 0xFF - (pixel & 0xFF);
    return (a << 24) | (r << 16) | (g << 8) | b; 
}

pub fn init() void {
    timer = 3;
    flip_timer = 0.08;
    program.args.u1 = 0;
    scary = .evilbob;
    audio.resetEngine();
    audio.Sound.play(.sponge_scream) catch { @import("std").debug.print("pretend its screaming", .{}); };
}

pub fn update() void {
    timer -= time.gameTime;
    if(timer <= 0) {
        scene.loadScene(@import("title.zig"));
        return;
    }

    flip_timer -= time.gameTime;
    if (flip_timer <= 0) {
        flip_timer = 0.08;
        if(program.args.u1 == 0) {
            program.args.u1 = 1;
        } else {
            program.args.u1 = 0;
        }
    }
}

pub fn render() void {
    draw.waitForDraws();
    @memset(draw.buffer, 0xFF000000);
    draw.queueBlitS(image.getImage(scary).?, program, .{ .x = 0, .y = 70, .height = draw.height, .width = draw.width }, null);
}

pub fn postRender() void { }

pub fn deinit() void {
    audio.Sound.stop(.sponge_scream);
}
