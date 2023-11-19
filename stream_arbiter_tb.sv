module stream_arbiter_tb #(
  parameter T_DATA_WIDTH = 8,
            T_QOS__WIDTH = 4,
            STREAM_COUNT = 2,
            T_ID___WIDTH = $clog2(STREAM_COUNT)
);

  //input, output 
  logic                     clk;
  logic                     rst_n;
  logic [T_DATA_WIDTH-1:0]  s_data_i  [STREAM_COUNT-1:0];
  logic [T_QOS__WIDTH-1:0]  s_qos_i   [STREAM_COUNT-1:0];
  logic [STREAM_COUNT-1:0]  s_last_i;
  logic [STREAM_COUNT-1:0]  s_valid_i;
  logic [STREAM_COUNT-1:0]  s_ready_o;
  // output stream
  logic [T_DATA_WIDTH-1:0]  m_data_o;
  logic [T_QOS__WIDTH-1:0]  m_qos_o;
  logic [T_ID___WIDTH-1:0]  m_id_o;
  logic                     m_last_o;
  logic                     m_valid_o;
  logic                     m_ready_i;
  
  //instant
  stream_arbiter  i_stream_arbiter  (.*);
  
  //dump
  initial begin
    $dumpvars;
  end
  
  //clk and reset
  initial begin
    clk   = 0;
    forever #10 clk = ~clk;
  end
  
  //test
  initial begin
    rst_n = 1;
    #20;
    rst_n = 0;
    #20;
    rst_n = 1;
    s_data_i[0] = '0;
    s_data_i[1] = '0;
    s_qos_i[0]  = '0;
    s_qos_i[1]  = '0;
    s_last_i    = '0;
    s_valid_i   = '0;
    m_ready_i   = 1;
    #10;
    
    //task one_stream x6
    for(int i = 0; i < 6; i++)
    begin
      one_stream;
    end
    
    //task diff_qos_stream
    diff_qos_stream;
    
    //task eq_prior_stream
    eq_prior_stream;
    $finish;
  end
  
  //task single stream to the arbiter
  task one_stream;
  
  logic       str;
  logic [2:0] num_pack;
  
  str       = $urandom_range(1, 0);
  num_pack  = $urandom_range(7, 2);
  
  for (int i = 0; i <= num_pack; i++)
  begin
    if      (i == 0)
    @(posedge clk)
    begin
      s_valid_i[str]  = 1;
      s_qos_i[str]    = $urandom_range(15, 0);
      s_data_i[str]   = $urandom_range(255, 0);
    end
    else if (i != num_pack)
    @(posedge clk)
    begin
      s_data_i[str]   = $urandom_range(255, 0);
    end
    else
    @(posedge clk)
    begin
      s_data_i[str]   = $urandom_range(255, 0);
      s_last_i[str]   = 1;
    end
  end
  
  @(posedge clk)
  begin
    s_valid_i   = '0;
    s_last_i    = '0;
    s_data_i[0] = '0;
    s_data_i[1] = '0;
    s_qos_i[0]  = '0;
    s_qos_i[1]  = '0;
  end
  
  #100;
  endtask
  
  //task both flows to the arbiter
  //task with different qos
  task diff_qos_stream;
  
  for(int m = 0; m < 4; m++)
  begin
    //first stream
    for (int i = 0; i < 4; i++)
    begin
      if      (i == 0)
      @(posedge clk)
      begin
        s_valid_i[0]  = 1;
        s_data_i[0]   = $urandom_range(255, 0);
        
        s_valid_i[1]  = 1;
        s_data_i[1]   = $urandom_range(255, 0);
        
        case(m)
          0:  //qos 1st > qos 2d (next qos 1st < pre qos 2d)
          begin
            s_qos_i[0]  = 15;
            s_qos_i[1]  = 13;
          end
          
          1:  //qos 1st > qos 2d (next qos 1st > pre qos 2d)
          begin
            s_qos_i[0]  = 15;
            s_qos_i[1]  = 13;
          end
          
          2:  //qos 1st < qos 2d (next qos 2d < pre qos 1st)
          begin
            s_qos_i[0]  = 13;
            s_qos_i[1]  = 15;
          end
          
          3:  //qos 1st < qos 2d (next qos 2d > pre qos 1st)
          begin
            s_qos_i[0]  = 13;
            s_qos_i[1]  = 15;
          end
        endcase
      end
      else if (i != 3)
      @(posedge clk)
      begin
        case(m)
          0:
          begin
            s_data_i[0] = $urandom_range(255, 0);
          end
          
          1:
          begin
            s_data_i[0] = $urandom_range(255, 0);
          end
          
          2:
          begin
            s_data_i[1] = $urandom_range(255, 0);
          end
          
          3:
          begin
            s_data_i[1] = $urandom_range(255, 0);
          end
        endcase
      end
      else if (i == 3)
      @(posedge clk)
      begin
        case(m)
          0:
          begin
            s_data_i[0] = $urandom_range(255, 0);
            s_last_i[0] = 1;
          end
          
          1:
          begin
            s_data_i[0] = $urandom_range(255, 0);
            s_last_i[0] = 1;
          end
          
          2:
          begin
            s_data_i[1] = $urandom_range(255, 0);
            s_last_i[1] = 1;
          end
          
          3:
          begin
            s_data_i[1] = $urandom_range(255, 0);
            s_last_i[1] = 1;
          end
        endcase
      end
    end
    //second stream
    for (int j = 0; j < 4; j++)
    begin
      if      (j == 0)
      @(posedge clk)
      begin
        case(m)
          0:  //qos 1st > qos 2d (next qos 1st < pre qos 2d)
          begin
            s_data_i[0]   = $urandom_range(255, 0);
            s_valid_i[0]  = 1;
            s_qos_i[0]    = 10;
            s_last_i[0]   = 0;
          end
          
          1:  //qos 1st > qos 2d (next qos 1st > pre qos 2d)
          begin
            s_data_i[0]   = $urandom_range(255, 0);
            s_valid_i[0]  = 1;
            s_qos_i[0]    = 14;
            s_last_i[0]   = 0;
          end
          
          2:  //qos 1st < qos 2d (next qos 2d < pre qos 1st)
          begin
            s_data_i[1]   = $urandom_range(255, 0);
            s_valid_i[1]  = 1;
            s_qos_i[1]    = 10;
            s_last_i[1]   = 0;
          end
          
          3:  //qos 1st < qos 2d (next qos 2d < pre qos 1st)
          begin
            s_data_i[1]   = $urandom_range(255, 0);
            s_valid_i[1]  = 1;
            s_qos_i[1]    = 14;
            s_last_i[1]   = 0;
          end
        endcase
      end
      else if (j != 3)
      @(posedge clk)
      begin
        case(m)
          0:
          begin
            s_data_i[1] = $urandom_range(255, 0);
          end
          
          1:
          begin
            s_data_i[0] = $urandom_range(255, 0);
          end
          
          2:
          begin
            s_data_i[0] = $urandom_range(255, 0);
          end
          
          3:
          begin
            s_data_i[1] = $urandom_range(255, 0);
          end
        endcase
      end
      else if (j == 3)
      @(posedge clk)
      begin
        case(m)
          0:
          begin
            s_data_i[1] = $urandom_range(255, 0);
            s_last_i[1] = 1;
          end
          
          1:
          begin
            s_data_i[0] = $urandom_range(255, 0);
            s_last_i[0] = 1;
          end
          
          2:
          begin
            s_data_i[0] = $urandom_range(255, 0);
            s_last_i[0] = 1;
          end
          
          3:
          begin
            s_data_i[1] = $urandom_range(255, 0);
            s_last_i[1] = 1;
          end
        endcase
      end
    end
    //third stream
    for (int k = 0; k < 4; k++)
    begin
      if      (k == 0)
      @(posedge clk)
      begin
        case(m)
          0:  //qos 1st > qos 2d (next qos 1st < pre qos 2d)
          begin
            s_data_i[1]   = 0;
            s_valid_i[1]  = 0;
            s_qos_i[1]    = 0;
            s_last_i[1]   = 0;
          end
          
          1:  //qos 1st > qos 2d (next qos 1st > pre qos 2d)
          begin
            s_data_i[0]   = 0;
            s_valid_i[0]  = 0;
            s_qos_i[0]    = 0;
            s_last_i[0]   = 0;
          end
          
          2:  //qos 1st < qos 2d (next qos 2d < pre qos 1st)
          begin
            s_data_i[0]   = 0;
            s_valid_i[0]  = 0;
            s_qos_i[0]    = 0;
            s_last_i[0]   = 0;
          end
          
          3:  //qos 1st < qos 2d (next qos 2d > pre qos 1st)
          begin
            s_data_i[1]   = 0;
            s_valid_i[1]  = 0;
            s_qos_i[1]    = 0;
            s_last_i[1]   = 0;
          end
        endcase
      end
      else if (k != 3)
      @(posedge clk)
      begin
        case(m)
          0:
          begin
            s_data_i[0] = $urandom_range(255, 0);
          end
          
          1:
          begin
            s_data_i[1] = $urandom_range(255, 0);
          end
          
          2:
          begin
            s_data_i[1] = $urandom_range(255, 0);
          end
          
          3:
          begin
            s_data_i[0] = $urandom_range(255, 0);
          end
        endcase
      end
      else if (k == 3)
      @(posedge clk)
      begin
        case(m)
          0:
          begin
            s_data_i[0] = $urandom_range(255, 0);
            s_last_i[0] = 1;
          end
          
          1:
          begin
            s_data_i[1] = $urandom_range(255, 0);
            s_last_i[1] = 1;
          end
          
          2:
          begin
            s_data_i[1] = $urandom_range(255, 0);
            s_last_i[1] = 1;
          end
          
          3:
          begin
            s_data_i[0] = $urandom_range(255, 0);
            s_last_i[0] = 1;
          end
        endcase
      end
    end
    
  @(posedge clk)
  begin
    s_valid_i   = '0;
    s_last_i    = '0;
    s_data_i[0] = '0;
    s_data_i[1] = '0;
    s_qos_i[0]  = '0;
    s_qos_i[1]  = '0;
  end
    
  #100;
  end
  
  #500;
  endtask
  
  //task with the round-robin principle
  task eq_prior_stream;
  
  for(int m = 0; m < 4; m++)
  begin
    //first stream
    for (int i = 0; i < 4; i++)
    begin
      if      (i == 0)
      @(posedge clk)
      begin
        s_valid_i[0]  = 1;
        s_data_i[0]   = $urandom_range(255, 0);
        
        s_valid_i[1]  = 1;
        s_data_i[1]   = $urandom_range(255, 0);
        
        case(m)
          0:  //qos 1st is equal qos 2d
          begin
            s_qos_i[0]  = 14;
            s_qos_i[1]  = 14;
          end
          
          1:  //qos 1st is zero, qos 2d isn't zero
          begin
            s_qos_i[0]  = 0;
            s_qos_i[1]  = 14;
          end
          
          2:  //qos 1st isn't zero, qos 2d is zero
          begin
            s_qos_i[0]  = 14;
            s_qos_i[1]  = 0;
          end
          
          3:  //qos 1st is zero and qos 2d is zero
          begin
            s_qos_i[0]  = 0;
            s_qos_i[1]  = 0;
          end
        endcase
      end
      
      else if (i != 3)
      @(posedge clk)
        s_data_i[0] = $urandom_range(255, 0);
      
      else if (i == 3)
      @(posedge clk)
      begin
        s_data_i[0] = $urandom_range(255, 0);
        s_last_i[0] = 1;
      end
    end
    //second stream
    for (int j = 0; j < 4; j++)
    begin
      if      (j == 0)
      @(posedge clk)
      begin
        s_data_i[0]   = $urandom_range(255, 0);
        s_valid_i[0]  = 1;
        s_qos_i[0]    = 15;
        s_last_i[0]   = 0;
      end
      
      else if (j != 3)
      @(posedge clk)
        s_data_i[1] = $urandom_range(255, 0);
      
      else if (j == 3)
      @(posedge clk)
      begin
        s_data_i[1] = $urandom_range(255, 0);
        s_last_i[1] = 1;
      end
    end
    //third stream
    for (int k = 0; k < 4; k++)
    begin
      if      (k == 0)
      @(posedge clk)
      begin
        s_data_i[1]   = 0;
        s_valid_i[1]  = 0;
        s_qos_i[1]    = 0;
        s_last_i[1]   = 0;
      end
      
      else if (k != 3)
      @(posedge clk)
        s_data_i[0] = $urandom_range(255, 0);
      
      else if (k == 3)
      @(posedge clk)
      begin
        s_data_i[0] = $urandom_range(255, 0);
        s_last_i[0] = 1;
      end
    end
    
  @(posedge clk)
  begin
    s_valid_i   = '0;
    s_last_i    = '0;
    s_data_i[0] = '0;
    s_data_i[1] = '0;
    s_qos_i[0]  = '0;
    s_qos_i[1]  = '0;
  end
    
  #100;
  end
  
  #500;
  endtask
  
endmodule