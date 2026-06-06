class read_monitor;
  virtual intf.mp_read_monitor vif;
  
  mailbox #(transaction) rdmon2scb;
  
  int         rd_mon_count;
  transaction tr;
  
  function new(virtual intf.mp_read_monitor vif,
               mailbox #(transaction) rdmon2scb);
    this.vif      = vif;
    this.rdmon2scb = rdmon2scb;
  endfunction
  
  // Correct read-monitor timing for a registered (clocked) RAM:
  //
  //   Cycle N  : read_en=1, read_addr=X driven by driver
  //   Cycle N+1: DUT presents read_data for address X
  //
  // BUG FIX: The old monitor captured read_en/read_addr on edge N, then
  // read_data on edge N+1 — but it used a FRESH transaction object for
  // every edge, so the read_en/read_addr sampled on edge N was in a
  // DIFFERENT 'tr' than the read_data sampled on edge N+1.  This meant
  // the scoreboard was always comparing data against the wrong address.
  //
  // Fix: use ONE transaction object.  On edge N, only capture if read_en=1.
  // On edge N+1, capture read_data for that same object and forward to SCB.
  // This perfectly pairs each address with its corresponding output data.
  task main();
    forever begin
      // --- Cycle N: look for an active read request ---
      @(vif.cb_read_monitor);
      wait (!vif.rst);
      
      if (!vif.cb_read_monitor.read_en) continue;  // skip idle cycles
      
      tr = new();
      tr.read_en   = vif.cb_read_monitor.read_en;
      tr.read_addr = vif.cb_read_monitor.read_addr;
      
      // --- Cycle N+1: read_data is now valid on the DUT output ---
      @(vif.cb_read_monitor);
      tr.read_data = vif.cb_read_monitor.read_data;
      
      rdmon2scb.put(tr);
      rd_mon_count++;
      tr.read_display("[Read Monitor -> ScoreBoard]");
    end
  endtask

endclass
