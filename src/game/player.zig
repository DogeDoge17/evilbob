const render = @import("../render.zig");
const input = @import("../input.zig");
const time = @import("../time.zig");
const task = @import("task.zig");
const img = @import("../image.zig");
const std = @import("std");

pub var cam: *render.Camera = undefined;

fn canMoveTo(x: f32, y: f32) bool {
    const tile = render.getMapTileInfo(x, y) orelse render.tiles[0];
    return tile.t_type == .AR or !tile.solid;
}

pub fn move() void {
    const move_speed = time.deltaTime * 3.4;
    const rotation_speed = time.deltaTime * 3.6;

    var move_x: f32 = 0;
    var move_y: f32 = 0;

    const behind = input.getKey(.Space);
    const flip:f32 = if(behind) -1 else 1;

    if(input.getKeyDown(.Space) or input.getKeyUp(.Space)) {
        cam.dir.x *= -1;
        cam.dir.y *= -1;
        cam.plane.x *= -1;
        cam.plane.y *= -1;
    }

    if (input.getKey(.W)) {
        move_x += cam.dir.x * flip;
        move_y += cam.dir.y * flip; 
    } else if (input.getKey(.S)) {
        move_x -= cam.dir.x * flip;
        move_y -= cam.dir.y * flip;
    }

    // strafes instaed of looking with shift (elite design)
    if(input.getKey(.LeftShift)) {
        if (input.getKey(.A)) {
            move_x -= cam.plane.x * flip;
            move_y -= cam.plane.y * flip;
        }
        else if (input.getKey(.D)) {
            move_x += cam.plane.x * flip;
            move_y += cam.plane.y * flip;
        }
    }

    const mag = @sqrt(move_x * move_x + move_y * move_y);
    if (mag > 0) {
        const norm_x = move_x / mag;
        const norm_y = move_y / mag;
        const potential_x = cam.position.x + norm_x * move_speed;
        const potential_y = cam.position.y + norm_y * move_speed;

        cam.position.x = if (canMoveTo(potential_x, cam.position.y)) potential_x else cam.position.x;
        cam.position.y = if (canMoveTo(cam.position.x, potential_y)) potential_y else cam.position.y;
    }

    // i wish i couldve used the mouse but minifb doesnt let you lock the cursor in place
    // could implement it with system calls but time
    if ((input.getKey(.D) and !input.getKey(.LeftShift)) or input.getKey(.Right)) {
        const old_dir_x = cam.dir.x;
        cam.dir.x = cam.dir.x * @cos(-rotation_speed) - cam.dir.y * @sin(-rotation_speed);
        cam.dir.y = old_dir_x * @sin(-rotation_speed) + cam.dir.y * @cos(-rotation_speed);

        const old_plane_x = cam.plane.x;
        cam.plane.x = cam.plane.x * @cos(-rotation_speed) - cam.plane.y * @sin(-rotation_speed);
        cam.plane.y = old_plane_x * @sin(-rotation_speed) + cam.plane.y * @cos(-rotation_speed);
    } else if((input.getKey(.A) and !input.getKey(.LeftShift)) or input.getKey(.Left)) {
        const old_dir_x = cam.dir.x;
        cam.dir.x = cam.dir.x * @cos(rotation_speed) - cam.dir.y * @sin(rotation_speed);
        cam.dir.y = old_dir_x * @sin(rotation_speed) + cam.dir.y * @cos(rotation_speed);

        const old_plane_x = cam.plane.x;
        cam.plane.x = cam.plane.x * @cos(rotation_speed) - cam.plane.y * @sin(rotation_speed);
        cam.plane.y = old_plane_x * @sin(rotation_speed) + cam.plane.y * @cos(rotation_speed);
    }
    std.debug.print("Player Position: ({}, {}) Direction: ({}, {}) Plane: ({}, {}) \n", .{cam.position.x, cam.position.y, cam.dir.x, cam.dir.y, cam.plane.x, cam.plane.y});
    if (cam.position.x < 0 or cam.position.y < 0 or cam.position.x >= render.mapWidth or cam.position.y >= render.mapHeight) {
        cam.position.x = render.mapWidth / 2;
        cam.position.y = render.mapHeight / 2;
    }
}

pub fn init() void {
}

pub fn update() void {
    move();
    // checkTasks();
}

pub var task_list: [2]task.Task = undefined;
pub fn checkTasks() void {
    var closest_task: ?*task.Task = null;
    var closest_distance: f32 = 9999999;
    const max_distance = 1.5;

    for (&task_list) |*t| {
        const dist = cam.position.distance((t.sprite orelse continue).pos );
        if (dist < max_distance and dist < closest_distance and !t.completed) {
            closest_task = t;
            closest_distance = dist;
        }
    }

    if (closest_task) |t| {
        if (input.getKey(.E)) {
            t.work();
            t.drawStatus();
        }
    }
}
