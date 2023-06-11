#include <stdio.h>
#include <unistd.h>

#include "asio_wrapper.h"

void task1(void* arg) { printf("Task 1: %s\n", (const char*)arg); }

void task2(void* arg) { printf("Task 2: %s\n", (const char*)arg); }

int main() {
  AsioWrapperHandle handle = asio_init(get_maxCPU());
  asio_run(handle);

  asio_post_strand(handle, task1, "Hello from task 1");
  asio_post_strand(handle, task2, "Hello from task 2");

  // Sleep for a while to allow the tasks to execute
  // You can replace this with your own logic
  // to keep the program running until the tasks complete
  // or until you decide to stop the event loop.
  // This is just for demonstration purposes.
  usleep(1000);

  asio_stop(handle);
  asio_destroy(handle);

  return 0;
}
