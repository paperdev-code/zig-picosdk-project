const std = @import("std");

// pico-sdk uses malloc and free, links to libc
const allocator = std.heap.c_allocator;

pub inline fn sleep_ms(ms: u32) void {
    struct {
        extern fn sleep_ms(u32) void;
    }.sleep_ms(ms);
}

pub const stdio = struct {
    pub inline fn init_all() void {
        struct {
            extern fn stdio_init_all() void;
        }.stdio_init_all();
    }

    pub fn log(
        comptime lvl: std.log.Level,
        comptime scope: @Type(.EnumLiteral),
        comptime format: []const u8,
        args: anytype,
    ) void {
        const lvl_text = comptime lvl.asText();
        const prefix2 = if (scope == .default)
            ": "
        else
            "(" ++ @tagName(scope) ++ "): ";

        const message = std.fmt.allocPrint(
            allocator,
            lvl_text ++ prefix2 ++ format ++ "\n\r",
            args,
        ) catch return;
        defer allocator.free(message);

        for (message) |char| {
            struct {
                extern fn putchar_raw(u8) void;
            }.putchar_raw(char);
        }
    }
};

/// Cyw43 function set
pub const cyw43 = struct {
    pub const LED_PIN: u32 = 0;

    pub inline fn init() !void {
        return if (struct {
            extern fn cyw43_arch_init() u32;
        }.cyw43_arch_init() != 0) error.cyw43InitFail else {};
    }

    pub inline fn deinit() void {
        struct {
            extern fn cyw43_arch_deinit() void;
        }.cyw43_arch_deinit();
    }

    pub inline fn gpio_put(gpio: u32, value: u1) void {
        struct {
            extern fn cyw43_arch_gpio_put(u32, bool) void;
        }.cyw43_arch_gpio_put(gpio, (value == 1));
    }

    pub inline fn gpio_get(gpio: u32) u1 {
        return @boolToInt(struct {
            extern fn cyw43_arch_gpio_get(u32) bool;
        }.cyw43_arch_gpio_get(gpio));
    }
};
