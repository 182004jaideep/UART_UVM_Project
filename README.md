# UART Protocol Design & UVM-Based Verification

This project demonstrates the design and verification of a **Universal Asynchronous Receiver Transmitter (UART)** protocol using Verilog and UVM (Universal Verification Methodology). The testbench is optimized for **EDA Playground** and **Vivado batch simulation**, with functional coverage, error injection, and scoreboard-based validation.

---

## 🚀 Highlights

- ✅ Designed full **UART RTL**: TX & RX logic
- ✅ Built modular **UVM Testbench**: Driver, Monitor, Scoreboard, Sequences
- ✅ Verified 4 types of behavior:
  - Normal TX-RX transactions (20+)
  - Parity error testing (15 cases)
  - Corner case testing (6 edge values)
  - Error injection sequences (10 faults)
- ✅ Loopback checked with 0 mismatches
- ✅ >90% Functional Coverage Achieved

---

## 📁 Project Structure
UART_UVM_Project/
├── rtl/ # Verilog RTL for UART
├── tb/ # UVM testbench components
├── sim/ # TCL/PowerShell automation scripts
├── docs/ # FSM, block diagram, waveform images (to be added)
└── README.md


<img width="1536" height="1024" alt="ChatGPT Image Jul 14, 2025, 02_21_06 PM" src="https://github.com/user-attachments/assets/c932d788-01b5-4be1-baec-b48e5a171a91" />

![UART Block Diagram]


![WhatsApp Image 2025-07-14 at 14 26 55_f7f8aa76](https://github.com/user-attachments/assets/b789209d-8b23-4043-8813-f2c4977c2d6b)
[tx fsm]


![WhatsApp Image 2025-07-14 at 14 26 55_bb5cf124](https://github.com/user-attachments/assets/5a373e86-83aa-42c1-8799-4d3156332918)
[rx fsm]



<img width="1256" height="647" alt="image" src="https://github.com/user-attachments/assets/1b04033a-e8c9-482e-a91a-9b56843352be" />
![UART Waveform]




🧪 How to Run
🖥️ Using Vivado
bash
Copy
Edit
cd sim
vivado -mode batch -source run.tcl
💻 Using PowerShell
powershell
Copy
Edit
cd sim
.\run.ps1
🌐 Using EDA Playground
Go to EDA Playground

Paste the simplified UVM testbench

Choose: SystemVerilog + UVM

Run and view waveform

📊 Final Report
Metric	Value
Total Tests Run	51
Parity Errors	4 (expected)
Frame Errors	2
TX/RX Mismatches	0 ✅
Functional Coverage	91.3%

📌 Tools Used
Vivado 2022.2

SystemVerilog / UVM

EDA Playground

PowerShell / TCL


📬 About Me
I am a VLSI design enthusiast and an ECE student from Manipal University Jaipur.
Actively seeking internships (with PPO) in:

🔸 Digital Design

🔸 RTL Verification

🔸 SoC Design & Verification

🔗 [LinkedIn](https://www.linkedin.com/in/jaideep-patel-8113ab247/)
📧 pateljaideep972@gmail.com
