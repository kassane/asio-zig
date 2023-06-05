#include "asio_wrapper.h"
#include <stdio.h>
#include <stdlib.h>

// Fibonacci calculation function
unsigned long long fibonacci(unsigned int n) {
  if (n <= 1) {
    return n;
  } else {
    return fibonacci(n - 1) + fibonacci(n - 2);
  }
}

// Task function to calculate Fibonacci number asynchronously
void fibonacci_task(void* arg) {
  unsigned int n = *(unsigned int*)arg;
  unsigned long long result = fibonacci(n);
  printf("Fibonacci(%u) = %llu\n", n, result);
}

int main() {
  // Initialize the ASIO wrapper
  AsioWrapperHandle handle = asio_init();

  // Calculate Fibonacci numbers asynchronously
  unsigned int n1 = 40;
  unsigned int n2 = 45;
  unsigned int n3 = 50;

  asio_post(handle, fibonacci_task, &n1);
  asio_post(handle, fibonacci_task, &n2);
  asio_post(handle, fibonacci_task, &n3);

  // Run the ASIO event-loop
  asio_run(handle);

  // Clean up and destroy the ASIO wrapper
  asio_destroy(handle);

  return 0;
}
