const sprite = @import("../sprite.zig");
const img = @import("../image.zig");
const render = @import("../render.zig");
const draw = @import("../draw.zig");
const time = @import("../time.zig");
const math = @import("../math.zig");
const std = @import("std");

pub const TaskTypes = enum {
    clean_table,
    garbage,
    toilet,
    wash_dishes,
    count_money,
};

pub const TaskFrame = struct {
    name: []const u8,
    type: TaskTypes,
    sprite: ?* const sprite.Sprite,
    finished: img.Assets,
    next: ?*const TaskFrame = null,
    length: f32 = 5,
    progress: f32 = 0,
    heap: bool = false,
    denominator: ?f32 = null,
    depth: f32 = 0,
    completed: bool = false,

    pub fn fromFrame(self: @This(), allocator: std.mem.Allocator, register_sprite: bool) !*Task {
        const next = blk: {
            if (self.next) |next_task| {
                break:blk try next_task.fromFrame(allocator, register_sprite);
            } else {
                break:blk null;
            }
        };        
    
        const sprite_copy = blk: {
            if (self.sprite) |s| {
                const new_sprite = try allocator.create(sprite.Sprite);
                new_sprite.* = s.*;
                break:blk new_sprite;
            } else {
                break:blk null;
            }
        };

        if(register_sprite)
            if(sprite_copy) |s| {
                render.curr_sprites.add(s) catch |err| {
                    std.debug.panic("Failed to register copied task sprite: {}\n", .{err});
                };
            };

        const new_task = try allocator.create(Task);
        new_task.* = .{
            .name = self.name,
            .type = self.type,
            .length = self.length,
            .progress = 0,
            .next = next,
            .depth = self.depth,
            .completed = false,
            .sprite = sprite_copy,
            .denominator = self.denominator,
            .finished = self.finished,
            .heap = true,
        };
        return new_task;
    }
};

// yoooo ts is kinda like json if you think about it
pub const possible_tasks = [_]TaskFrame {
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{.x = 20, .y = 15 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{ .x = 16, .y = 15 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{ .x = 18, .y = 18 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{ .x = 8, .y = 18 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{ .x = 10, .y = 15 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{ .x = 7, .y = 14 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Clean Table", 
        .type = TaskTypes.clean_table, 
        .length = 3, 
        .finished = .table_clean,
        .sprite = &.{
            .pos = .{ .x = 5, .y = 17 },
            .texture = img.Assets.table_dirty,
        }
    },
    .{ 
        .name = "Take Out Garbage", 
        .type = TaskTypes.garbage, 
        .length = 4,
        .finished = .trash,
        .denominator = 2,
        .sprite = &.{
            .pos = .{ .x = 6.5, .y = 9.7 },
            .texture = img.Assets.trash_full,
        },
        .next = &.{
            .name = "Throw in Dumpster",
            .type = TaskTypes.garbage,
            .length = 1,
            .finished = .dumpster_finished,
            .depth = 50,
            .sprite = &.{
                .pos = .{ .x = 14, .y = 3.2 },
                .texture = img.Assets.dumpster,
            }
        },
    },
    .{
        .name = "Do Dishes",
        .type = .wash_dishes,
        .length = 5,
        .finished = .kitchen_sink_clean,
        .sprite = &.{
            .pos = .{ .x = 10.6, .y = 7 },
            .texture = .kitchen_sink,
        },
    },
    .{
        .name = "Clean Toilet",
        .type = .toilet,
        .length = 5,
        .finished = .toliet,
        .sprite = &.{
            .pos = .{ .x = 6.5, .y = 6},
            .texture = .toliet,
        },
    },
    .{
        .name = "Clean Toilet",
        .type = .toilet,
        .length = 5,
        .finished = .toliet,
        .sprite = &.{
            .pos = .{ .x = 5.5, .y = 6},
            .texture = .toliet,
        },
    },
    .{
        .name = "Count Money",
        .type = .count_money,
        .finished = .count_finish,
        .length = 3,
        .sprite = &.{
            .pos = .{ .x = 12.4, .y = 11.7},
            .texture = .count,
        }
    }
};


pub const Task = struct {
    name: []const u8,
    type: TaskTypes,
    sprite: ?*sprite.Sprite,
    finished: img.Assets,
    next: ?*Task = null,
    length: f32 = 5,
    progress: f32 = 0,
    heap: bool = false,
    depth: f32 = 0,
    denominator: ?f32 = 0,
    completed: bool,
    
    pub inline fn drawStatus(self: *const @This()) void {
        draw.waitForDraws();
        render.the_font.renderStringF(render.argb(255, 255, 255, 255), 
        draw.width / 2 - 100, 
        draw.height / 2 + 110, 
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
                s.texture = self.finished;
            }
        }
    }
    
    pub fn deinit(self: *@This(), allocator: std.mem.Allocator, kill_sprite: bool, recursive: bool) void {
        if(self.heap) {
            if(kill_sprite){
                if (self.sprite) |s| {
                    render.curr_sprites.remove(s);
                    allocator.destroy(s);
                }
            }
            allocator.destroy(self);
        }
        if(recursive)
            if(self.next) |next_task| {
                next_task.deinit(allocator, kill_sprite, true);
            };
    }
};  

const LinkedTask = struct {
    task: *Task,
    prev: ?*LinkedTask,
    next: ?*LinkedTask,

    pub fn removeSelf(self: *@This(), allocator: std.mem.Allocator, kill_sprite: bool) void {
        if (self.prev) |prev_node| {
            prev_node.next = self.next;
        }
        if (self.next) |next_node| {
            next_node.prev = self.prev;
        }

        if(self.task.heap) {
            if(kill_sprite)
                if (self.task.sprite) |s| {
                    render.curr_sprites.remove(s);
                    std.heap.page_allocator.destroy(s);
                };
            std.heap.page_allocator.destroy(self.task);
        }

        allocator.destroy(self);
    }
};

const checklist_bg = img.Assets.task_bg;
var shuffle_me: [possible_tasks.len]usize = undefined;

pub const CheckList = struct {
    head: ?*LinkedTask = null,
    tail: ?*LinkedTask = null,
    arena: std.heap.ArenaAllocator = undefined,
    visible: bool = false,
    total_tasks: usize = 0,

    pub fn MakeWork(allocator: std.mem.Allocator, task_count: usize, task_pool: []const TaskFrame) !@This() {
        var self: @This() = .{ .head = null, .tail = null, .visible = false, .total_tasks = 0, .arena = std.heap.ArenaAllocator.init(allocator)};
        try std.testing.expect(task_count <= task_pool.len);

        for (0..shuffle_me.len) |i| {
            shuffle_me[i] = i;
        }
        var prng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        });
        prng.random().shuffle(usize, shuffle_me[0..]);

        for (0..task_count) |i| {
            self.addTask(task_pool[shuffle_me[i]].fromFrame(self.arena.allocator(), true) catch |err| {
                std.debug.panic("Failed to copy task into checklist: {}\n", .{err});
            });
        }

        for(task_count..task_pool.len) |i| {
            const idx = shuffle_me[i];

            var next_task:?TaskFrame = task_pool[idx];

            while (next_task) |nt| {
               
                if(nt.sprite) |spr| {
                    _ = render.curr_sprites.createSprite(self.arena.allocator(), spr.pos, nt.finished) catch |err| {
                        std.debug.panic("Failed to create sprite for unused checklist task: {}\n", .{err});
                    };
                }

                if (nt.next) |nxt| {
                    next_task = nxt.*;
                } else {
                    break;
                }
            }
            // var fake_task = task_pool[idx].fromFrame(std.heap.page_allocator, true) catch |err| {
            //     std.debug.panic("Failed to co_t task into checklist: {}\n", .{err});
            // };
            // fake_task.progress = fake_task.length; 
            // fake_task.work();
            // fake_task.deinit(std.heap.page_allocator, false, true);
        }

        return self;        
    }

    pub fn clockOut(self: *@This()) void {
        // var current = self.head;

        self.arena.deinit();

        // while (current) |node| {
        //     node.task.deinit(std.heap.page_allocator, true, true);
        //     const next = node.next;
        //     std.heap.page_allocator.destroy(node);
        //     current = next;
        // }

        // self.head = null;
        // self.tail = null;
        // self.total_tasks = 0;
    }

    pub fn addTask(self: *@This(), task: *Task) void {
        const new_node = self.arena.allocator().create(LinkedTask) catch |err| {
            std.debug.panic("Failed to create linked task node: {}\n", .{err});
        };
        new_node.* = .{ .task = task, .next = null, .prev = self.tail };

        if (self.tail) |tail_node| {
            tail_node.next = new_node;
        } else {
            self.head = new_node;
        }
        self.tail = new_node;
        self.total_tasks += 1;
    }

    // what do you guys think of the name
    pub fn checkList(self: *@This()) bool {
        var current = self.head;

        // std.debug.print("{}\n", .{&current});

        while (current) |node| {
            current = node.next;

            if (node.task.completed) {

                if (node.task.next) |next| {
                    node.task = next;
                } else {
                    if(node == self.tail){
                        self.tail = node.prev;
                        if(self.tail) |tail| {
                            tail.next = null;
                        }
                    }

                    if(node == self.head){
                        self.head = current; 
                    } else{
                        if(current) |next_node| {
                            next_node.prev = node.prev;
                        }
                        if(node.prev) |prev| {
                            prev.next = current;
                        }

                        // std.heap.page_allocator.destroy(node);
                    }
                    self.total_tasks -= 1;
                }
            }
        }

        return self.head == null;
    }

    pub fn drawList(self: *const @This()) void {
        if (!self.visible) return;

        const box_width: usize = 260;
        const box_height: usize = @max(self.total_tasks, @as(usize, 1)) * @as(usize, 30) + 20;
        
        draw.blit(
            img.getImage(checklist_bg).?,
            0xFFFFFFFF,
            draw.width - box_width - 10,
            10,
            box_width,
            box_height,
        );

        var y_offset: usize = 10;
        var current = self.head;

        if(self.head != null) { 
            while (current) |node| {
                const multi = node.task.depth > 0 or node.task.next != null; 

                if(multi) {
                    const num, var dem = math.decimal2Frac(node.task.depth / 100);
                    dem = node.task.denominator orelse dem;
                    render.the_font.renderStringF(render.argb(255, 255, 255, 255), draw.width - box_width, y_offset + 10, 16,
                    "({d:.0}/{d:.0}) {s}", .{num, dem, node.task.name}) catch |err| {
                        std.debug.panic("Failed to draw checklist item: {}\n", .{err});
                    };
                } else {
                    render.the_font.renderStringF(render.argb(255, 255, 255, 255), 
                        draw.width - box_width, y_offset + 10, 16, 
                        "{s}", .{node.task.name }) catch |err| {
                        std.debug.panic("Failed to draw checklist item: {}\n", .{err});
                    };
                }
                y_offset += 30;
                current = node.next;
            } 
        } else {
            render.the_font.renderString(render.argb(255, 255, 255, 255), 
                draw.width - box_width, y_offset + 10, 16, "Leave.");
        }
    }
};
