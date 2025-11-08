const std = @import("std");

test "read-back" {
    const inFile = try std.fs.cwd().openFile("bin.fntdat", .{});
    defer inFile.close();
    const inContents = try inFile.readToEndAlloc(std.testing.allocator, 10 * 1024 * 1024);
    defer std.testing.allocator.free(inContents);
    var stdout = std.fs.File.stdout().writerStreaming(&.{});
    var i: usize = 0;
    var wrap:u8 = 0;
    while (i + 4 <= inContents.len) : (i += 4) {
        const b0 = inContents[i + 0];
        const b1 = inContents[i + 1];
        const b2 = inContents[i + 2];
        const b3 = inContents[i + 3];
        const number = @as(u32, b0)
            | (@as(u32, b1) << 8)
            | (@as(u32, b2) << 16)
            | (@as(u32, b3) << 24);
        try stdout.interface.print("{d} ", .{number});
        wrap += 1;
        if(wrap == 5) {
            wrap = 0;
            try stdout.interface.print("\n", .{});
            try stdout.interface.flush();
        }
    }
    try stdout.interface.flush();
}

pub fn main() !void {
    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer args.deinit(); 

    const this = args.next() orelse @panic("how");

    const filePath = args.next() orelse "";

    if(filePath.len == 0) {
        var stdout = std.fs.File.stdout().writerStreaming(&.{});
        try stdout.interface.print("Usage:\n {s} -- \"filepath\"\n", .{this});
        try stdout.interface.flush();
        return;
    }
    

    const inFile = try std.fs.cwd().openFile(filePath, .{});
    defer inFile.close();
    
    const inContents = try inFile.readToEndAlloc(std.heap.page_allocator, 10 * 1024 * 1024); 
    defer std.heap.page_allocator.free(inContents);
    
    const outFile = try std.fs.cwd().createFile("bin.fntdat", .{});
    defer outFile.close();

    var buff: [30]u8 = .{ 0 } ** 30;
    var i: usize = 0;

    var previous: u8 = 0;
    for(inContents) |char| {
        defer previous = char;
        switch(char) {
            ' ', '\n','\r', '\t' => {
                if(previous == ' ' or previous == '\n' or previous == '\r')
                    continue;
                var numBuff: [4]u8 = .{ 0 } ** 4;
                const foundNumber = try std.fmt.parseInt(u32, buff[0..i], 10);
                numBuff[0] = @as(u8, @intCast(foundNumber & 0xFF));
                numBuff[1] = @as(u8, @intCast((foundNumber >> 8) & 0xFF));
                numBuff[2] = @as(u8, @intCast((foundNumber >> 16) & 0xFF));
                numBuff[3] = @as(u8, @intCast((foundNumber >> 24) & 0xFF));
                _ = try outFile.write(numBuff[0..4]);
                i = 0;
            },
            else => {
                if (i >= buff.len) {
                    @panic("bro what is this number its too big!");
                }
                buff[i] = char; 
                i += 1;
            }
        }
    }
}
