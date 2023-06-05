const std = @import("std");
const testing = std.testing;
const asio = @cImport(@cInclude("asio_wrapper.h"));

test "io_context" {
    var handle: asio.AsioWrapperHandle = asio.asio_init();
    asio.asio_run(handle);
    asio.asio_post(handle, &task1, @intToPtr(?*anyopaque, @ptrToInt("Hello from task 1")));

    std.time.sleep(10000);
    asio.asio_stop(handle);
    asio.asio_destroy(handle);
}

fn task1(arg: ?*anyopaque) callconv(.C) void {
    std.debug.print("Task 1: {s}\n", .{@ptrCast([*:0]const u8, arg)});
}
