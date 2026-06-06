class read_driver;
  virtual intf.mp_read_driver vif;
  
  mailbox #(transaction) gen2rddriv;
  
  int         rd_driv_count;
  transaction tr;
  
  function new(virtual intf.mp_read_driver vif,
               mailbox #(transaction) gen2rddriv);
    this.vif        = vif;
    this.gen2rddriv = gen2rddriv;
  endfunction
  
  task reset();
    if (vif.rst) begin
      $display("[Read Driver Reset: Started]");
      vif.cb_read_driver.read_en   <= 1'b0;
      vif.cb_read_driver.read_addr <= '0;
      $display("[Read Driver Reset: Done]");
    end
  endtask
  
  // BUG FIX: Same issue as write_driver — extra idle cycles before/after
  // driving caused the read monitor to sample wrong cycles.
  //
  // New pattern:
  //   1. get transaction
  //   2. wait 1 edge — drive read_en + read_addr (DUT latches them)
  //   3. wait 1 edge — DUT produces read_data; monitor will sample it here
  //   4. de-assert read_en for clean idle
  //
  // The read monitor aligns to the same edges, so the timing matches exactly.
  task main();
    forever begin
      gen2rddriv.get(tr);
      
      // Cycle N: drive the request
      @(vif.cb_read_driver);
      vif.cb_read_driver.read_en   <= tr.read_en;
      vif.cb_read_driver.read_addr <= tr.read_addr;
      
      tr.read_display("[Read Driver -> DUT]");
      rd_driv_count++;
      
      // Cycle N+1: de-assert; DUT is producing read_data this cycle
      @(vif.cb_read_driver);
      vif.cb_read_driver.read_en <= 1'b0;
    end
  endtask

endclass
