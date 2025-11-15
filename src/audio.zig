const std = @import("std");
pub const miniaudio = @import("miniaudio_c");
pub const math = @import("math.zig");

const sound_clips = [_][:0]const u8{
    "sponge_walk",
    "im_evil_fella",
    "im_evil_spongebob",
    "sponge_scream",
    "bear_5_scream",
    "bear_5_theme",
    "bear_5_warning",
};
var embedded_sounds:[sound_clips.len][]const u8 = undefined;
pub var sounds: [sound_clips.len]Sound = undefined;

pub var engine: miniaudio.ma_engine = .{};

pub fn resetEngine() void{
    miniaudio.ma_engine_listener_set_direction(&engine, 0, 0, 0, 0);
    miniaudio.ma_engine_listener_set_position(&engine, 0, 0, 0, 0);
    miniaudio.ma_engine_listener_set_velocity(&engine, 0, 0, 0, 0);
    for(&sounds) |*sound| {
        _ = miniaudio.ma_sound_seek_to_pcm_frame(&sound.sound, 0);
        _ = miniaudio.ma_sound_stop(&sound.sound);
    }
}

pub const Assets = blk: {
    var fields: [sound_clips.len]std.builtin.Type.EnumField = undefined;

    for (sound_clips, 0..) |name, i| {
        fields[i] = .{ .name = name, .value = i };
    }

    const enumInfo = std.builtin.Type.Enum{
        .tag_type = usize,
        .fields = &fields,
        .decls = &[0]std.builtin.Type.Declaration{},
        .is_exhaustive = false,
    };
    break:blk @Type(std.builtin.Type{ .@"enum" = enumInfo });
};

pub const Sound = struct{
    decoder: miniaudio.struct_ma_decoder = .{},
    sound: miniaudio.ma_sound = .{},

    pub fn setPosition(id:Assets, pos: math.Vector2(f32)) void {
        miniaudio.ma_sound_set_position(&sounds[@as(usize, @intFromEnum(id))].sound, pos.x, 0, pos.y);
    }

    pub fn play(id:Assets) !void {
        const res = miniaudio.ma_sound_start(&sounds[@as(usize, @intFromEnum(id))].sound);
        if(res != miniaudio.MA_SUCCESS) return error.play_fail;
    }

    pub fn setLoop(id:Assets, looping: bool) void{
        miniaudio.ma_sound_set_looping(&sounds[@as(usize, @intFromEnum(id))].sound,  @as(c_uint, @intFromBool(looping))); 
    }

    pub fn stop(id:Assets) void {
         _ = miniaudio.ma_sound_stop(&sounds[@as(usize, @intFromEnum(id))].sound);
    }

    pub fn isPlaying(id:Assets) bool {
        return miniaudio.ma_sound_is_playing(&sounds[@as(usize, @intFromEnum(id))].sound) > 0;
    }
};

pub fn init() !void {
    inline for(0..sound_clips.len) |i| {
        embedded_sounds[i] = @embedFile(sound_clips[i]);
    }

    var res = miniaudio.ma_engine_init(null, &engine);
    if(res != miniaudio.MA_SUCCESS){
        return error.engine_init_failure;
    }
    errdefer _ = miniaudio.ma_engine_uninit(&engine);

    for(&sounds, 0..) |*sound, i| {
        sound.* = .{};

        res = miniaudio.ma_decoder_init_memory( @as(*const anyopaque, @ptrCast(embedded_sounds[i])), embedded_sounds[i].len, null, &sound.decoder);
        if (res != miniaudio.MA_SUCCESS) return error.decode_fail;
        errdefer _ = miniaudio.ma_decoder_uninit(&sound.decoder);
        
        res = miniaudio.ma_sound_init_from_data_source(&engine, @as(*miniaudio.ma_data_source, @ptrCast(&sound.decoder)),
            miniaudio.MA_SOUND_FLAG_DECODE, null,  &sound.sound);
        if (res != miniaudio.MA_SUCCESS) return error.sound_load_fail;

        miniaudio.ma_sound_set_spatialization_enabled(&sound.sound, 1);
        miniaudio.ma_sound_set_position(&sound.sound, 0, 0, 0);
        miniaudio.ma_sound_set_attenuation_model(&sound.sound, miniaudio.ma_attenuation_model_exponential);
        miniaudio.ma_sound_set_min_distance(&sound.sound, 0.5);
        miniaudio.ma_sound_set_max_distance(&sound.sound, 50.0);
    }
}

// const Engine = struct {
//     eng: c.ma_engine = undefined,
//
//     pub fn init(self: *@This()) !void {
//         const res = c.ma_engine_init(0, &self.eng);
//         if(res != c.MA_SUCCESS){
//             return error.epic_fail;
//         } 
//     }
//     pub fn initSoundFromFile(engine:*@This(), sound: *Engine, file_path: [*:0]const u8, flags: u32, group: [*c]c.ma_sound_group, done_fence: [*c]c.ma_fence) !void {
//         const res = c.ma_sound_init_from_file(&engine.eng, file_path, flags, group, done_fence, &sound.eng);
//         if(res != c.MA_SUCCESS) {
//             return error.epic_fail;
//         } 
//     }
//
//     pub fn listenerSetPosition(self: *@This(), listener_index: u32, x:f32, y:f32, z:f32) void {
//         c.ma_engine_listener_set_position(&self.eng, listener_index, x, y, z);
//     }
//     pub fn listenerSetDirection(self: *@This(), listener_index: u32, x:f32, y:f32, z:f32) void {
//         c.ma_engine_listener_set_direction(&self.eng, listener_index, x, y, z);
//     }
//     pub fn deinit(self: *@This()) void {
//         c.ma_engine_uninit(&self.eng); 
//     }
// };
//
// const Sound = struct {
//     sound: c.ma_sound = undefined,
//
//     pub fn initFromFile(self:*@This(), engine: *Engine, file_path: [*:0]const u8, flags: u32, group: [*c]c.ma_sound_group, done_fence: [*c]c.ma_fence) !void {
//         const res = c.ma_sound_init_from_file(&engine.eng, file_path, flags, group, done_fence, &self.sound);
//         if(res != c.MA_SUCCESS) {
//             return error.epic_fail;
//         }
//     }
//
//     pub fn start(self: *@This()) i32 {
//         return c.ma_sound_start(&self.sound);
//     }
//
//     pub fn setPosition(self: *@This(), x:f32, y:f32, z:f32) void {
//         c.ma_sound_set_position(&self.sound, x, y, z); 
//     }
//
//     pub fn deinit(self: *@This()) void {
//         c.ma_sound_uninit(&self.sound);
//     }
// };



// test "spatial audio" {
//     var engine = Engine{};
//     try engine.init();
//     defer engine.deinit();
//
//     var sound = Sound{ .sound = .{} };
//     try sound.initFromFile(&engine, "test.mp3", 0, null, null);
//     defer sound.deinit();
//
//     var listener_angle:f32 = 0.0;
//     sound.setPosition(0, 0, -1);
//     engine.listenerSetPosition(0, 0, 0, 0);
//
//     _ = sound.start();
//
//     while(true) {
//         listener_angle += 0.01;
//         engine.listenerSetDirection(0, @sin(listener_angle), 0, @cos(listener_angle));
//         // 1 millisecond in nanoseconds
//         // there are 1_000_000 nanoseconds in a millisecond
//         std.Thread.sleep(1_000000);
//     }
// }

