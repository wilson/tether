const std = @import("std");
const native_endian = @import("builtin").target.cpu.arch.endian();

// ----------------------------------------------------------------------------
// The Block (64 Bytes)
// ----------------------------------------------------------------------------
// The fundamental physical unit of Tether. All frames are multiples of this size.
// This corresponds to the standard x86/ARM cache line size.
pub const BLOCK_SIZE = 64;

// ----------------------------------------------------------------------------
// The Header (Block 0)
// ----------------------------------------------------------------------------
pub const Header = extern struct {
    // 0-3: Magic (OBOL in ASCII)
    magic: u32 = 0x4F424F4C,
    // 4-5: FlowID
    flow_id: u16,
    // 6: Flags (LAMP, SYNC)
    flags: u8,
    // 7: Reserved
    reserved: u8 = 0,

    // 8-13: SenderID (48-bit) - Modeled as u32 + u16
    sender_id_hi: u32,
    sender_id_lo: u16,

    // 14-19: TargetID (48-bit) - Modeled as u16 + u32
    target_id_hi: u16,
    target_id_lo: u32,

    // 20-23: Nano (The "Bridge" Field)
    // Fills the alignment gap to ensure SlotID starts at 24.
    tai64n_nano: u32,

    // 24-31: SlotID (Index of the Chunk)
    slot_id: u64,

    // 32-39: GrantAmount (Bytes)
    grant_amount: u64,

    // 40-47: NackSlot (Singleton Error)
    nack_slot: u64,

    // 48-55: Checksum (CRC64-ISO)
    checksum: u64,

    // 56-63: TAI64N Seconds
    tai64n_sec: u64,

    /// Flag Definitions
    pub const FLAGS = struct {
        pub const LAMP: u8 = 0x01;
        pub const SYNC: u8 = 0x02;
    };
    
    /// Helper to check a flag branchlessly (returns 1 or 0)
    pub fn hasFlag(self: Header, mask: u8) u1 {
        return @intFromBool((self.flags & mask) != 0);
    }

    /// Calculates the CRC64-ISO of the frame, obeying the "Zero Rule".
    /// The frame slice must include the Header and any Payload Blocks.
    pub fn calculateChecksum(frame: []u8) u64 {
        // 1. Assert frame is valid length
        if (frame.len < BLOCK_SIZE or frame.len % BLOCK_SIZE != 0) return 0;

        // 2. Local copy of the header to zero out the checksum field
        var temp_header = std.mem.bytesToValue(Header, frame[0..64]);
        temp_header.checksum = 0; // The Zero Rule

        // 3. CRC the zeroed header
        var crc = std.hash.crc.Crc64Iso.init();
        crc.update(std.mem.asBytes(&temp_header));

        // 4. CRC the payload blocks (if any)
        if (frame.len > 64) {
            crc.update(frame[64..]);
        }

        return crc.final();
    }
};

// Compile-time layout verification
comptime {
    if (@sizeOf(Header) != 64) @compileError("Header must be exactly 64 bytes");
    if (@alignOf(Header) != 8) @compileError("Header must be 8-byte aligned");
    if (@offsetOf(Header, "slot_id") != 24) @compileError("SlotID must start at offset 24");
}

// ----------------------------------------------------------------------------
// Control Plane (Block 1+)
// ----------------------------------------------------------------------------

/// The Preamble for all Flow 0 payloads.
/// Sits at bytes 0-7 of the Payload Block.
pub const ControlPreamble = extern struct {
    tag: Tag,      // u32
    reserved: u32 = 0,
};

pub const Tag = enum(u32) {
    Reserved = 0,
    Hail     = 1,
    Define   = 2,
    Manifest = 3,
    Nack     = 4,
};

// ----------------------------------------------------------------------------
// Payload Bodies
// ----------------------------------------------------------------------------
// These start at Byte 8 of the Payload Block.
// Explicit padding arrays ensure the struct fills the Block completely.

/// Tag 1: Hail (128-byte Total Grant implies 1 Header + 1 Payload Block)
pub const PayloadHail = extern struct {
    preamble: ControlPreamble = .{ .tag = .Hail },
    version: u32 = 1,
    capabilities: u32 = 0,
    
    // Padding: 64 (Block) - 8 (Ctrl) - 8 (Body) = 48 bytes
    padding: [48]u8 = [_]u8{0} ** 48,
};

/// Tag 2: Define (Flow Geometry)
pub const PayloadDefine = extern struct {
    preamble: ControlPreamble = .{ .tag = .Define },
    target_flow: u16,
    reserved: u16 = 0,
    slot_size: u32,
    total_bytes: u64,

    // Padding: 64 (Block) - 8 (Ctrl) - 16 (Body) = 40 bytes
    padding: [40]u8 = [_]u8{0} ** 40,
};

/// Tag 3: Manifest ("Expense Report")
pub const PayloadManifest = extern struct {
    preamble: ControlPreamble = .{ .tag = .Manifest },
    target_flow: u16,
    reserved: u16 = 0,
    checksum_lo: u32,
    checksum_hi: u32,
    total_slots: u64,
    total_frames: u64,

    // Data length: 64 (Block) - 8 (Preamble) - 28 (Body) = 36.
    // Padding: 64 - 36 = 28 bytes.
    padding: [28]u8 = [_]u8{0} ** 28,
};

/// Tag 4: Nack (Bulk Re-Transmit)
/// Note: This is variable length in terms of "Blocks", but fixed in layout.
/// The `slots` array size depends on the allocated buffer.
pub const PayloadNack = extern struct {
    preamble: ControlPreamble = .{ .tag = .Nack },
    target_flow: u16,
    reserved: u16 = 0,
    count: u32,
    
    // The "slots" array follows immediately here.
    // In strict Zig `extern`, we can't define a variable array at the end.
    // TODO: Pointer math.
};

// Verification
comptime {
    if (@sizeOf(PayloadHail) != 64) @compileError("PayloadHail must be 64 bytes");
    if (@sizeOf(PayloadDefine) != 64) @compileError("PayloadDefine must be 64 bytes");
    if (@sizeOf(PayloadManifest) != 64) @compileError("PayloadManifest must be 64 bytes");
    // TODO: Variable-length aligned checks.
    // if (@sizeOf(PayloadNack) != 64) @compileError("PayloadManifest must be 64 bytes");
}
