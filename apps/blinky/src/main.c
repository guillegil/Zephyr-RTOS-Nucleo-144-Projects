#include <zephyr/drivers/gpio.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/printk.h>

#define STACK_SIZE 512
#define PRIO 5

struct blinker {
  struct gpio_dt_spec gpio;
  int period_ms;
  const char *name;
};

static const struct blinker leds[] = {
    {GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios), 250, "green"},
    {GPIO_DT_SPEC_GET(DT_ALIAS(led1), gpios), 500, "blue"},
    {GPIO_DT_SPEC_GET(DT_ALIAS(led2), gpios), 1000, "red"},
};

static void blink_thread(void *p1, void *p2, void *p3) {
  const struct blinker *b = p1;
  int64_t next = k_uptime_get() + b->period_ms;

  while (1) {
    gpio_pin_toggle_dt(&b->gpio);
    k_sleep(K_TIMEOUT_ABS_MS(next));
    next += b->period_ms;
  }
}

K_THREAD_STACK_ARRAY_DEFINE(stacks, ARRAY_SIZE(leds), STACK_SIZE);
static struct k_thread threads[ARRAY_SIZE(leds)];

int main(void) {
  for (size_t i = 0; i < ARRAY_SIZE(leds); i++) {
    if (!gpio_is_ready_dt(&leds[i].gpio)) {
      printk("LED %s not ready\n", leds[i].name);
      return -ENODEV;
    }
    gpio_pin_configure_dt(&leds[i].gpio, GPIO_OUTPUT_INACTIVE);

    k_thread_create(&threads[i], stacks[i], STACK_SIZE, blink_thread,
                    (void *)&leds[i], NULL, NULL, PRIO, 0, K_NO_WAIT);
    k_thread_name_set(&threads[i], leds[i].name);
  }

  printk("Blinky: green/500ms, blue/750ms, red/1100ms\n");
  return 0;
}