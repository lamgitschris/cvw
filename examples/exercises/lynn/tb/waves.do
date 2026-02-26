# coremark_waves.do

add wave -divider "PC / INSTR"

add wave -hex sim:/testbench/dut/PC
add wave -hex sim:/testbench/dut/Instr
add wave -bin sim:/testbench/dut/PCSrc


add wave -divider "ADDRESS PATH"

# Raw ALU address
add wave -hex sim:/testbench/dut/IEUAdrRaw

# Wrapped address (before alignment)
add wave -hex sim:/testbench/dut/DAdrWrapped

# Final address sent to RAM
add wave -hex sim:/testbench/dut/IEUAdr

add wave -divider "MEM CONTROL"

add wave -bin sim:/testbench/dut/MemEn
add wave -hex sim:/testbench/dut/WriteByteEn
add wave -hex sim:/testbench/dut/ieu/LoadType
add wave -hex sim:/testbench/dut/ieu/StoreType

add wave -divider "LSU"

add wave -hex sim:/testbench/dut/ieu/lsu/Adr
add wave -hex sim:/testbench/dut/ieu/lsu/WriteByteEnOut
add wave -hex sim:/testbench/dut/ieu/lsu/StoreDataOut
add wave -hex sim:/testbench/dut/ieu/lsu/LoadDataOut

add wave -divider "DATA MEMORY"

add wave -bin sim:/testbench/DataMemory/En
add wave -bin sim:/testbench/DataMemory/WriteEn
add wave -hex sim:/testbench/DataMemory/WriteByteEn
add wave -hex sim:/testbench/DataMemory/MemoryAddress
add wave -hex sim:/testbench/DataMemory/WriteData
add wave -hex sim:/testbench/DataMemory/ReadData

run -all
view wave
