
CROSS=riscv-none-embed-
CFLAGS=

# ---- TinyFPGA BX Board ---

TINYUSB_SOURCES = \
    tinyusb/edge_detect.v \
    tinyusb/serial.v \
    tinyusb/usb_fs_in_arb.v \
    tinyusb/usb_fs_in_pe.v \
    tinyusb/usb_fs_out_arb.v \
    tinyusb/usb_fs_out_pe.v \
    tinyusb/usb_fs_pe.v \
    tinyusb/usb_fs_rx.v \
    tinyusb/usb_fs_tx_mux.v \
    tinyusb/usb_fs_tx.v \
    tinyusb/usb_reset_det.v \
    tinyusb/usb_serial_ctrl_ep.v \
    tinyusb/usb_uart_bridge_ep.v \
    tinyusb/usb_uart_core.v \
    tinyusb/usb_uart_i40.v \
	tinyusb/pll.v

tinysim: tinyfpga_tb.vvp tinyfpga_fw.hex
	vvp -N $< +firmware=tinyfpga_fw.hex

tinysynsim: tinyfpga_syn_tb.vvp tinyfpga_fw.hex
	vvp -N $< +firmware=tinyfpga_fw.hex

tinyfpga.blif: tinyfpga.v spimemio.v simpleusb.v picosoc.v ../picorv32.v $(TINYUSB_SOURCES)
	yosys -ql tinyfpga.log -p 'synth_ice40 -top tinyfpga -blif tinyfpga.blif' $^

tinyfpga.json: tinyfpga.v spimemio.v simpleusb.v picosoc.v ../picorv32.v $(TINYUSB_SOURCES)
	yosys -q -p 'synth_ice40 -top tinyfpga -json $@' $^

tinyfpga_tb.vvp: tinyfpga_tb.v tinyfpga.v spimemio.v simpleusb.v picosoc.v ../picorv32.v spiflash.v $(TINYUSB_SOURCES)
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

tinyfpga_syn_tb.vvp: tinyfpga_tb.v tinyfpga_syn.v spiflash.v $(TINYUSB_SOURCES)
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

tinyfpga_syn.v: tinyfpga.blif
	yosys -p 'read_blif -wideports tinyfpga.blif; write_verilog tinyfpga_syn.v'

tinyfpga.asc: tinyfpga.pcf tinyfpga.json
	nextpnr-ice40 --lp8k --freq 24 --opt-timing --package cm81 --pcf tinyfpga.pcf --json tinyfpga.json --asc tinyfpga.asc

tinyfpga.bin: tinyfpga.asc
	icetime -d hx8k -c 24 -mtr tinyfpga.rpt tinyfpga.asc
	icepack tinyfpga.asc tinyfpga.bin

tinyprog: tinyfpga.bin tinyfpga_fw.bin
	tinyprog -p tinyfpga.bin -u tinyfpga_fw.bin

tinyprog_fw: tinyfpga_fw.bin
	tinyprog -u tinyfpga_fw.bin

tinyfpga_sections.lds: sections.lds
	$(CROSS)cpp -P -DTINYFPGA -o $@ $^

tinyfpga_fw.elf: tinyfpga_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DTINYFPGA -march=rv32imc -Wl,-Bstatic,-T,tinyfpga_sections.lds,--strip-debug -ffreestanding -nostdlib -o tinyfpga_fw.elf start.s firmware.c

tinyfpga_fw.hex: tinyfpga_fw.elf
	$(CROSS)objcopy -O verilog tinyfpga_fw.elf tinyfpga_fw.hex

tinyfpga_fw.bin: tinyfpga_fw.elf
	$(CROSS)objcopy -O binary tinyfpga_fw.elf tinyfpga_fw.bin

# ---- iCE40 HX8K Breakout Board ----

hx8ksim: hx8kdemo_tb.vvp hx8kdemo_fw.hex
	vvp -N $< +firmware=hx8kdemo_fw.hex

hx8ksynsim: hx8kdemo_syn_tb.vvp hx8kdemo_fw.hex
	vvp -N $< +firmware=hx8kdemo_fw.hex

hx8kdemo.blif: hx8kdemo.v spimemio.v simpleuart.v picosoc.v ../picorv32.v
	yosys -ql hx8kdemo.log -p 'synth_ice40 -top hx8kdemo -blif hx8kdemo.blif' $^

hx8kdemo_tb.vvp: hx8kdemo_tb.v hx8kdemo.v spimemio.v simpleuart.v picosoc.v ../picorv32.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

hx8kdemo_syn_tb.vvp: hx8kdemo_tb.v hx8kdemo_syn.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

hx8kdemo_syn.v: hx8kdemo.blif
	yosys -p 'read_blif -wideports hx8kdemo.blif; write_verilog hx8kdemo_syn.v'

hx8kdemo.asc: hx8kdemo.pcf hx8kdemo.blif
	arachne-pnr -d 8k -o hx8kdemo.asc -p hx8kdemo.pcf hx8kdemo.blif

hx8kdemo.bin: hx8kdemo.asc
	icetime -d hx8k -c 12 -mtr hx8kdemo.rpt hx8kdemo.asc
	icepack hx8kdemo.asc hx8kdemo.bin

hx8kprog: hx8kdemo.bin hx8kdemo_fw.bin
	iceprog hx8kdemo.bin
	iceprog -o 1M hx8kdemo_fw.bin

hx8kprog_fw: hx8kdemo_fw.bin
	iceprog -o 1M hx8kdemo_fw.bin

hx8kdemo_sections.lds: sections.lds
	$(CROSS)cpp -P -DHX8KDEMO -o $@ $^

hx8kdemo_fw.elf: hx8kdemo_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DHX8KDEMO -march=rv32imc -Wl,-Bstatic,-T,hx8kdemo_sections.lds,--strip-debug -ffreestanding -nostdlib -o hx8kdemo_fw.elf start.s firmware.c

hx8kdemo_fw.hex: hx8kdemo_fw.elf
	$(CROSS)objcopy -O verilog hx8kdemo_fw.elf hx8kdemo_fw.hex

hx8kdemo_fw.bin: hx8kdemo_fw.elf
	$(CROSS)objcopy -O binary hx8kdemo_fw.elf hx8kdemo_fw.bin

# ---- iCE40 IceBreaker Board ----

icebsim: icebreaker_tb.vvp icebreaker_fw.hex
	vvp -N $< +firmware=icebreaker_fw.hex

icebsynsim: icebreaker_syn_tb.vvp icebreaker_fw.hex
	vvp -N $< +firmware=icebreaker_fw.hex

icebreaker.json: icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v ../picorv32.v
	yosys -ql icebreaker.log -p 'synth_ice40 -top icebreaker -json icebreaker.json' $^

icebreaker_tb.vvp: icebreaker_tb.v icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v ../picorv32.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

icebreaker_syn_tb.vvp: icebreaker_tb.v icebreaker_syn.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

icebreaker_syn.v: icebreaker.json
	yosys -p 'read_json icebreaker.json; write_verilog icebreaker_syn.v'

icebreaker.asc: icebreaker.pcf icebreaker.json
	nextpnr-ice40 --freq 13 --up5k --asc icebreaker.asc --pcf icebreaker.pcf --json icebreaker.json

icebreaker.bin: icebreaker.asc
	icetime -d up5k -c 12 -mtr icebreaker.rpt icebreaker.asc
	icepack icebreaker.asc icebreaker.bin

icebprog: icebreaker.bin icebreaker_fw.bin
	iceprog icebreaker.bin
	iceprog -o 1M icebreaker_fw.bin

icebprog_fw: icebreaker_fw.bin
	iceprog -o 1M icebreaker_fw.bin

icebreaker_sections.lds: sections.lds
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

icebreaker_fw.elf: icebreaker_sections.lds start.s firmware.c
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -march=rv32ic -Wl,-Bstatic,-T,icebreaker_sections.lds,--strip-debug -ffreestanding -nostdlib -o icebreaker_fw.elf start.s firmware.c

icebreaker_fw.hex: icebreaker_fw.elf
	$(CROSS)objcopy -O verilog icebreaker_fw.elf icebreaker_fw.hex

icebreaker_fw.bin: icebreaker_fw.elf
	$(CROSS)objcopy -O binary icebreaker_fw.elf icebreaker_fw.bin

# ---- Testbench for SPI Flash Model ----

spiflash_tb: spiflash_tb.vvp firmware.hex
	vvp -N $<

spiflash_tb.vvp: spiflash.v spiflash_tb.v
	iverilog -s testbench -o $@ $^

# ---- ASIC Synthesis Tests ----

cmos.log: spimemio.v simpleuart.v picosoc.v ../picorv32.v
	yosys -l cmos.log -p 'synth -top picosoc; abc -g cmos2; opt -fast; stat' $^

# ---- Clean ----

clean:
	rm -f testbench.vvp testbench.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f hx8kdemo_fw.elf hx8kdemo_fw.hex hx8kdemo_fw.bin cmos.log
	rm -f tinyfpga_fw.elf tinyfpga_fw.hex tinyfpga_fw.bin cmos.log
	rm -f icebreaker_fw.elf icebreaker_fw.hex icebreaker_fw.bin
	rm -f hx8kdemo.blif hx8kdemo.log hx8kdemo.asc hx8kdemo.rpt hx8kdemo.bin
	rm -f hx8kdemo_syn.v hx8kdemo_syn_tb.vvp hx8kdemo_tb.vvp
	rm -f tinyfpga.json tinyfpga.blif tinyfpga.log tinyfpga.asc tinyfpga.rpt tinyfpga.bin
	rm -f tinyfpga_syn.v tinyfpga_syn_tb.vvp tinyfpga_tb.vvp
	rm -f icebreaker.json icebreaker.log icebreaker.asc icebreaker.rpt icebreaker.bin
	rm -f icebreaker_syn.v icebreaker_syn_tb.vvp icebreaker_tb.vvp

.PHONY: spiflash_tb clean
.PHONY: hx8kprog hx8kprog_fw hx8ksim hx8ksynsim
.PHONY: icebprog icebprog_fw icebsim icebsynsim
