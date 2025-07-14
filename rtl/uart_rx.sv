// -----------------------------------------------------------------------------
// Module      : uart_rx
// Description : UART Receiver with FSM, parity & stop bit check, and FIFO-ready interface.
// -----------------------------------------------------------------------------
module uart_rx #(
    parameter int DATA_WIDTH = 8,
    parameter int STOP_BITS  = 1,       // 1 or 2 stop bits
    parameter int PARITY_EN  = 0,       // 1 = enable parity
    parameter int PARITY_ODD = 0        // 0 = even, 1 = odd parity
)(
    input  logic clk,
    input  logic rst_n,

    // UART inputs
    input  logic baud_tick,
    input  logic rx,
    input  logic rx_abort,

    // FIFO interface
    input  logic fifo_full,

    // UART outputs
    output logic [DATA_WIDTH-1:0] data_out,
    output logic data_valid,
    output logic rx_busy,
    output logic rx_error,
    output logic frame_error,
    output logic parity_error,
    output logic rx_overrun
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
        DONE,
        ERROR
    } rx_state_t;

    rx_state_t state, next_state;
    
    // ---------------------------------------------------------------------------
    // Internal Registers
    // ---------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0] shift_reg;    // Shift register for incoming data
    logic [3:0] bit_count;               // Data bit counter
    logic [1:0] stop_count;              // Stop bit counter  
    logic parity_bit;                    // Calculated parity
    logic rx_sync;                       // Synchronized RX input
    logic error_entry;                   // Error state entry detection
    
    // ---------------------------------------------------------------------------
    // FSM state register
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // ---------------------------------------------------------------------------
    // FSM Next state logic
    // ---------------------------------------------------------------------------
    always_comb begin 
        next_state = state;
        case(state)
            IDLE: begin 
                if (rx_abort) 
                    next_state = ERROR;
                else if (rx == 1'b0) 
                    next_state = START; // Start bit detected
            end

            START: begin 
                if (rx_abort) 
                    next_state = ERROR;
                else if (baud_tick) begin
                    if (rx == 1'b0) 
                        next_state = DATA; // Valid start bit
                    else 
                        next_state = ERROR; // Invalid start bit
                end
            end

            DATA: begin
                if (rx_abort) 
                    next_state = ERROR;
                else if (baud_tick) begin
                    if (bit_count == DATA_WIDTH - 1) 
                        next_state = (PARITY_EN) ? PARITY : STOP; // Move to parity or stop
                end 
            end

            PARITY: begin
                if (rx_abort) 
                    next_state = ERROR;
                else if (baud_tick) 
                    next_state = STOP; // Move to stop bit
            end

            STOP: begin
                if (rx_abort) 
                    next_state = ERROR;
                else if (baud_tick) begin
                    if (rx == 1'b1) begin
                        if (stop_count == STOP_BITS - 1) 
                            next_state = DONE; // All stop bits received
                    end else 
                        next_state = ERROR; // Invalid stop bit
                end
            end

            DONE: begin
                if (fifo_full) 
                    next_state = ERROR; // FIFO overrun
                else 
                    next_state = IDLE; // Ready for next byte
            end

            ERROR: begin
                next_state = IDLE; // Reset to IDLE on error
            end

            default: next_state = IDLE; // Default case
        endcase
    end

    // ---------------------------------------------------------------------------
    // Sequential RX Logic (data sampling, shift, parity, stop bits, error)
    // ---------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= '0;
            bit_count <= '0;
            stop_count <= '0;
            parity_bit <= 1'b0;
            rx_sync <= 1'b1;
            data_out <= '0;
            data_valid <= 1'b0;
            rx_error <= 1'b0;
            frame_error <= 1'b0;
            parity_error <= 1'b0;
            rx_overrun <= 1'b0;
            error_entry <= 1'b0;
        end else begin 
            // Default values
            data_valid <= 1'b0;
            rx_error <= 1'b0;
            frame_error <= 1'b0;
            parity_error <= 1'b0;
            rx_overrun <= 1'b0;
            error_entry <= (state != ERROR) && (next_state == ERROR);

            rx_sync <= rx; // Synchronize RX input

            case (state)
                START: begin
                    if (baud_tick) begin
                        bit_count <= 0;
                        stop_count <= 0;
                        if (rx_sync != 1'b0)
                            frame_error <= 1'b1;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        shift_reg <= {rx_sync, shift_reg[DATA_WIDTH-1:1]};
                        bit_count <= bit_count + 1;
                        
                        // Calculate parity on the last data bit
                        if (bit_count == DATA_WIDTH - 1) begin
                            parity_bit <= PARITY_ODD ? ~^{rx_sync, shift_reg[DATA_WIDTH-1:1]} : ^{rx_sync, shift_reg[DATA_WIDTH-1:1]};
                        end
                    end
                end

                PARITY: begin
                    if (baud_tick) begin
                        if (rx_sync != parity_bit)
                            parity_error <= 1'b1;
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        if (rx_sync != 1'b1)
                            frame_error <= 1'b1;
                        stop_count <= stop_count + 1;
                    end
                end

                DONE: begin
                    if (!fifo_full) begin
                        data_out <= shift_reg;
                        data_valid <= 1'b1;
                    end else begin
                        rx_overrun <= 1'b1;
                    end
                end

                ERROR: begin
                    if (error_entry)
                        rx_error <= 1'b1;
                end

                default: begin
                    // Reset counters in IDLE
                    if (state == IDLE) begin
                        bit_count <= '0;
                        stop_count <= '0;
                    end
                end
            endcase
        end
    end

    // ---------------------------------------------------------------------------
    // Receiver Busy Signal
    // ---------------------------------------------------------------------------
    assign rx_busy = (state != IDLE && state != ERROR);

endmodule