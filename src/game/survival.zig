const std = @import("std");
const renderer = @import("../render.zig");
const time = @import("../time.zig");
const draw = @import("../draw.zig"); 
const spr = @import("../sprite.zig");
const img = @import("../image.zig");
const evil = @import("evil.zig");
const player = @import("player.zig");
const task = @import("task.zig");
const input = @import("../input.zig");

var camera: renderer.Camera = undefined;
var bop:evil.Evil = undefined;
var evilBoob: img.Assets = .evilbob;

var check_list:task.CheckList = .{};

var misc_sprites: [3]*spr.Sprite = undefined;

var skybox: *img.Image = undefined;

pub fn init() !void {
    camera = .{
        .dir = .{ .x = 0.001, .y = -1.001 },
        .plane = .{ .x = -1.001, .y = 0.001 },
        .position = .{ .x = 13, .y = 31 }
    };
    skybox = img.image_cache.items[@as(usize, @intFromEnum(img.Assets.skybox))];

    renderer.cam = &camera;
    player.cam = &camera;

    won = false;
    win_opacity = 0;

    bop = evil.Evil.init(renderer.curr_sprites, .{ .x = 0.5, .y = 0.5 }, 2, evilBoob);
    bop.targt = &player.cam.position;
    renderer.curr_sprites.add(&bop.sprite) catch |err| {
            @import("std").debug.panic("Failed to add evil sprite {}", .{err});
    };

    check_list = try task.CheckList.MakeWork(std.heap.page_allocator, 5, task.possible_tasks[0..task.possible_tasks.len]);
    check_list.visible = true;

    misc_sprites[0] = try renderer.curr_sprites.createSprite(std.heap.page_allocator, .{ .x = 19.5, .y = 7.5 }, .krabs_furn);
    misc_sprites[1] = try renderer.curr_sprites.createSprite(std.heap.page_allocator, .{ .x = 5.5, .y = 9.5 }, .sink);
    misc_sprites[2] = try renderer.curr_sprites.createSprite(std.heap.page_allocator, .{ .x = 12.5, .y = 9.5 }, .grill);

    player.init();
}

pub fn deinit() void {
    check_list.clockOut();        
    renderer.curr_sprites.reset();
    bop.kill();
    for (misc_sprites) |s| {
        std.heap.page_allocator.destroy(s);
    }
}


// var opacity_pixel: u32 = 0x00000000;
const black_img: img.Image = img.Image{
    .width = 1,
    .height = 1,
    .pixels = &.{ 0xFF000000 },
};
var win_opacity: f32 = 0;

var paused: bool = false;
var won: bool = false;
pub fn update() void {
    if(input.getKeyDown(.Escape)) {
        paused = !paused;
        time.gameSpeed = if(paused) 0 else 1;
    }

    if (won) {
        win_opacity = win_opacity + 255 * time.gameTime;
            
        if(win_opacity > 255) {
            @import("../scene.zig").loadScene(@import("win.zig"));
        }
        return;
    }

    player.update();
    player.checkTasks(&check_list);
    if(check_list.checkList()) {
        won = player.cam.position.distance(.{ .x = 13, .y = 31 }) < 1;
    }
    
    bop.update();
    if (bop.checkKill()) { @import("../scene.zig").loadScene(@import("jumpscare.zig")); return; }
}

pub fn render() void {
    if(won) {
        draw.waitForDraws();
        draw.blit(&black_img, renderer.combineColors(@as(u8, @intFromFloat(win_opacity)), 0,0,0), 0, 0, draw.width, draw.height); 
        return;
    }

    draw.waitForDraws();
    @memcpy(draw.buffer, skybox.pixels);
    renderer.render(); 
}


pub fn postRender() void {
    player.postRender();
    check_list.drawList();
    if(paused) {
        draw.waitForDraws();
        draw.blit(&black_img, renderer.combineColors(200, 0,0,0), 0, 0, draw.width, draw.height); 
        draw.waitForDraws();
        renderer.the_font.renderString(0xFFFFFFFF, draw.width / 2 - 62, draw.height / 2 - 12, 24, "PAUSED");
    }
}
