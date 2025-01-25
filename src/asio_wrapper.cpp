#include "asio_wrapper.h"

#include <asio/io_context.hpp>
#include <asio/post.hpp>
#include <asio/read.hpp>
#include <asio/static_thread_pool.hpp>
#include <asio/strand.hpp>
#include <asio/write.hpp>
#include <cstddef>
#include <cstdio>
#include <thread>

#ifdef WIN32
#include <windows.h>
#else
#include <asio/posix/stream_descriptor.hpp>
using streamer = asio::posix::stream_descriptor;
#endif

struct AsioWrapper {
  asio::io_context io_context;
  asio::static_thread_pool thread_pool;
  std::atomic<bool> stop_flag;
#ifndef WIN32
  streamer stream;
#endif
  asio::strand<asio::io_context::executor_type> strand;

#ifdef WIN32
  AsioWrapper(std::size_t thread_pool_size) noexcept
      : thread_pool(thread_pool_size), stop_flag(false),
        strand(io_context.get_executor()) {}
#else
  AsioWrapper(std::size_t thread_pool_size) noexcept
      : thread_pool(thread_pool_size), stop_flag(false), stream(io_context),
        strand(io_context.get_executor()) {}
#endif

  ~AsioWrapper() noexcept {
    stop();
    thread_pool.join();
  }

  void run() noexcept {
    while (!stop_flag) {
      asio::error_code ec;
      io_context.poll_one();
      if (ec) {
        std::printf("Error in the event loop: %s", ec.message().c_str());
        std::exit(-1);
      }
    }
  }

  void stop() noexcept { stop_flag = true; }

  void post_task_pool(void (*task)(void *), void *arg) noexcept {
    asio::post(thread_pool, [task, arg]() { task(arg); });
  }

  void post_task_strand(void (*task)(void *), void *arg) noexcept {
    asio::post(strand, [task, arg]() { task(arg); });
  }
#ifndef WIN32
  void write(const char *data, std::size_t size) noexcept {
    asio::post(strand, [this, data, size]() {
      asio::async_write(stream, asio::buffer(data, size),
                        [data](const asio::error_code &error, std::size_t) {
                          if (error) {
                            std::printf("Write error: %s\n",
                                        error.message().c_str());
                            std::exit(-1);
                          }
                          delete[] data;
                        });
    });
  }

  void read(void (*callback)(const char *, std::size_t),
            std::size_t size) noexcept {
    char *buffer = new char[size];
    asio::post(strand, [this, buffer, size, callback]() {
      asio::async_read(stream, asio::buffer(buffer, size),
                       [buffer, callback](const asio::error_code &error,
                                          std::size_t bytes_transferred) {
                         if (error) {
                           std::printf("Read error: %s\n",
                                       error.message().c_str());
                           std::exit(-1);
                         }
                         callback(buffer, bytes_transferred);
                         delete[] buffer;
                       });
    });
  }
#endif
};

extern "C" {
AsioWrapperHandle asio_init(size_t num_threads) {
  AsioWrapper *wrapper = new AsioWrapper(num_threads);
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

void asio_post_pool(AsioWrapperHandle handle, void (*task)(void *), void *arg) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    wrapper->post_task_pool(task, arg);
  }
}

void asio_post_strand(AsioWrapperHandle handle, void (*task)(void *),
                      void *arg) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    wrapper->post_task_strand(task, arg);
  }
}

#ifndef WIN32
void asio_write(AsioWrapperHandle handle, const char *data, std::size_t size) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    wrapper->write(data, size);
  }
}

void asio_read(AsioWrapperHandle handle,
               void (*callback)(const char *, std::size_t), std::size_t size) {
  AsioWrapper *wrapper = static_cast<AsioWrapper *>(handle);
  if (wrapper) {
    wrapper->read(callback, size);
  }
}
#endif

size_t get_maxCPU(void) {
  size_t n_threads = 1;
#ifdef WIN32
  SYSTEM_INFO sys_info;
  GetSystemInfo(&sys_info);
  n_threads = sys_info.dwNumberOfProcessors;
#else
  n_threads = std::thread::hardware_concurrency();
#endif
  return n_threads;
}
}
