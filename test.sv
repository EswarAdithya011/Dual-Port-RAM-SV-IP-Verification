program test (intf intf);
  environment env;
  
  initial begin
    env = new(intf);
    env.gen.gen_count = 200;
    env.run();
  end

endprogram
