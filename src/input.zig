const minifb = @import("minifb");
const std = @import("std");
const deque = @import("deque.zig");
const math = @import("math.zig");

const KeyStatus = struct {
    state: KeyStates,
    frame: u64,
    queue: deque.Deque(KeyStates),
};

const KeyStates = enum(u8) {
    inactive = 0,
    pressed = 1,
    held = 2,
    released = 3,
};

pub var keyStates: [max_key_count]KeyStatus = [_]KeyStatus{ 
    .{  .frame = 0, 
        .state = .inactive,
        .queue = deque.Deque(KeyStates).empty, 
    } 
} ** max_key_count;

var mouse = math.Vector2{ .x = 0, .y = 0 }; 

var currentFrame: u64 = 0;
var allocator: std.mem.Allocator = undefined;
var activeWindow: *minifb.Window = undefined;

const max_key_count:usize = blk: {
    const fields = @typeInfo(minifb.Key).@"enum".fields;
    var max = 0;
    for (fields) |field| {
        max = @max(max, field.value);
    }
    break :blk max + 1;
};

/// UPDATE WILL PERFORM THE NEC CHANGES ON THE PREVIOUS FRAME'S STATES AND PREP FOR THE NEXT FRAME
pub fn update(frame: u64) void {
    currentFrame = frame;
    
    for (0..keyStates.len) |i| {
        const key:*KeyStatus = &keyStates[i];

        const capturedEvent = key.queue.popFront();
        if(capturedEvent) |event| {
            key.*.state = event;
        } else {
            key.*.state = switch(key.*.state) {
                .released => .inactive,
                .held => .held,
                .pressed => .held,
                .inactive => .inactive
            };
        }
    }   
}

fn printState(i:usize, text: []const u8) void {
    // std.debug.print("{s} -- currFrame {}\tkey frame {}\tkey state {}\n", .{text, currentFrame, keyStates[i].frame, keyStates[i].state});
    _ = i;
    _ = text;
}

pub fn printQueue() void {
    const sI = @as(usize, @intCast(@intFromEnum(minifb.Key.Space)));
    var bruh = keyStates[sI].queue.iterator();
    std.debug.print("{} ", .{keyStates[sI].state});
    while(bruh.next()) |qI| {
        std.debug.print("{}, ", .{qI});
    }
    std.debug.print("\n", .{});
}
/// Fires in a non deterministic way relavtive to frame updates
/// May fire multiple times per frame or not at all
fn onKeyEvent(window: *minifb.cWindow, key: minifb.Key, keyMod: minifb.KeyMod, isPressed: bool) callconv(.c) void {
    _ = window;
    _ = keyMod;
    const index = @as(usize, @intCast(@intFromEnum(key)));

    if (!isPressed) {
        // enqueue release once, then stop
        if (keyStates[index].queue.back()) |back| if (back == .released) return;
        keyStates[index].queue.pushBack(allocator, .released) catch |err| {
            std.debug.print("queue push error: {}\n", .{err});
        };
        return; // critical: don't enqueue anything else on release
    }

    // Press path: only enqueue if not already logically down
    if (keyStates[index].state == .pressed or keyStates[index].state == .held) return;
    if (keyStates[index].queue.back()) |back| if (back == .pressed or back == .held) return;

    keyStates[index].queue.pushBack(allocator, .pressed) catch |err| {
        std.debug.print("queue push error: {}\n", .{err});
    };
}

pub fn initInput(window: *minifb.Window, alloc: std.mem.Allocator) !void {
    allocator = alloc;
    for(&keyStates) |*state|{
        state.*.queue = try .initCapacity(alloc, 16);
    }
    window.onKeyboard(onKeyEvent);
    activeWindow = window;
}

pub inline fn getKeyDown(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed;
    // return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].superState.pressed;
}

pub inline fn getKey(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed or keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .held;
    // return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].superState.held or keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].superState.pressed;
}

pub inline fn getKeyUp(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .released;
    // return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].superState.released;
}

pub inline fn getMouseX() f32 {
    return activeWindow.getMouseX();
}
pub inline fn getMouseY() f32 {
    return activeWindow.getMouseY();
}
