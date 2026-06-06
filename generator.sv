class generator;
  rand transaction tr;
  
  mailbox #(transaction) gen2rddriv;
  mailbox #(transaction) gen2wrdriv;
  
  event gen_ended;
  int   gen_count;
  
  function new(mailbox #(transaction) gen2rddriv,
               mailbox #(transaction) gen2wrdriv);
    this.gen2rddriv = gen2rddriv;
    this.gen2wrdriv = gen2wrdriv;
  endfunction
  
  task main();
    repeat (gen_count) begin
      transaction rd_tr, wr_tr;
      
      tr = new();
      assert(tr.randomize())
        else $fatal(1, "Gen:: Randomization Failed!!");
      
      // Shallow copy — each driver gets its own handle so they can't stomp each other
      rd_tr = new tr;
      wr_tr = new tr;
      
      gen2rddriv.put(rd_tr);
      gen2wrdriv.put(wr_tr);
    end
    -> gen_ended;
  endtask

endclass
