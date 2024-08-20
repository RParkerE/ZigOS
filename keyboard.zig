const pic = @import("pic.zig");
const console = @import("console.zig");

const KEYBOARD_DATA_PORT = 0x60;

const SCANCODE_MAP = [_]u8{ 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n', 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' ' };

pub fn handler() void {
    const scancode = pic.inb(KEYBOARD_DATA_PORT);
    console.printf("Keyboard interrupt received. Scancode: {d}\n", .{scancode});

    if (scancode < SCANCODE_MAP.len) {
        const key = SCANCODE_MAP[scancode];
        if (key != 0) {
            console.putChar(key);
        }
    }

    pic.sendEOI(1);
}
