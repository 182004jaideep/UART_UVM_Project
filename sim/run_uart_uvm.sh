#!/bin/bash

# =====================================
# UART UVM Simulation Script (GUI Mode)
# =====================================

echo "----------------------------------"
echo " 🛠️  UART UVM Simulation Starting"
echo "----------------------------------"

# Step 1: Move to the script's directory
cd "$(dirname "$0")"

# Step 2: Create and map simulation libraries
echo "📁 Creating work and uvm libraries..."
vlib work 2>/dev/null
vmap work work

if [ ! -d "uvm" ]; then
    vlib uvm
fi

# Step 3: Compile UVM 1.2 package
echo "📦 Compiling UVM 1.2 package..."
vlog -work uvm -sv +acc=rn \
+incdir+uvm-1.2/src \
+incdir+uvm-1.2/src/base \
+incdir+uvm-1.2/src/comps \
+incdir+uvm-1.2/src/macros \
+incdir+uvm-1.2/src/dpi \
+incdir+uvm-1.2/src/seq \
+incdir+uvm-1.2/src/tlm1 \
+incdir+uvm-1.2/src/dap \
+incdir+uvm-1.2/src/reg \
+incdir+uvm-1.2/src/tlm2 \
+incdir+uvm-1.2/src/objections \
+incdir+uvm-1.2/src/compatibility \
uvm-1.2/src/uvm_pkg.sv || {
    echo "❌ Failed to compile uvm_pkg.sv"
    exit 1
}

# Step 4: Compile RTL files
echo "📦 Compiling RTL files..."
vlog -sv +acc=rn rtl/*.sv || {
    echo "❌ RTL Compilation Failed"
    exit 1
}

# Step 5: Compile Interface
echo "📡 Compiling UART interface..."
vlog -sv +acc=rn interface/*.sv || {
    echo "❌ Interface Compilation Failed"
    exit 1
}

# Step 6: Compile UVM Testbench
echo "🧪 Compiling UVM Testbench..."
vlog -sv -L uvm +acc=rn +define+UVM_NO_DPI +incdir+uvm-1.2/src tb/tb_uart_top.sv || {
    echo "❌ Testbench Compilation Failed"
    exit 1
}

# Step 7: Launch Simulation in GUI mode
echo "🚀 Launching ModelSim GUI..."
vsim work.tb_uart_top -L uvm +UVM_TESTNAME=uart_test +UVM_VERBOSITY=UVM_MEDIUM -sv_seed random -do "
view wave;
add wave -r *;
run -all;
"

echo "✅ Simulation Completed Successfully"