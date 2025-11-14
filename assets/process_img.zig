const std = @import("std");

// Preps the PNG images in the current directory by rotating them and converting to TGA format.
// Requires ImageMagick (magick) 
//   https://imagemagick.org/
pub fn main() !void { 
    const cwd = std.fs.cwd();
    var dir = try cwd.openDir(".", .{ .iterate =  true });
    defer dir.close();

    var stdout = std.fs.File.stdout().writerStreaming(&.{});
    defer stdout.interface.flush() catch |err| {
        std.debug.print("Failed to flush stdout: {}\n", .{err});
    };
    var it = dir.iterate();

    var comic = false;
    while(try it.next()) |entry| {
        if(entry.kind == .file) {
            if(std.mem.endsWith(u8, entry.name, ".png")) {
                const tga = try std.mem.concat(std.heap.page_allocator, u8, &.{ entry.name[0..entry.name.len - 3], "tga" });
                defer std.heap.page_allocator.free(tga);

                var mag = std.process.Child.init(&.{"magick", entry.name, "-rotate", "270", tga }, std.heap.page_allocator);
                _ = try mag.spawnAndWait();
                const name = tga[0..std.mem.lastIndexOf(u8, tga, ".") orelse tga.len];

                if(std.mem.eql(u8, name, "comic")){
                    comic = true;
                    continue;
                }
                try stdout.interface.print("\"{s}\",\n", .{name});
            }
        }
    }
    
    if(comic) {
        try stdout.interface.print("\"comic\",\n", .{}); // your guess is as good as mine brotato chip
    }
}
