module stream_arbiter #(
  parameter   T_DATA_WIDTH = 8,
              T_QOS__WIDTH = 4,
              STREAM_COUNT = 2,
              T_ID___WIDTH = $clog2(STREAM_COUNT)
)(
  input  logic                     clk,
  input  logic                     rst_n,
  // input streams
  input  logic [T_DATA_WIDTH-1:0]  s_data_i  [STREAM_COUNT-1:0],
  input  logic [T_QOS__WIDTH-1:0]  s_qos_i   [STREAM_COUNT-1:0],
  input  logic [STREAM_COUNT-1:0]  s_last_i,
  input  logic [STREAM_COUNT-1:0]  s_valid_i,
  output logic [STREAM_COUNT-1:0]  s_ready_o,
  // output stream
  output logic [T_DATA_WIDTH-1:0]  m_data_o,
  output logic [T_QOS__WIDTH-1:0]  m_qos_o,
  output logic [T_ID___WIDTH-1:0]  m_id_o,
  output logic                     m_last_o,
  output logic                     m_valid_o,
  input  logic                     m_ready_i
);
  
  logic [1:0]  qos_i, qos_i_d;
  
  prior i_prior(.*);
  
  enum logic [1:0]
  {
    IDLE    = 2'b00,
    BCAST   = 2'b01,
    RRBCAST = 2'b10,
    FRBCAST = 2'b11
  } state;
  
  //FSM
  always_ff @(posedge clk)
    if    (!rst_n)
    begin
      state <= IDLE;
    end
    else
    begin
      case(state)
      IDLE:
        if      (qos_i == 2'b11 & m_ready_i)
          state <= RRBCAST;
        else if (qos_i != 2'b0 & m_ready_i)
          state <= BCAST;
      
      RRBCAST:
        if  (s_last_i[0] & s_ready_o[0] & s_valid_i[0])
          state <= FRBCAST;
      
      FRBCAST:
        if  (s_last_i[1] & s_ready_o[1] & s_valid_i[1])
          state <= IDLE;
      
      BCAST:
        if  ((s_last_i[0] & s_ready_o[0] & s_valid_i[0]) | (s_last_i[1] & s_ready_o[1] & s_valid_i[1]))
          state <= IDLE;
      endcase
    end
  
  //Register transfer
  always_ff @(posedge clk)
    if  (!rst_n)
    begin
      m_valid_o <= '0;
      m_last_o  <= '0;
      m_id_o    <= '0;
      m_qos_o   <= '0;
      m_data_o  <= '0;
    end
    else
    begin
      m_valid_o <= s_valid_i[0] | s_valid_i[1];
      m_last_o  <= s_last_i[0]  | s_last_i[1];
      
      case(state)
        IDLE:
        begin
          qos_i_d <= qos_i;
        
          if      (qos_i == 2'b11)
          begin
            m_id_o    <= 1'b0;
            m_qos_o   <= s_qos_i[0];
            m_data_o  <= s_data_i[0];
          end
          else
          begin
            if (qos_i == 2'b01)
            begin
              m_id_o    <= 1'b0;
              m_qos_o   <= s_qos_i[0];
              m_data_o  <= s_data_i[0];
            end
            
            if (qos_i == 2'b10)
            begin
              m_id_o    <= 1'b1;
              m_qos_o   <= s_qos_i[1];
              m_data_o  <= s_data_i[1];
            end
          end
          
        end
        
        RRBCAST:
        begin
          m_data_o <= s_data_i[0];
        end
        
        FRBCAST:
        begin
          m_data_o <= s_data_i[1];
          m_qos_o  <= s_qos_i[1];
          m_id_o   <= 1;
        end
        
        BCAST:
        begin
          
          if      (s_last_i[0] | s_last_i[1])
            qos_i_d <= 'b0;
          
          if      (qos_i_d == 2'b01)
            m_data_o <= s_data_i[0];
          else if (qos_i_d == 2'b10)
            m_data_o <= s_data_i[1];
        end
      endcase
    end
  
  //Comb other logic
  always_comb
  begin
    case(state)
      IDLE:
      begin
        s_ready_o = 2'b0;
        
        if      (qos_i == 2'b11)
          s_ready_o = 2'b01;
        else if (qos_i == 2'b01)
          s_ready_o = 2'b01;
        else if (qos_i == 2'b10)
          s_ready_o = 2'b10;
        else
          s_ready_o = 2'b0;
      end
      
      RRBCAST:
      begin
        s_ready_o = 2'b01;
      end
      
      FRBCAST:
      begin
        s_ready_o = 2'b10;
      end
      
      BCAST:
      begin
        if      (qos_i == 2'b11)
          s_ready_o = 2'b01;
        else if (qos_i == 2'b01)
          s_ready_o = 2'b01;
        else if (qos_i == 2'b10)
          s_ready_o = 2'b10;
        else
          s_ready_o = 2'b0;
      end
    endcase
  end
    
endmodule: stream_arbiter

module prior #(
  parameter T_QOS__WIDTH = 4,  
            STREAM_COUNT = 2
)(
  input  logic [T_QOS__WIDTH-1:0] s_qos_i   [STREAM_COUNT-1:0],
  input  logic [STREAM_COUNT-1:0] s_valid_i,
  output logic [STREAM_COUNT-1:0] qos_i
);
  
  always_comb
  begin
    qos_i = 2'b0;
    
    if    ( s_valid_i[0] &  s_valid_i[1])
    begin
      if      ((s_qos_i[0] >  s_qos_i[1]) & (s_qos_i[1] != 4'b0))
      begin
        qos_i = 2'b01;
      end
      else if ((s_qos_i[0] >  s_qos_i[1]) & (s_qos_i[1] == 4'b0))
      begin
        qos_i = 2'b11;
      end
      else if ((s_qos_i[0] <  s_qos_i[1]) & (s_qos_i[0] != 4'b0))
      begin
        qos_i = 2'b10;
      end
      else if ((s_qos_i[0] <  s_qos_i[1]) & (s_qos_i[0] == 4'b0))
      begin
        qos_i = 2'b11;
      end
      else if ((s_qos_i[0] == s_qos_i[1]))
      begin
        qos_i = 2'b11;
      end
    end
  
  if    ( s_valid_i[0] & ~s_valid_i[1])
    begin
      qos_i = 2'b01;
    end
    
    if    (~s_valid_i[0] &  s_valid_i[1])
    begin
      qos_i = 2'b10;
    end
  end
  
endmodule: prior  