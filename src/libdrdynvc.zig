const std = @import("std");
const drdynvc_priv = @import("drdynvc_priv.zig");
const c = drdynvc_priv.c;

var g_allocator: std.mem.Allocator = std.heap.c_allocator;

//*****************************************************************************
// int drdynvc_init(void);
export fn drdynvc_init() c_int
{
    return c.LIBDRDYNVC_ERROR_NONE;
}

//*****************************************************************************
// int drdynvc_deinit(void);
export fn drdynvc_deinit() c_int
{
    return c.LIBDRDYNVC_ERROR_NONE;
}

//*****************************************************************************
// int drdynvc_create(struct drdynvc_t** drdynvc);
export fn drdynvc_create(drdynvc: ?**c.drdynvc_t) c_int
{
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        const priv = drdynvc_priv.drdynvc_priv_t.create(&g_allocator) catch
                return c.LIBDRDYNVC_ERROR_MEMORY;
        adrdynvc.* = @ptrCast(priv);
        return c.LIBDRDYNVC_ERROR_NONE;
    }
    return 1;
}

//*****************************************************************************
// int drdynvc_delete(struct drdynvc_t* drdynvc);
export fn drdynvc_delete(drdynvc: ?*c.drdynvc_t) c_int
{
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        // cast c.drdynvc_t to drdynvc_priv.rdpc_priv_t
        const priv: *drdynvc_priv.drdynvc_priv_t = @ptrCast(adrdynvc);
        priv.delete();
    }
    return c.LIBDRDYNVC_ERROR_NONE;
}

//*****************************************************************************
// int drdynvc_process_data(struct drdynvc_t* drdynvc,
//                      uint16_t channel_id,
//                      void* data, uint32_t bytes);
export fn drdynvc_process_data(drdynvc: ?*c.drdynvc_t,
        channel_id: u16, data: ?*anyopaque, bytes: u32) c_int
{
    var rv = c.LIBDRDYNVC_ERROR_PROCESS_DATA;
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        // check if data is nil
        if (data) |adata|
        {
            // cast c.drdynvc_t to drdynvc_priv.rdpc_priv_t
            const priv: *drdynvc_priv.drdynvc_priv_t = @ptrCast(adrdynvc);
            var slice: []u8 = undefined;
            slice.ptr = @ptrCast(adata);
            slice.len = bytes;
            if (priv.process_slice_data(channel_id, slice)) |arv|
            {
                rv = arv;
            }
            else |err|
            {
                priv.logln(@src(), "drdynvc_process_data err {}",
                        .{err}) catch return c.LIBDRDYNVC_ERROR_LOG;
            }
        }
    }
    return rv;
}

//*****************************************************************************
// int drdynvc_send_cap_response(struct drdynvc_t* drdynvc,
//                               uint16_t channel_id,
//                               uint16_t version);
export fn drdynvc_send_cap_response(drdynvc: ?*c.drdynvc_t,
        channel_id: u16, version: u16) c_int
{
    var rv = c.LIBDRDYNVC_ERROR_CAP_RESPONSE;
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        // cast c.drdynvc_t to drdynvc_priv.rdpc_priv_t
        const priv: *drdynvc_priv.drdynvc_priv_t = @ptrCast(adrdynvc);
        rv = priv.send_cap_response(channel_id, version) catch
                return c.LIBDRDYNVC_ERROR_CAP_RESPONSE;
    }
    return rv;
}

//*****************************************************************************
// int drdynvc_send_create_response(struct drdynvc_t* drdynvc,
//                                  uint16_t channel_id,
//                                  uint32_t drdynvc_channel_id,
//                                  int32_t creation_status);
export fn drdynvc_send_create_response(drdynvc: ?*c.drdynvc_t, channel_id: u16,
        drdynvc_channel_id: u32, creation_status: i32) c_int
{
    var rv = c.LIBDRDYNVC_ERROR_CREATE_RESPONSE;
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        // cast c.drdynvc_t to drdynvc_priv.rdpc_priv_t
        const priv: *drdynvc_priv.drdynvc_priv_t = @ptrCast(adrdynvc);
        rv = priv.send_create_response(channel_id, drdynvc_channel_id,
                creation_status) catch
                return c.LIBDRDYNVC_ERROR_CREATE_RESPONSE;
    }
    return rv;
}

//*****************************************************************************
// int drdynvc_send_data_first(struct drdynvc_t* drdynvc, uint16_t channel_id,
//                             uint32_t drdynvc_channel_id, uint32_t total_bytes,
//                             void* data, uint32_t bytes);
export fn drdynvc_send_data_first(drdynvc: ?*c.drdynvc_t, channel_id: u16,
        drdynvc_channel_id: u32, total_bytes: u32,
        data: ?*anyopaque, bytes: u32) c_int
{
    var rv = c.LIBDRDYNVC_ERROR_DATA_FIRST;
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        // check if data is nil
        if (data) |adata|
        {
            // cast c.drdynvc_t to drdynvc_priv.rdpc_priv_t
            const priv: *drdynvc_priv.drdynvc_priv_t = @ptrCast(adrdynvc);
            var slice: []u8 = undefined;
            slice.ptr = @ptrCast(adata);
            slice.len = bytes;
            rv = priv.send_slice_data_first(channel_id,
                    drdynvc_channel_id, total_bytes, slice) catch
                    return c.LIBDRDYNVC_ERROR_DATA_FIRST;
        }
    }
    return rv;
}

//*****************************************************************************
// int drdynvc_send_data(struct drdynvc_t* drdynvc, uint16_t channel_id,
//                       uint32_t drdynvc_channel_id,
//                       void* data, uint32_t bytes);
export fn drdynvc_send_data(drdynvc: ?*c.drdynvc_t, channel_id: u16,
        drdynvc_channel_id: u32, data: ?*anyopaque, bytes: u32) c_int
{
    var rv = c.LIBDRDYNVC_ERROR_DATA;
    // check if drdynvc is nil
    if (drdynvc) |adrdynvc|
    {
        // check if data is nil
        if (data) |adata|
        {
            // cast c.drdynvc_t to drdynvc_priv.rdpc_priv_t
            const priv: *drdynvc_priv.drdynvc_priv_t = @ptrCast(adrdynvc);
            var slice: []u8 = undefined;
            slice.ptr = @ptrCast(adata);
            slice.len = bytes;
            rv = priv.send_slice_data(channel_id,
                    drdynvc_channel_id, slice) catch
                    return c.LIBDRDYNVC_ERROR_DATA;
        }
    }
    return rv;
}
