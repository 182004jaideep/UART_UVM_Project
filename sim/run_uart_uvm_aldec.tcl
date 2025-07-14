# ============================================================================
# UART UVM Simulation - Active-HDL Student Edition (Final Version)
# ============================================================================
puts "\n=========================================="
puts "UART UVM Simulation - Active-HDL"
puts "=========================================="

# --- Configuration ---
set PROJECT_ROOT "C:/UART_UVM_PROJECT"
set WORK_LIB_DIR "$PROJECT_ROOT/work"
set WORK_LIB_NAME "work"
set ASDB_FILE "$PROJECT_ROOT/uart_waveform.asdb"
set LOG_FILE "$PROJECT_ROOT/sim_log.txt"
set TOP_MODULE "tb_uart_top"
set UVM_LIB_PATH "$PROJECT_ROOT/uvm-1.2"

puts "Project Root: $PROJECT_ROOT"
puts "Waveform Output: $ASDB_FILE"
puts "Log Output: $LOG_FILE"
puts "=========================================="

# --- Start Transcript Logging ---
transcript file $LOG_FILE
transcript on

# --- Set Up Library ---
puts "\n--- Setting up library ---"
if {[file exists $WORK_LIB_DIR]} {
    puts "Removing old library..."
    catch {file delete -force $WORK_LIB_DIR}
}
catch {vlib $WORK_LIB_DIR}
catch {vmap $WORK_LIB_NAME $WORK_LIB_DIR}
puts "✅ Library '$WORK_LIB_NAME' is ready."

# --- RTL Files ---
set RTL_FILES [list \
    "$PROJECT_ROOT/rtl/uart_top.sv" \
    "$PROJECT_ROOT/rtl/uart_tx.sv" \
    "$PROJECT_ROOT/rtl/uart_rx.sv" \
    "$PROJECT_ROOT/rtl/uart_fifo.sv" \
    "$PROJECT_ROOT/rtl/bund_gen.sv" \
    "$PROJECT_ROOT/interface/uart_if.sv" \
]

# --- TB / UVM Files ---
set TB_FILES [list \
    "$PROJECT_ROOT/uvm-1.2/src/uvm_pkg.sv" \
    "$PROJECT_ROOT/tb/uart_pkg.sv" \
    "$PROJECT_ROOT/tb/uart_env.sv" \
    "$PROJECT_ROOT/tb/uart_agent.sv" \
    "$PROJECT_ROOT/tb/uart_driver.sv" \
    "$PROJECT_ROOT/tb/uart_monitor.sv" \
    "$PROJECT_ROOT/tb/uart_scoreboard.sv" \
    "$PROJECT_ROOT/tb/uart_test_lib.sv" \
    "$PROJECT_ROOT/tb/uart_sequence_lib.sv" \
    "$PROJECT_ROOT/tb/tb_uart_top.sv" \
]

# --- Compile RTL ---
puts "\n--- Compiling RTL Files ---"
foreach file $RTL_FILES {
    if {[file exists $file]} {
        puts "Compiling: $file"
        if {[catch {vlog -sv -work $WORK_LIB_NAME $file} result]} {
            puts "❌ ERROR compiling $file: $result"
            return
        } else {
            puts "✅ Compiled: $file"
        }
    } else {
        puts "❌ File not found: $file"
        return
    }
}

# --- Compile Testbench ---
puts "\n--- Compiling Testbench Files ---"
foreach file $TB_FILES {
    if {[file exists $file]} {
        puts "Compiling: $file"
        if {[catch {vlog -sv -work $WORK_LIB_NAME +incdir+$UVM_LIB_PATH $file} result]} {
            puts "❌ ERROR compiling $file: $result"
            return
        } else {
            puts "✅ Compiled: $file"
        }
    } else {
        puts "❌ File not found: $file"
        return
    }
}

# --- Run Simulation ---
puts "\n--- Launching Simulation ---"
if {[catch {vsim -voptargs="+acc" -lib $WORK_LIB_NAME $TOP_MODULE -gui} result]} {
    puts "❌ ERROR: Failed to launch simulation: $result"
    return
}

puts "✅ Simulation started. Running for 1000us..."
catch {add wave -r /*}
run 1000us

# --- Save Waveform ---
puts "📦 Saving waveform as: $ASDB_FILE"
catch {asdb save $ASDB_FILE}
catch {wave zoomfull}

puts "\n=========================================="
puts "✅ UART UVM Simulation Complete!"
puts "Log: $LOG_FILE"
puts "Waveform: $ASDB_FILE"
puts "=========================================="

exit