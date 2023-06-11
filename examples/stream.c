#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "asio_wrapper.h"

void print_data(void* data) {
  const char* str = (const char*)data;
  printf("Received data: %s\n", str);
}

void send_data(void* arg) {
  AsioWrapperHandle handle = (AsioWrapperHandle)arg;

  // Create a buffer with the data to send
  const char* data = "Hello, world!";

  // Perform the asynchronous write operation
  asio_post_strand(handle, print_data, (void*)data);
}

int main() {
  AsioWrapperHandle handle = asio_init(get_maxCPU());
  if (!handle) {
    printf("Failed to initialize AsioWrapper\n");
    return -1;
  }

  // Run the event loop in a separate thread
  asio_run(handle);

  // Send data using asynchronous operations
  send_data((void*)handle);

  // Sleep for a while to allow the callbacks to be executed
  sleep(1);

  // Stop the ASIO event loop and clean up resources
  asio_stop(handle);
  asio_destroy(handle);

  return 0;
}
