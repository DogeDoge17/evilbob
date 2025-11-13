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

pub var mouseStates: [max_mouse_count]KeyStatus = [_]KeyStatus{ 
    .{  .frame = 0, 
        .state = .inactive,
        .queue = deque.Deque(KeyStates).empty, 
    } 
} ** max_mouse_count;

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

const max_mouse_count:usize = blk: {
    const fields = @typeInfo(minifb.MouseButton).@"enum".fields;
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
    
    // for (0..mouseStates.len) |i| {
    //     const button:*KeyStatus = &mouseStates[i];
    //
    //     const capturedEvent = button.queue.popFront();
    //     if(capturedEvent) |event| {
    //         std.debug.print("{}\n", .{event});
    //         button.*.state = event;
    //     } else if(button.frame < currentFrame) {
    //         button.*.state = switch(button.*.state) {
    //             .released => .inactive,
    //             .held => .held,
    //             .pressed => .held,
    //             .inactive => .inactive
    //         };
    //     }
    // }  
    
    // const buttonStatus = activeWindow.getMouseButtonBuffer();

    // for(0..8) |i| {
    //     mouseStates[i].state = if(buttonStatus[i] == 0) switch(mouseStates[i].state) {
    //             .inactive => .inactive,
    //             .held => .released,
    //             .pressed => .released,
    //             .released => .inactive
    //         }
    //         else switch(mouseStates[i].state) {
    //             .inactive => .pressed,
    //             .held => .pressed,
    //             .pressed => .released,
    //             .released => .inactive
    //     };
    // }
    //
    for (0..mouseStates.len) |i| {
        const button:*KeyStatus = &mouseStates[i];

        const capturedEvent = button.queue.popFront();
        if(capturedEvent) |event| {
            button.*.state = event;
        } else {
            button.*.state = switch(button.*.state) {
                .released => .inactive,
                .held => .held,
                .pressed => .held,
                .inactive => .inactive
            };
        }
    }  
}

/// Fires in a non deterministic way relavtive to frame updates
/// May fire multiple times per frame or not at all
fn onKeyEvent(window: *minifb.cWindow, key: minifb.Key, keyMod: minifb.KeyMod, isPressed: bool) callconv(.c) void {
    _ = window;
    _ = keyMod;
    const index = @as(usize, @intCast(@intFromEnum(key)));

    if (!isPressed) {
        if (keyStates[index].queue.back()) |back| if (back == .released) return;
        keyStates[index].queue.pushBack(allocator, .released) catch |err| {
            std.debug.print("queue push error: {}\n", .{err});
        };
        return; 
    }

    if (keyStates[index].state == .pressed or keyStates[index].state == .held) return;
    if (keyStates[index].queue.back()) |back| if (back == .pressed or back == .held) return;

    keyStates[index].queue.pushBack(allocator, .pressed) catch |err| {
        std.debug.print("queue push error: {}\n", .{err});
    };
}

fn onMouseEvent(window: *minifb.cWindow, button: minifb.MouseButton, keyMod: minifb.KeyMod, is_pressed: bool) callconv(.c) void {
    _ = window;
    _ = keyMod;
    const index = @as(usize, @intCast(@intFromEnum(button)));

    // mouseStates[index].frame = currentFrame;

    if(is_pressed) {
        mouseStates[index].queue.pushBack(allocator, .pressed) catch |err| {
            std.debug.print("queue push error: {}\n", .{err});
        };
    }
    else {
        mouseStates[index].queue.pushBack(allocator, .released) catch |err| {
            std.debug.print("queue push error: {}\n", .{err});
        };
    }


    // if (!is_pressed) {
    //     if (mouseStates[index].queue.back()) |back| if (back == .released) return;
    //     mouseStates[index].queue.pushBack(allocator, .released) catch |err| {
    //         std.debug.print("queue push error: {}\n", .{err});
    //     };
    //     return; 
    // }
    //
    // if (mouseStates[index].state == .pressed or mouseStates[index].state == .held) return;
    // if (mouseStates[index].queue.back()) |back| if (back == .pressed or back == .held) return;
    //
    // mouseStates[index].queue.pushBack(allocator, .pressed) catch |err| {
    //     std.debug.print("queue push error: {}\n", .{err});
    // };
}

pub fn initInput(window: *minifb.Window, alloc: std.mem.Allocator) !void {
    allocator = alloc;
    for(&keyStates) |*state|{
        state.*.queue = try .initCapacity(alloc, 16);
    }
    for(&mouseStates) |*state|{
        state.*.queue = try .initCapacity(alloc, 16);
    }
    window.onKeyboard(onKeyEvent);
    window.onMouseButton(onMouseEvent);
    activeWindow = window;
}

pub inline fn getKeyDown(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed;
}

pub inline fn getKey(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed or keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .held;
}

pub inline fn getKeyUp(keyCode: minifb.Key) bool {
    return keyStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .released;
}

pub inline fn getMouseDown(keyCode: minifb.MouseButton) bool {
    return mouseStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed;
}

pub inline fn getMouse(keyCode: minifb.MouseButton) bool {
    return mouseStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .pressed or mouseStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .held;
}

pub inline fn getMouseUp(keyCode: minifb.MouseButton) bool {
    return mouseStates[@as(usize, @intCast(@intFromEnum(keyCode)))].state == .released;
}

pub var mx_offset: i32 = 0;
pub var my_offset: i32 = 0;
pub var mx_multiplier: f32 = 0;
pub var my_multiplier: f32 = 0;
pub inline fn getMouseXA(comptime T: anytype) T {
    const mx = @as(f32, @floatFromInt(@max(activeWindow.getMouseX() - mx_offset, 0))) * mx_multiplier;
    return @as(T, switch(@typeInfo(@TypeOf(T))) {
        .float => @floatCast(mx),
        .int =>  @intFromFloat(mx),
        else => @intFromFloat(mx)
    });
}

pub inline fn getMouseYA(comptime T: anytype) T {
    const my = @as(f32, @floatFromInt(@max(activeWindow.getMouseY() - my_offset, 0))) * my_multiplier;
    return @as(T, switch(@typeInfo(@TypeOf(T))) {
        .float => @floatCast(my),
        .int =>  @intFromFloat(my),
        else => @intFromFloat(my)
    });
}

pub inline fn getMouseX() f32 {
    return activeWindow.getMouseX() + mx_offset;
}
pub inline fn getMouseY() f32 {
    return activeWindow.getMouseY() + my_offset;
}
