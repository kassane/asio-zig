const std = @import("std");
const testing = std.testing;
const asio = @cImport(@cInclude("asio_wrapper.h"));

test "Semantic Analyzer" {
    testing.refAllDeclsRecursive(@This());
}
test "Task runner" {
    const handle: asio.AsioWrapperHandle = asio.asio_init();

    asio.asio_run(handle);
    defer asio.asio_destroy(handle);

    asio.asio_post(handle, &taskHello, @intToPtr(?*anyopaque, @ptrToInt("Hello from task 1")));

    std.time.sleep(10000);
    asio.asio_stop(handle);
}

test "Fibonacci" {
    const handle: asio.AsioWrapperHandle = asio.asio_init();

    asio.asio_run(handle);
    defer asio.asio_destroy(handle);
    const values = [_]usize{
        10, 20, 30, // fast
        //40, 50, 60, // slow
    };
    for (0..values.len) |i| {
        asio.asio_post(handle, &fibTask, @intToPtr(?*anyopaque, @ptrToInt(&values[i])));
    }
}

fn taskHello(arg: ?*anyopaque) callconv(.C) void {
    std.debug.print("Task 1:\n{s}\n", .{@ptrCast([*:0]const u8, arg)});
}

fn fibTask(arg: ?*anyopaque) callconv(.C) void {
    const n = @ptrCast(*usize, @alignCast(std.meta.alignment(*usize), arg)).*;
    std.debug.print("Fibonacci ({}): {}\n", .{ n, fibonacci(n) });
}
fn fibonacci(index: usize) usize {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}
