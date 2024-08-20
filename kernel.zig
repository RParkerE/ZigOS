const console = @import("console.zig");
const idt = @import("idt.zig");
const interrupts = @import("interrupts.zig");
const pic = @import("pic.zig");
const pmm = @import("memory_manager.zig");
const pit = @import("pit.zig");
const keyboard = @import("keyboard.zig");

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
    console.setColors(.Blue, .LightGray);
    console.clear();
    console.putString("Welcome To ZigOS");
    console.setForegroundColor(.LightRed);
    console.putChar('!');

    console.putString("\nInitializing interrupts...");
    interrupts.init();
    console.putString(" Done.");

    console.putString("\nInitializing physical memory manager...");
    pmm.init();
    console.putString(" Done.");

    console.putString("\nPhysical Memory Manager initialized");

    // Example usage of the physical memory manager
    if (pmm.allocate_page()) |page| {
        console.printf("\nAllocated page at address: 0x{X:0>16}", .{@intFromPtr(&page)});
    } else {
        console.putString("\nFailed to allocate page");
    }

    console.putString("\nSystem initialized. Press keys to see them echo.\n");

    var counter: u32 = 0;
    while (true) {
        asm volatile ("hlt");
        counter += 1;
        if (counter % 100 == 0) { // Assuming PIT is set to 100Hz
            console.putChar('.');
        }
    }
}

// Ensure we have a stack
export var stack_bottom: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
export const stack_top = &stack_bottom[stack_bottom.len - 1];
