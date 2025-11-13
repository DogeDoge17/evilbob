const sprite = @import("../sprite.zig");
const img = @import("../image.zig");
const render = @import("../render.zig");
const draw = @import("../draw.zig");
const std = @import("std");
const time = @import("../time.zig");

pub const TaskTypes = enum {
    clean_table,
    garbage,
    toilet,
    chop_veggies,
    wash_dishes,
    count_money,
};

// yoooo ts is kinda like json if you think about it
pub const possible_tasks = [_]Task{
    .{ // table 1
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finised = img.get("clean_table")
        // .sprite = &.{
        //     .pos = .{5, 5},
        //
        // }
    },
    .{ 
        .name = "Take Out Garbage", 
        .type = TaskTypes.garbage, 
        .length = 4,
        .finised = img.get("garbage"),
        .next = next(.{
            .name = "Throw in Dumpster",
            .type = TaskTypes.garbage,
            .length = 1,
            .finised = img.get("dumpster"),
            .depth = 50,
        }),
    },
};

fn next(task: Task) *Task {
    const task_ptr = std.heap.page_allocator.create(Task) catch |err| {
        std.debug.panic("Failed to create next task: {}\n", .{err});
    };
    task_ptr.* = task; 
    return task_ptr;
}

pub const Task = struct {
    name: []const u8,
    type: TaskTypes,
    length: f32 = 5,
    progress: f32 = 0,
    next: ?*Task = null,
    depth: f32 = 0,
    completed: bool,
    sprite: ?*sprite.Sprite,
    finised: img.Assets,
    
    pub inline fn drawStatus(self: *const @This()) void {
        render.the_font.renderStringF(render.argb(255, 255, 255, 255), 
        draw.width / 2 - 50, 
        draw.height / 2 - 40, 
        24,
        "{s} - {d:.0}%", .{self.name, self.progress / self.length * 100}) catch |err| {
            std.debug.panic("Failed to draw task status: {}\n", .{err});
        };
    }

    pub fn work(self: *@This()) void {
        if (self.completed) return;
        self.progress += time.deltaTime;

        if (self.progress >= self.length) {
            self.progress = self.length;
            self.completed = true;
            if (self.sprite) |s| {
                s.texture = self.finised;
            }
        }
    }

    // pub fn createJobs() 

};  

// struct 
