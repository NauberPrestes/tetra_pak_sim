SIM=sim/sim.vvp
VCD=sim/wave.vcd

# Default target
all: mux

# -------------------------------------------------
# MUX configuration
# -------------------------------------------------

mux: RTL=rtl/modules_mux.v
mux: TB=tb/tb_mux.v
mux: run

# -------------------------------------------------
# SERDES configuration
# -------------------------------------------------

serdes: RTL=rtl/modules_serdes.v
serdes: TB=tb/tb_serdes.v
serdes: run

# -------------------------------------------------
# 8b/10b configuration
# -------------------------------------------------

8b10b: RTL=rtl/modules_8b10b.v
8b10b: TB=tb/tb_8b10b.v
8b10b: run

# -------------------------------------------------
# Compile
# -------------------------------------------------

compile:
	mkdir -p sim
	iverilog -Wall -o $(SIM) $(RTL) $(TB)

# -------------------------------------------------
# Run simulation
# -------------------------------------------------

run: compile
	vvp $(SIM)

# -------------------------------------------------
# Open waveform
# -------------------------------------------------

wave:
	gtkwave $(VCD) waves/signals.gtkw

# -------------------------------------------------
# Clean
# -------------------------------------------------

clean:
	rm -rf sim/*