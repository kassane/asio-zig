#include <stdio.h>
#include <unistd.h>

#include "asio_wrapper.h"

void timerTask(void* arg) {
  int* counter = (int*)arg;
  printf("Timer Task:\n Counter = %d\n", (*counter)++);
}

int main() {
  AsioWrapperHandle handle = asio_init();
  asio_run(handle);

  int counter = 0;
  while (counter < 10) {
    asio_post_pool(handle, timerTask, &counter);
  }

  // Sleep for a while to allow the tasks to execute
  usleep(1000);

  asio_stop(handle);
  asio_destroy(handle);

  return 0;
}
