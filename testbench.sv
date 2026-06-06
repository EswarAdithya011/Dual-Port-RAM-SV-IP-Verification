`include "header.svh"

module tb;
  logic clk = 0;
  logic rst;
  
  intf intf(.clk(clk), .rst(rst));
  
  dual_port_ram DUT(.intf(intf));
  
  test t1(.intf(intf));
  
  always #5 clk = ~clk;
  
  initial begin
    rst = 1;
    #20;
    rst = 0;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
  end

endmodule