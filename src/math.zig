// sir just use @Vector 
// NOOOOOOOOOOOOOOOOOOO
//

test "frac" {
    const std = @import("std");

    const num, const dem = decimal2Frac(1.0/3.0);
    std.debug.print("{}/{}\n", .{num, dem});
    try std.testing.expect(num == 1 and dem == 3);

}

pub fn decimal2Frac(decimal:f32) struct{ f32, f32 } {
    const original_abs_value = @abs(decimal);
    const decimal_sign: f32 = if(decimal < 0) -1 else 1;

    if(original_abs_value == @trunc(original_abs_value)) { return .{original_abs_value * decimal_sign, 1}; }
    if(original_abs_value < 1.0E-19) { return .{0, 1}; }
    if(original_abs_value > 1.0E19) { return .{ 9999999 * decimal_sign, 1}; }

    var z = original_abs_value;
    var previous_denominator: f32 = 0;
    var out_numerator: f32 = @trunc(z);
    var out_denominator: f32 = 1;
    var scratch_value:f32 = undefined;

    const max_iter = 100;
    for(0..max_iter) |_| {
        z = (z - @trunc(z));
        if(z < 0.00001) break;
        z = 1 / z;

        scratch_value = out_denominator;
        out_denominator = (out_denominator * @trunc(z)) + previous_denominator;
        previous_denominator = scratch_value;

        out_numerator = @floor(original_abs_value * out_denominator + 0.5);

        if(@abs(original_abs_value - (out_numerator / out_denominator)) < 0.00001) break;
    } 


    return .{out_numerator * decimal_sign, out_denominator};
}

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
