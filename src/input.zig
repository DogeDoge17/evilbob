const minifb = @import("minifb");
const std = @import("std");
const deque = @import("deque.zig");

const KeyStatus = struct {
    state: KeyStates,
    frame: u64,
    queue: deque.Deque(KeyStates),
};

const KeyStates = enum {
    inactive,
    pressed,
    held,
    released,
};

pub var keyStates: [max_key_count]KeyStatus = [_]KeyStatus{ .{ .frame = 0, .state = .inactive,  .queue = deque.Deque(KeyStates).empty  } } ** max_key_count;
var currentFrame: u64 = 0;

const max_key_count:usize = blk: {
    const fields = @typeInfo(minifb.Key).@"enum".fields;
    var max = 0;
    for (fields) |field| {
        max = @max(max, field.value);
    }
    break :blk max + 1;
};

pub fn update(frame: u64) void {
    currentFrame = frame;
    const spaceKeyIndex = @as(usize, @intCast(@intFromEnum(minifb.Key.Space))); 
    if(keyStates[spaceKeyIndex].state != .inactive) {
        printState(spaceKeyIndex, "start of update loop");
    }
    for (0..keyStates.len) |i| {
        const lastStat = keyStates[i].state;
        if(keyStates[i].frame == currentFrame) 
            continue;
        keyStates[i].state = switch(keyStates[i].state) {
            .pressed => .held,
            .released => .inactive,
            else => keyStates[i].state,
        };

        if(i == spaceKeyIndex and lastStat != .inactive) {
            printState(i, "update loop");
            std.debug.print("\n", .{});
        }
 
    }
}

fn printState(i:usize, text: []const u8) void {
    std.debug.print("{s} -- currFrame {}\tkey frame {}\tkey state {}\n", .{text, currentFrame, keyStates[i].frame, keyStates[i].state});
}

fn onKeyEvent(window: *minifb.cWindow, key: minifb.Key, keyMod: minifb.KeyMod, isPressed: bool) callconv(.c) void {
    _ = window;
    _ = keyMod;
    const index = @as(usize, @intCast(@intFromEnum(key)));
    
    printState(index, "start of hook");
    if(!isPressed) {
        keyStates[index].frame = currentFrame;
        keyStates[index].state = .released; 
        printState(index, "release hook");
        std.debug.print("\n", .{});
        return;
    }

    if(keyStates[index].frame == currentFrame) 
        return;
    keyStates[index].frame = currentFrame;

    keyStates[index].state = switch(keyStates[index].state) {
        .inactive => .pressed,
        .released => .pressed,
        else => keyStates[index].state,
    };
    printState(index, "end hook");
    std.debug.print("\n", .{});
}

pub fn initHooks(window: *minifb.Window) void {
    window.onKeyboard(onKeyEvent);
}

pub fn GetKeyDown(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed;
}

pub fn GetKey(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed or keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .held;
}

pub fn GetKeyUp(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .released;
}
