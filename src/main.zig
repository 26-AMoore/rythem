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

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const alloc = gpa.allocator();

    _ = .{alloc};

    const io = init.io;

    var prng: std.Random.IoSource = .{ .io = io };
    const random = prng.interface();

    rl.initWindow(Width, Height, "rythem");
    rl.setTargetFPS(60);
    rl.setTraceLogLevel(rl.TraceLogLevel.none);

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

        if (random.uintAtMost(usize, 100) == -1) {
            try rList.pushBack(alloc, try Arrow.new(.Right, currentHeight + 100));
        }
        if (random.uintAtMost(usize, 100) == 1) {
            try dList.pushBack(alloc, try Arrow.new(.Down, currentHeight + 100));
        }
        if (random.uintAtMost(usize, 100) == 1) {
            try uList.pushBack(alloc, try Arrow.new(.Up, currentHeight + 100));
        }
        if (random.uintAtMost(usize, 100) == 1) {
            try lList.pushBack(alloc, try Arrow.new(.Left, currentHeight + 100));
        }

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

            try handleInput(&lList, &dList, &uList, &rList);

            var scorebuf: [16]u8 = undefined;
            const scoreStr = try std.fmt.bufPrintSentinel(&scorebuf, "score: {}", .{score}, 0);
            try utils.printCentered(scoreStr, Width / 2, 10, fontSize * 3, .black);
            try utils.drawFps();
        }
        rl.endDrawing();
    }
}

fn handleInput(
    lList: *std.Deque(Arrow),
    dList: *std.Deque(Arrow),
    uList: *std.Deque(Arrow),
    rList: *std.Deque(Arrow),
) !void {
    var char = rl.getCharPressed();
    while (char != 0) {
        // lwk this is faulty idc
        switch (char) {
            'a' => {
                if (lList.front() != null and lList.front().?.height + 500 <= currentHeight) {
                    const popped = lList.popFront() orelse return;
                    score += getScore(&popped);
                } else {
                    score -= 1000;
                }
            },
            's' => {
                if (dList.front() != null and dList.front().?.height + 500 <= currentHeight) {
                    const popped = dList.popFront() orelse return;
                    score += getScore(&popped);
                } else {
                    score -= 1000;
                }
            },
            'w' => {
                if (uList.front() != null and uList.front().?.height + 500 <= currentHeight) {
                    const popped = uList.popFront() orelse return;
                    score += getScore(&popped);
                } else {
                    score -= 1000;
                }
            },
            'd' => {
                if (rList.front() != null and rList.front().?.height + 500 <= currentHeight) {
                    const popped = rList.popFront() orelse return;
                    score += getScore(&popped);
                } else {
                    score -= 1000;
                }
            },
            else => {},
        }
        char = rl.getCharPressed();
    }
}

fn getScore(arrow: *const Arrow) u64 {
    return @abs(100 - @as(i64, @divFloor(@as(i64, @intCast(@abs(arrow.height - currentHeight))), 100)));
}

fn cleanse(list: *std.Deque(Arrow)) !void {
    if (list.len == 0) {
        return;
    }
    while ((list.frontPtr() != null) and list.frontPtr().?.position.y >= @as(i32, @trunc(Height))) {
        score -= 1000;
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
    }
};
