// -------------------------------------------------------------------
// Module      : uart_fifo
// Description : Parameterized synchronous FIFO for UART TX/RX buffering
// -------------------------------------------------------------------
module uart_fifo #(
    parameter int DEPTH = 16,
    parameter int WIDTH = 8
)(
    input logic clk,    // system clock
    input logic rst_n,  // active low reset

    input logic wr_en,  // write enable
    input logic [WIDTH-1:0] wr_data, // data to write

    input logic rd_en,  // read enable
    output logic [WIDTH-1:0] rd_data, // data output
    output logic full,  // FIFO full flag
    output logic empty  // FIFO empty flag
);
    // internal memory array (depth entries of width bits)
    logic [WIDTH-1:0] mem [DEPTH-1:0];
    
    logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr; // write and read pointer
    logic [$clog2(DEPTH):0] count; // counter to track number of elements in FIFO

    // OUTPUT READ DATA
    assign rd_data = mem[rd_ptr]; // read data from memory at read pointer
    assign full = (count == DEPTH); // FIFO full condition
    assign empty = (count == 0); // FIFO empty condition

    // Synchronous fifo behavior
    always_ff @(posedge clk or negedge rst_n) begin
        // reset condition
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            // Handle simultaneous read and write
            case ({wr_en & ~full, rd_en & ~empty})
                2'b00: begin // No operation
                    // count remains same
                end
                2'b01: begin // Read only
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
                2'b10: begin // Write only
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                2'b11: begin // Simultaneous read and write
                    mem[wr_ptr] <= wr_data;
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                    // count remains same
                end
            endcase
        end
    end
endmodule