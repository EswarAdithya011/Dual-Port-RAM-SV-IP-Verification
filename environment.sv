class environment;
  generator     gen;
  read_driver   rd_driv;
  read_monitor  rd_mon;
  write_driver  wr_driv;
  write_monitor wr_mon;
  scoreboard    scb;
  coverage      cov;      // NEW: coverage collector wired into environment
  
  mailbox #(transaction) gen2rddriv;
  mailbox #(transaction) gen2wrdriv;
  mailbox #(transaction) rdmon2scb;
  mailbox #(transaction) wrmon2scb;  
  
  function new(virtual intf vif);
    gen2rddriv = new();
    gen2wrdriv = new();
    rdmon2scb  = new();
    wrmon2scb  = new();
    
    gen     = new(gen2rddriv, gen2wrdriv);
    rd_driv = new(vif.mp_read_driver,   gen2rddriv);
    rd_mon  = new(vif.mp_read_monitor,  rdmon2scb);
    wr_driv = new(vif.mp_write_driver,  gen2wrdriv);
    wr_mon  = new(vif.mp_write_monitor, wrmon2scb);
    scb     = new(rdmon2scb, wrmon2scb);
    cov     = new(vif);    // coverage gets the virtual interface
  endfunction
  
  task pre_test();
    rd_driv.reset();
    wr_driv.reset();
  endtask
  
  // Generator task extended to also sample coverage on every transaction
  task run_gen_with_coverage();
    repeat (gen.gen_count) begin
      transaction rd_tr, wr_tr;
      gen.tr = new();
      assert(gen.tr.randomize())
        else $fatal(1, "Gen:: Randomization Failed!!");
      
      rd_tr = new gen.tr;
      wr_tr = new gen.tr;
      
      // Sample coverage on every generated transaction
      cov.sample(gen.tr);
      
      gen.gen2rddriv.put(rd_tr);
      gen.gen2wrdriv.put(wr_tr);
    end
    -> gen.gen_ended;
  endtask
  
  task test();
    fork
      run_gen_with_coverage();   // replaces gen.main() — adds coverage
      wr_driv.main();
      wr_mon.main();
      rd_driv.main();
      rd_mon.main();
      scb.main();
    join_none
  endtask
  
  task post_test();
    wait(gen.gen_ended.triggered);
    wait(wr_driv.wr_driv_count == gen.gen_count);
    wait(rd_driv.rd_driv_count == gen.gen_count);
    #200;
    scb.report();
    cov.report();    // NEW: print coverage after scoreboard
  endtask
  
  task run();
    pre_test();
    test();
    post_test();
    $finish;
  endtask

endclass