const std = @import("std");

pub fn main() !void { 
    const cwd = std.fs.cwd();
    var dir = try cwd.openDir(".", .{ .iterate =  true });
    defer dir.close();

    var it = dir.iterate();

    while(try it.next()) |entry| {
        if(entry.kind == .file) {
            if(std.mem.endsWith(u8, entry.name, ".png")) {
                const tga = try std.mem.concat(std.heap.page_allocator, u8, &.{ entry.name[0..entry.name.len - 3], "tga" });
                // const tga = try std.mem.concat(std.heap.page_allocator, u8, .{ "hi", "tga" });
                defer std.heap.page_allocator.free(tga);

                var mag = std.process.Child.init(&.{"magick", entry.name, "-rotate", "270", tga }, std.heap.page_allocator);
                _ = try mag.spawnAndWait();
            }
        }
    }

}
