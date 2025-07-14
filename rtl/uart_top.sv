module uart_top #(
    parameter int DATA_WIDTH = 8,
    parameter int STOP_BITS  = 1,
    parameter bit PARITY_EN  = 0,
    parameter bit PARITY_ODD = 0,
    parameter int BAUD_RATE  = 115200,
    parameter int CLK_FREQ   = 50000000,
    parameter int FIFO_DEPTH = 16
)(
    input  logic clk,
    input  logic rst_n,

    // UART physical interface
    input  logic rx,
    output logic tx,

    // Host interface - TX
    input  logic [DATA_WIDTH-1:0] tx_data,
    input  logic tx_wr_en,
    output logic tx_full,
    output logic tx_empty,

    // Host interface - RX
    output logic [DATA_WIDTH-1:0] rx_data,
    input  logic rx_rd_en,
    output logic rx_full,
    output logic rx_empty,

    // Status signals
    output logic tx_busy,
    output logic rx_busy,
    output logic tx_error,
    output logic rx_error,
    output logic frame_error,
    output logic parity_error,
    output logic tx_underrun,
    output logic rx_overrun,

    // Control signals
    input  logic abort_tx,
    input  logic rx_abort
);

    // Internal signals
    logic baud_tick;
    logic tx_fifo_rd_en;
    logic tx_fifo_empty;
    logic [DATA_WIDTH-1:0] tx_fifo_data;
    logic rx_fifo_wr_en;
    logic rx_fifo_full;
    logic [DATA_WIDTH-1:0] rx_fifo_data;
    logic rx_data_valid;

    // Baud rate generator
    baud_gen #(
        .BAUD_RATE(BAUD_RATE),
        .CLK_FREQ(CLK_FREQ)
    ) baud_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tick(baud_tick)
    );

    // TX FIFO
    uart_fifo #(
        .DEPTH(FIFO_DEPTH),
        .WIDTH(DATA_WIDTH)
    ) tx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tx_wr_en),
        .wr_data(tx_data),
        .rd_en(tx_fifo_rd_en),
        .rd_data(tx_fifo_data),
        .full(tx_full),
        .empty(tx_fifo_empty)
    );

    // RX FIFO
    uart_fifo #(
        .DEPTH(FIFO_DEPTH),
        .WIDTH(DATA_WIDTH)
    ) rx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(rx_fifo_wr_en),
        .wr_data(rx_fifo_data),
        .rd_en(rx_rd_en),
        .rd_data(rx_data),
        .full(rx_fifo_full),
        .empty(rx_empty)
    );

    // UART Transmitter
    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .PARITY_EN(PARITY_EN),
        .PARITY_ODD(PARITY_ODD)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .data_in(tx_fifo_data),
        .data_valid(~tx_fifo_empty),
        .fifo_empty(tx_fifo_empty),
        .abort_tx(abort_tx),
        .data_read(tx_fifo_rd_en),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_underrun(tx_underrun),
        .tx_error(tx_error)
    );

    // UART Receiver
    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .STOP_BITS(STOP_BITS),
        .PARITY_EN(PARITY_EN),
        .PARITY_ODD(PARITY_ODD)
    ) uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick),
        .rx(rx),
        .rx_abort(rx_abort),
        .fifo_full(rx_fifo_full),
        .data_out(rx_fifo_data),
        .data_valid(rx_data_valid),
        .rx_busy(rx_busy),
        .rx_error(rx_error),
        .frame_error(frame_error),
        .parity_error(parity_error),
        .rx_overrun(rx_overrun)
    );

    // Connect RX data valid to RX FIFO write enable
    assign rx_fifo_wr_en = rx_data_valid;
    assign tx_empty = tx_fifo_empty;
    assign rx_full = rx_fifo_full;

endmodule