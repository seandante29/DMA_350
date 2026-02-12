module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 128,  //128
    parameter ID_W   = 4
    )(
    input  wire              clk,
    input  wire              resetn,
    input  wire              stat_error_intr_reg,// from internal reg
    input  wire              stat_done_intr_reg,// from internal reg
    input  wire              link_en,        // from part select
    input wire               LINKHDERR,
    
    // Control
    input  wire              enable_cmd_partsel,
    input  wire              pause_cmd_partsel,
    input  wire              resume_cmd_partsel,
    input  wire              disable_cmd_partsel,
    input  wire              stop_cmd_partsel,      // from internal reg
    input wire               stat_disable_intr_reg,
    input wire               stat_stop_intr_reg,
    input  wire              cmd_done,
    // Triggers
    input  wire              use_src_trigin,
    input  wire [1:0]        src_trigin_type,
    input  wire [1:0]        src_trigin_mode,
    input  wire [7:0]        src_trigin_sel,
    
    input  wire              use_des_trigin,
    input  wire [1:0]        des_trigin_type,
    input  wire [1:0]        des_trigin_mode,
    input  wire [7:0]        des_trigin_sel,
    
    input  wire              use_trigout,
    input  wire [1:0]        trigout_type,
    input  wire [5:0]        trigout_sel,
    
    input  wire              src_trigin_sw,
    input  wire              des_trigin_sw,
    input  wire              trig_out_ack_sw,
    
    input  wire              src_trigin,
    input  wire              des_trigin,
    output reg               src_trigack,
    output reg               des_trigack,
    output reg               trig_out_req,
    input  wire              trig_out_ack,
    
    // Config// from part select
    input  wire [ADDR_W-1:0] SRC_ADDR,
    input  wire [ADDR_W-1:0] des_ADDR,
    input  wire [2:0]        transize,
    input  wire [15:0]       srcxsize,
    input  wire [15:0]       desxsize,
    input  wire [2:0]        x_type,
    input  wire [31:0]      fillval,
    input  wire  [15:0]            src_xaddr_inc,
    input  wire   [15:0]           des_xaddr_inc,
    
    // AXI READ
    input  wire              ARREADY,
    output reg               ARVALID,
    output reg  [ADDR_W-1:0] ARADDR,
    output reg  [2:0]        ARSIZE,
    output reg  [1:0]        ARBURST,
    output reg  [ID_W-1:0]   ARID,
    output reg  [3:0]        ARLEN,
    
    input wire              [3:0] RID,
    input  wire              RVALID,
    input  wire [127 : 0]    RDATA, //128
    input  wire [1:0]        RRESP,
    input  wire              RLAST,
    output reg               RREADY,
    
    // AXI WRITE
    input  wire              AWREADY,
    output reg               AWVALID,
    output reg  [ADDR_W-1:0] AWADDR,
    output reg  [2:0]        AWSIZE,
    output reg  [1:0]        AWBURST,
    output reg  [ID_W-1:0]   AWID,
    output reg  [3:0] AWLEN,
    
    input  wire              WREADY,
    output reg               WVALID,
    output reg  [DATA_W-1:0] WDATA,
    output reg               WLAST,
    
    input  wire              BVALID,
    input  wire [1:0]        BRESP,
    output reg               BREADY,
    
    // Status
    output reg               DONE,
    
    
    output reg [31:0] SRCADDR_UPDATED,
    output reg [31:0]  DESADDR_UPDATED,
    output reg [31:0]  XSIZE_UPDATED,
    output reg wr_en_for_updated,
    
    output wire [31:0] SRCADDR_INITIAL,
    output wire [31:0] DESADDR_INITIAL,
    output wire [31:0] SRCXSIZE_INITIAL,
    output wire [31:0] DESXSIZE_INITIAL,
    // Error flags
    output wire               config_error,
    output reg               ard_error,
    output reg               arpoison_error,
    output reg               awr_error,
    output reg               bus_error,
    output wire               regvalerr,
    output reg               ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA,// FROM DATA FSM TO INTERNAL REGISTER 
    output reg               STAT_STOP_DATA, STAT_DISABLE_DATA, STAT_RESUMEWAIT_DATA, 
    output reg               STAT_TRIGOUTACKWAIT_DATA, STAT_SRCTRIGINWAIT_DATA, 
    output reg               STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA, STAT_DONE_DATA
    );
    
    wire ERROR;
    // Internal counters
    reg reg1,reg2;
    reg cmd_done_reg;
    reg [15:0] src_left, des_left, fill_count;
    reg [7:0] wrap_rd_ptr;
    reg [DATA_W-1:0] wdata_mask;
    integer i;
    reg [15:0] srcxsize_reg,desxsize_reg;
    // FIFO memory
    reg [127:0] fifo_mem [0:255];
    reg [7:0]   fifo_wptr;
    reg [7:0]   fifo_rptr;
    integer j;
    reg config_error_size,config_error_src, config_error_des, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6;
    reg regvalerr_src,regvalerr_des,regvalerr_trigout;
    reg [ADDR_W-1:0] src_addr_reg, des_addr_reg;
    reg [3:0] state, next_st;
    reg case1,case2,case3,case4,case5,case6;
    localparam IDLE      = 4'd0,
    CONFIG    = 4'd1,
    WAIT_TRIG = 4'd2,
    AR        = 4'd3,
    R         = 4'd4,
    AW        = 4'd5,
    W         = 4'd6,
    B         = 4'd7,
    TRIG_OUT  = 4'd8,
    PAUSED    = 4'd9,
    DONE_ST   = 4'd10,
    ERROR_ST  = 4'd11,
    WRAP_FILL = 4'd12,
    WAIT = 4'd13,
    WAIT_1 = 4'd14,
    WAIT_2 = 4'd15;
    
    assign config_error = config_error_size | config_error_src | config_error_des | config_error_trigout | config_error_inc | config_error_x_type | config_error_case3 | config_error_case6;
    assign regvalerr = regvalerr_src | regvalerr_des | regvalerr_trigout;
    assign ERROR    = config_error || ard_error || arpoison_error || awr_error || bus_error;
    assign  SRCADDR_INITIAL = src_addr_reg;
    assign DESADDR_INITIAL = des_addr_reg;
    assign SRCXSIZE_INITIAL = {16'd0,srcxsize_reg};
    assign DESXSIZE_INITIAL = {16'd0,desxsize_reg};

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
            wr_en_for_updated <=(state > CONFIG && state <= DONE_ST);
            SRCADDR_UPDATED <= SRCADDR_UPDATED;
            DESADDR_UPDATED <= DESADDR_UPDATED;
            XSIZE_UPDATED <= (case6 && x_type == 2)? (src_left>=(desxsize_reg - srcxsize_reg))?({des_left,(src_left-(desxsize_reg - srcxsize_reg))}):{des_left,16'b0}
                            : (case6 && x_type == 1)? {(des_left+(desxsize_reg - srcxsize_reg)),src_left}:{des_left,src_left};// src_left-(desxsize_reg - srcxsize_reg)
            if(state == WAIT_TRIG)
            begin
                SRCADDR_UPDATED <= src_addr_reg;
                DESADDR_UPDATED <= des_addr_reg;
            end
            else if(state ==  R && src_left !=0) begin
                if(RVALID) begin
                    if(src_xaddr_inc == 1)
                    begin
                        SRCADDR_UPDATED <= (case6 && x_type == 2) ? (src_left>(desxsize_reg - srcxsize_reg)) ? (src_addr_reg + ((srcxsize_reg   - (src_left-(desxsize_reg - srcxsize_reg))) *( 2**transize))) 
                                                    : SRCADDR_UPDATED
                                                    :src_addr_reg + ((srcxsize_reg - src_left) *( 2**transize)) ;
                    end
                    else
                        SRCADDR_UPDATED <=  src_addr_reg;
                end
            end 
            else if(state == W  && des_left !=0) begin 
                if(WREADY)
                    if(des_xaddr_inc == 1)
                    begin
                        DESADDR_UPDATED <= des_addr_reg + ((desxsize_reg - des_left) * ( 2**transize));
                    end
                    else
                        DESADDR_UPDATED <=  des_addr_reg;
            end 
        end
    end
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= IDLE;
        else
            state <= next_st; 
    end
    
    
    // Next State Logic
    always @(*) begin
        next_st = state;
        if (stop_cmd_partsel) begin
            next_st = IDLE;
        end else begin
            case (state)
            IDLE:
                if (enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                    if(LINKHDERR)  
                        next_st = DONE_ST;
                    else
                        next_st = WAIT;
                end
                else
                next_st = IDLE;
        
            WAIT: 
                if (stat_error_intr_reg) 
                    next_st = ERROR_ST;
                else 
                    next_st = reg2 ? CONFIG : WAIT;
            
            CONFIG: begin
                if (config_error)
                    next_st = ERROR_ST;
                else if (case1 || x_type == 0)
                    next_st = DONE_ST;
                else if (case2)
                    next_st = (x_type == 3) ? WAIT_TRIG : ERROR_ST; 
                else if (case3)
                    next_st = ERROR_ST;
                else if (case6)
                    next_st = (x_type == 0) ? DONE_ST : WAIT_TRIG;
                else
                    next_st = WAIT_TRIG;
                end
            
            
            WAIT_TRIG:
                if (config_error)
                    next_st = ERROR_ST;
                else if (pause_cmd_partsel)
                    next_st = PAUSED;
                else if (use_src_trigin && use_des_trigin) begin  
                    if ((src_trigin_type == 2'b00 && src_trigin_sw) && (des_trigin_type == 2'b00 && des_trigin_sw))
                        next_st = (case2 && x_type == 'd3) ? WRAP_FILL : AR; 
                    else if ((src_trigin_type == 2'b10 && src_trigin) && (des_trigin_type == 2'b10 && des_trigin))
                        next_st = (case2 && x_type == 'd3) ? WRAP_FILL : AR;  
                end
                else if (!use_src_trigin && !use_des_trigin)
                    next_st = AR;
                else
                    next_st = WAIT_TRIG;
            
            AR:
                if (ARVALID && ARREADY)
                    next_st = R;
                else
                    next_st = AR;
            
            R:
                if ((RRESP == 2 || RRESP == 3) && RVALID)
                    next_st = ERROR_ST;
                else if (RVALID && RREADY && RLAST) begin
                    if ((src_left > 0 || fill_count > 1) &&(case6 && (x_type != 1) || case2))
                        next_st = WRAP_FILL;
                    else
                        next_st = AW;
                end 
                else
                    next_st = R;
            
            WRAP_FILL:
                if (src_left == 0 && fill_count == 0)
                    next_st = AW;
                else
                    next_st = WRAP_FILL;
            
            AW:
                if (AWVALID && AWREADY)
                    next_st = W;
            
            W:
                if (WREADY && WVALID && WLAST)
                    next_st = B;
            
            B:
                if (BVALID && BREADY)
                    next_st = (BRESP <= 1) ? TRIG_OUT : ERROR_ST;
            
            TRIG_OUT:
                if (!use_trigout)
                    next_st = DONE_ST;
                else begin
                    if (trigout_type == 2'b00 && trig_out_ack_sw)
                        next_st = DONE_ST;
                    else if (trigout_type == 2'b10 && trig_out_ack)
                        next_st = DONE_ST;
                end
            
            PAUSED:
                if (resume_cmd_partsel)
                    next_st = WAIT_TRIG;
            
            DONE_ST:
                next_st = IDLE;
            
            ERROR_ST:
                next_st = IDLE;
            
            default: next_st = IDLE;
            endcase
        end
    end
    
    // Sequential Logic
    always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        {ARVALID, RREADY, AWVALID, WVALID, BREADY,WLAST,case1,case2,case3,case4,case5,case6,des_addr_reg,src_addr_reg,wdata_mask,
        DONE, trig_out_req,  ard_error,WDATA,AWADDR,ARADDR,AWSIZE,AWBURST,AWLEN,desxsize_reg,ARID,ARSIZE,ARBURST,srcxsize_reg,ARLEN,AWID,
        arpoison_error, awr_error, bus_error,cmd_done_reg} <= 0;
        {ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA, STAT_STOP_DATA, STAT_DISABLE_DATA, STAT_RESUMEWAIT_DATA,
        STAT_TRIGOUTACKWAIT_DATA, STAT_SRCTRIGINWAIT_DATA, STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA, STAT_DONE_DATA} <= 'b0;
        {config_error_size,config_error_src, config_error_des, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6} <= 'd0;
        {regvalerr_src,regvalerr_des,regvalerr_trigout} <= 'd0;
        
        fifo_wptr   <= 0;
        fifo_rptr   <= 0;
        src_left    <= 0;
        des_left    <= 0;
        fill_count  <= 0;
        wrap_rd_ptr <= 0;
        src_trigack <= 0;
        des_trigack <= 0;
        reg1<=0;
        reg2<=0;
        for(j=0;j<256;j=j+1) begin
            fifo_mem [j] <= 'd0;
        end
    end 
    else begin
            ARVALID      <= 0;
            RREADY       <= 0;
            AWVALID      <= 0;
            WVALID       <= 0;
            BREADY       <= 0;
            DONE         <= stop_cmd_partsel? 1: 0;
            trig_out_req <= 0;
            src_trigack  <= 0;
            des_trigack  <= 0;
            cmd_done_reg <= cmd_done;
            reg1<=0;
            reg2<=0;
            STAT_RESUMEWAIT_DATA <= 'd0;
            STAT_PAUSED_DATA <= 'd0;
            STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
            STAT_SRCTRIGINWAIT_DATA <= 1'b0;
            STAT_DESTRIGINWAIT_DATA <= 1'b0;
            
            if (disable_cmd_partsel || stop_cmd_partsel )
            ENABLECMD_DATA    <= 1;
            else  
            ENABLECMD_DATA    <= 0;
            
            if (disable_cmd_partsel) begin
                DISABLECMD_DATA <= 1;
                STAT_DISABLE_DATA <= 1;
            end
            else if( stat_disable_intr_reg == 0)begin
                STAT_DISABLE_DATA  <= 0;
                DISABLECMD_DATA <= 0;
            end
            
            if (stop_cmd_partsel) begin
                STAT_STOP_DATA    <= 1;
                STOPCMD_DATA <= 1;
            end
            else if(stat_stop_intr_reg == 0) begin
                STAT_STOP_DATA    <= 0;
                STOPCMD_DATA <= 0;
            end
            STAT_DONE_DATA <= stat_done_intr_reg ? STAT_DONE_DATA:0 ;
            
            case (state)
                IDLE: begin
                    if (stat_error_intr_reg == 0) begin
                        {config_error_size,config_error_src, config_error_des, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6 }<= 0;
                        ard_error      <= 0;
                        arpoison_error <= 0;
                        awr_error      <= 0;
                        bus_error      <= 0;
                        {regvalerr_src,regvalerr_des,regvalerr_trigout} <= 'd0;
                    end
                    fifo_wptr   <= 0;
                    fifo_rptr   <= 0;
                    wrap_rd_ptr <= 0;
                    fill_count  <= 0;
                    ARLEN       <= 0;
                end
                
                WAIT:
                begin
                    reg1<=1;
                    reg2<=reg1;
                    if(reg2) begin
                        case1 <= (srcxsize == 0 && desxsize == 0);
                        case2 <= (srcxsize == 0 && desxsize > 0);
                        case3 <= (srcxsize > 0 && desxsize == 0);
                        case4 <= (srcxsize == desxsize && srcxsize > 0);
                        case5 <= ((srcxsize > desxsize) && (desxsize != 0));
                        case6 <= ((srcxsize < desxsize) && (srcxsize !=0));
                    end
                end 
                
                CONFIG: begin
                    wdata_mask <= {DATA_W{1'b0}};
                    for (i = 0; i < DATA_W; i = i + 1) begin
                        if (i < ((8'd1 << transize) << 3))
                            wdata_mask[i] <= 1'b1;
                    end
                    
                    src_addr_reg <= SRC_ADDR;
                    des_addr_reg <= des_ADDR;
                    
                    srcxsize_reg <= srcxsize;
                    ARLEN   <= (case5) ? desxsize - 1 : srcxsize - 1;
                    ARBURST <= (src_xaddr_inc == 'b1) ? 2'b01 : 2'b00;
                    ARSIZE  <= transize;
                    ARID    <= 0;
                    
                    desxsize_reg <= desxsize;
                    AWLEN <= (case6 && x_type == 1)? srcxsize - 1: desxsize - 1;
                    AWBURST <= (des_xaddr_inc == 'b1) ? 2'b01 : 2'b00;
                    AWSIZE  <= transize;
                    AWID    <= 0;
                    config_error_inc <= ((x_type > 3) |(src_xaddr_inc>1| (des_xaddr_inc>1))? 1 : 0);
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
                        des_left <= 0;
                    end 
                    else if (case2) begin
                        if (x_type == 3) begin
                            src_left <= 0;
                            des_left <= desxsize;
                        end 
                        else if (x_type == 0)
                        config_error_x_type <= 0;
                        else
                        config_error_x_type <= 1;
                    end 
                    else if (case3)
                        config_error_case3 <= 1;
                    else if (case4 || case5) begin
                        src_left <= desxsize;
                        des_left <= desxsize;
                    end 
                    else if (case6) begin
                        case (x_type)
                            0: begin src_left <= 0; des_left <= 0; end
                            1: begin src_left <= srcxsize; des_left <= srcxsize; end
                            2: begin src_left <= desxsize; des_left <= desxsize; end
                            3: begin src_left <= srcxsize; des_left <= desxsize; end
                            default:begin src_left <= srcxsize; des_left <= desxsize;  config_error_case6 <= 1; end
                        endcase
                    end
                    fill_count <= ((srcxsize < desxsize) && x_type == 3 && (case2 || case6)) ? ((desxsize - srcxsize) & 16'hFFFF) : 0;
                end
                
                WAIT_TRIG: begin
                    if (use_src_trigin && use_des_trigin) begin  
                        if ((src_trigin_type == 2'b10 && src_trigin) && (des_trigin_type == 2'b10 && des_trigin)) begin
                            src_trigack <= 1;
                            des_trigack <= 1;
                        end 
                        else begin
                            if (!((src_trigin_type == 2'b00 && src_trigin_sw) && (des_trigin_type == 2'b00 && des_trigin_sw))) begin
                            STAT_SRCTRIGINWAIT_DATA <= 1'b1;
                            STAT_DESTRIGINWAIT_DATA <= 1'b1;				
                            end	
                        end
                    end
                end
                
                AR: begin
                    ARVALID <= 1;
                    ARADDR  <= src_addr_reg;
                end
                
                R: begin
                    if (fifo_wptr + 1 != fifo_rptr)
                        RREADY <= 1;
                    else
                        RREADY <= 0;
                    
                    if (RVALID && RREADY && src_left > 0 ) begin
                        fifo_mem[fifo_wptr] <= RDATA;
                        fifo_wptr           <= fifo_wptr + 1;
                        src_left            <= src_left - 1;
                        if(RRESP == 2'b11)    
                        begin
                            bus_error <= 1'b1;
                            ard_error <=1'b1;
                        end
                        else if(RRESP == 2'b10)
                        begin
                            bus_error <=1'b1;
                            arpoison_error <= 1'b1;
                        end
                    end
                end
                
                WRAP_FILL: begin
                    case (x_type)
                        2: begin
                            if ((!(desxsize - src_left < srcxsize)) && src_left > 0) begin
                                fifo_mem[fifo_wptr] <= fifo_mem[wrap_rd_ptr];
                                wrap_rd_ptr         <= (wrap_rd_ptr == srcxsize[7:0]) ? 0 : wrap_rd_ptr + 1;
                                fifo_wptr           <= fifo_wptr + 1;
                                src_left            <= src_left - 1;
                            end
                        end
                        3: begin
                            if (fill_count > 0 && src_left == 0 && (case2 || case6)) begin
                                fifo_mem[fifo_wptr] <= {96'd0,fillval};
                                fill_count          <= fill_count - 1;
                                fifo_wptr           <= fifo_wptr + 1;
                            end
                        end
                        default: fifo_mem[fifo_wptr] <= fifo_mem[fifo_wptr];
                    endcase
                end
                
                AW: begin
                    AWVALID <= 1;
                    AWADDR  <= des_addr_reg;
                end
                
                W: begin
                    WVALID <= 1;
                    WLAST  <= (des_left == 1);
                    if (WREADY && des_left > 0 && WVALID) begin
                        WDATA     <= fifo_mem[fifo_rptr] & wdata_mask;
                        des_left  <= des_left - 1;
                        fifo_rptr <= fifo_rptr + 1;
                    end
                end
                
                B: begin
                    BREADY <= 1;
                    if (BRESP >= 2) begin
                        awr_error<= 1;
                        bus_error <= 1;
                    end
                end
                
                TRIG_OUT: begin
                    if (use_trigout && trigout_type == 'b10)
                    trig_out_req <= 1;
                    
                    if (use_trigout && !trig_out_ack_sw && trigout_type == 'b00)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else if (use_trigout && !trig_out_ack && trigout_type == 'b10)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else 
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
                end
                
                DONE_ST: begin
                    DONE <= 1;
                    STAT_DONE_DATA <= !link_en ? 1 : 0;
                end 
                
                PAUSED: begin
                    STAT_RESUMEWAIT_DATA <= !resume_cmd_partsel ? 1 : 0;
                    STAT_PAUSED_DATA <= 1;
                end
            endcase
        end
    end
    
endmodule
