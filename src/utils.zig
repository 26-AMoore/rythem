const rl = @import("raylib");
const std = @import("std");
const main = @import("main.zig");

pub fn loadTextureFromMem(comptime memory: [:0]const u8) !rl.Texture2D {
    return rl.loadTextureFromImage(try rl.loadImageFromMemory(".png", memory));
}

pub fn drawFps() !void {
    var fps_buf: [5]u8 = undefined; //Okay because we know buffer size and it is constant
    const fps: [:0]u8 = try std.fmt.bufPrintSentinel(&fps_buf, "{d}", .{rl.getFPS()}, 0);
    const fpsSize = rl.measureText(fps, main.fontSize);

    rl.drawRectangle(0, 0, fpsSize + 4, main.fontSize, .black);
    rl.drawText(fps, 1, 0, main.fontSize, .green);
}

pub fn printCentered(text: [:0]const u8, x: i32, y: i32, fontsize: ?i32, color: ?rl.Color) !void {
    const size = rl.measureText(text, fontsize orelse 20);
    rl.drawText(text, x - @divFloor(size, 2), y, fontsize orelse 20, color orelse .black);
}
