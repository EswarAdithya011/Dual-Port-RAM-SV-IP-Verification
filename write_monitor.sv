class write_monitor;
  virtual intf.mp_write_monitor vif;
  
  mailbox #(transaction) wrmon2scb;
  
  int         wr_mon_count;
  transaction tr;
  
  function new(virtual intf.mp_write_monitor vif,
               mailbox #(transaction) wrmon2scb);
    this.vif      = vif;
    this.wrmon2scb = wrmon2scb;
  endfunction
  
  // BUG FIX (Critical): The original monitor sampled on EVERY clock edge
  // unconditionally.  This caused it to endlessly re-capture the idle bus
  // (write_en=0, stale addr/data) producing the repeated garbage in the log:
  //   "write_en=0, write_addr=3, write_data=ac" repeating forever.
  //
  // Fix: after aligning to a clock edge, WAIT until write_en is actually
  // asserted (active-high) before sampling addr/data and forwarding to the
  // scoreboard.  This ensures exactly 1 scoreboard transaction per real write.
  //
  // Also added: wait(!vif.rst) so monitor ignores reset period correctly.
  task main();
    forever begin
      tr = new();
      
      @(vif.cb_write_monitor);   // align to rising edge
      wait (!vif.rst);           // ignore reset period
      
      // KEY FIX: only proceed when write is actually enabled
      if (!vif.cb_write_monitor.write_en) continue;
      
      tr.write_en   = vif.cb_write_monitor.write_en;
      tr.write_addr = vif.cb_write_monitor.write_addr;
      tr.write_data = vif.cb_write_monitor.write_data;
      
      wrmon2scb.put(tr);
      wr_mon_count++;
      tr.write_display("[Write Monitor -> ScoreBoard]");
    end
  endtask

endclass
