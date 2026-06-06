class write_driver;
  virtual intf.mp_write_driver vif;
  
  mailbox #(transaction) gen2wrdriv;
  
  int         wr_driv_count;
  transaction tr;
  
  function new(virtual intf.mp_write_driver vif,
               mailbox #(transaction) gen2wrdriv);
    this.vif        = vif;
    this.gen2wrdriv = gen2wrdriv;
  endfunction
  
  task reset();
    if (vif.rst) begin
      $display("[Write Driver Reset: Started]");
      vif.cb_write_driver.write_en   <= 1'b0;
      vif.cb_write_driver.write_addr <= '0;
      vif.cb_write_driver.write_data <= '0;
      $display("[Write Driver Reset: Done]");
    end
  endtask
  
  task main();
    forever begin
      gen2wrdriv.get(tr);
      
      @(vif.cb_write_driver);
      vif.cb_write_driver.write_en   <= tr.write_en;
      vif.cb_write_driver.write_addr <= tr.write_addr;
      vif.cb_write_driver.write_data <= tr.write_data;
      
      // FIX: Only print write transactions where write_en=1.
      // write_addr and write_data are always randomised by the generator,
      // but they have NO effect on the DUT when write_en=0 — printing them
      // creates confusion. We only log real writes.
      if (tr.write_en)
        tr.write_display("[Write Driver -> DUT (write_en=1 - ACTUAL WRITE)]");
      // write_en=0: silently skip, nothing is written to DUT memory
      
      wr_driv_count++;
      
      @(vif.cb_write_driver);
      vif.cb_write_driver.write_en <= 1'b0;
    end
  endtask

endclass