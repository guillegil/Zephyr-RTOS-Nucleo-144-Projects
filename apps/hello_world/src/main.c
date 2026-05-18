#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

int main(void) {
  printk("Hello from my_app on %s!\n", CONFIG_BOARD);
  return 0;
}