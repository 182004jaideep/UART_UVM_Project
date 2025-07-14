// -----------------------------------------------------------------------------
// Module      : uart_tx
// Description : UART Transmitter (FSM-based) with parity, stop bits, abort
//               detection, FIFO support, and underrun error handling.
// -----------------------------------------------------------------------------
module uart_tx #(
    parameter int DATA_WIDTH = 8,       // Width of UART data
    parameter int STOP_BITS  = 1,       // 1 or 2 stop bits
    parameter bit PARITY_EN  = 0,       // Enable parity
    parameter bit PARITY_ODD = 0        // 0: even, 1: odd
)(
    input  logic clk,
    input  logic rst_n,

    input  logic baud_tick,                      // Baud rate tick signal
    input  logic [DATA_WIDTH-1:0] data_in,       // Data from FIFO
    input  logic data_valid,                     // FIFO has data to send
    input  logic fifo_empty,                     // FIFO status
    input  logic abort_tx,                       // Abort transmission

    output logic data_read,                      // Trigger FIFO read
    output logic tx,                             // Serial output line
    output logic tx_busy,                        // High during transmission
    output logic tx_underrun,                    // FIFO empty during send
    output logic tx_error                        // General transmission error
);

    // ---------------------------------------------------------------------------
    // FSM State Declaration
    // ---------------------------------------------------------------------------
    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP,
        ERROR
    } tx_state_t;

    tx_state_t state, next_state;

    // ---------------------------------------------------------------------------
    // Internal Registers
    // ---------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] shift_reg;
    logic [3:0] bit_count;
    logic [1:0] stop_count;
    logic parity_bit;
    logic error_entry;

    // ---------------------------------------------------------------------------
    // Next State Logic
    // ---------------------------------------------------------------------------
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (abort_tx)
                    next_state = ERROR;
                else if (data_valid)
                    next_state = START;
            end

            START: begin
                if (abort_tx)
                    next_state = ERROR;
                else if (baud_tick)
                    next_state = DATA;
            end

            DATA: begin
                if (abort_tx)
                    next_state = ERROR;
                else if (fifo_empty && bit_count < DATA_WIDTH-1)
                    next_state = ERROR;
                else if (baud_tick && bit_count == DATA_WIDTH-1)
                    next_state = (PARITY_EN) ? PARITY : STOP;
            end

            PARITY: begin
                if (abort_tx)
                    next_state = ERROR;
                else if (baud_tick)
                    next_state = STOP;
            end

            STOP: begin
                if (abort_tx)
                    next_state = ERROR;
                else if (baud_tick && stop_count == STOP_BITS - 1)
                    next_state = IDLE;
            end

            ERROR: begin
                if (!abort_tx)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ---------------------------------------------------------------------------
    // FSM Register
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ---------------------------------------------------------------------------
    // Sequential Logic
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg     <= '0;
            bit_count     <= 0;
            stop_count    <= 0;
            parity_bit    <= 0;
            data_read     <= 0;
            tx_underrun   <= 0;
            tx_error      <= 0;
            error_entry   <= 0;
        end else begin
            data_read   <= 0;
            tx_underrun <= 0;
            tx_error    <= 0;
            error_entry <= (state != ERROR && next_state == ERROR);

            // Load data and prepare parity in IDLE->START transition
            if (state == IDLE && next_state == START) begin
                shift_reg   <= data_in;
                bit_count   <= 0;
                stop_count  <= 0;
                parity_bit  <= PARITY_ODD ? ~^data_in : ^data_in;
                data_read   <= 1;
            end

            // Shift out data bits during DATA state
            if (state == DATA && baud_tick) begin
                shift_reg <= shift_reg >> 1;
                bit_count <= bit_count + 1;
            end

            // Count STOP bits
            if (state == STOP && baud_tick)
                stop_count <= stop_count + 1;

            // Error handling logic
            if (error_entry) begin
                tx_error <= 1;
                if (state == DATA && fifo_empty)
                    tx_underrun <= 1;
            end

            // Reset counters when leaving states
            if (state == DATA && next_state != DATA)
                bit_count <= 0;
            if (state == STOP && next_state != STOP)
                stop_count <= 0;
        end
    end

    // ---------------------------------------------------------------------------
    // Output Logic
    // ---------------------------------------------------------------------------
    always_comb begin
        tx = 1'b1;  // Default line idle (high)
        tx_busy = (state != IDLE && state != ERROR);

        unique case (state)
            START:   tx = 1'b0;
            DATA:    tx = shift_reg[0];
            PARITY:  tx = parity_bit;
            STOP:    tx = 1'b1;
            ERROR:   tx = 1'b1;
            default: tx = 1'b1;
        endcase
    end

endmodule