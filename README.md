# Asio C Wrapper - Event-loop

The wrapper provides functions for initializing the ASIO library, running it, stopping it, and posting tasks to be executed asynchronously within the event-loop. It handles the necessary conversions and memory management required to interface with ASIO from C or Zig code. Additionally, it utilizes ASIO's thread pool (`asio::static_thread_pool`) for multithreading support, allowing tasks to be executed concurrently on multiple threads.


### How to build and run

* Need [zig 0.12.0](https://ziglang.org/download) or higher.

```bash
# Zig binding test (only)
$> zig build test

# Build all C examples
$> zig build -Doptimize={option} # to debug no need `-Doptimize` flag
```
**Note:** `{option} == Debug (default) | ReleaseSafe | ReleaseFast | ReleaseSmall`