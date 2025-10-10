const std = @import("std");
const parse = @import("parse");
const hexdump = @import("hexdump");
pub const c = @cImport(
{
    @cInclude("libdrdynvc.h");
    @cInclude("rdp_constants.h");
});

const g_devel = false;

const drdynvc_channel_t = struct
{
    s: *parse.parse_t,
    total_bytes: usize = 0,
};

const map_t = std.AutoArrayHashMapUnmanaged(u32, *drdynvc_channel_t);

const drdynvc_priv_sub_t = struct
{
    map: map_t,
};

pub const drdynvc_priv_t = extern struct
{
    drdynvc: c.drdynvc_t = .{}, // must be first
    allocator: *const std.mem.Allocator,
    sub: *drdynvc_priv_sub_t,

    //*************************************************************************
    pub fn create(allocator: *const std.mem.Allocator) !*drdynvc_priv_t
    {
        const priv: *drdynvc_priv_t = try allocator.create(drdynvc_priv_t);
        errdefer allocator.destroy(priv);
        const sub = try allocator.create(drdynvc_priv_sub_t);
        sub.* = .{.map = try map_t.init(allocator.*, &.{}, &.{})};
        priv.* = .{.allocator = allocator, .sub = sub};
        return priv;
    }

    //*************************************************************************
    pub fn delete(self: *drdynvc_priv_t) void
    {
        for (self.sub.map.values()) |channel|
        {
            channel.s.delete();
            self.allocator.destroy(channel);
        }
        self.sub.map.deinit(self.allocator.*);
        self.allocator.destroy(self.sub);
        self.allocator.destroy(self);
    }

    //*************************************************************************
    pub fn logln(self: *drdynvc_priv_t, src: std.builtin.SourceLocation,
            comptime fmt: []const u8, args: anytype) !void
    {
        // check if function is assigned
        if (self.drdynvc.log_msg) |alog_msg|
        {
            const alloc_buf = try std.fmt.allocPrint(self.allocator.*,
                    fmt, args);
            defer self.allocator.free(alloc_buf);
            const alloc1_buf = try std.fmt.allocPrint(self.allocator.*,
                    "drdynvc:{s}:{s}\x00", .{src.fn_name, alloc_buf});
            defer self.allocator.free(alloc1_buf);
            _ = alog_msg(&self.drdynvc, alloc1_buf.ptr);
        }
    }

    //*************************************************************************
    pub fn logln_devel(self: *drdynvc_priv_t, src: std.builtin.SourceLocation,
            comptime fmt: []const u8, args: anytype) !void
    {
        if (g_devel)
        {
            return self.logln(src, fmt, args);
        }
    }

    //*************************************************************************
    fn process_create_request(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "", .{});
        const cbId = header & 0x03;
        const Pri = (header >> 2) & 0x03;
        const Cmd = header >> 4;
        const ChannelId = try read124(cbId, s);
        const rem = s.get_rem();
        try s.check_rem(rem);
        const ChannelNameNT = std.mem.sliceTo(s.in_u8_slice(rem), 0);
        const ChannelName = try std.fmt.allocPrint(self.allocator.*,
                "{s}\x00", .{ChannelNameNT});
        defer self.allocator.free(ChannelName);
        try self.logln(@src(), "cbId 0x{X} Pri 0x{X} Cmd 0x{X} " ++
                "ChannelId 0x{X} ChannelName {s}",
                .{cbId, Pri, Cmd, ChannelId, ChannelNameNT});
    
        // create map, delete old is any
        if (self.sub.map.get(ChannelId)) |channel|
        {
            channel.s.delete();
            self.allocator.destroy(channel);
        }
        const channel = try self.allocator.create(drdynvc_channel_t);
        channel.* = .{.s = try parse.parse_t.create(self.allocator, 1024)};
        try self.sub.map.put(self.allocator.*, ChannelId, channel);
    
        if (self.drdynvc.create_request) |acreate_request|
        {
            return acreate_request(&self.drdynvc, channel_id,
                    ChannelId, ChannelName.ptr);
        }
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    fn process_data_first(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        const cbId = header & 0x03;
        const Len = (header >> 2) & 0x03;
        const Cmd = header >> 4;
        const ChannelId = try read124(cbId, s);
        const Length = try read124(Len, s);
        try self.logln(@src(), "cbId 0x{X} Len 0x{X} Cmd 0x{X} " ++
                "ChannelId 0x{X} Length {}",
                .{cbId, Len, Cmd, ChannelId, Length});
        if (self.sub.map.get(ChannelId)) |channel|
        {
            try channel.s.reset(Length);
            const rem = s.get_rem();
            try s.check_rem(rem);
            try channel.s.check_rem(rem);
            channel.s.out_u8_slice(s.in_u8_slice(rem));
            channel.total_bytes = Length;
            return c.LIBDRDYNVC_ERROR_NONE;
        }
        return c.LIBDRDYNVC_ERROR_DATA_FIRST;
    }

    //*************************************************************************
    fn process_data(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        const cbId = header & 0x03;
        const Sp = (header >> 2) & 0x03;
        const Cmd = header >> 4;
        const ChannelId = try read124(cbId, s);
        try self.logln(@src(), "cbId 0x{X} Sp 0x{X} Cmd 0x{X} " ++
                "ChannelId 0x{X}",
                .{cbId, Sp, Cmd, ChannelId});
        if (self.sub.map.get(ChannelId)) |channel|
        {
            const rem = s.get_rem();
            try s.check_rem(rem);
            const slice = s.in_u8_slice(rem);
            if (channel.total_bytes > 0)
            {
                try channel.s.check_rem(rem);
                channel.s.out_u8_slice(slice);
                if (channel.s.offset >= channel.total_bytes)
                {
                    channel.total_bytes = 0;
                    // got all
                    if (self.drdynvc.data) |adata|
                    {
                        const out_slice = channel.s.get_out_slice();
                        return adata(&self.drdynvc, channel_id,
                                ChannelId, out_slice.ptr,
                                @intCast(out_slice.len));
                    }
                }
            }
            else
            {
                // all fit in one
                if (self.drdynvc.data) |adata|
                {
                    return adata(&self.drdynvc, channel_id,
                            ChannelId, slice.ptr, @intCast(slice.len));
                }
            }
            return c.LIBDRDYNVC_ERROR_NONE;
        }
        return c.LIBDRDYNVC_ERROR_DATA;
    }

    //*************************************************************************
    fn process_close(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        const cbId = header & 0x03;
        const Sp = (header >> 2) & 0x03;
        const Cmd = header >> 4;
        const ChannelId = try read124(cbId, s);
        try self.logln(@src(), "cbId 0x{X} Sp 0x{X} Cmd 0x{X} " ++
                "ChannelId 0x{X}",
                .{cbId, Sp, Cmd, ChannelId});
        if (self.drdynvc.close) |aclose|
        {
            return aclose(&self.drdynvc, channel_id, ChannelId);
        }
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    fn process_capabilities_request(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "", .{});
        const cbId = header & 0x03;
        const Sp = (header >> 2) & 0x03;
        const Cmd = header >> 4;
        try s.check_rem(3 + 8);
        s.in_u8_skip(1); // Pad
        const Version = s.in_u16_le();
        const PriorityCharge0 = s.in_u16_le();
        const PriorityCharge1 = s.in_u16_le();
        const PriorityCharge2 = s.in_u16_le();
        const PriorityCharge3 = s.in_u16_le();
        try self.logln(@src(), "cbId 0x{X} Sp 0x{X} Cmd 0x{X} Version 0x{X}",
                .{cbId, Sp, Cmd, Version});
        try self.logln(@src(), "PriorityCharge0 0x{X} " ++
                "PriorityCharge1 0x{X} PriorityCharge2 0x{X} " ++
                "PriorityCharge3 0x{X}",
                .{PriorityCharge0, PriorityCharge1,
                PriorityCharge2, PriorityCharge3});
        if (self.drdynvc.capabilities_request) |acapabilities_request|
        {
            return acapabilities_request(&self.drdynvc, channel_id, Version,
                    PriorityCharge0, PriorityCharge1,
                    PriorityCharge2, PriorityCharge3);
        }
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    fn process_data_first_compressed(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        _ = s;
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    fn process_data_compressed(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        _ = s;
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    fn process_soft_sync_request(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        _ = s;
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    fn process_soft_sync_response(self: *drdynvc_priv_t, channel_id: u16,
            header: u8, s: *parse.parse_t) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X} header 0x{X}",
                .{channel_id, header});
        _ = s;
        return c.LIBDRDYNVC_ERROR_NONE;
    }

    //*************************************************************************
    pub fn process_slice_data(self: *drdynvc_priv_t, channel_id: u16,
            slice: []u8) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X}", .{channel_id});
        try hexdump.printHexDump(0, slice);
        const s = try parse.parse_t.create_from_slice(self.allocator, slice);
        defer s.delete();
        try s.check_rem(1);
        const header = s.in_u8();
        const Cmd = header >> 4;
        return switch (Cmd)
        {
            0x01 => self.process_create_request(channel_id, header, s),
            0x02 => self.process_data_first(channel_id, header, s),
            0x03 => self.process_data(channel_id, header, s),
            0x04 => self.process_close(channel_id, header, s),
            0x05 => self.process_capabilities_request(channel_id, header, s),
            0x06 => self.process_data_first_compressed(channel_id, header, s),
            0x07 => self.process_data_compressed(channel_id, header, s),
            0x08 => self.process_soft_sync_request(channel_id, header, s),
            0x09 => self.process_soft_sync_response(channel_id, header, s),
            else => c.LIBDRDYNVC_ERROR_PROCESS_DATA,
        };
    }

    //*************************************************************************
    pub fn send_capabilities_response(self: *drdynvc_priv_t, channel_id: u16,
            version: u16) !c_int
    {
        const s = try parse.parse_t.create(self.allocator, 64);
        defer s.delete();
        try s.check_rem(4);
        s.out_u8(0x50);
        s.out_u8_skip(1);
        s.out_u16_le(version);
        const slice = s.get_out_slice();
        if (self.drdynvc.send_data) |asend_data|
        {
            return asend_data(&self.drdynvc, channel_id,
                    slice.ptr, @truncate(slice.len));
        }
        return c.LIBDRDYNVC_ERROR_CAPABILITIES_RESPONSE;
    }
    
    //*************************************************************************
    pub fn send_create_response(self: *drdynvc_priv_t, channel_id: u16,
            drdynvc_channel_id: u32, creation_status: i32) !c_int
    {
        const s = try parse.parse_t.create(self.allocator, 64);
        defer s.delete();
        if (drdynvc_channel_id <= 0xFF)
        {
            try s.check_rem(2);
            s.out_u8(0x10);
            s.out_u8(@truncate(drdynvc_channel_id));
        }
        else if (drdynvc_channel_id <= 0xFFFF)
        {
            try s.check_rem(3);
            s.out_u8(0x11);
            s.out_u16_le(@truncate(drdynvc_channel_id));
        }
        else
        {
            try s.check_rem(5);
            s.out_u8(0x12);
            s.out_u32_le(drdynvc_channel_id);
        }
        try s.check_rem(4);
        s.out_i32_le(creation_status);
        const slice = s.get_out_slice();
        if (self.drdynvc.send_data) |asend_data|
        {
            return asend_data(&self.drdynvc, channel_id,
                    slice.ptr, @truncate(slice.len));
        }
        return c.LIBDRDYNVC_ERROR_CREATE_RESPONSE;
    }

};

//*****************************************************************************
fn read124(flags: u8, s: *parse.parse_t) !u32
{
    var rv: u32 = 0;
    if (flags == 0x00)
    {
        try s.check_rem(1);
        rv = s.in_u8();
    }
    else if (flags == 0x01)
    {
        try s.check_rem(2);
        rv = s.in_u16_le();
    }
    else if (flags == 0x02)
    {
        try s.check_rem(4);
        rv = s.in_u32_le();
    }
    else
    {
        return error.InvalidParam;
    }
    return rv;
}
