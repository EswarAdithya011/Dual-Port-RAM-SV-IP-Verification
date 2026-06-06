// Assertions module — bound to the DUT via bind in testbench
// Checks fundamental protocol rules on the RAM interface.
module ram_assertions (
  input logic clk,
  input logic rst,
  input logic write_en,
  input logic [7:0] write_addr,
  input logic [7:0] write_data,
  input logic read_en,
  input logic [7:0] read_addr,
  input logic [7:0] read_data
);

  // -----------------------------------------------------------------------
  // 1. RESET: read_data must be 0 one cycle after rst goes high
  // -----------------------------------------------------------------------
  property p_reset_clears_read_data;
    @(posedge clk) rst |=> (read_data === 8'h00);
  endproperty
  a_reset_clears_read_data: assert property (p_reset_clears_read_data)
    else $error("[ASSERT FAIL] read_data not cleared after reset");

  // -----------------------------------------------------------------------
  // 2. WRITE-THEN-READ: data written at cycle N to address A must appear
  //    when address A is read at cycle N+1 (DUT has 1-cycle read latency).
  //    The sequence: write_en asserted → next cycle: read_en to same addr
  //    → that same cycle: read_data equals what was written.
  // -----------------------------------------------------------------------
  property p_write_then_read;
    logic [7:0] waddr, wdata;
    @(posedge clk) disable iff (rst)
    (write_en, waddr = write_addr, wdata = write_data) ##1
    (read_en && (read_addr === waddr)) |-> ##1 (read_data === wdata);
  endproperty
  a_write_then_read: assert property (p_write_then_read)
    else $error("[ASSERT FAIL] Read-after-write data mismatch");

  // -----------------------------------------------------------------------
  // 3. READ DATA STABLE: when read_en is LOW, read_data must not change
  //    (DUT is registered — output holds its last value).
  // -----------------------------------------------------------------------
  property p_read_data_stable_when_idle;
    @(posedge clk) disable iff (rst)
    (!read_en) |=> $stable(read_data);
  endproperty
  a_read_data_stable: assert property (p_read_data_stable_when_idle)
    else $error("[ASSERT FAIL] read_data changed while read_en was low");

  // -----------------------------------------------------------------------
  // 4. NO X/Z ON CONTROL SIGNALS: write_en and read_en must never be X/Z
  // -----------------------------------------------------------------------
  property p_no_x_write_en;
    @(posedge clk) disable iff (rst)
    !$isunknown(write_en);
  endproperty
  a_no_x_write_en: assert property (p_no_x_write_en)
    else $error("[ASSERT FAIL] write_en is X or Z");

  property p_no_x_read_en;
    @(posedge clk) disable iff (rst)
    !$isunknown(read_en);
  endproperty
  a_no_x_read_en: assert property (p_no_x_read_en)
    else $error("[ASSERT FAIL] read_en is X or Z");

endmodule

// Bind attaches assertions to the DUT without touching DUT source code
bind dual_port_ram ram_assertions u_assertions (
  .clk        (intf.clk),
  .rst        (intf.rst),
  .write_en   (intf.write_en),
  .write_addr (intf.write_addr),
  .write_data (intf.write_data),
  .read_en    (intf.read_en),
  .read_addr  (intf.read_addr),
  .read_data  (intf.read_data)
);