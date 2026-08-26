const rl = @import("raylib");
const std = @import("std");
const utils = @import("utils.zig");

pub const fontSize: i32 = 20;

const VWidth = 50;
const VHeight = 80;
const VScale = 10.0;

const Height = VHeight * VScale;
const Width = VWidth * VScale;

var currentHeight: i64 = 0;
var score: u64 = 0;
const speed = 10;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const alloc = gpa.allocator();

    _ = .{alloc};

    rl.initWindow(Width, Height, "rythem");
    rl.setTargetFPS(60);

    const renderTexture: rl.RenderTexture2D = try rl.loadRenderTexture(VWidth, VHeight);
    const renderTextureSrc: rl.Rectangle = rl.Rectangle{ .x = 0, .y = 0, .height = -VHeight, .width = VWidth };
    const renderTextureDest: rl.Rectangle = rl.Rectangle{ .x = 0, .y = 0, .height = Height, .width = Width };

    const nrarrow = try utils.loadTextureFromMem(@embedFile("media/nrarrow.png"));
    const nlarrow = try utils.loadTextureFromMem(@embedFile("media/nlarrow.png"));
    const ndarrow = try utils.loadTextureFromMem(@embedFile("media/ndarrow.png"));
    const nuarrow = try utils.loadTextureFromMem(@embedFile("media/nuarrow.png"));

    var rList: std.Deque(Arrow) = .empty;
    var dList: std.Deque(Arrow) = .empty;
    var uList: std.Deque(Arrow) = .empty;
    var lList: std.Deque(Arrow) = .empty;

    for (0..1) |i| {
        try rList.pushBack(alloc, try Arrow.new(.Right, @as(i64, @intCast(i)) * 10));
    }
    for (0..0) |i| {
        try dList.pushBack(alloc, try Arrow.new(.Down, @as(i64, @intCast(i)) * 10));
    }
    for (0..1) |i| {
        try uList.pushBack(alloc, try Arrow.new(.Up, @as(i64, @intCast(i)) * 10));
    }
    for (0..2) |i| {
        try lList.pushBack(alloc, try Arrow.new(.Left, @as(i64, @intCast(i)) * 10));
    }

    while (!rl.windowShouldClose()) {
        rl.beginTextureMode(renderTexture);
        {
            rl.clearBackground(.gray);

            rl.drawTexture(nlarrow, 2, VHeight - 12, .white);
            rl.drawTexture(ndarrow, 14, VHeight - 12, .white);
            rl.drawTexture(nuarrow, 26, VHeight - 12, .white);
            rl.drawTexture(nrarrow, 38, VHeight - 12, .white);
            rl.drawLine(0, VHeight - 14, VWidth, VHeight - 14, .black);
        }
        rl.endTextureMode();
        currentHeight += speed;

        rl.beginDrawing();
        {
            rl.drawTexturePro(renderTexture.texture, renderTextureSrc, renderTextureDest, rl.Vector2{ .x = 0, .y = 0 }, 0, .white);
            drawUntilOffScreen(rList);
            drawUntilOffScreen(dList);
            drawUntilOffScreen(lList);
            drawUntilOffScreen(uList);

            try cleanse(&rList);
            try cleanse(&dList);
            try cleanse(&lList);
            try cleanse(&uList);

            var char = rl.getCharPressed();
            while (char != 0) {
                // lwk this is faulty idc
                switch (char) {
                    'h' => {
                        const popped = lList.popFront() orelse break;
                        score += getScore(&popped);
                    },
                    'j' => {
                        const popped = dList.popFront() orelse break;
                        score += getScore(&popped);
                    },
                    'k' => {
                        const popped = uList.popFront() orelse break;
                        score += getScore(&popped);
                    },
                    'l' => {
                        const popped = rList.popFront() orelse break;
                        score += getScore(&popped);
                    },
                    else => {},
                }
                char = rl.getCharPressed();
            }

            std.log.debug("height: {}", .{currentHeight});

            var scorebuf: [16]u8 = undefined;
            const scoreStr = try std.fmt.bufPrintSentinel(&scorebuf, "score: {}", .{score}, 0);
            try utils.printCentered(scoreStr, Width / 2, 10, fontSize * 3, .black);
            try utils.drawFps();
        }
        rl.endDrawing();
    }
}

fn getScore(arrow: *const Arrow) u64 {
    return @abs(100 - @as(i64, @intCast(@abs(arrow.height - currentHeight))));
}

fn cleanse(list: *std.Deque(Arrow)) !void {
    if (list.len == 0) {
        return;
    }
    while ((list.frontPtr() != null) and list.frontPtr().?.position.y >= @as(i32, @trunc(Height))) {
        _ = list.popFront() orelse return;
    }
}

fn drawUntilOffScreen(list: std.Deque(Arrow)) void {
    var i: usize = 0;
    if (list.len == 0) {
        return;
    }
    while (list.atPtr(i).height <= currentHeight) {
        list.atPtr(i).draw();
        i += 1;
        if (i >= list.len) {
            return;
        }
    }
}

const ArrowDirection = enum { Up, Left, Down, Right };

const Arrow = struct {
    direction: ArrowDirection,
    image: rl.Texture,
    position: rl.Vector2,
    height: i64,
    pub fn new(direction: ArrowDirection, height: i64) !Arrow {
        const image = switch (direction) {
            ArrowDirection.Up => try utils.loadTextureFromMem(@embedFile("media/uarrow.png")),
            ArrowDirection.Left => try utils.loadTextureFromMem(@embedFile("media/larrow.png")),
            ArrowDirection.Down => try utils.loadTextureFromMem(@embedFile("media/darrow.png")),
            ArrowDirection.Right => try utils.loadTextureFromMem(@embedFile("media/rarrow.png")),
        };
        const position = switch (direction) {
            ArrowDirection.Up => rl.Vector2{ .x = 26 * VScale, .y = 0 },
            ArrowDirection.Left => rl.Vector2{ .x = 2 * VScale, .y = 0 },
            ArrowDirection.Down => rl.Vector2{ .x = 14 * VScale, .y = 0 },
            ArrowDirection.Right => rl.Vector2{ .x = 38 * VScale, .y = 0 },
        };
        return Arrow{ .height = height, .image = image, .position = position, .direction = direction };
    }

    pub fn draw(self: *Arrow) void {
        self.position.y = self.position.y + speed;
        rl.drawTextureEx(self.image, self.position, 0, VScale, .white);
        std.debug.print("position: {}\n", .{self.position.y});
    }
};
