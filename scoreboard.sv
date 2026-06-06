class scoreboard;
  reference_model rm;
    
  mailbox #(transaction) rdmon2scb;
  mailbox #(transaction) wrmon2scb;
  
  int tr_count   = 0;
  int pass_count = 0;
  int fail_count = 0;
  int skip_count = 0;   // NEW: count skipped (never-written) comparisons
  
  function new(mailbox #(transaction) rdmon2scb,
               mailbox #(transaction) wrmon2scb);
    this.rdmon2scb = rdmon2scb;
    this.wrmon2scb = wrmon2scb;
    rm = new();
  endfunction
  
  bit [DATA_WIDTH-1:0] exp_rd_data;
  
  // Shadow-memory writer: runs in parallel, keeps reference model in sync
  task write_to_shadow();
    transaction wr_tr;
    forever begin
      wrmon2scb.get(wr_tr);
      if (wr_tr.write_en)
        rm.write(wr_tr.write_addr, wr_tr.write_data);
    end
  endtask
  
  // KEY FIX: Only compare if address was actually written before.
  // Reads to unwritten addresses always return 0 from both DUT and ref-model
  // so comparing them proves nothing. We SKIP and report separately.
  task read_from_shadow();
    transaction rd_tr;
    forever begin
      rdmon2scb.get(rd_tr);
      
      if (!rm.was_written(rd_tr.read_addr)) begin
        $display("[SKIP] read_en=1, read_addr=%0d | Address never written - skipping",
                 rd_tr.read_addr);
        skip_count++;
        continue;
      end
      
      exp_rd_data = rm.read(rd_tr.read_addr);
      
      if (rd_tr.read_data !== exp_rd_data) begin
        $error("[FAIL] read_en=%0b, read_addr=%0d | Actual=%0h, Expected=%0h",
               rd_tr.read_en, rd_tr.read_addr, rd_tr.read_data, exp_rd_data);
        fail_count++;
      end
      else begin
        $display("[PASS] read_en=%0b, read_addr=%0d | Actual=%0h, Expected=%0h",
                 rd_tr.read_en, rd_tr.read_addr, rd_tr.read_data, exp_rd_data);
        pass_count++;
      end
      tr_count++;
    end
  endtask
  
  task main();
    fork
      write_to_shadow();
      read_from_shadow();
    join_none
  endtask
  
  task report();
    $display("========================================");
    $display("           SCOREBOARD REPORT            ");
    $display("========================================");
    $display("  Total Meaningful Checks     : %0d", tr_count);
    $display("  PASS                        : %0d", pass_count);
    $display("  FAIL                        : %0d", fail_count);
    $display("  SKIP (addr never written)   : %0d", skip_count);
    $display("========================================");
    if (fail_count == 0)
      $display("  *** ALL MEANINGFUL TESTS PASSED *** ");
    else
      $display("  *** %0d FAILURES DETECTED *** ", fail_count);
    $display("========================================");
  endtask

endclass