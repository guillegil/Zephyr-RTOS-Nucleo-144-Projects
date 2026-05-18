#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

#define STACK_SIZE 1024
#define PRIO 5

static K_MUTEX_DEFINE(print_mtx);

static void say(const char *who, int n) {
  k_mutex_lock(&print_mtx, K_FOREVER);
  printk("[%s] tick %d (uptime %lld ms)\n", who, n, k_uptime_get());
  k_mutex_unlock(&print_mtx);
}

static void thread_fn(void *name, void *period_ms, void *unused) {
  int i = 0;
  int period = POINTER_TO_INT(period_ms);

  while (1) {
    say((const char *)name, i++);
    k_msleep(period);
  }
}

K_THREAD_DEFINE(t_fast, STACK_SIZE, thread_fn, "fast", INT_TO_POINTER(500),
                NULL, PRIO, 0, 0);

K_THREAD_DEFINE(t_slow, STACK_SIZE, thread_fn, "slow", INT_TO_POINTER(1000),
                NULL, PRIO, 0, 0);

int main(void) {
  printk("Booted on %s — main exits, threads keep running.\n", CONFIG_BOARD);
  return 0;
}