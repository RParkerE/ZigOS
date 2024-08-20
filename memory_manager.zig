const console = @import("console.zig");
const std = @import("std");

// Constants
const MEMORY_SIZE: usize = 2 * 1024 * 1024 * 1024; // 2GB of RAM
const PAGE_SIZE: usize = 4096; // 4KB pages
const PAGE_TABLE_ENTRIES: usize = 1024;
const PAGE_DIRECTORY_ENTRIES: usize = 1024;

// Page Table Entry structure
const PageTableEntry = packed struct {
    present: bool = false,
    writable: bool = false,
    user_accessible: bool = false,
    write_through: bool = false,
    cache_disabled: bool = false,
    accessed: bool = false,
    dirty: bool = false,
    pat: bool = false,
    global: bool = false,
    available: u3 = 0,
    address: usize = 0,
};

// Page Directory Entry structure
const PageDirectoryEntry = packed struct {
    present: bool = false,
    writable: bool = false,
    user_accessible: bool = false,
    write_through: bool = false,
    cache_disabled: bool = false,
    accessed: bool = false,
    reserved: bool = false,
    page_size: bool = false,
    global: bool = false,
    available: u3 = 0,
    address: usize = 0,
};

// Global variables
var next_free_page: usize = 0x100000; // Start allocating after 1 MB
var page_directory: [PAGE_DIRECTORY_ENTRIES]PageDirectoryEntry align(4096) = undefined;
var page_tables: [PAGE_DIRECTORY_ENTRIES][PAGE_TABLE_ENTRIES]PageTableEntry align(4096) = undefined;

// Function to allocate a single page
pub fn allocate_page() ?usize {
    if (next_free_page >= MEMORY_SIZE) {
        return null; // Out of memory
    }
    const page = next_free_page;
    next_free_page += PAGE_SIZE;
    return page;
}

// Function to free a single page
pub fn free_page(page: usize) void {
    // Simple implementation: only free if it's the last allocated page
    if (page >= 0x100000 and page == next_free_page - PAGE_SIZE) {
        next_free_page = page;
    }
}

// Function to set up identity mapping for the entire memory
pub fn setup_identity_mapping() void {
    const pages_to_map = MEMORY_SIZE / PAGE_SIZE;
    const tables_needed = (pages_to_map + PAGE_TABLE_ENTRIES - 1) / PAGE_TABLE_ENTRIES;

    console.putString("\nSetting up page tables... ");
    for (page_tables[0..tables_needed], 0..) |*table, table_index| {
        console.printf("Setting up page table {d}...\n", .{table_index});
        for (table[0..PAGE_TABLE_ENTRIES], 0..) |*entry, entry_index| {
            const page_number = table_index * PAGE_TABLE_ENTRIES + entry_index;
            if (page_number * PAGE_SIZE < MEMORY_SIZE) {
                console.printf("Mapping page {d} (0x{X})...\n", .{ page_number, page_number * PAGE_SIZE });
                entry.* = PageTableEntry{
                    .present = true,
                    .writable = true,
                    .user_accessible = false,
                    .write_through = false,
                    .cache_disabled = false,
                    .accessed = false,
                    .dirty = false,
                    .pat = false,
                    .global = false,
                    .available = 0,
                    .address = page_number,
                };
            } else {
                entry.* = PageTableEntry{ .present = false, .writable = false, .user_accessible = false, .write_through = false, .cache_disabled = false, .accessed = false, .dirty = false, .pat = false, .global = false, .available = 0, .address = 0 };
            }
        }
    }
    console.putString(" Done.\n");

    console.putString("Setting up page directory... ");
    for (&page_directory, 0..) |*entry, i| {
        if (i < tables_needed) {
            entry.* = PageDirectoryEntry{
                .present = true,
                .writable = true,
                .user_accessible = false,
                .write_through = false,
                .cache_disabled = false,
                .accessed = false,
                .reserved = false,
                .page_size = false,
                .global = false,
                .available = 0,
                .address = @as(usize, @intFromPtr(&page_tables[i]) >> 12),
            };
        } else {
            entry.* = PageDirectoryEntry{ .present = false, .writable = false, .user_accessible = false, .write_through = false, .cache_disabled = false, .accessed = false, .reserved = false, .page_size = false, .global = false, .available = 0, .address = 0 };
        }
    }
    console.putString(" Done.\n");

    console.putString("Verifying page directory setup...");
    var valid_entries: usize = 0;
    for (&page_directory) |entry| {
        if (entry.present) {
            valid_entries += 1;
        }
    }
    console.printf(" Found {d} valid entries.\n", .{valid_entries});
    if (valid_entries == 0) {
        console.putString("ERROR: No valid entries in page directory!\n");
        return;
    }
}

// Function to enable paging
pub fn enable_paging() void {
    console.putString("Loading page directory address into CR3...");
    asm volatile ("mov %[pd], %%cr3"
        :
        : [pd] "r" (@intFromPtr(&page_directory)),
    );
    console.putString(" Done.\n");

    // Read initial CR0 value
    var cr0: usize = undefined;
    asm volatile ("mov %%cr0, %[cr0]"
        : [cr0] "=r" (cr0),
    );
    console.printf("Initial CR0 value: 0x{X}\n", .{cr0});

    // Set paging bit
    console.putString("Setting paging bit in CR0...");
    cr0 |= 0x80000000;
    asm volatile ("mov %[cr0], %%cr0"
        :
        : [cr0] "r" (cr0),
    );
    console.putString(" Done.\n");

    // Verify paging is enabled
    asm volatile ("mov %%cr0, %[cr0]"
        : [cr0] "=r" (cr0),
    );
    if ((cr0 & 0x80000000) != 0) {
        console.putString("Paging successfully enabled.\n");
    } else {
        console.putString("WARNING: Paging not enabled!\n");
    }

    // Safety check: try to disable paging
    console.putString("Attempting to disable paging...");
    cr0 &= ~@as(usize, 0x80000000);
    asm volatile ("mov %[cr0], %%cr0"
        :
        : [cr0] "r" (cr0),
    );
    console.putString(" Done.\n");

    // Verify paging is disabled
    asm volatile ("mov %%cr0, %[cr0]"
        : [cr0] "=r" (cr0),
    );
    if ((cr0 & 0x80000000) == 0) {
        console.putString("Paging successfully disabled.\n");
    } else {
        console.putString("WARNING: Failed to disable paging!\n");
    }
}

// Main initialization function
pub fn init() void {
    console.putString("\nSetting up identity mapping...");
    setup_identity_mapping();
    console.putString(" Done.\n");

    console.putString("Enabling paging...");
    enable_paging();
    console.putString(" Done.\n");
}
