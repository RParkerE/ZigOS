const std = @import("std");

/// IDT entry structure
const IDTEntry = packed struct {
    offset_low: u16,
    selector: u16,
    zero: u8,
    type_attr: u8,
    offset_high: u16,
};

/// IDTR structure
const IDTR = packed struct {
    limit: u16,
    base: u32,
};

/// Number of IDT entries
const IDT_SIZE: usize = 256;

/// IDT array
var idt: [IDT_SIZE]IDTEntry = undefined;

/// IDTR instance
var idtr: IDTR = undefined;

/// Initialize the IDT
pub fn init() void {
    // Calculate IDT size in bytes
    const idt_size_bytes = @sizeOf(IDTEntry) * IDT_SIZE;

    // Set up IDTR
    idtr = IDTR{
        .limit = @truncate(idt_size_bytes - 1),
        .base = @intFromPtr(&idt),
    };

    // Load IDT
    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "r" (&idtr),
        : "memory"
    );
}

/// Set an IDT entry
pub fn setDescriptor(vector: u8, handler: u32, selector: u16, flags: u8) void {
    idt[vector] = IDTEntry{
        .offset_low = @truncate(handler),
        .selector = selector,
        .zero = 0,
        .type_attr = flags,
        .offset_high = @truncate(handler >> 16),
    };
}

/// Load the IDT
pub fn load() void {
    asm volatile ("lidt (%[idtr])"
        :
        : [idtr] "r" (&idtr),
        : "memory"
    );
}
