#include "asio_wrapper.h"
#include <asio.hpp>
#include <asio/executor.hpp>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <iostream>

struct AsioWrapper {
    asio::io_context io_context;
    std::thread thread;
    std::mutex mutex;
    std::condition_variable cv;
    bool stop_flag;

    AsioWrapper() noexcept : stop_flag(false) {}

    ~AsioWrapper() noexcept {
        stop();
        if (thread.joinable()) {
            thread.join();
        }
    }

    void run() noexcept {
        while (!stop_flag) {
            asio::error_code ec;
            io_context.run(ec);
            if (ec) {
                // Handle errors in the event loop
                // You can add your own error handling logic here
                std::cerr << "Error in the event loop: " << ec.message() << std::endl;
            }
        }
    }

    void stop() noexcept {
        {
            std::lock_guard<std::mutex> lock(mutex);
            stop_flag = true;
        }
        cv.notify_all();
    }
};

extern "C" {
    AsioWrapperHandle asio_init() {
        AsioWrapper* wrapper = new AsioWrapper();
        return static_cast<AsioWrapperHandle>(wrapper);
    }

    void asio_run(AsioWrapperHandle handle) {
        AsioWrapper* wrapper = static_cast<AsioWrapper*>(handle);
        if (wrapper) {
            wrapper->thread = std::thread([wrapper]() {
                wrapper->run();
            });
        }
    }

    void asio_stop(AsioWrapperHandle handle) {
        AsioWrapper* wrapper = static_cast<AsioWrapper*>(handle);
        if (wrapper) {
            wrapper->stop();
        }
    }

    void asio_destroy(AsioWrapperHandle handle) {
        AsioWrapper* wrapper = static_cast<AsioWrapper*>(handle);
        if (wrapper) {
            delete wrapper;
        }
    }

    void asio_post(AsioWrapperHandle handle, void (*task)(void*), void* arg) {
        AsioWrapper* wrapper = static_cast<AsioWrapper*>(handle);
        if (wrapper) {
            asio::post(wrapper->io_context.get_executor(), [task, arg]() { task(arg); });
        }
    }
}

