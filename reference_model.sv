class reference_model;

  // Shadow memory — bit initialises to 0, matching DUT reset behaviour
  bit [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];
  
  // NEW: Track which addresses have been written at least once.
  // Without this, reading an unwritten address compares 0==0 (meaningless).
  bit addr_written [2**ADDR_WIDTH];

  function void write(bit [ADDR_WIDTH-1:0] addr, bit [DATA_WIDTH-1:0] data);
    mem[addr]          = data;
    addr_written[addr] = 1'b1;   // mark address as initialised
  endfunction

  function bit [DATA_WIDTH-1:0] read(bit [ADDR_WIDTH-1:0] addr);
    return mem[addr];
  endfunction

  // Scoreboard calls this before comparing so it can skip unwritten addresses
  function bit was_written(bit [ADDR_WIDTH-1:0] addr);
    return addr_written[addr];
  endfunction

endclass