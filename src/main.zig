const std = @import("std");
const pico = @import("picosdk");

const LED_PIN = pico.cyw43.LED_PIN;

export fn main() i32 {
    pico.stdio.init_all();

    pico.cyw43.init() catch {
        std.log.err("WiFi fail.", .{});
        return 1;
    };
    defer pico.cyw43.deinit();

    while (true) {
        pico.sleep_ms(500);
        pico.cyw43.gpio_put(
            LED_PIN,
            switch (pico.cyw43.gpio_get(LED_PIN)) {
                0 => 1,
                1 => 0,
            },
        );
    }

    return 0;
}

pub const std_options = struct {
    pub const logFn = pico.stdio.log;
};
