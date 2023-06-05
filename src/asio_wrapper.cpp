#include "asio_wrapper.h"
#include <asio/io_context.hpp>
#include <asio/static_thread_pool.hpp>
#include <asio/strand.hpp>
#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <thread>

struct AsioWrapper {
  asio::io_context io_context;
  asio::static_thread_pool thread_pool;
  std::atomic<bool> stop_flag;

  // explicit AsioWrapper() noexcept : stop_flag(false) {}
  AsioWrapper(std::size_t thread_pool_size) noexcept
      : thread_pool(thread_pool_size), stop_flag(false) {}

  ~AsioWrapper() noexcept {
    stop();
    thread_pool.join();
  }

  void run() noexcept {
    while (!stop_flag) {
      asio::error_code ec;
      io_context.poll_one(ec);
      if (ec) {
        // Handle errors in the event loop
        // You can add your own error handling logic here
        std::printf("Error in the event loop: %s", ec.message().c_str());
        std::exit(-1);
      }
    }
  }

  void stop() noexcept { stop_flag = true; }
};

extern "C" {
AsioWrapperHandle asio_init() {
  AsioWrapper *wrapper = new AsioWrapper(std::thread::hardware_concurrency());
  return static_cast<AsioWrapperHandle>(wrapper);
}

void asio_run(AsioWrapperHandle handle) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    asio::post(wrapper->thread_pool, [wrapper]() { wrapper->run(); });
  }
}

void asio_stop(AsioWrapperHandle handle) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    wrapper->stop();
  }
}

void asio_destroy(AsioWrapperHandle handle) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    delete wrapper;
  }
}

void asio_post(AsioWrapperHandle handle, void (*task)(void *), void *arg) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    asio::post(wrapper->thread_pool, [task, arg]() { task(arg); });
  }
}
}
