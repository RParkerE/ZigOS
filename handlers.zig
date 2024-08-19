const std = @import("std");
const idt = @import("idt.zig");
const console = @import("console.zig");
const pic = @import("pic.zig");

pub const InterruptStackFrame = extern struct {
    eip: u32,
    cs: u32,
    eflags: u32,
};

/// Enum for interrupt vector numbers.
const InterruptVector = enum(u8) {
    DivideByZero = 0,
    Debug = 1,
    NonMaskable = 2,
    Breakpoint = 3,
    Overflow = 4,
    BoundRangeExceeded = 5,
    InvalidOpcode = 6,
    DeviceNotAvailable = 7,
    DoubleFault = 8,
    InvalidTSS = 10,
    SegmentNotPresent = 11,
    StackSegmentFault = 12,
    GeneralProtectionFault = 13,
    PageFault = 14,
    FPUError = 16,
    AlignmentCheck = 17,
    MachineCheck = 18,
    SIMDError = 19,
    SpuriousInterrupt = 0xFF,
};

/// Helper function to print interrupt messages.
fn handleInterrupt(comptime vector: InterruptVector, state: *InterruptStackFrame) void {
    const message = switch (vector) {
        .DivideByZero => "Divide by zero",
        .Debug => "Debug interrupt",
        .NonMaskable => "Non-maskable interrupt",
        .Breakpoint => "Breakpoint interrupt",
        .Overflow => "Overflow error",
        .BoundRangeExceeded => "Bound range exceeded error",
        .InvalidOpcode => "Invalid opcode",
        .DeviceNotAvailable => "Device not available error",
        .DoubleFault => "Double fault",
        .InvalidTSS => "Invalid TSS error",
        .SegmentNotPresent => "Segment not present error",
        .StackSegmentFault => "Stack segment fault",
        .GeneralProtectionFault => "General protection fault",
        .PageFault => "Page fault",
        .FPUError => "FPU error",
        .AlignmentCheck => "Alignment check (not handled)",
        .MachineCheck => "Machine check (not handled)",
        .SIMDError => "SIMD error",
        .SpuriousInterrupt => "Spurious interrupt",
    };
    console.printf("{s}! eip: 0x{x}, cs: 0x{x}, eflags: 0x{x}\n", .{ message, state.eip, state.cs, state.eflags });
}

export fn divErrISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.DivideByZero, state);
    haltSystem("Divide by zero fault!");
}

export fn debugISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.Debug, state);
}

export fn nonMaskableISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.NonMaskable, state);
}

export fn breakpointISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.Breakpoint, state);
}

export fn overflowISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.Overflow, state);
}

export fn boundRangeExceededISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.BoundRangeExceeded, state);
}

export fn invalidOpcodeISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.InvalidOpcode, state);
}

export fn deviceNotAvailableISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.DeviceNotAvailable, state);
}

export fn doubleFaultISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.DoubleFault, state);
    haltSystem("Double fault!");
}

export fn invalidTSSISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.InvalidTSS, state);
    haltSystem("Invalid TSS error!");
}

export fn segmentNotPresentISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.SegmentNotPresent, state);
    haltSystem("Segment not present error!");
}

export fn stackSegFaultISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.StackSegmentFault, state);
    haltSystem("Stack segment fault!");
}

export fn gpaFaultISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.GeneralProtectionFault, state);
    haltSystem("General protection fault!");
}

export fn pageFaultISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.PageFault, state);
    haltSystem("Page fault!");
}

export fn fpuErrISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.FPUError, state);
    haltSystem("FPU error!");
}

export fn alignCheckISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.AlignmentCheck, state);
}

export fn machineCheckISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.MachineCheck, state);
}

export fn simdErrISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.SIMDError, state);
    haltSystem("SIMD error!");
}

export fn spuriousIntISR(state: *InterruptStackFrame) callconv(.Interrupt) void {
    handleInterrupt(InterruptVector.SpuriousInterrupt, state);
    haltSystem("Spurious Interrupt!");
}

/// Function to halt the system and print an error message.
fn haltSystem(message: []const u8) void {
    console.printf("{s}\n", .{message});
    while (true) {} // Enter an infinite loop to halt the system.
}

pub fn registerHandlers() void {
    const IDT_FLAGS = 0b1110; // Interrupt gate with DPL 0

    idt.setDescriptor(@intFromEnum(InterruptVector.DivideByZero), @intFromPtr(&divErrISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.Debug), @intFromPtr(&debugISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.NonMaskable), @intFromPtr(&nonMaskableISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.Breakpoint), @intFromPtr(&breakpointISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.Overflow), @intFromPtr(&overflowISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.BoundRangeExceeded), @intFromPtr(&boundRangeExceededISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.InvalidOpcode), @intFromPtr(&invalidOpcodeISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.DeviceNotAvailable), @intFromPtr(&deviceNotAvailableISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.DoubleFault), @intFromPtr(&doubleFaultISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.InvalidTSS), @intFromPtr(&invalidTSSISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.SegmentNotPresent), @intFromPtr(&segmentNotPresentISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.StackSegmentFault), @intFromPtr(&stackSegFaultISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.GeneralProtectionFault), @intFromPtr(&gpaFaultISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.PageFault), @intFromPtr(&pageFaultISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.FPUError), @intFromPtr(&fpuErrISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.AlignmentCheck), @intFromPtr(&alignCheckISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.MachineCheck), @intFromPtr(&machineCheckISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.SIMDError), @intFromPtr(&simdErrISR), 0x08, IDT_FLAGS);
    idt.setDescriptor(@intFromEnum(InterruptVector.SpuriousInterrupt), @intFromPtr(&spuriousIntISR), 0x08, IDT_FLAGS);

    // Load the IDT
    idt.load();
}
