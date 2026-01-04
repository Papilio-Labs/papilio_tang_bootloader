// led_blink.v
// Parameterized LED blink module. Toggle `led` every INTERVAL clock cycles.
// Default INTERVAL is 27_000_000 for a 27 MHz clock (1 second per toggle).

`timescale 1ns/1ps

module led_blink #(
    // Clock frequency in MHz (default 27 MHz)
    // The module converts this to Hz internally: CLOCK_HZ = CLOCK_MHZ * 1_000_000
    parameter integer CLOCK_MHZ = 27,
    // Interval in seconds between toggles (default 1 second)
    parameter integer SECONDS = 1,
    // Initial LED state
    parameter INITIAL = 1'b1
) (
    input  wire clk,
    output reg  led
);

    // Safe clog2 implementation to compute counter width from INTERVAL.
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    // Convert MHz parameter to Hz and compute interval in clock cycles.
    // CLOCK_HZ = CLOCK_MHZ * 1_000_000
    localparam integer CLOCK_HZ = CLOCK_MHZ * 1000000;
    // INTERVAL = CLOCK_HZ * SECONDS
    localparam integer INTERVAL = CLOCK_HZ * SECONDS;

    // Ensure at least 1 bit of width to avoid zero-width vectors.
    localparam integer WIDTH = (INTERVAL <= 1) ? 1 : clog2(INTERVAL);

    reg [WIDTH-1:0] counter = 0;

    // Initialize LED state
    initial begin
        led = INITIAL;
    end

    // Counting and toggle logic
    always @(posedge clk) begin
        if (counter == INTERVAL - 1) begin
            counter <= 0;
            led <= ~led;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
