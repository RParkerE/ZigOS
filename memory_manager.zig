// File: physical_memory_manager.zig

const std = @import("std");

// Constants
const MEMORY_SIZE: usize = 2 * 1024 * 1024 * 1024; // 2GB of RAM
const PAGE_SIZE: usize = 4096; // 4KB pages
const PAGE_TABLE_ENTRIES: usize = 1024;
const PAGE_DIRECTORY_ENTRIES: usize = 1024;

// Page Table Entry structure
const PageTableEntry = packed struct {
    present: bool,
    writable: bool,
    user_accessible: bool,
    write_through: bool,
    cache_disabled: bool,
    accessed: bool,
    dirty: bool,
    pat: bool,
    global: bool,
    available: u3,
    address: usize,
};

// Page Directory Entry structure
const PageDirectoryEntry = packed struct {
    present: bool,
    writable: bool,
    user_accessible: bool,
    write_through: bool,
    cache_disabled: bool,
    accessed: bool,
    reserved: bool,
    page_size: bool,
    global: bool,
    available: u3,
    address: usize,
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

    // Set up page tables
    for (page_tables[0..tables_needed], 0..) |*table, table_index| {
        for (table, 0..) |*entry, entry_index| {
            const page_number = table_index * PAGE_TABLE_ENTRIES + entry_index;
            if (page_number * PAGE_SIZE < MEMORY_SIZE) {
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
                    .address = @as(usize, page_number),
                };
            } else {
                entry.* = PageTableEntry{ .present = false, .writable = false, .user_accessible = false, .write_through = false, .cache_disabled = false, .accessed = false, .dirty = false, .pat = false, .global = false, .available = 0, .address = 0 };
            }
        }
    }

    // Set up the page directory
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
}

// Function to enable paging
pub fn enable_paging() void {
    // Load the page directory address into CR3
    asm volatile ("mov %[pd], %%cr3"
        :
        : [pd] "r" (@intFromPtr(&page_directory)),
    );

    // Enable paging by setting the PG bit in CR0
    asm volatile (
        \\mov %%cr0, %%eax
        \\or $0x80000000, %%eax
        \\mov %%eax, %%cr0
        ::: "eax");
}

// Main initialization function
pub fn init() void {
    setup_identity_mapping();
    enable_paging();
}
