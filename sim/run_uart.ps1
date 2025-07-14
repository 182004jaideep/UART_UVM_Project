# Run UART UVM Simulation in Active-HDL Student Edition (Batch Mode)
$ActiveHDLPath = "C:\Aldec\Active-HDL-Student-Edition\BIN"
$TclScript = "C:\UART_UVM_PROJECT\run_uart_uvm_aldec.tcl"

# Navigate to Active-HDL BIN directory
Push-Location $ActiveHDLPath

# Run simulation
Write-Host "⚙️ Starting UART UVM Simulation..."
.\avhdl.exe -do $TclScript

Pop-Location