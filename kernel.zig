const console = @import("console.zig");
const idt = @import("idt.zig");
const interrupts = @import("interrupts.zig");
const pic = @import("pic.zig");

/// Define constants for Multiboot header flags
const ALIGN = 1 << 0; // Align to 4-byte boundary
const MEMINFO = 1 << 1; // Include memory info
const MB1_MAGIC: u32 = 0x1BADB002; // Magic number for Multiboot1 specification
const FLAGS: u32 = ALIGN | MEMINFO; // Combined flags for Multiboot header

/// Define a packed structure for the Multiboot header
const MultibootHeader = extern struct {
    magic: u32 = MB1_MAGIC, // Magic number identifying Multiboot
    flags: u32, // Flags indicating which information is present
    checksum: u32, // Checksum for validation
};

/// Initialize the Multiboot header with proper alignment and section placement
export var multiboot align(4) linksection(".multiboot") = MultibootHeader{
    .flags = FLAGS, // Set the flags
    .checksum = @as(u32, ((-(@as(i64, MB1_MAGIC) + @as(i64, FLAGS))) & 0xFFFFFFFF)), // Compute checksum
};

/// Entry point of the program, visible to the linker
/// Uses naked calling convention and does not return
export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\  mov $stack_top, %%esp
        \\  call main
        \\  cli
        \\1:
        \\  hlt
        \\  jmp 1b
        ::: "memory");
}

/// Main function of the program
pub export fn main() void {
    console.setColors(.White, .Blue);
    console.clear();
    console.putString("Hello, world!");
    console.setForegroundColor(.LightRed);
    console.putChar('!');

    // Initialize IDT
    // TODO: FIGURE OUT WHY THIS BREAKS THE HEADER WHEN CALLED (NO MULTIBOOT HEADER FOUND WHEN UNCOMMENTED)
    // interrupts.init();

    // Enter an infinite loop to keep the kernel running
    while (true) {
        asm volatile ("hlt");
    }
}

// Ensure we have a stack
export var stack_bottom: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
export const stack_top = &stack_bottom[stack_bottom.len - 1];
