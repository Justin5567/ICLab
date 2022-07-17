`timescale 1ns/1ps

`include "Usertype_PKG.sv"
`include "INF.sv"
`include "PATTERN.sv"
`include "PATTERN_bridge.sv"
`include "PATTERN_pokemon.sv"
`include "../00_TESTBED/pseudo_DRAM.sv"
`include "CHECKER.sv"

`ifdef RTL
  `include "bridge.sv"
  `include "pokemon.sv"
`endif

module TESTBED;
  
parameter simulation_cycle = 15.0;
  reg  SystemClock;

  INF             inf();
  PATTERN         test_p(.clk(SystemClock), .inf(inf.PATTERN));
  PATTERN_bridge  test_pb(.clk(SystemClock), .inf(inf.PATTERN_bridge));
  PATTERN_pokemon test_pp(.clk(SystemClock), .inf(inf.PATTERN_pokemon));
  pseudo_DRAM     dram_r(.clk(SystemClock), .inf(inf.DRAM)); 
  Checker 		  check_inst (.clk(SystemClock), .inf(inf.CHECKER));

  `ifdef RTL
	bridge  dut_b(.clk(SystemClock), .inf(inf.bridge_inf) );
	pokemon dut_p(.clk(SystemClock), .inf(inf.pokemon_inf) );
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
  `endif
end

endmodule