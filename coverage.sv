class coverage;
  virtual intf vif;
  transaction tr;

  covergroup cg_ram_ops;
    // Was a write issued?
    cp_write_en: coverpoint tr.write_en {
      bins write_active = {1};
      bins write_idle   = {0};
    }
    // Was a read issued?
    cp_read_en: coverpoint tr.read_en {
      bins read_active = {1};
      bins read_idle   = {0};
    }
    // All four combinations: W+R, W only, R only, neither (guarded by constraint)
    cp_rw_combo: cross cp_write_en, cp_read_en;

    // Write address space — four quarters
    cp_write_addr: coverpoint tr.write_addr {
      bins low     = {[0   : 63 ]};
      bins mid     = {[64  : 127]};
      bins midhigh = {[128 : 191]};
      bins high    = {[192 : 255]};
    }
    // Read address space — four quarters
    cp_read_addr: coverpoint tr.read_addr {
      bins low     = {[0   : 63 ]};
      bins mid     = {[64  : 127]};
      bins midhigh = {[128 : 191]};
      bins high    = {[192 : 255]};
    }
    // Write data corner cases
    cp_write_data: coverpoint tr.write_data {
      bins zero    = {8'h00};
      bins all_one = {8'hFF};
      bins others  = default;
    }
    
    // NEW: Cross write_addr region x write_data corners — ensures all memory
    // regions are exercised with corner-case data values
    cp_addr_data_cross: cross cp_write_addr, cp_write_data;
  endgroup

  function new(virtual intf vif);
    this.vif = vif;
    cg_ram_ops = new();
  endfunction

  // Called by environment after every generated transaction
  function void sample(transaction t);
    this.tr = t;
    cg_ram_ops.sample();
  endfunction

  function void report();
    $display("========================================");
    $display("          COVERAGE REPORT               ");
    $display("  cg_ram_ops coverage = %0.2f %%", cg_ram_ops.get_coverage());
    $display("========================================");
  endfunction

endclass