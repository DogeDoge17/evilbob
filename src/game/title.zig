const draw = @import("../draw.zig");
const renderer = @import("../render.zig");
const ui = @import("ui.zig");
const std = @import("std");
const scene_manager = @import("../scene.zig");
const input = @import("../input.zig");

var play_button: ui.Element = undefined;
var spong: ui.Element = undefined;

const first_names = [_][]const u8 {
    "Sponge",
    "Spingle",
    "Spinge",
    "Tringle",
    "Flip",
    "Spunch",
    // "\x42\x69\x74\x63\x68",
    "Squinch",
    "Sping",
    "Spangled",
    "Sput",
    "Spunsk",
    "Spork",
    "Spangle",
    "Sprong",
    "Blip",
    "Bloop",
    "Goy",
    "Poop"
};

const last_names = [_][]const u8 {
    "bob",
    "bop",
    "plop",
    "dinge",
    "flop",
    "binch",
    "top",
    "flop",
    // "\x63\x6F\x63\x6B",
    "bopple",
    "bill",
    "bing",
    "banner",
    "nik",
    "lop",
    "tingle",
    "bunk",
    "toop",

};
var first_name:usize = 0;
var last_name:usize = 0;

pub fn init() !void {
    play_button = .{
        .texture = .playbtn,
        .pos = .{ .x = 30, .y = 310 },
        .height = 70,
        .width = 250,
    };

    spong = .{
        .texture = .evilbob,
        .pos = .{ .x = draw.width - 370, .y = draw.height - 390 },
        .height = 550,
        .width = 650,
    };

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    first_name = std.Random.intRangeAtMost(prng.random(), usize, 0, first_names.len - 1);
    last_name = std.Random.intRangeAtMost(prng.random(), usize, 0, last_names.len - 1);
}

pub fn deinit() void {

}

pub fn update() void {
    if(play_button.clicked()) {
        scene_manager.loadScene(@import("survival.zig")); 
        return;
    }
}

pub fn render() void {
    draw.waitForDraws();
    @memset(draw.buffer, renderer.argb(255, 0, 0, 0));

    play_button.render();
    spong.render();
    const tempSep = renderer.the_font.line_seperation;
    defer renderer.the_font.line_seperation = tempSep;
    renderer.the_font.line_seperation *= 1.8;

    renderer.the_font.renderStringF(renderer.argb(255, 255, 255, 255), 10, 40, 48, "Survival the\n{s}{s}\nthe killer", .{first_names[first_name], last_names[last_name]}) catch |err| { std.debug.panic("{}", .{err}); };
}

pub fn postRender() void {
}
