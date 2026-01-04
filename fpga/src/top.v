// top.v
// Simple 1-second blink for pin L16 driven by a 27 MHz clock.
// Assumption: input clock is 27_000_000 Hz. The LED (net `L16`) is
// toggled every 27,000,000 clock cycles -> one toggle per second.
// That means a full on/off cycle is 2 seconds.

`timescale 1ns/1ps

module top (
    input  wire clk_27mhz, // 27 MHz input clock
    output wire led,        // top-level LED port; map this to physical pin L16 in constraints
    output wire reconfig,    // reconfiguration mode pin (active high)
    input  wire rst_n,        // Active low reset
    output wire rgb_led,     // WS2812B RGB LED data output

//    SPI Flash programming
    input wire          esp_clk,
    input wire          esp_cs_n,
    output  wire          esp_miso,
    input wire          esp_mosi,

    output  wire          spiflash_clk,
    output  wire          spiflash_cs_n,
    input wire          spiflash_miso,
    output  wire          spiflash_mosi
);

    // Instantiate the parameterized LED blink module. The clock frequency
    // is given in MHz (CLOCK_MHZ) and the interval is in seconds (SECONDS).
    // With CLOCK_MHZ=27 and SECONDS=1 the LED toggles once per second -> 1s ON / 1s OFF.
     led_blink #(
         .CLOCK_MHZ(27),
         .SECONDS(1)
     ) u_led_blink (
         .clk(clk_27mhz),
         .led(led)
     );

    // Timed reconfiguration control: hold high for 5 seconds, then low
    timed_restart #(
        .CLOCK_MHZ(27),
        .HOLD_SECS(1)
    ) u_timed_restart (
        .clk(clk_27mhz),
        .esp_cs_n(esp_cs_n),
        .reconfig(reconfig)
    );

    // SPI Flash
    assign spiflash_clk = esp_clk;
    assign spiflash_mosi = esp_mosi;
    assign spiflash_cs_n = esp_cs_n;
    assign esp_miso = spiflash_miso;



    // WS2812B RGB LED controller
    // Simple reset signal - could be tied to power-on reset or button
//    reg rst_n = 1'b1;
    
    // Common colors (GRB format):
    // Red:     24'h00FF00
    // Green:   24'hFF0000
    // Blue:    24'h0000FF
    // Yellow:  24'hFFFF00
    // Cyan:    24'hFF00FF
    // Magenta: 24'h00FFFF
    // White:   24'hFFFFFF
    // Purple:  24'h007F7F
    // Orange:  24'h80FF00
    // Off:     24'h000000
    
    ws2812b #(
        .LED_COLOR(24'h000505)  // Purple color
    ) u_ws2812b (
        .clk(clk_27mhz),
        .rst_n(rst_n),
        .dout(rgb_led)
    );

endmodule
