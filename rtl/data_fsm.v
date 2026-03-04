module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter ID_W   = 4
)(
    input  wire                 clk,
    input  wire                 resetn,
    input  wire                 stat_error_intr_reg,
    input  wire                 stat_done_intr_reg,
    input  wire                 link_en,
    input  wire                 LINKHDERR,
    
    // Control
    input  wire                 enable_cmd_partsel,
    input  wire                 pause_cmd_partsel,
    input  wire                 resume_cmd_partsel,
    input  wire                 disable_cmd_partsel,
    input  wire                 stop_cmd_partsel,
    input  wire                 stat_disable_intr_reg,
    input  wire                 stat_stop_intr_reg,
    input  wire                 cmd_done,

    // Triggers
    
    input  wire                 use_src_trigin,
    input  wire [1:0]           src_trigin_type,
    input  wire [1:0]           src_trigin_mode,
    input  wire [7:0]           src_trigin_blk_size,
    input  wire [7:0]           src_trigin_sel,
    input wire [1:0] src_trig_req_type,
    input  wire                 use_des_trigin,
    input  wire [1:0]           des_trigin_type,
    input  wire [1:0]           des_trigin_mode,
    input  wire [7:0]           des_trigin_blk_size,
    input  wire [7:0]           des_trigin_sel,
    input wire [1:0] des_trig_req_type,
    input  wire                 use_trigout,
    input  wire [1:0]           trigout_type,
    input  wire [5:0]           trigout_sel,
    input  wire                 src_trigin_sw,
    input  wire                 des_trigin_sw,
    input  wire                 trig_out_ack_sw,
    input  wire                 src_trigin,
    input  wire                 des_trigin,
    output reg                  src_trigack,
    output reg [1:0] src_trigack_type,
    output reg [1:0] des_trigack_type,
    
    output reg                  des_trigack,
    output reg                  trig_out_req,
    input  wire                 trig_out_ack,

    // Config
    input  wire [ADDR_W-1:0]    SRC_ADDR,
    input  wire [ADDR_W-1:0]    des_ADDR,
    input  wire [2:0]           transize,
    input  wire [15:0]          srcxsize,
    input  wire [15:0]          desxsize,
    input  wire [2:0]           x_type,
    input  wire [31:0]          fillval,
    input  wire [15:0]          src_xaddr_inc,
    input  wire [15:0]          des_xaddr_inc,
    input  wire [3:0]           src_max_burst_len,
    input  wire [3:0]           des_max_burst_len,

    // AXI READ
    input  wire                 ARREADY,
    output reg                  ARVALID,
    output reg  [ADDR_W-1:0]    ARADDR,
    output reg  [2:0]           ARSIZE,
    output reg  [1:0]           ARBURST,
    output reg  [ID_W-1:0]      ARID,
    output reg  [3:0]           ARLEN,
    
    input  wire [3:0]           RID,
    input  wire                 RVALID,
    input  wire [31:0]         RDATA,
    input  wire [1:0]           RRESP,
    input  wire                 RLAST,
    output reg                  RREADY,
    
    // AXI WRITE
    input  wire                 AWREADY,
    output reg                  AWVALID,
    output reg  [ADDR_W-1:0]    AWADDR,
    output reg  [2:0]           AWSIZE,
    output reg  [1:0]           AWBURST,
    output reg  [ID_W-1:0]      AWID,
    output reg  [3:0]           AWLEN,
    
    input  wire                 WREADY,
    output reg                 WVALID,
    output reg  [31:0]    WDATA,
    output reg                 WLAST,
    
    input  wire                 BVALID,
    input  wire [1:0]           BRESP,
    output reg                  BREADY,
    
    // Status
    output reg                  DONE,
    output reg  [31:0]          SRCADDR_UPDATED,
    output reg  [31:0]          DESADDR_UPDATED,
    output reg  [31:0]          XSIZE_UPDATED,
    output reg                  wr_en_for_updated,
    
    output wire [31:0]          SRCADDR_INITIAL,
    output wire [31:0]          DESADDR_INITIAL,
    output wire [31:0]          SRCXSIZE_INITIAL,
    output wire [31:0]          DESXSIZE_INITIAL,

    // Error flags
    
    output wire                 config_error,
    output reg                  ard_error,
    output reg                  arpoison_error,
    output reg                  awr_error,
    output reg                  bus_error,
    output wire                 regvalerr,
    output reg                  ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA,
    output reg                  STAT_STOP_DATA, STAT_DISABLE_DATA, STAT_RESUMEWAIT_DATA, 
    output reg                  STAT_TRIGOUTACKWAIT_DATA, STAT_SRCTRIGINWAIT_DATA, 
    output reg                  STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA, STAT_DONE_DATA
);
    

    wire       ERROR;


    // multiple reads
    reg [15:0] src_xsize_remaining;   
    reg [15:0] des_xsize_remaining; 
    reg [1:0] src_trig_req_type_reg;
    reg [1:0] des_trig_req_type_reg;
    //
    reg        reg1, reg2;
    reg        cmd_done_reg;
    reg [15:0] src_left, des_left, fill_count;
    reg [7:0]  wrap_rd_ptr;
    reg [DATA_W-1:0] wdata_mask;
    integer    i;
    reg [15:0] srcxsize_reg, desxsize_reg;

    reg [31:0] fifo_mem [0:31];
    reg [5:0]   fifo_wptr;
    reg [5:0]   fifo_rptr;
    integer     j;

    reg config_error_size, config_error_src, config_error_des, config_error_trigout;
    reg config_error_inc, config_error_x_type, config_error_case3, config_error_case6;
    reg regvalerr_src, regvalerr_des, regvalerr_trigout;

    reg [ADDR_W-1:0] src_addr_reg, des_addr_reg;
    reg [3:0] state, next_st;
    reg       case1, case2, case3, case4, case5, case6;
    
    wire full =( (fifo_wptr +1)  == {~fifo_rptr[5],fifo_rptr[4:0]});
    wire empty = (fifo_wptr == fifo_rptr);


   
    assign config_error = config_error_size | config_error_src | config_error_des | config_error_trigout | 
                          config_error_inc | config_error_x_type | config_error_case3 | config_error_case6;
    assign regvalerr    = regvalerr_src | regvalerr_des | regvalerr_trigout;
    assign ERROR        = config_error || ard_error || arpoison_error || awr_error ;//|| bus_error;

    assign SRCADDR_INITIAL  = src_addr_reg;
    assign DESADDR_INITIAL  = des_addr_reg;
    assign SRCXSIZE_INITIAL = {16'd0, srcxsize_reg};
    assign DESXSIZE_INITIAL = {16'd0, desxsize_reg};

 
    localparam RD_IDLE       = 5'd0,
               RD_WAIT       = 5'd1,
               RD_CONFIG     = 5'd2,
               RD_WAIT_TRIG  = 5'd3,
               RD_AR         = 5'd4,
               RD_R          = 5'd5,
               RD_WRAP_FILL  = 5'd6,
               RD_ERROR_ST   = 5'd7,
               RD_PAUSED     = 5'd8;
    
    localparam W_IDLE        = 5'd9,
               W_AW          = 5'd10,
               W_W           = 5'd11,
               W_B           = 5'd12,
               W_TRIG_OUT    = 5'd13,
               W_DONE_ST     = 5'd14,
               W_ERROR_ST    = 5'd15,
               W_PAUSED      = 5'd16;
    reg [4:0] rd_state, wr_state, wr_next_st, rd_next_st,wr_pause_state, rd_pause_state;
    reg       bus_error_w, bus_error_r, done_signal, wr_start;
    
//assign WVALID = ((wr_state == W_W )&&(!empty)) ? 1 : 0;

//assign WLAST = (wr_state == W_W && WVALID) ? ((des_xsize_remaining - AWLEN) == des_left ? 1 : 0) : 0;
 // assign  WLAST = ((wr_state == W_W )&&((DESADDR_UPDATED - AWADDR)== (AWLEN -1) * 2**transize))?1:0;
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
        begin
            wr_en_for_updated <= 'd0;
            SRCADDR_UPDATED <= 'd0;
            DESADDR_UPDATED <= 'd0;
            XSIZE_UPDATED <= 'd0;
        end
        else begin
            wr_en_for_updated <=(rd_state > RD_CONFIG && rd_state <= RD_PAUSED);
            SRCADDR_UPDATED <= SRCADDR_UPDATED;
            DESADDR_UPDATED <= DESADDR_UPDATED;
            //XSIZE_UPDATED <= (case6 && x_type == 2)?(src_xsize_remaining == 0 && src_left <= srcxsize_reg && src_left!=0)?XSIZE_UPDATED:(src_xsize_remaining>=src_left)?({des_left,src_left}):{des_left,srcxsize_reg-((desxsize_reg -src_left)%srcxsize_reg)}
            //                : (case6 && x_type == 1)? {(des_left+(desxsize_reg - srcxsize_reg)),src_left}:{des_left,src_left};// src_left-(desxsize_reg - srcxsize_reg)
            if (case6 && x_type == 2) begin
                if (src_xsize_remaining == 0 && src_left <= srcxsize_reg && src_left != 0) begin
                    XSIZE_UPDATED <= XSIZE_UPDATED;
                end
                else if (src_xsize_remaining >= src_left) begin
                    XSIZE_UPDATED <= {des_left, src_left};
                end
                else begin
                    XSIZE_UPDATED <= {des_left,
                                      srcxsize_reg - ((desxsize_reg - src_left) % srcxsize_reg)};
                end
            end
            
            else if (case6 && x_type == 1) begin
                XSIZE_UPDATED <= {des_left + (desxsize_reg - srcxsize_reg), src_left};
            end
            
            else begin
                XSIZE_UPDATED <= {des_left, src_left};
            end 
            
            if(rd_state == RD_WAIT_TRIG)
            begin
                SRCADDR_UPDATED <= src_addr_reg;
                //DESADDR_UPDATED <= des_addr_reg;
            end
            else if(rd_state ==  RD_R && src_left !=0) begin
                if(RVALID) begin
                    if(src_xaddr_inc == 1)
                    begin
                        SRCADDR_UPDATED <= (case6 && x_type == 2) ? (src_left>(desxsize_reg - srcxsize_reg)) ? (src_addr_reg + ((srcxsize_reg   - (src_left-(desxsize_reg - srcxsize_reg))) *( 2**transize))) 
                                                    : src_addr_reg +((desxsize_reg -src_left)%srcxsize_reg)
                                                    :src_addr_reg + ((srcxsize_reg - src_left) *( 2**transize)) ;
                    end
                    else
                        SRCADDR_UPDATED <=  src_addr_reg;
                end
            end 
            
            if(wr_state == W_W  && des_left !=0) begin 
                if(WREADY)
                    if(des_xaddr_inc == 1)
                    begin
                        DESADDR_UPDATED <= des_addr_reg + ((desxsize_reg - des_left) * ( 2**transize));
                    end
                    else
                        DESADDR_UPDATED <=  des_addr_reg;
                else DESADDR_UPDATED <= DESADDR_UPDATED;
            end 
            
        end
    end
    
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin 
            {ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA, STAT_STOP_DATA, STAT_DISABLE_DATA,STAT_DONE_DATA} <= 'b0;
        end else begin 
            if (disable_cmd_partsel || stop_cmd_partsel)
                ENABLECMD_DATA <= 1;
            else  
                ENABLECMD_DATA <= 0;
            
            if (disable_cmd_partsel) begin
                DISABLECMD_DATA <= 1;
                STAT_DISABLE_DATA <= 1;
            end else if(stat_disable_intr_reg == 0) begin
                STAT_DISABLE_DATA <= 0;
                DISABLECMD_DATA <= 0;
            end
            
            if (stop_cmd_partsel) begin
                STAT_STOP_DATA <= 1;
                STOPCMD_DATA <= 1;
            end else if(stat_stop_intr_reg == 0) begin
                STAT_STOP_DATA <= 0;
                STOPCMD_DATA <= 0;
            end
            if(wr_state == W_DONE_ST)
            STAT_DONE_DATA <= !link_en ? 1 : 0;
            else
            STAT_DONE_DATA <= stat_done_intr_reg ? STAT_DONE_DATA : 0;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            rd_state <= 'd0;
            wr_state <= 'd0;
            end
        else begin
            rd_state <= rd_next_st;
            wr_state <= wr_next_st;
            end
    end

    always @(*) begin
        rd_next_st = rd_state;
        if (stop_cmd_partsel) begin
            rd_next_st = RD_IDLE;
        end
        else if(pause_cmd_partsel)begin
            rd_next_st = RD_PAUSED;
        end else begin
            case (rd_state)
                RD_IDLE:
                    if (wr_state == W_IDLE && enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                        if(LINKHDERR)  
                            rd_next_st = RD_IDLE;
                        else
                            rd_next_st = RD_WAIT;
                    end else
                        rd_next_st = RD_IDLE;
                        
                RD_PAUSED:
                    if(resume_cmd_partsel)
                            rd_next_st = rd_pause_state;
            
                RD_WAIT: 
                    if (stat_error_intr_reg) 
                        rd_next_st = RD_ERROR_ST;
                    else 
                        rd_next_st = reg2 ? RD_CONFIG : RD_WAIT;
            
                RD_CONFIG: begin
                  
                    if (config_error)
                        rd_next_st = RD_ERROR_ST;
                    else if (case1 || x_type == 0)
                        rd_next_st = RD_IDLE;
                    else if (case2)
                        rd_next_st = (x_type == 3) ? RD_WAIT_TRIG : RD_ERROR_ST; 
                    else if (case3)
                        rd_next_st = RD_ERROR_ST;
                    else if (case6)
                        rd_next_st = (x_type == 0) ? RD_IDLE : RD_WAIT_TRIG;
                    else
                        rd_next_st = RD_WAIT_TRIG;
                end
            
                RD_WAIT_TRIG:
                begin
                    
                    if (config_error)
                        rd_next_st = RD_ERROR_ST;
                    else if (pause_cmd_partsel)
                        rd_next_st = RD_PAUSED;
                    else if (use_src_trigin && use_des_trigin) begin  
                        if ((src_trigin_type == 2'b00 && src_trigin_sw) && (des_trigin_type == 2'b00 && des_trigin_sw))
                            rd_next_st = (case2 && x_type == 'd3) ? RD_WRAP_FILL : RD_AR; 
                        else if ((src_trigin_type == 2'b10 && src_trigin) && (des_trigin_type == 2'b10 && des_trigin))
                            rd_next_st = (case2 && x_type == 'd3) ? RD_WRAP_FILL : RD_AR;  
                        else
                            rd_next_st = RD_WAIT_TRIG;
                    end else if (!use_src_trigin && !use_des_trigin)
                        rd_next_st = RD_AR;
                    else
                        rd_next_st = RD_WAIT_TRIG;
            end
                RD_AR:
                begin
                  
                   
                    
                    if (ARVALID && ARREADY)
                        rd_next_st = RD_R;
                    else
                        rd_next_st = RD_AR;
              end
                RD_R:
                    if ((RRESP == 2 || RRESP == 3) && RVALID)
                        rd_next_st = RD_ERROR_ST;
                    else if (RVALID && RREADY && RLAST) begin
                        if(src_left > 'd1)
                            rd_next_st = RD_AR;
                       
                        else if (( fill_count > 1) && ( (x_type == 3) && (case6  || case2)))
                            rd_next_st = RD_WRAP_FILL;
                        else 
                            rd_next_st = RD_IDLE; end
                    else
                        rd_next_st = RD_R;
                        
                RD_WRAP_FILL:
                    if (src_left == 0 && fill_count == 0)
                        rd_next_st = RD_IDLE;
                    else
                        rd_next_st = RD_WRAP_FILL;
                
                RD_ERROR_ST:
                    rd_next_st = RD_IDLE;
            
                default: rd_next_st = RD_IDLE;
            endcase
        end
    end

// Next State Logic
    always @(*) begin
        wr_next_st = wr_state;
        if (stop_cmd_partsel) begin
            wr_next_st = W_IDLE;
        end 
        else if(pause_cmd_partsel)begin
            wr_next_st = W_PAUSED;
        end
        else begin
            case (wr_state)
            W_IDLE:
                if (enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                    if(done_signal)  
                        wr_next_st = W_DONE_ST;
                    else if(wr_start)
                        wr_next_st = W_AW;
                end
             W_PAUSED:
                    if(resume_cmd_partsel)
                            wr_next_st = wr_pause_state;
             W_AW:
                if (AWVALID && AWREADY)
                    wr_next_st = W_W;
            
            W_W:
                if (WREADY && WVALID && WLAST)
                        wr_next_st = W_B;
                          
            W_B:
                if (BVALID && BREADY)begin
                    if(BRESP < 1) begin
                        if(des_left > 'd0)
                            wr_next_st = W_AW;     
                        else
                            wr_next_st = W_TRIG_OUT; end
                    else
                        wr_next_st = W_ERROR_ST;end
            W_TRIG_OUT:
                if (!use_trigout)
                    wr_next_st = W_DONE_ST;
                else begin
                    if (trigout_type == 2'b00 && trig_out_ack_sw)
                        wr_next_st = W_DONE_ST;
                    else if (trigout_type == 2'b10 && trig_out_ack)
                        wr_next_st = W_DONE_ST;
                end
            
            W_DONE_ST:
                wr_next_st = W_IDLE;
            
            W_ERROR_ST:
                wr_next_st = W_IDLE;
            
            default: wr_next_st = W_IDLE;
            endcase
        end
    end
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {ARVALID, RREADY, case1, case2, case3, case4, case5, case6, des_addr_reg, src_addr_reg, wdata_mask,
            ard_error, ARADDR, desxsize_reg, ARID, ARSIZE, ARBURST, srcxsize_reg, ARLEN,src_xsize_remaining,src_trig_req_type_reg,des_trig_req_type_reg,
             arpoison_error, bus_error_r, cmd_done_reg} <= 0;
            { STAT_RESUMEWAIT_DATA,
              STAT_SRCTRIGINWAIT_DATA, STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA} <= 'b0;
            {config_error_size, config_error_src, config_error_des, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6} <= 'd0;
            {regvalerr_src, regvalerr_des, regvalerr_trigout} <= 'd0;
            rd_pause_state <= RD_IDLE;
            fifo_wptr       <= 0;
          // fifo_rptr       <= 0;
            src_left        <= 0;
            fill_count      <= 0;
            wrap_rd_ptr     <= 0;
            src_trigack     <= 0;
            des_trigack     <= 0;
            done_signal <= 0;
            src_trigack_type <= 'd0;
            des_trigack_type <= 'd0;
            wr_start <= 'd0;
            reg1 <= 0;
            reg2 <= 0;
            for(j=0; j<32; j=j+1) begin
                fifo_mem[j] <= 'd0;
            end
        end else begin
            ARVALID      <= 0;
            RREADY       <= 0;
            src_trigack  <= 0;
            des_trigack  <= 0;
            cmd_done_reg <= cmd_done;
            reg1 <= 0;
            reg2 <= 0;
            STAT_RESUMEWAIT_DATA     <= 'd0;
            STAT_PAUSED_DATA         <= 'd0;
           // STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
            STAT_SRCTRIGINWAIT_DATA  <= 1'b0;
            STAT_DESTRIGINWAIT_DATA  <= 1'b0;

                rd_pause_state <=(rd_next_st != RD_PAUSED )? rd_next_st :rd_pause_state; 
            case (rd_state)
                RD_IDLE: begin
                    done_signal <= 0;
                    if (enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                        if(LINKHDERR) done_signal <= 1;
                    end
                    if (stat_error_intr_reg == 0) begin
                        {config_error_size, config_error_src, config_error_des, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6} <= 0;
                        ard_error      <= 0;
                        arpoison_error <= 0;
                        bus_error_r    <= 0;
                        {regvalerr_src, regvalerr_des, regvalerr_trigout} <= 'd0;
                    end
                    fifo_wptr   <= 0;
                    wrap_rd_ptr <= 0;
                    fill_count  <= 0;
                    ARLEN       <= 0;
                end
                
                RD_WAIT: begin
                    reg1 <= 1;
                    reg2 <= reg1;
                    if(reg2) begin
                        case1 <= (srcxsize == 0 && desxsize == 0);
                        case2 <= (srcxsize == 0 && desxsize > 0);
                        case3 <= (srcxsize > 0 && desxsize == 0);
                        case4 <= (srcxsize == desxsize && srcxsize > 0);
                        case5 <= ((srcxsize > desxsize) && (desxsize != 0));
                        case6 <= ((srcxsize < desxsize) && (srcxsize != 0));
                    end
                end 
                
                RD_CONFIG: begin
                
                   des_trig_req_type_reg <= 'd1;
                   src_trig_req_type_reg <= 'd1;
                    if (case1 || x_type == 0) done_signal <= 1;

                    wdata_mask <= {DATA_W{1'b0}};
                    for (i = 0; i < DATA_W; i = i + 1) begin
                        if (i < ((8'd1 << transize) << 3))
                            wdata_mask[i] <= 1'b1;
                    end
                    
                    src_addr_reg <= SRC_ADDR;
                    des_addr_reg <= des_ADDR;
                    srcxsize_reg <= srcxsize;
                    desxsize_reg <= desxsize;

                    config_error_inc  <= ((x_type > 3) | (src_xaddr_inc > 1 | (des_xaddr_inc > 1)) ? 1 : 0);
                    config_error_size <= (transize > 4) | (srcxsize > 'd256) | (desxsize > 'd256);
                    
                    if (use_src_trigin) begin
                        if ((src_trigin_type != 2'b00 && src_trigin_type != 2'b10) || src_trigin_mode != 2'b00) begin
                            config_error_src <= 1;
                            regvalerr_src    <= 1;
                        end
                    end
                    
                    if (use_des_trigin) begin
                        if ((des_trigin_type != 2'b00 && des_trigin_type != 2'b10) || src_trigin_mode != 2'b00) begin
                            config_error_des <= 1;
                            regvalerr_des    <= 1;
                        end
                    end
                    
                    if (use_trigout) begin
                        if (trigout_type != 2'b00 && trigout_type != 2'b10) begin
                            config_error_trigout <= 1;
                            regvalerr_trigout    <= 1;
                        end
                    end
                    
                    if (case1) begin
                        src_left <= 0;
                    end else if (case2) begin
                        if (x_type == 3) begin
                            src_left <= 0;
                        end else if (x_type == 0)
                            config_error_x_type <= 0;
                        else
                            config_error_x_type <= 1;
                    end else if (case3)
                        config_error_case3 <= 1;
                    else if (case4 || case5) begin
                        src_left <= desxsize;
                    end else if (case6) begin
                        case (x_type)
                            0: begin src_left <= 0; end
                            1: begin src_left <= srcxsize; end
                            2: begin src_left <= desxsize; end
                            3: begin src_left <= srcxsize; end
                            default: begin src_left <= srcxsize; config_error_case6 <= 1; end
                        endcase
                    end
                    fill_count <= ((srcxsize < desxsize) && x_type == 3 && (case2 || case6)) ? ((desxsize - srcxsize) & 16'hFFFF) : 0;
                end
                
                RD_WAIT_TRIG: begin
                 src_xsize_remaining <= srcxsize_reg;
                    
                    if (use_src_trigin && use_des_trigin) begin 
                    src_trig_req_type_reg <= src_trig_req_type;
                    des_trig_req_type_reg <= des_trig_req_type; 
                        if ((src_trigin_type == 2'b10 && src_trigin) && (des_trigin_type == 2'b10 && des_trigin)) begin
                            src_trigack <= 1;
                            des_trigack <= 1;
                            if(src_trig_req_type == 'd0)
                                src_trigack_type <= 'd0;
                            else if(src_trig_req_type == 'd1)
                                src_trigack_type <= 'd1;
                            
                            if(des_trig_req_type == 'd0)
                                des_trigack_type <= 'd0;
                            else if(des_trig_req_type == 'd1)
                                des_trigack_type <= 'd1;
                            
                        end else begin
                            if (!((src_trigin_type == 2'b00 && src_trigin_sw) && (des_trigin_type == 2'b00 && des_trigin_sw))) begin
                                STAT_SRCTRIGINWAIT_DATA <= 1'b1;
                                STAT_DESTRIGINWAIT_DATA <= 1'b1;    
                            end 
                        end
                    end
                end 
                
                RD_AR: begin                   
                    //ARLEN   <= (src_trig_req_type == 'd0) ? 'd0 :  ;
                    if(src_trig_req_type_reg == 'd0) 
                        ARLEN <= 'd0;
                    else if(src_trig_req_type == 'd1)
                        ARLEN <= ((src_xsize_remaining - 1) > src_max_burst_len) ? src_max_burst_len : src_xsize_remaining - 1;
                    
                    ARBURST <= (src_xaddr_inc[0]) ? 2'b01 : 2'b00;
                    ARSIZE  <= transize;
                    ARID    <= 0;
                    ARVALID <= 1;
                   // ARADDR <= (src_xaddr_inc == 'd0) ? src_addr_reg : (src_xsize_remaining == srcxsize_reg)? src_addr_reg : (ARVALID && ARREADY) ? ARADDR + ((ARLEN + 1) * 2**transize) : ARADDR;
                    ARADDR <= (case6 && x_type == 'd2 && src_xsize_remaining == 0)? SRCADDR_INITIAL: ((src_xsize_remaining == src_left) && case6 && x_type == 2) ? ARADDR : src_addr_reg + (srcxsize_reg - src_xsize_remaining)  * (2**transize);
                   	src_xsize_remaining <= (case6 && x_type == 'd2 && src_xsize_remaining == 0) ? (srcxsize_reg > src_left) ? src_left : srcxsize_reg : (src_xsize_remaining);
                    end
        

                RD_R: begin
                    if (full)
                        RREADY <= 0;
                    else
                        RREADY <= 1;
                    if (RVALID && RREADY && RLAST) begin
                            src_xsize_remaining <= src_xsize_remaining - (ARLEN + 1);
                    end                
                    if ( RVALID && RREADY && src_left > 0 && !full) begin
                   
                        fifo_mem[fifo_wptr[4:0]] <= RDATA;
                        fifo_wptr           <= fifo_wptr + 1;
                        src_left            <= src_left - 1;
                        
                
                        if (RRESP == 2'b11) begin
                            bus_error_r <= 1'b1;
                            ard_error   <= 1'b1;
                        end else if (RRESP == 2'b10) begin
                            bus_error_r    <= 1'b1;
                            arpoison_error <= 1'b1;
                        end
                    end
                
                    end
                    
                RD_WRAP_FILL: begin
                    case (x_type)
                        2: begin
                            if ((!(desxsize - src_left < srcxsize)) && src_left > 0) begin
                                fifo_mem[fifo_wptr[4:0]] <= RDATA;
                               // wrap_rd_ptr         <= (wrap_rd_ptr == srcxsize[7:0]) ? 0 : wrap_rd_ptr + 1;
                                fifo_wptr           <= fifo_wptr + 1;
                                src_left            <= src_left - 1;
                            end
                        end
                        3: begin
                            if (fill_count > 0 && src_left == 0 && (case2 || case6)) begin
                                fifo_mem[fifo_wptr[4:0]] <= {96'd0, fillval};
                                fill_count          <= fill_count - 1;
                                fifo_wptr           <= fifo_wptr + 1;
                            end
                        end
                        default: fifo_mem[fifo_wptr[4:0]] <= fifo_mem[fifo_wptr[4:0]];
                    endcase
                end
            endcase
            
            if(rd_state == RD_R/* && fifo_wptr == {2'b00,AWLEN}*/&& RLAST)
                wr_start <= 1;
        end
    end
    
    
    // wr_fsm_seq
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
           wr_pause_state <= W_IDLE;
         AWVALID      <= 0;
            WVALID       <= 0;
            BREADY       <= 0;
            DONE <= 0;
       fifo_rptr   <= 0;
        des_left    <= 0;
           trig_out_req <= 0;
           STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
           WLAST <= 0;
           awr_error<=0;
           AWLEN <= 'd0;
           AWADDR <= 0;
           des_xsize_remaining <= 0;
           WDATA <= 0;
           AWID <= 0;
           AWSIZE <= 0;
           AWBURST <= 0;
           bus_error_w <= 'd0;
    end 
    else begin
            AWVALID      <= 0;
           WVALID       <= 0;
            BREADY       <= 0;
           DONE         <= stop_cmd_partsel? 1: 0;
           trig_out_req <= 0;
           // STAT_RESUMEWAIT_DATA <= 'd0;
           // STAT_PAUSED_DATA <= 'd0;
            STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
            //STAT_SRCTRIGINWAIT_DATA <= 1'b0;
           // STAT_DESTRIGINWAIT_DATA <= 1'b0;

                wr_pause_state <= (wr_next_st  != W_PAUSED )? wr_next_st :wr_pause_state; 
            case (wr_state)
                W_IDLE: begin
               // AWADDR <= des_addr_reg;
                    des_xsize_remaining <= desxsize_reg;
                    if (stat_error_intr_reg == 0) begin
                        awr_error      <= 0;
                        bus_error_w      <= 0;
                    end
                   
                    fifo_rptr   <= 0;
                 if (case1) begin
                        des_left <= 0;
                    end 
                    else if (case2) begin
                        if (x_type == 3) begin
                            des_left <= desxsize;
                        end 
                    end 
                    else if (case4 || case5) begin
                        des_left <= desxsize;
                    end 
                    else if (case6) begin
                        case (x_type)
                            0: begin des_left <= 0; end
                            1: begin des_left <= srcxsize; end
                            2: begin des_left <= desxsize; end
                            3: begin des_left <= desxsize; end
                            default:begin  des_left <= desxsize;  end
                        endcase
                    end
                end
                W_AW: begin
                    AWVALID <= 1;
                    AWADDR  <= /*(des_xsize_remaining == des_left) ? AWADDR :*/ des_addr_reg + (desxsize_reg - des_xsize_remaining)  * (2**transize);
                    if(des_trig_req_type_reg == 'd0) 
                        AWLEN <= 'd0;
                    else if(des_trig_req_type == 'd1)
                    AWLEN <= ((des_xsize_remaining - 1) > des_max_burst_len) ? des_max_burst_len : des_xsize_remaining - 1;//(case6 && x_type == 1)? srcxsize - 1: desxsize - 1;
                    AWBURST <= (des_xaddr_inc == 'b1) ? 2'b01 : 2'b00;
                    AWSIZE  <= transize;
                    AWID    <= 0;
                end
               
             W_W:
             begin
                 WLAST  <= (des_left == (des_xsize_remaining - AWLEN))? 1 :0 ;
                WVALID <= ((empty) || WLAST) ? 0 : 1;
                   // WDATA     <= fifo_mem[fifo_rptr[4:0]] & wdata_mask;
                    //WVALID <= ((des_left == (des_xsize_remaining - AWLEN+1) && WREADY) || fifo_wptr == fifo_rptr) ? 0 : 1;
                  if(WVALID && WREADY && WLAST)
                        des_xsize_remaining <= des_xsize_remaining - (AWLEN + 1);
                    if (WREADY && des_left > 0 && !empty && !WLAST) begin
                                           
                    WDATA     <= fifo_mem[fifo_rptr[4:0]] & wdata_mask;
                    des_left  <= des_left - 1;
                    fifo_rptr <= fifo_rptr + 1;
                    end
                    end                     
             
             
              //begin
                    
//                    WLAST  <= (des_left == (des_xsize_remaining - AWLEN))? 1 :0 ;
//                    if(WVALID && WREADY && WLAST)
//                        des_xsize_remaining <= des_xsize_remaining - (AWLEN + 1);
//                    if (WREADY && des_left > 0 && !empty) begin
//                        WVALID <= 1;
//                        WDATA     <= fifo_mem[fifo_rptr[4:0]] & wdata_mask;
//                        des_left  <= des_left - 1;
//                        fifo_rptr <= fifo_rptr + 1;
//                    end
//                end               
                W_B: begin
                    BREADY <= 1;
                    if (BRESP >= 2) begin
                        awr_error<= 1;
                        bus_error_w <= 1;
                    end
                end                
                W_TRIG_OUT: begin
                    if (use_trigout && trigout_type == 'b10)
                    trig_out_req <= 1;                    
                    if (use_trigout && !trig_out_ack_sw && trigout_type == 'b00)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else if (use_trigout && !trig_out_ack && trigout_type == 'b10)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else 
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
                end
                
                W_DONE_ST: begin
                    DONE <= 1;
                    //STAT_DONE_DATA <= !link_en ? 1 : 0;
                end
            endcase
        end
    end 
    
endmodule
