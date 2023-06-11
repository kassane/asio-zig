#ifndef ASIO_WRAPPER_H
#define ASIO_WRAPPER_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for the Asio wrapper
typedef void* AsioWrapperHandle;

// Function to initialize the Asio wrapper
AsioWrapperHandle asio_init(size_t num_threads);

// Function to run the event loop
void asio_run(AsioWrapperHandle handle);

// Function to stop the event loop
void asio_stop(AsioWrapperHandle handle);

// Function to destroy the Asio wrapper
void asio_destroy(AsioWrapperHandle handle);

// Function to post a task to the thread pool
void asio_post_pool(AsioWrapperHandle handle, void (*task)(void*), void* arg);

// Function to post a task to the strand
void asio_post_strand(AsioWrapperHandle handle, void (*task)(void*), void* arg);

// Write data to a stream
void asio_write(AsioWrapperHandle handle, const char* data, size_t size);

// Read data from a stream
void asio_read(AsioWrapperHandle handle, void (*callback)(const char*, size_t),
               size_t size);

// Get max CPUs Core
size_t get_maxCPU(void);

#ifdef __cplusplus
}
#endif

#endif  // ASIO_WRAPPER_H
