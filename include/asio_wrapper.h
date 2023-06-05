#ifndef ASIO_WRAPPER_H
#define ASIO_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for the Asio wrapper
typedef void* AsioWrapperHandle;

// Function to initialize the Asio wrapper
AsioWrapperHandle asio_init();

// Function to run the event loop
void asio_run(AsioWrapperHandle handle);

// Function to stop the event loop
void asio_stop(AsioWrapperHandle handle);

// Function to destroy the Asio wrapper
void asio_destroy(AsioWrapperHandle handle);

// Function to post a task to the thread pool
void asio_post(AsioWrapperHandle handle, void (*task)(void*), void* arg);

#ifdef __cplusplus
}
#endif

#endif // ASIO_WRAPPER_H

