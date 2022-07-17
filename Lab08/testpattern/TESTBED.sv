`timescale 1ns/1ps

`include "Usertype_PKG.sv"
`include "INF.sv"
`include "PATTERN.sv"
`include "PATTERN_bridge.sv"
`include "PATTERN_pokemon.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"

`ifdef RTL
  `include "bridge.sv"
  `include "pokemon.sv"
  `define CYCLE_TIME 4.0
`endif

`ifdef GATE
  `include "bridge_SYN.v"
  `include "bridge_Wrapper.sv"
  `include "pokemon_SYN.v"
  `include "pokemon_Wrapper.sv"
  `define CYCLE_TIME 4.0
`endif

module TESTBED;
  
parameter simulation_cycle = `CYCLE_TIME;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  PATTERN_bridge  test_pb(.clk(SystemClock), .inf(inf.PATTERN_bridge));
  PATTERN_pokemon test_pp(.clk(SystemClock), .inf(inf.PATTERN_pokemon));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 

  `ifdef RTL
	bridge  dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	pokemon dut_p(.clk(SystemClock), .inf(inf.pokemon_inf) );
  `endif
  
  `ifdef GATE
	bridge_svsim  dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	pokemon_svsim dut_p(.clk(SystemClock), .inf(inf.pokemon_inf) );
  `endif  
 //------ Generate Clock ------------
  initial begin
    SystemClock = 0;
	#30
    forever begin
      #(simulation_cycle/2.0)
        SystemClock = ~SystemClock;
    end
  end
  
//------ Dump FSDB File ------------  
initial begin
  `ifdef RTL
    $fsdbDumpfile("PSG.fsdb");
    $fsdbDumpvars(0,"+all");
    $fsdbDumpSVA;
  `elsif GATE
    $fsdbDumpfile("PSG_SYN.fsdb");
    $sdf_annotate("bridge_SYN.sdf",dut_b.bridge);      
    $sdf_annotate("pokemon_SYN.sdf",dut_p.pokemon);      
    $fsdbDumpvars(0,"+all");
  `endif
end

endmodule