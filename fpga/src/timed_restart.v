// timed_restart.v
// Hold the reconfiguration output high for a programmable number of seconds
// after configuration/power-up, then drive it low permanently.
// Parameters:
//  - CLOCK_MHZ: input clock frequency in MHz (default 27 MHz)
//  - HOLD_SECS: seconds to hold the output high (default 5 seconds)

`timescale 1ns/1ps

module timed_restart #(
    parameter integer CLOCK_MHZ = 27,
    parameter integer HOLD_SECS = 5
)(
    input  wire clk,
    input  wire esp_cs_n,
    output reg  reconfig
);

    // Verilog-2001 compatible clog2
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    // Convert MHz to Hz and compute total count
    localparam integer CLOCK_HZ  = CLOCK_MHZ * 1000000;
    localparam integer COUNT_MAX = CLOCK_HZ * HOLD_SECS;

    // Ensure at least 1 bit
    localparam integer WIDTH = (COUNT_MAX <= 1) ? 1 : clog2(COUNT_MAX);

    reg [WIDTH-1:0] count = 0;

    // Start high by default
    initial begin
        reconfig = 1'b1;
    end

    always @(posedge clk) begin
        if (reconfig) begin
            if (esp_cs_n == 1'b0) begin
                // Reset timer when esp_cs_n is active (low)
                count <= 0;
            end else if (count == COUNT_MAX - 1) begin
                reconfig <= 1'b0;  // drop low after hold time
            end else begin
                count <= count + 1;
            end
        end
        // Once low, remain low forever
    end

endmodule