import params_pkg::*;

interface intf (input logic clk, rst);
  logic write_en;
  logic [ADDR_WIDTH-1:0] write_addr;
  logic [DATA_WIDTH-1:0] write_data;

  logic read_en;
  logic [ADDR_WIDTH-1:0] read_addr;
  logic [DATA_WIDTH-1:0] read_data;
  
  clocking cb_read_driver @(posedge clk);
    default input #1step output #0;
    output read_en, read_addr;
    input  read_data;
  endclocking
  
  clocking cb_read_monitor @(posedge clk);
    default input #1step output #1;
    input read_en, read_addr, read_data;
  endclocking
  
  clocking cb_write_driver @(posedge clk);
    default input #1step output #0;
    output write_en, write_addr, write_data;
  endclocking
  
  clocking cb_write_monitor @(posedge clk);
    default input #1step output #1;
    input write_en, write_addr, write_data;
  endclocking
  
  modport mp_read_driver  (clocking cb_read_driver,  input rst);
  modport mp_read_monitor (clocking cb_read_monitor, input rst);
  modport mp_write_driver (clocking cb_write_driver, input rst);
  modport mp_write_monitor(clocking cb_write_monitor,input rst);
  
  modport mp_dut (input clk, rst, write_en, write_addr, write_data, read_en, read_addr, 
                  output read_data);
  
endinterface
