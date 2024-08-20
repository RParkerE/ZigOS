const std = @import("std");
const idt = @import("idt.zig");
const handlers = @import("handlers.zig");
const pic = @import("pic.zig");
const pit = @import("pit.zig");
const console = @import("console.zig");

/// Enable CPU interrupts.
pub fn enable() void {
    console.putString("About to enable interrupts...\n");
    asm volatile ("sti");
    console.putString("Interrupts should be enabled now.\n");
}

/// Initialize interrupts
pub fn init() void {
    console.putString("\nInitializing IDT...");
    idt.init();
    console.putString(" Done.\n");

    console.putString("Registering interrupt handlers...");
    handlers.registerHandlers();
    console.putString(" Done.\n");

    console.putString("Initializing PIC...");
    pic.init();
    console.putString(" Done.\n");

    //console.putString("Initializing PIT...");
    //pit.init(100); // Initialize PIT with 100 Hz frequency
    //console.putString(" Done.\n");

    console.putString("Enabling interrupts...");
    enable();
    console.putString(" Done.\n");
}
