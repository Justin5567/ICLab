`timescale 1ns/100ps

`include "Usertype_PKG.sv"
`include "INF.sv"
`include "PATTERN_pokemon.sv"

`ifdef RTL
  `include "pokemon.sv"
`endif

module TESTBED;
  
  parameter simulation_cycle = 15.0;
  reg  SystemClock;

  INF  inf();
  PATTERN_pokemon test_p(.clk(SystemClock), .inf(inf.PATTERN_pokemon));
  
  `ifdef RTL
	pokemon dut(.clk(SystemClock), .inf(inf.pokemon_inf) );
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
  
//------ Dump VCD File ------------  
initial begin
  `ifdef RTL
    $fsdbDumpfile("pokemon.fsdb");
    $fsdbDumpvars(0,"+all");
    $fsdbDumpSVA;
  `endif
end

endmodule