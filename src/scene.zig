pub const VTable = struct {
    init: *const fn() void,
    deinit: *const fn() void,
    update: *const fn() void,
    render: *const fn() void,
};

pub var loadedScene: ?VTable = null;

pub fn loadScene(comptime T: anytype) !void {
    if(loadedScene) |loaded| {
        loaded.deinit();
    }

    loadedScene = .{
        .deinit = @as(*const fn() void,@ptrCast(&@field(T, "deinit"))),
        .render = @as(*const fn() void,@ptrCast(&@field(T, "render"))),
        .init = @as(*const fn() void,@ptrCast(&@field(T, "init"))),
        .update = @as(*const fn() void,@ptrCast(&@field(T, "update"))),
    };
    loadedScene.?.init();
}

pub inline fn update() void {
    loadedScene.?.update();
}

pub inline fn deinit() void {
    loadedScene.?.deinit();
}

pub inline fn render() void {
    loadedScene.?.render();
}

pub inline fn init() void {
    loadedScene.?.init();
}
