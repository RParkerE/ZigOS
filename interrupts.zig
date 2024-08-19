const std = @import("std");
const idt = @import("idt.zig");
const handlers = @import("handlers.zig");
const pic = @import("pic.zig");

/// Enable CPU interrupts.
pub fn enable() void {
    asm volatile ("sti");
}

/// Initialize interrupts
pub fn init() void {
    idt.init();
    handlers.registerHandlers();
    pic.init();
    enable();
}
