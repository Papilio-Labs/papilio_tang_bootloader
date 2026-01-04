module ws2812b(
    input wire clk,           // Input clock (27MHz)
    input wire rst_n,         // Active low reset
    input wire [23:0] led_color_in,  // Dynamic color input
    output reg dout          // Data output to WS2812B
);

    // Parameters for WS2812B timing (for 27MHz clock)
    parameter T0H = 9;       // 0.35us (9 cycles @ 27MHz)
    parameter T0L = 22;      // 0.8us  (22 cycles @ 27MHz)
    parameter T1H = 19;      // 0.7us  (19 cycles @ 27MHz)
    parameter T1L = 16;      // 0.6us  (16 cycles @ 27MHz)
    parameter RES = 1350;    // >50us reset time (1350 cycles @ 27MHz)

    // State definitions
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam SEND = 2'b01;
    localparam RESET = 2'b10;

    // Counters and registers
    reg [9:0] bit_counter;    // Counts bits being sent (24 bits total)
    reg [9:0] cycle_counter;  // Counts clock cycles for timing
    reg [23:0] led_data;      // Data to send

    // Main state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            dout <= 0;
            bit_counter <= 0;
            cycle_counter <= 0;
            led_data <= led_color_in;
        end else begin
            case (state)
                IDLE: begin
                    dout <= 0;
                    bit_counter <= 23;  // Start with MSB
                    cycle_counter <= 0;
                    led_data <= led_color_in;  // Latch new color
                    state <= SEND;
                end

                SEND: begin
                    if (cycle_counter == 0) begin
                        dout <= 1;  // Start of bit
                    end else if (led_data[bit_counter] == 1'b1 && cycle_counter == T1H) begin
                        dout <= 0;  // End of '1' bit
                    end else if (led_data[bit_counter] == 1'b0 && cycle_counter == T0H) begin
                        dout <= 0;  // End of '0' bit
                    end

                    if ((led_data[bit_counter] == 1'b1 && cycle_counter == (T1H + T1L - 1)) ||
                        (led_data[bit_counter] == 1'b0 && cycle_counter == (T0H + T0L - 1))) begin
                        cycle_counter <= 0;
                        if (bit_counter == 0) begin
                            state <= RESET;
                        end else begin
                            bit_counter <= bit_counter - 1;
                        end
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end

                RESET: begin
                    dout <= 0;
                    if (cycle_counter == RES - 1) begin
                        state <= IDLE;
                        cycle_counter <= 0;
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
