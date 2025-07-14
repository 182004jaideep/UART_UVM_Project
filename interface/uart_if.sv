// -----------------------------------------------------------------------------
// File       : uart_if.sv
// Description: UART Interface for UVM testbench and DUT binding
// -----------------------------------------------------------------------------

interface uart_if #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst_n
);

    // UART physical signals
    logic tx;
    logic rx;

    // TX Host interface
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  tx_wr_en;
    logic                  tx_full;
    logic                  tx_empty;

    // RX Host interface
    logic [DATA_WIDTH-1:0] rx_data;
    logic                  rx_rd_en;
    logic                  rx_full;
    logic                  rx_empty;

    // Status signals
    logic tx_busy;
    logic rx_busy;
    logic tx_error;
    logic rx_error;
    logic frame_error;
    logic parity_error;
    logic tx_underrun;
    logic rx_overrun;

    // Control signals
    logic abort_tx;
    logic rx_abort;

    // -------------------------------------------------------------------------
    // Modport for DUT (input/output directions match DUT port directions)
    // -------------------------------------------------------------------------
    modport DUT (
        input  clk,
        input  rst_n,
        input  tx_data,
        input  tx_wr_en,
        input  rx_rd_en,
        input  abort_tx,
        input  rx_abort,
        input  rx,

        output tx,
        output tx_full,
        output tx_empty,
        output rx_data,
        output rx_full,
        output rx_empty,

        output tx_busy,
        output rx_busy,
        output tx_error,
        output rx_error,
        output frame_error,
        output parity_error,
        output tx_underrun,
        output rx_overrun
    );

    // -------------------------------------------------------------------------
    // Modport for Testbench (driving inputs, reading outputs)
    // -------------------------------------------------------------------------
    modport TB (
        input  clk,
        input  rst_n,
        output tx_data,
        output tx_wr_en,
        output rx_rd_en,
        output abort_tx,
        output rx_abort,
        output rx,

        input  tx,
        input  tx_full,
        input  tx_empty,
        input  rx_data,
        input  rx_full,
        input  rx_empty,

        input  tx_busy,
        input  rx_busy,
        input  tx_error,
        input  rx_error,
        input  frame_error,
        input  parity_error,
        input  tx_underrun,
        input  rx_overrun
    );

endinterface