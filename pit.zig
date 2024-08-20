const pic = @import("pic.zig");
const console = @import("console.zig");

const PIT_CHANNEL0_DATA = 0x40;
const PIT_COMMAND = 0x43;
const PIT_FREQUENCY = 1193182;

var ticks: u64 = 0;

pub fn init(frequency: u32) void {
    const divisor = PIT_FREQUENCY / frequency;

    // Set PIT to generate square wave
    pic.outb(PIT_COMMAND, 0x36);

    // Set PIT frequency
    pic.outb(PIT_CHANNEL0_DATA, @truncate(divisor));
    pic.outb(PIT_CHANNEL0_DATA, @truncate(divisor >> 8));
}

pub fn handler() void {
    ticks += 1;
    if (ticks % 100 == 0) {
        console.printf("Tick: {}\n", .{ticks});
    }
    pic.sendEOI(0);
}

pub fn getTicks() u64 {
    return ticks;
}
