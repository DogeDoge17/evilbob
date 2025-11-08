// sir just use @Vector 
// NOOOOOOOOOOOOOOOOOOO

pub fn Vector2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn add(a: *const @This(), b: @This()) @This() {
            return .{
                .x = a.x + b.x,
                .y = a.y + b.y,
            };
        }

        pub fn sub(a: *const @This(), b: @This()) @This() {
            return .{
                .x = a.x - b.x,
                .y = a.y - b.y,
            };
        }
        pub fn mul(a: *const @This(), b: T) @This() {
            return .{
                .x = a.x * b,
                .y = a.y * b,
            };
        }

        pub fn normalize(v: *const @This()) @This() {
            const length = @sqrt(v.x * v.x + v.y * v.y);
            if (length == 0) {
                return .{ .x = 0, .y = 0 };
            }
            return .{
                .x = v.x / length,
                .y = v.y / length,
            };
        }

        pub fn magnitude(v: *const @This()) T {
            return @sqrt(v.x * v.x + v.y * v.y);
        }

        pub fn distance(a: *const @This(), b: @This()) T {
            const dx = a.x - b.x;
            const dy = a.y - b.y;
            return @sqrt(dx * dx + dy * dy);
        }

        pub fn moveTowards(current: *const @This(), target: *const @This(), maxDistanceDelta: T) @This() {
            const toVector_x = target.x - current.x;
            const toVector_y = target.y - current.y;

            const sqDist = toVector_x * toVector_x + toVector_y * toVector_y;

            if (sqDist == 0 or (maxDistanceDelta * maxDistanceDelta) >= sqDist) {
                return .{ .x = target.x, .y = target.y };
            }

            const dist = @sqrt(sqDist);

            return .{
                .x = current.x + toVector_x / dist * maxDistanceDelta,
                .y = current.y + toVector_y / dist * maxDistanceDelta,
            };
        }
    };
}

pub fn Rectangle(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        width: T,
        height: T,
    };
}

// pub const FVector2 = struct {
//     x: f32,
//     y: f32,
// };
//
// pub const Vector2 = struct {
//     x: i32,
//     y: i32,
// };
//
// pub const FVector3 = struct {
//     x: f32,
//     y: f32,
//     z: f32,
// };
