const time = @import("../time.zig");
const scene = @import("../scene.zig");
const draw = @import("../draw.zig");
const image = @import("../image.zig");
const audio = @import("../audio.zig");
const math = @import("../math.zig");

var scary:image.Assets = undefined;
var timer:f32 = 0;
var flip_timer:f32 = 0;
var offset: math.Vector2(usize) = .{ .x = 0, .y = 0 };
var program:draw.program = .{ .fragment = &inverse, .args = .{} };
var le_sound: audio.Assets = .sponge_scream;

const JumpscareTypes = enum {
    evilbob,
    bear_5,
};
pub var scare_man:JumpscareTypes = .evilbob;

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
    audio.resetEngine();

    switch (scare_man) {
        .evilbob =>  {
            scary = .evilbob; 
            le_sound = .sponge_scream;
            timer = 3;
            offset = .{ .x = 0, .y = 70 };

            flip_timer = 0.08;
            program.args.u1 = 0;
        },

        .bear_5 => { 
            scary = .bear_5_jumpscare_0;
            le_sound = .bear_5_scream;
            timer = 4.7778;
            offset = .{ .x = 0, .y = 0 };
        }
    }

    audio.Sound.play(le_sound) catch { @import("std").debug.print("pretend its screaming", .{}); };
}

pub fn update() void {
    timer -= time.gameTime;
    if(timer <= 0) {
        scene.loadScene(@import("title.zig"));
        return;
    }

    switch (scare_man) {
        .evilbob => spongeUpdate(),
        .bear_5 => bear5Update(),
    }
}


pub fn bear5Update() void { 
    if(timer > 3.99) {
        scary = .bear_5_jumpscare_0;
    }
    else if (timer > 2.67) {
        scary = .bear_5_jumpscare_1;
    }
    else if (timer > 1.224) {
        scary = .bear_5_jumpscare_2;
    }
    else {
        scary = .bear_5_jumpscare_3;
    }

}

pub fn spongeUpdate() void { 
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
    draw.queueBlitS(image.getImage(scary).?, program, .{ .x = offset.x, .y = offset.y, .height = draw.height, .width = draw.width }, null);
}

pub fn postRender() void { }

pub fn deinit() void {
    audio.Sound.stop(le_sound);
}
