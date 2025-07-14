// -------------------------------------------------------------------
// Module      : baud_gen
// Description : Generates a single-cycle baud tick pulse based on
//               system clock and target baud rate.
// -------------------------------------------------------------------
module baud_gen #(
    parameter int BAUD_RATE = 115200, // target baud rate in bps 
    parameter int CLK_FREQ = 50000000 // system clock frequency in Hz
)(
    input logic clk,    // system clock
    input logic rst_n,  // active low reset
    output logic tick   // baud tick pulse
);
    // calculating the number of clock cycles per baud interval
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;
    
    // counter width is sized based on the divisor 
    logic [$clog2(DIVISOR)-1:0] counter;

    // Tick generator logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            tick <= 0;
        end else begin
            if (counter == DIVISOR - 1) begin
                tick <= 1;             // generate tick pulse
                counter <= 0;          // reset counter
            end else begin
                tick <= 0;             // no tick pulse
                counter <= counter + 1; // increment counter
            end
        end
    end
endmodule         