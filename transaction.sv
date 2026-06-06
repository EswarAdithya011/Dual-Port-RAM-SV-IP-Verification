import params_pkg::*;

class transaction;
  rand bit        write_en;
  randc bit [ADDR_WIDTH-1:0] write_addr;
  rand bit [DATA_WIDTH-1:0] write_data;
  rand bit        read_en;
  rand bit [ADDR_WIDTH-1:0] read_addr;
  // read_data is an output from the DUT - not randomized
  logic [DATA_WIDTH-1:0] read_data;
  
  // At least one port must be active each transaction
  constraint c_valid_op {
    write_en || read_en;
  }
  
  // Bias: more writes than reads to build up data in RAM
  constraint c_en_dist {
    soft write_en dist {1 := 70, 0 := 30};
    soft read_en  dist {1 := 70, 0 := 30};
  }
  
  // No simultaneous READ & WRITE to the same address (RAW hazard)
  constraint c_same_addr_hazard {
    (write_en && read_en) -> (read_addr != write_addr);
  }
  
  // FIX: Bias write_data toward corner values so coverage bins for
  // 0x00 and 0xFF are hit within 100 transactions.
  // Without this, P(0x00) = 1/256 and P(0xFF) = 1/256 per transaction
  // — almost never hit in a 100-transaction run.
  constraint c_data_corners {
    soft write_data dist {
      8'h00        := 20,   // zero - corner case
      8'hFF        := 20,   // all-ones - corner case  
      [8'h01:8'hFE]:= 60    // everything else
    };
  }
  
  function void write_display(string s);
    $display("-------------%s------------", s);
    $display("write_en = %0b, write_addr = %0d, write_data = %0h",
              write_en, write_addr, write_data);
    $display("-------------------------");
  endfunction
  
  function void read_display(string s);
    $display("-------------%s------------", s);
    $display("read_en = %0b, read_addr = %0d, read_data = %0h",
              read_en, read_addr, read_data);
    $display("-------------------------");
  endfunction

endclass