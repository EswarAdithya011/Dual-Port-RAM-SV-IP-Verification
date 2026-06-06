`include "params.sv"
import params_pkg::*;

module dual_port_ram (intf.mp_dut intf);

  logic [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

  // Write port — synchronous, edge-triggered
  always_ff @(posedge intf.clk, posedge intf.rst) begin
    if (intf.rst) begin
      for (int i = 0; i < (2**ADDR_WIDTH); i++)
        mem[i] <= '0;
    end
    else if (intf.write_en) begin
      mem[intf.write_addr] <= intf.write_data;
    end
  end

  // Read port — synchronous, registered output (1-cycle latency)
  always_ff @(posedge intf.clk, posedge intf.rst) begin
    if (intf.rst)
      intf.read_data <= '0;
    else if (intf.read_en)
      intf.read_data <= mem[intf.read_addr];
  end

endmodule
