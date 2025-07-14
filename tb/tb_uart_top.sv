`include "uvm_macros.svh"
import uvm_pkg::*;

// =============================================================================
// UART TRANSACTION CLASS
// =============================================================================
class uart_transaction extends uvm_sequence_item;
    rand bit [7:0] tx_data;
    rand bit       tx_wr_en;
    rand bit       rx_rd_en;
    rand bit       abort_tx;
    rand bit       rx_abort;
    rand bit       rx;

    bit [7:0] rx_data;
    bit       tx_full, tx_empty, rx_full, rx_empty;
    bit       tx_busy, rx_busy;
    bit       tx_error, rx_error;
    bit       frame_error, parity_error;
    bit       tx_underrun, rx_overrun;

    rand bit [1:0] test_type; // 0=normal, 1=parity, 2=corner, 3=error
    rand int delay_cycles;

    constraint c_data     { tx_data inside {[8'h00:8'hFF]}; }
    constraint c_ctrl     {
        tx_wr_en dist {1:=80, 0:=20};
        rx_rd_en dist {1:=70, 0:=30};
        abort_tx dist {0:=95, 1:=5};
        rx_abort dist {0:=95, 1:=5};
    }
    constraint c_test     { test_type dist {0:=60, 1:=20, 2:=15, 3:=5}; }
    constraint c_delay    { delay_cycles inside {[1:10]}; }

    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(tx_data, UVM_ALL_ON)
        `uvm_field_int(tx_wr_en, UVM_ALL_ON)
        `uvm_field_int(rx_rd_en, UVM_ALL_ON)
        `uvm_field_int(abort_tx, UVM_ALL_ON)
        `uvm_field_int(rx_abort, UVM_ALL_ON)
        `uvm_field_int(rx, UVM_ALL_ON)
        `uvm_field_int(test_type, UVM_ALL_ON)
        `uvm_field_int(delay_cycles, UVM_ALL_ON)
        `uvm_field_int(rx_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("TX: 0x%0h, RX: 0x%0h, test=%0d, parity_err=%0b", tx_data, rx_data, test_type, parity_error);
    endfunction
endclass

// =============================================================================
// BASE SEQUENCE CLASS
// =============================================================================
class uart_base_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_base_sequence)
    
    function new(string name = "uart_base_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        // Override in derived classes
    endtask
    
    // Utility task for creating transactions
    task create_and_send_transaction(int test_type = 0, bit [7:0] data = 0, bit force_data = 0);
        uart_transaction tx;
        tx = uart_transaction::type_id::create("tx");
        start_item(tx);
        if (force_data) begin
            assert(tx.randomize() with {
                tx_data == data;
                test_type == local::test_type;
            });
        end else begin
            assert(tx.randomize() with {
                test_type == local::test_type;
            });
        end
        finish_item(tx);
    endtask
endclass

// =============================================================================
// SEQUENCE 1: RANDOM TEST
// =============================================================================
class uart_random_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_random_sequence)
    
    function new(string name = "uart_random_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info("SEQ", "Starting Random Sequence", UVM_LOW)
        repeat(20) begin
            create_and_send_transaction(0); // Normal test type
            #100ns; // Wait for transaction completion
        end
        `uvm_info("SEQ", "Random Sequence Completed", UVM_LOW)
    endtask
endclass

// =============================================================================
// SEQUENCE 2: PARITY TEST
// =============================================================================
class uart_parity_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_parity_sequence)
    
    function new(string name = "uart_parity_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info("SEQ", "Starting Parity Test Sequence", UVM_LOW)
        repeat(15) begin
            create_and_send_transaction(1); // Parity test type
            #150ns;
        end
        `uvm_info("SEQ", "Parity Test Sequence Completed", UVM_LOW)
    endtask
endclass

// =============================================================================
// SEQUENCE 3: CORNER CASE TEST
// =============================================================================
class uart_corner_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_corner_sequence)
    
    function new(string name = "uart_corner_sequence");
        super.new(name);
    endfunction
    
    task body();
        bit [7:0] corner_values[] = {8'h00, 8'hFF, 8'h55, 8'hAA, 8'h0F, 8'hF0};
        
        `uvm_info("SEQ", "Starting Corner Case Sequence", UVM_LOW)
        foreach(corner_values[i]) begin
            `uvm_info("SEQ", $sformatf("Testing corner value: 0x%0h", corner_values[i]), UVM_LOW)
            create_and_send_transaction(2, corner_values[i], 1); // Corner case with specific data
            #200ns;
        end
        `uvm_info("SEQ", "Corner Case Sequence Completed", UVM_LOW)
    endtask
endclass

// =============================================================================
// SEQUENCE 4: ERROR INJECTION TEST
// =============================================================================
class uart_error_sequence extends uart_base_sequence;
    `uvm_object_utils(uart_error_sequence)
    
    function new(string name = "uart_error_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info("SEQ", "Starting Error Injection Sequence", UVM_LOW)
        repeat(10) begin
            create_and_send_transaction(3); // Error injection test type
            #250ns;
        end
        `uvm_info("SEQ", "Error Injection Sequence Completed", UVM_LOW)
    endtask
endclass

// =============================================================================
// UART DRIVER
// =============================================================================
class uart_driver extends uvm_driver #(uart_transaction);
    `uvm_component_utils(uart_driver)

    virtual uart_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Could not get vif")
    endfunction

    task run_phase(uvm_phase phase);
        uart_transaction tx;
        
        // Initialize interface
        vif.tx_data   <= 8'h00;
        vif.tx_wr_en  <= 1'b0;
        vif.rx_rd_en  <= 1'b0;
        vif.abort_tx  <= 1'b0;
        vif.rx_abort  <= 1'b0;
        vif.rx        <= 1'b1; // Idle state
        
        forever begin
            seq_item_port.get_next_item(tx);
            drive_transaction(tx);
            seq_item_port.item_done();
        end
    endtask

    task drive_transaction(uart_transaction tx);
        wait(vif.rst_n);
        repeat(tx.delay_cycles) @(posedge vif.clk);

        case (tx.test_type)
            0: drive_normal(tx);
            1: drive_parity(tx);
            2: drive_corner(tx);
            3: drive_error(tx);
        endcase

        `uvm_info("DRV", $sformatf("Driven: %s", tx.convert2string()), UVM_LOW)
    endtask

    task drive_normal(uart_transaction tx);
        // Drive TX data
        @(posedge vif.clk);
        vif.tx_data   <= tx.tx_data;
        vif.tx_wr_en  <= tx.tx_wr_en;
        vif.abort_tx  <= tx.abort_tx;
        vif.rx_abort  <= tx.rx_abort;

        @(posedge vif.clk);
        vif.tx_wr_en  <= 1'b0;
        vif.abort_tx  <= 1'b0;
        vif.rx_abort  <= 1'b0;
        
        // Wait for transmission to complete
        if (tx.tx_wr_en) begin
            wait(vif.tx_busy);
            wait(!vif.tx_busy);
        end
        
        // Drive RX read
        if (tx.rx_rd_en && !vif.rx_empty) begin
            @(posedge vif.clk);
            vif.rx_rd_en <= 1'b1;
            @(posedge vif.clk);
            vif.rx_rd_en <= 1'b0;
        end
    endtask

    task drive_parity(uart_transaction tx);
        @(posedge vif.clk);
        vif.tx_data  <= tx.tx_data;
        vif.tx_wr_en <= 1'b1;

        @(posedge vif.clk);
        vif.tx_wr_en <= 1'b0;

        // Wait for transmission to complete
        wait(vif.tx_busy);
        wait(!vif.tx_busy);
    endtask

    task drive_corner(uart_transaction tx);
        @(posedge vif.clk);
        vif.tx_data  <= tx.tx_data;
        vif.tx_wr_en <= 1'b1;
        @(posedge vif.clk);
        vif.tx_wr_en <= 1'b0;
        
        // Wait for transmission
        wait(vif.tx_busy);
        wait(!vif.tx_busy);
        
        repeat(5) @(posedge vif.clk);
    endtask

    task drive_error(uart_transaction tx);
        @(posedge vif.clk);
        vif.tx_data   <= tx.tx_data;
        vif.tx_wr_en  <= 1'b1;
        vif.abort_tx  <= tx.abort_tx;
        vif.rx_abort  <= tx.rx_abort;

        @(posedge vif.clk);
        vif.tx_wr_en <= 1'b0;
        repeat(3) @(posedge vif.clk);
        vif.abort_tx  <= 1'b0;
        vif.rx_abort  <= 1'b0;
    endtask
endclass

// =============================================================================
// UART MONITOR
// =============================================================================
class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if vif;

    uvm_analysis_port #(uart_transaction) ap;           // For scoreboard
    uvm_analysis_port #(uart_transaction) coverage_ap;  // For coverage

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get vif")

        ap = new("ap", this);
        coverage_ap = new("coverage_ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        uart_transaction tx;
        forever begin
            tx = uart_transaction::type_id::create("tx");
            collect_transaction(tx);
            ap.write(tx);
            coverage_ap.write(tx);
            #10ns; // Prevent tight loop
        end
    endtask

    task collect_transaction(uart_transaction tx);
        // Wait for any activity
        @(posedge vif.clk);
        
        // Look for write or read activity
        if (vif.tx_wr_en || vif.rx_rd_en || vif.tx_busy || vif.rx_busy) begin
            // Sample stimulus signals
            tx.tx_data = vif.tx_data;
            tx.tx_wr_en = vif.tx_wr_en;
            tx.rx_rd_en = vif.rx_rd_en;
            tx.abort_tx = vif.abort_tx;
            tx.rx_abort = vif.rx_abort;
            tx.rx = vif.rx;

            // Sample response signals
            tx.rx_data = vif.rx_data;
            tx.tx_full = vif.tx_full;
            tx.tx_empty = vif.tx_empty;
            tx.rx_full = vif.rx_full;
            tx.rx_empty = vif.rx_empty;
            tx.tx_busy = vif.tx_busy;
            tx.rx_busy = vif.rx_busy;
            tx.tx_error = vif.tx_error;
            tx.rx_error = vif.rx_error;
            tx.frame_error = vif.frame_error;
            tx.parity_error = vif.parity_error;
            tx.tx_underrun = vif.tx_underrun;
            tx.rx_overrun = vif.rx_overrun;

            `uvm_info("MON", $sformatf("Collected: %s", tx.convert2string()), UVM_HIGH)
        end else begin
            // No activity - wait for next clock
            @(posedge vif.clk);
        end
    endtask
endclass

// =============================================================================
// FIXED COVERAGE CLASS
// =============================================================================
class uart_coverage extends uvm_component;
    `uvm_component_utils(uart_coverage)

    uvm_analysis_export #(uart_transaction) cov_export;
    uvm_tlm_analysis_fifo #(uart_transaction) cov_fifo;

    // Fixed covergroup - using transaction fields directly
    covergroup uart_cov with function sample(uart_transaction tx);
        tx_data_cp: coverpoint tx.tx_data { 
            bins data_vals[] = {[8'h00:8'hFF]}; 
        }
        test_type_cp: coverpoint tx.test_type { 
            bins normal = {0};
            bins parity = {1};
            bins corner = {2};
            bins error = {3};
        }
        parity_err_cp: coverpoint tx.parity_error {
            bins no_error = {0};
            bins error = {1};
        }
        frame_err_cp: coverpoint tx.frame_error {
            bins no_error = {0};
            bins error = {1};
        }
        
        // Cross coverage
        test_x_parity: cross test_type_cp, parity_err_cp;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        uart_cov = new;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export", this);
        cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        uart_transaction tx;
        forever begin
            cov_fifo.get(tx);
            uart_cov.sample(tx); // Pass transaction to sample function
            `uvm_info("COV", $sformatf("Sampled TX: %0h, type: %0d", tx.tx_data, tx.test_type), UVM_HIGH)
        end
    endtask
    
    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("Coverage: %0.2f%%", uart_cov.get_coverage()), UVM_LOW)
    endfunction
endclass

// =============================================================================
// ENHANCED SCOREBOARD
// =============================================================================
class uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(uart_scoreboard)

    uvm_analysis_export #(uart_transaction) sb_export;
    uvm_tlm_analysis_fifo #(uart_transaction) sb_fifo;

    int total_transactions, normal_transactions, parity_transactions;
    int corner_transactions, error_transactions;
    int error_count, parity_error_count, frame_error_count, data_mismatch_count;
    
    // Store transmitted data for loopback checking
    bit [7:0] tx_data_queue[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
        sb_fifo = new("sb_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        sb_export.connect(sb_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        uart_transaction tx;
        forever begin
            sb_fifo.get(tx);
            total_transactions++;
            check_transaction(tx);
        end
    endtask

    function void check_transaction(uart_transaction tx);
        case(tx.test_type)
            0: normal_transactions++;
            1: parity_transactions++;
            2: corner_transactions++;
            3: error_transactions++;
        endcase

        // Store TX data for loopback verification
        if (tx.tx_wr_en) begin
            tx_data_queue.push_back(tx.tx_data);
        end

        // Check RX data against stored TX data
        if (tx.rx_rd_en && !tx.rx_empty && tx_data_queue.size() > 0) begin
            bit [7:0] expected_data = tx_data_queue.pop_front();
            if (tx.rx_data !== expected_data) begin
                data_mismatch_count++;
                `uvm_error("SB", $sformatf("TX/RX mismatch: Expected=0x%0h, Got=0x%0h", expected_data, tx.rx_data));
            end else begin
                `uvm_info("SB", $sformatf("✓ TX matches RX: 0x%0h", tx.rx_data), UVM_HIGH);
            end
        end

        // Count errors
        if (tx.tx_error || tx.rx_error)
            error_count++;

        if (tx.parity_error) begin
            parity_error_count++;
            if (tx.test_type != 3)  // ignore if error-injection
                `uvm_warning("SB", $sformatf("Unexpected parity error in test_type %0d", tx.test_type));
        end

        if (tx.frame_error) begin
            frame_error_count++;
            `uvm_info("SB", "Frame error detected", UVM_LOW)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", "=========== FINAL SCOREBOARD REPORT ===========", UVM_LOW)
        `uvm_info("SB", $sformatf("Total: %0d | Normal: %0d | Parity: %0d | Corner: %0d | Error: %0d",total_transactions, normal_transactions, parity_transactions, corner_transactions, error_transactions), UVM_LOW)
        `uvm_info("SB", $sformatf("TX/RX mismatches: %0d", data_mismatch_count), UVM_LOW)
        `uvm_info("SB", $sformatf("Parity errors:     %0d", parity_error_count), UVM_LOW)
        `uvm_info("SB", $sformatf("Frame errors:      %0d", frame_error_count), UVM_LOW)
        `uvm_info("SB", $sformatf("Total errors:      %0d", error_count), UVM_LOW)
        `uvm_info("SB", "===============================================", UVM_LOW)

        if (total_transactions == 0)
            `uvm_fatal("SB", "✗ No transactions occurred!")
    endfunction
endclass

// =============================================================================
// UART AGENT
// =============================================================================
class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    
    uart_driver driver;
    uart_monitor monitor;
    uvm_sequencer #(uart_transaction) sequencer;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = uart_driver::type_id::create("driver", this);
        monitor = uart_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(uart_transaction)::type_id::create("sequencer", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

// =============================================================================
// UART ENVIRONMENT
// =============================================================================
class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent agent;
    uart_scoreboard scoreboard;
    uart_coverage coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = uart_agent::type_id::create("agent", this);
        scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
        coverage   = uart_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.sb_export);
        agent.monitor.coverage_ap.connect(coverage.cov_export);
    endfunction
endclass

// =============================================================================
// TEST CLASSES
// =============================================================================

// Base Test Class
class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)
    
    uart_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// Test 1: Basic Random Test
class uart_basic_test extends uart_base_test;
    `uvm_component_utils(uart_basic_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_random_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "🚀 Starting Basic Random Test", UVM_LOW)
        seq = uart_random_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #10us; // Wait for completion
        `uvm_info("TEST", "✅ Basic Random Test Completed", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

// Test 2: Parity Test
class uart_parity_test extends uart_base_test;
    `uvm_component_utils(uart_parity_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_parity_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "🚀 Starting Parity Test", UVM_LOW)
        seq = uart_parity_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #15us; // Wait for completion
        `uvm_info("TEST", "✅ Parity Test Completed", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

// Test 3: Corner Case Test
class uart_corner_test extends uart_base_test;
    `uvm_component_utils(uart_corner_test)
    
    function new(string name = "uart_corner_test", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_corner_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "🚀 Starting Corner Case Test", UVM_LOW)
        seq = uart_corner_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #20us; // Wait for completion
        `uvm_info("TEST", "✅ Corner Case Test Completed", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

// Test 4: Error Injection Test
class uart_error_test extends uart_base_test;
    `uvm_component_utils(uart_error_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        uart_error_sequence seq;
        phase.raise_objection(this);
        
        `uvm_info("TEST", "🚀 Starting Error Injection Test", UVM_LOW)
        seq = uart_error_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        #25us; // Wait for completion
        `uvm_info("TEST", "✅ Error Injection Test Completed", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

class uart_all_tests extends uart_base_test;
    `uvm_component_utils(uart_all_tests)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uart_random_sequence rand_seq;
        uart_parity_sequence parity_seq;
        uart_corner_sequence corner_seq;
        uart_error_sequence error_seq;

        phase.raise_objection(this);

        // Run basic random test
        `uvm_info("TEST", "▶️ Starting uart_random_sequence", UVM_LOW)
        rand_seq = uart_random_sequence::type_id::create("rand_seq");
        rand_seq.start(env.agent.sequencer);

        // Run parity test
        `uvm_info("TEST", "▶️ Starting uart_parity_sequence", UVM_LOW)
        parity_seq = uart_parity_sequence::type_id::create("parity_seq");
        parity_seq.start(env.agent.sequencer);

        // Run corner case test
        `uvm_info("TEST", "▶️ Starting uart_corner_sequence", UVM_LOW)
        corner_seq = uart_corner_sequence::type_id::create("corner_seq");
        corner_seq.start(env.agent.sequencer);

        // Run error injection test
        `uvm_info("TEST", "▶️ Starting uart_error_sequence", UVM_LOW)
        error_seq = uart_error_sequence::type_id::create("error_seq");
        error_seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask
endclass

// =============================================================================
// FIXED TESTBENCH TOP MODULE
// =============================================================================
module tb_uart_top;
    // Clock and reset
    reg clk = 0;
    reg rst_n = 0;
    
    // Clock generation (50MHz to match DUT default)
    always #10ns clk = ~clk; 
    
    // Reset generation
    initial begin
        rst_n = 0;
        #100ns rst_n = 1;
    end
    
    // Interface instance
    uart_if #(.DATA_WIDTH(8)) uart_if_inst (
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // DUT instance with correct parameter matching
    uart_top #(
        .DATA_WIDTH(8),
        .STOP_BITS(1),
        .PARITY_EN(0),
        .PARITY_ODD(0),
        .BAUD_RATE(115200),
        .CLK_FREQ(50000000),  // Match clock frequency
        .FIFO_DEPTH(16)
    ) dut (
        .clk(uart_if_inst.clk),
        .rst_n(uart_if_inst.rst_n),
        .tx_data(uart_if_inst.tx_data),
        .tx_wr_en(uart_if_inst.tx_wr_en),
        .tx_full(uart_if_inst.tx_full),
        .tx_empty(uart_if_inst.tx_empty),
        .rx_data(uart_if_inst.rx_data),
        .rx_rd_en(uart_if_inst.rx_rd_en),
        .rx_full(uart_if_inst.rx_full),
        .rx_empty(uart_if_inst.rx_empty),
        .tx_busy(uart_if_inst.tx_busy),
        .rx_busy(uart_if_inst.rx_busy),
        .tx_error(uart_if_inst.tx_error),
        .rx_error(uart_if_inst.rx_error),
        .frame_error(uart_if_inst.frame_error),
        .parity_error(uart_if_inst.parity_error),
        .tx_underrun(uart_if_inst.tx_underrun),
        .rx_overrun(uart_if_inst.rx_overrun),
        .abort_tx(uart_if_inst.abort_tx),
        .rx_abort(uart_if_inst.rx_abort),
        .rx(uart_if_inst.rx),
        .tx(uart_if_inst.tx)
    );
    
    // Connect TX to RX for loopback testing
    assign uart_if_inst.rx = uart_if_inst.tx;
    
    // UVM configuration and test execution
    initial begin
        // Configure the virtual interface
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", uart_if_inst);
        
        // Enable waveform dumping
        $dumpfile("uart_waves.vcd");
        $dumpvars(0, tb_uart_top);
        
        // Run the test
        run_test();
    end
    
    // Timeout watchdog
    initial begin
        #1ms; // Increased timeout
        `uvm_fatal("TIMEOUT", "Test timed out!")
    end
    
endmodule