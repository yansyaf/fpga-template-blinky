`timescale 1ns / 1ps

module blinky(
    input wire clk,
    input wire rst,
    output wire led
);

    // 125 MHz clock
    // 2^26 / 125e6 ~= 0.53 seconds toggle
    reg [26:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

    assign led = counter[26];

endmodule
