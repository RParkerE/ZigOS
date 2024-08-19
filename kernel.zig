const console = @import("console.zig");

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
    // Clear the base pointer register (EBP)
        \\ xorl %%ebp, %%ebp
        // Call the main function (_main)
        \\ call main
        // If main returns, trigger an undefined instruction exception to crash the program
        \\ ud2
    );
}

/// Main function of the program
pub export fn main() void {
    console.setColors(.White, .Blue);
    console.clear();
    console.putString("Hello, world!");
    console.setForegroundColor(.LightRed);
    console.putChar('!');
}
