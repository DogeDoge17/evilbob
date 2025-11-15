const std = @import("std");

test "frac" {
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

const perm: [512]u8 = .{
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
    8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,
    11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,
    139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,
    245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
    200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,
    124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,
    28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,
    9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,
    49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,
    236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
    151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
    8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,
    11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,134,
    139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,
    245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
    200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,250,
    124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,
    28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,
    9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,107,
    49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,138,
    236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
};

pub fn fade(t: f32) f32 {
    return t * t * t * (t * (t * 6 - 15) + 10);
}

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + t * (b - a);
}

pub fn grad(hash: u8, x: f32) f32 {
    return if ((hash & 1) == 0) x else -x;
}

pub fn perlin1D(px: f32) f32 {
    const X = @as(usize, @intFromFloat(@floor(px))) & 255;
    const x = px - @floor(px);
    const u = fade(x);

    const a = perm[X];
    const b = perm[X + 1];

    const value = lerp(grad(a, x), grad(b, x - 1), u);

    return (value + 1) * 0.5;
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
