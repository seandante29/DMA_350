module mux_logic #(parameter WIDTH = 32)
 (
 input wire [31:0] cmd_data,
 input wire clk,resetn,
 input rst_posedge,
 input wire link_en,data_done,
 input wire [4:0] wptr,//input from cmd fsm
 input wire [31:0] header_in,// from cmd fsm
 // previous values
 input  wire [31:0] channel_status, 
 input  wire [31:0] control_config,
 input  wire [31:0] interrupt_enable,
    input  wire [31:0] x_transfer_count,
    input  wire [31:0] CH_next_cmd_addr,
    input  wire [31:0] addr_increment_cfg,
 input  wire [31:0] read_transfer_cfg,// previous values
 input  wire [31:0] write_transfer_cfg,
    input  wire [31:0] read_trigger_cfg,
    input  wire [31:0] write_trigger_cfg,
    input  wire [31:0] trigger_out_cfg,
    input  wire [31:0] read_base_addr,
    input  wire [31:0] write_base_addr,
    input  wire [31:0] fill_data,
    input wire [31:0] read_template_data,
    input wire [31:0] write_template_data,
    input wire [31:0] template_config,
    input wire [31:0] auto_restart_config,
    input wire [31:0] y_transfer_count,
    input wire [31:0] line_stride,
 //reg bank input
    input wire cmd_done,// from cmd fsm after rlast and count!=0 and only for a cycle(+1cyc delay)
    input wire [31:0] read_base_addr_UPDATED,
    input wire [31:0]  write_base_addr_UPDATED,
    input wire [31:0]  x_transfer_count_UPDATED,y_transfer_count_UPDATED,
    input wire  wr_en_for_updated,
     input wire [31:0] read_base_addr_INITIAL,read_base_addr_LINEINITIAL,
     input wire [31:0] write_base_addr_INITIAL,write_base_addr_LINEINITIAL,
     input wire [31:0] SRCx_transfer_count_INITIAL,DESy_transfer_count_INITIAL,
     input wire [31:0] DESx_transfer_count_INITIAL,SRCy_transfer_count_INITIAL,//inputs from data fsm
    input wire [WIDTH-1 : 0] cfg_channel_start,// cmd fsm values
    input wire [WIDTH-1 : 0] cfg_channel_status,
    input wire [WIDTH-1 : 0] cfg_interrupt_enable,
    input wire [WIDTH-1 : 0] cfg_control_config,
    input wire [WIDTH-1 : 0] cfg_read_base_addr,
    input wire [WIDTH-1 : 0] cfg_write_base_addr,
    input wire [WIDTH-1 : 0] cfg_x_transfer_count,
    input wire [WIDTH-1 : 0] cfg_read_transfer_cfg,
    input wire [WIDTH-1 : 0] cfg_write_transfer_cfg,
    input wire [WIDTH-1 : 0] cfg_addr_increment_cfg,
    input wire [WIDTH-1 : 0] cfg_fill_data,
    input wire [WIDTH-1 : 0] cfg_read_trigger_cfg,
    input wire [WIDTH-1 : 0] cfg_write_trigger_cfg,
    input wire [WIDTH-1 : 0] cfg_trigger_out_cfg,
    input wire [WIDTH-1 : 0] cfg_auto_restart_config,
    input wire [WIDTH-1 : 0] cfg_next_cmd_addr,
    input wire [WIDTH-1 : 0] cfg_line_stride,
    input wire [WIDTH-1 : 0] cfg_y_transfer_count,
    input wire [31:0] cfg_read_template_data,
    input wire [31:0] cfg_write_template_data,
    input wire [31:0] cfg_template_config,
    input wire chn_cmd_wr_en_o,//wr en for all registers from apb(paddr && pwrite) - only in access state
    input wire chn_stat_wr_en_o,
    input wire chn_intren_wr_en_o,
    input wire chn_ctrl_wr_en_o,
    input wire chn_read_base_addr_wr_en_o,
    input wire chn_write_base_addr_wr_en_o,
    input wire chn_x_transfer_count_wr_en_o,
    input wire chn_srctrans_wr_en_o,
    input wire chn_destrans_wr_en_o,
    input wire chn_xaddrinc_wr_en_o,
    input wire chn_fillval_wr_en_o,
    input wire chn_srctrigin_wr_en_o,
    input wire chn_destrigin_wr_en_o,
    input wire chn_trigout_wr_en_o,
    input wire chn_next_cmd_addr_wr_en_o,
    input wire chn_srctmplt_wr_en_o,
    input wire chn_destmplt_wr_en_o,
    input wire chn_tmpltcfg_wr_en_o,
    input wire chn_autocfg_wr_en_o,
    input wire chn_yaddr_wr_en_o,
    input wire chn_y_transfer_count_wr_en_o,
 // internal reg
 output reg [(WIDTH * 21) -1:0] mux_out_reg//to internal reg 
 );
 
    reg [31:0] cmd_data_mem [0:31];
    
    reg [1023:0] cmd_data_in;
    reg [4:0] rd_ptr;
    reg chn_cmd_wr_en_reg;//for delay
    reg chn_stat_wr_en_reg;
    reg chn_intren_wr_en_reg;
    reg chn_ctrl_wr_en_reg;
    reg chn_read_base_addr_wr_en_reg;
    reg chn_write_base_addr_wr_en_reg;
    reg chn_x_transfer_count_wr_en_reg;
    reg chn_srctrans_wr_en_reg;
    reg chn_destrans_wr_en_reg;
    reg chn_xaddrinc_wr_en_reg;
    reg chn_fillval_wr_en_reg;
    reg chn_srctrigin_wr_en_reg;
    reg chn_destrigin_wr_en_reg;
    reg chn_trigout_wr_en_reg;
    reg chn_next_cmd_addr_wr_en_reg;
    reg chn_srctmplt_wr_en_reg;
    reg chn_destmplt_wr_en_reg;
    reg chn_tmpltcfg_wr_en_reg;
    reg chn_autocfg_wr_en_reg;
    reg chn_yaddr_wr_en_reg;
    reg chn_y_transfer_count_wr_en_reg;
    wire [31:0] HEADER_CMD =header_in ;
    wire [31:0] interrupt_enable_CMD = cmd_data_in [(WIDTH*3)-1:(WIDTH*2)];
    wire [31:0] control_config_CMD   = cmd_data_in [(WIDTH*4)-1:(WIDTH*3)];
    wire [31:0] read_base_addr_CMD   = cmd_data_in [(WIDTH*5)-1:(WIDTH*4)];
    wire [31:0] write_base_addr_CMD   = cmd_data_in [(WIDTH*7)-1:(WIDTH*6)];
    wire [31:0] x_transfer_count_CMD   = cmd_data_in [(WIDTH*9)-1:(WIDTH*8)];
    wire [31:0] read_transfer_cfg_CMD   = cmd_data_in [(WIDTH*11)-1:(WIDTH*10)];
    wire [31:0] write_transfer_cfg_CMD   = cmd_data_in [(WIDTH*12)-1:(WIDTH*11)];
    wire [31:0] addr_increment_cfg_CMD   = cmd_data_in [(WIDTH*13)-1:(WIDTH*12)];
    wire [31:0] line_stride_CMD = cmd_data_in [(WIDTH*14)-1:(WIDTH*13)];
    wire [31:0] fill_data_CMD   = cmd_data_in [(WIDTH*15)-1:(WIDTH*14)];
    wire [31:0] y_transfer_count_CMD   = cmd_data_in [(WIDTH*16)-1:(WIDTH*15)];
    wire [31:0] template_config_CMD = cmd_data_in [(WIDTH*17)-1:(WIDTH*16)];
    wire [31:0] read_template_data_CMD = cmd_data_in [(WIDTH*18)-1:(WIDTH*17)];
    wire [31:0] write_template_data_CMD = cmd_data_in [(WIDTH*19)-1:(WIDTH*18)];    
    wire [31:0] read_trigger_cfg_CMD   = cmd_data_in [(WIDTH*20)-1:(WIDTH*19)];
    wire [31:0] write_trigger_cfg_CMD   = cmd_data_in [(WIDTH*21)-1:(WIDTH*20)];
    wire [31:0] trigger_out_cfg_CMD   = cmd_data_in [(WIDTH*22)-1:(WIDTH*21)];
    wire [31:0] auto_restart_config_CMD = cmd_data_in [(WIDTH*30)-1 : (WIDTH*29)];
    wire [31:0] CH_next_cmd_addr_CMD = cmd_data_in [(WIDTH*31)-1:(WIDTH*30)];
    wire [31:0] DEFAULT_VALUE = 32'd0;
    wire REGCLEAR = HEADER_CMD[0];
    wire [(WIDTH * 19) -1:0] concat_cmd;
    integer i,j;
    
    mux m0 (control_config,DEFAULT_VALUE,control_config_CMD,REGCLEAR,HEADER_CMD[3],concat_cmd[(WIDTH*2)-1:(WIDTH*1)]);
    mux m1 (interrupt_enable,DEFAULT_VALUE,interrupt_enable_CMD,REGCLEAR,HEADER_CMD[2],concat_cmd[(WIDTH*1)-1:0]);
    mux m2 (read_base_addr_INITIAL,DEFAULT_VALUE,read_base_addr_CMD,REGCLEAR,HEADER_CMD[4],concat_cmd[(WIDTH*3)-1:(WIDTH*2)]);
    mux m3 (write_base_addr_INITIAL,DEFAULT_VALUE,write_base_addr_CMD,REGCLEAR,HEADER_CMD[6],concat_cmd[(WIDTH*4)-1:(WIDTH*3)]);
    mux m4 ({DESx_transfer_count_INITIAL[15:0],SRCx_transfer_count_INITIAL[15:0]},DEFAULT_VALUE,x_transfer_count_CMD,REGCLEAR,HEADER_CMD[8],concat_cmd[(WIDTH*5)-1:(WIDTH*4)]);
    mux m5 (read_transfer_cfg,DEFAULT_VALUE,read_transfer_cfg_CMD,REGCLEAR,HEADER_CMD[10],concat_cmd[(WIDTH*6)-1:(WIDTH*5)]);
    mux m6 (write_transfer_cfg,DEFAULT_VALUE,write_transfer_cfg_CMD,REGCLEAR,HEADER_CMD[11],concat_cmd[(WIDTH*7)-1:(WIDTH*6)]);
    mux m7 (addr_increment_cfg,DEFAULT_VALUE,addr_increment_cfg_CMD,REGCLEAR,HEADER_CMD[12],concat_cmd[(WIDTH*8)-1:(WIDTH*7)]);
    mux m8 (line_stride,DEFAULT_VALUE,line_stride_CMD,REGCLEAR,HEADER_CMD[13],concat_cmd[(WIDTH*18)-1:(WIDTH*17)]);
    mux m9 (fill_data,DEFAULT_VALUE,fill_data_CMD,REGCLEAR,HEADER_CMD[14],concat_cmd[(WIDTH*9)-1:(WIDTH*8)]);
    mux m10 ({DESy_transfer_count_INITIAL[15:0],SRCy_transfer_count_INITIAL[15:0]},DEFAULT_VALUE,y_transfer_count_CMD,REGCLEAR,HEADER_CMD[15],concat_cmd[(WIDTH*19)-1:(WIDTH*18)]);
    mux m11 (template_config,DEFAULT_VALUE,template_config_CMD,REGCLEAR,HEADER_CMD[16],concat_cmd[(WIDTH*10)-1:(WIDTH*9)]);
    mux m12 (read_template_data,DEFAULT_VALUE,read_template_data_CMD,REGCLEAR,HEADER_CMD[17],concat_cmd[(WIDTH*11)-1:(WIDTH*10)]);
    mux m13 (write_template_data,DEFAULT_VALUE,write_template_data_CMD,REGCLEAR,HEADER_CMD[18],concat_cmd[(WIDTH*12)-1:(WIDTH*11)]);
    mux m14 (read_trigger_cfg,DEFAULT_VALUE,read_trigger_cfg_CMD,REGCLEAR,HEADER_CMD[19],concat_cmd[(WIDTH*13)-1:(WIDTH*12)]);
    mux m15 (write_trigger_cfg,DEFAULT_VALUE,write_trigger_cfg_CMD,REGCLEAR,HEADER_CMD[20],concat_cmd[(WIDTH*14)-1:(WIDTH*13)]);
    mux m16 (trigger_out_cfg,DEFAULT_VALUE,trigger_out_cfg_CMD,REGCLEAR,HEADER_CMD[21],concat_cmd[(WIDTH*15)-1:(WIDTH*14)]);
    mux m17 (auto_restart_config,DEFAULT_VALUE,auto_restart_config_CMD,REGCLEAR,HEADER_CMD[29],concat_cmd[(WIDTH*16)-1:(WIDTH*15)]);
    mux m18 (CH_next_cmd_addr,DEFAULT_VALUE,CH_next_cmd_addr_CMD,REGCLEAR,HEADER_CMD[30],concat_cmd[(WIDTH*17)-1:(WIDTH*16)]);
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            chn_cmd_wr_en_reg       <= 1'b0;
            chn_stat_wr_en_reg      <= 1'b0;
            chn_intren_wr_en_reg    <= 1'b0;
            chn_ctrl_wr_en_reg      <= 1'b0;
            chn_read_base_addr_wr_en_reg   <= 1'b0;
            chn_write_base_addr_wr_en_reg   <= 1'b0;
            chn_x_transfer_count_wr_en_reg     <= 1'b0;
            chn_srctrans_wr_en_reg  <= 1'b0;
            chn_destrans_wr_en_reg  <= 1'b0;
            chn_xaddrinc_wr_en_reg  <= 1'b0;
            chn_fillval_wr_en_reg   <= 1'b0;
            chn_srctrigin_wr_en_reg <= 1'b0;
            chn_destrigin_wr_en_reg <= 1'b0;
            chn_trigout_wr_en_reg   <= 1'b0;
            chn_next_cmd_addr_wr_en_reg  <= 1'b0;
            chn_srctmplt_wr_en_reg  <= 1'b0;
            chn_destmplt_wr_en_reg  <= 1'b0;
            chn_tmpltcfg_wr_en_reg  <= 1'b0;
            chn_autocfg_wr_en_reg <= 1'b0;
            chn_yaddr_wr_en_reg <= 1'b0;
            chn_y_transfer_count_wr_en_reg <= 1'b0;
        end
        else begin
            chn_cmd_wr_en_reg       <= chn_cmd_wr_en_o;
            chn_stat_wr_en_reg      <= chn_stat_wr_en_o;
            chn_intren_wr_en_reg    <= chn_intren_wr_en_o;
            chn_ctrl_wr_en_reg      <= chn_ctrl_wr_en_o;
            chn_read_base_addr_wr_en_reg   <= chn_read_base_addr_wr_en_o;
            chn_write_base_addr_wr_en_reg   <= chn_write_base_addr_wr_en_o;
            chn_x_transfer_count_wr_en_reg     <= chn_x_transfer_count_wr_en_o;
            chn_srctrans_wr_en_reg  <= chn_srctrans_wr_en_o;
            chn_destrans_wr_en_reg  <= chn_destrans_wr_en_o;
            chn_xaddrinc_wr_en_reg  <= chn_xaddrinc_wr_en_o;
            chn_fillval_wr_en_reg   <= chn_fillval_wr_en_o;
            chn_srctrigin_wr_en_reg <= chn_srctrigin_wr_en_o;
            chn_destrigin_wr_en_reg <= chn_destrigin_wr_en_o;
            chn_trigout_wr_en_reg   <= chn_trigout_wr_en_o;
            chn_next_cmd_addr_wr_en_reg  <= chn_next_cmd_addr_wr_en_o;
            chn_srctmplt_wr_en_reg  <= chn_srctmplt_wr_en_o;
            chn_destmplt_wr_en_reg  <= chn_destmplt_wr_en_o;
            chn_tmpltcfg_wr_en_reg  <= chn_tmpltcfg_wr_en_o;
            chn_autocfg_wr_en_reg <= chn_autocfg_wr_en_o;
            chn_yaddr_wr_en_reg <= chn_yaddr_wr_en_o;
            chn_y_transfer_count_wr_en_reg <= chn_y_transfer_count_wr_en_o;
        end
    end
    
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn) begin
            for(j=0;j<32;j=j+1)
                cmd_data_mem [j] <= 'd0;
        end
        else begin
            cmd_data_mem [wptr] <= cmd_data; 
        end
    end
    
    always @(*)
    begin
        rd_ptr = 'd1;
        for(i=1;i<32;i=i+1) 
            if (i == 1 ||i == 23 || i == 25 || i == 27)
            begin
            cmd_data_in [(WIDTH * i) +: WIDTH ] = 'd0;
            end
            else if(HEADER_CMD[i]) 
            begin
                cmd_data_in [(WIDTH * i) +: WIDTH ] = cmd_data_mem [rd_ptr];
                rd_ptr = rd_ptr+1'b1; 
            end
            else
            cmd_data_in [(WIDTH * i) +: WIDTH ] = 'd0;
    end
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            mux_out_reg [(WIDTH*21)-1 :0]  <= 'd0;
        end
        else begin
            // WORD 0 : CMD
            if (chn_cmd_wr_en_reg)
            mux_out_reg[(WIDTH*1)-1:0] <= cfg_channel_start;
            else
            mux_out_reg[5:0] <= 0  ;
            
            // WORD 1 : STATUS
            if (chn_stat_wr_en_reg)
            mux_out_reg[(WIDTH*2)-1:(WIDTH*1)] <= cfg_channel_status;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[51:48] <= 0;
            
            // WORD 2 : INTREN
            if (chn_intren_wr_en_reg)
            mux_out_reg[(WIDTH*3)-1:(WIDTH*2)] <= cfg_interrupt_enable;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*3)-1:(WIDTH*2)] <= concat_cmd[(WIDTH*1)-1:(WIDTH*0)];
            
            // WORD 3 : CTRL
            if (chn_ctrl_wr_en_reg)
            mux_out_reg[(WIDTH*4)-1:(WIDTH*3)] <= cfg_control_config;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*4)-1:(WIDTH*3)] <= concat_cmd[(WIDTH*2)-1:(WIDTH*1)];
            
            // WORD 4 : read_base_addr
            if (chn_read_base_addr_wr_en_reg)
            mux_out_reg[(WIDTH*5)-1:(WIDTH*4)] <= cfg_read_base_addr;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*5)-1:(WIDTH*4)]  <= read_base_addr_UPDATED;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*5)-1:(WIDTH*4)] <= concat_cmd[(WIDTH*3)-1:(WIDTH*2)];
            
            // WORD 5 : write_base_addr
            if (chn_write_base_addr_wr_en_reg)
            mux_out_reg[(WIDTH*6)-1:(WIDTH*5)] <= cfg_write_base_addr;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*6)-1:(WIDTH*5)]  <= write_base_addr_UPDATED;
            else if (/*(link_en && data_done) ||*/ cmd_done)
            mux_out_reg[(WIDTH*6)-1:(WIDTH*5)] <= concat_cmd[(WIDTH*4)-1:(WIDTH*3)];
            
            // WORD 6 : x_transfer_count
            if (chn_x_transfer_count_wr_en_reg)
            mux_out_reg[(WIDTH*7)-1:(WIDTH*6)] <= cfg_x_transfer_count;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*7)-1:(WIDTH*6)]  <= x_transfer_count_UPDATED;
            else if (/*(link_en && data_done) ||*/ cmd_done)
            mux_out_reg[(WIDTH*7)-1:(WIDTH*6)] <= concat_cmd[(WIDTH*5)-1:(WIDTH*4)];
            
            // WORD 7 : SRCTRANS
            if (chn_srctrans_wr_en_reg)
            mux_out_reg[(WIDTH*8)-1:(WIDTH*7)] <= cfg_read_transfer_cfg;
            else if (/*(link_en && data_done) ||*/ cmd_done)
            mux_out_reg[(WIDTH*8)-1:(WIDTH*7)] <= concat_cmd[(WIDTH*6)-1:(WIDTH*5)];
            
            // WORD 8 : DESTRANS
            if (chn_destrans_wr_en_reg)
            mux_out_reg[(WIDTH*9)-1:(WIDTH*8)] <= cfg_write_transfer_cfg;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*9)-1:(WIDTH*8)] <= concat_cmd[(WIDTH*7)-1:(WIDTH*6)];
            
            // WORD 9 : XADDRINC
            if (chn_xaddrinc_wr_en_reg)
            mux_out_reg[(WIDTH*10)-1:(WIDTH*9)] <= cfg_addr_increment_cfg;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*10)-1:(WIDTH*9)] <= concat_cmd[(WIDTH*8)-1:(WIDTH*7)];
            
            // WORD 9 : YADDRSTRIDE
            if (chn_yaddr_wr_en_reg)
            mux_out_reg[(WIDTH*20)-1:(WIDTH*19)] <= cfg_line_stride;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*20)-1:(WIDTH*19)] <= concat_cmd[(WIDTH*18)-1:(WIDTH*17)];
            
            // WORD 10 : y_transfer_count
            if (chn_y_transfer_count_wr_en_reg)
            mux_out_reg[(WIDTH*21)-1:(WIDTH*20)] <= cfg_y_transfer_count;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*21)-1:(WIDTH*20)]  <= y_transfer_count_UPDATED;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*21)-1:(WIDTH*20)] <= concat_cmd[(WIDTH*19)-1:(WIDTH*18)];
            
            // WORD 10 : FILLVAL
            if (chn_fillval_wr_en_reg)
            mux_out_reg[(WIDTH*11)-1:(WIDTH*10)] <= cfg_fill_data;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*11)-1:(WIDTH*10)] <= concat_cmd[(WIDTH*9)-1:(WIDTH*8)];
            
            // tmplcfg
            if (chn_tmpltcfg_wr_en_reg)
            mux_out_reg[(WIDTH*12)-1:(WIDTH*11)] <= cfg_template_config;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*12)-1:(WIDTH*11)] <= concat_cmd[(WIDTH*10)-1:(WIDTH*9)];
            
            //srctmplt
             if (chn_srctmplt_wr_en_reg)
            mux_out_reg[(WIDTH*13)-1:(WIDTH*12)] <= cfg_read_template_data;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*13)-1:(WIDTH*12)] <= concat_cmd[(WIDTH*11)-1:(WIDTH*10)];
            
            //destmplt
             if (chn_destmplt_wr_en_reg)
            mux_out_reg[(WIDTH*14)-1:(WIDTH*13)] <= cfg_write_template_data;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*14)-1:(WIDTH*13)] <= concat_cmd[(WIDTH*12)-1:(WIDTH*11)];
            
            // WORD 11 : SRCTRIGIN
            if (chn_srctrigin_wr_en_reg)
            mux_out_reg[(WIDTH*15)-1:(WIDTH*14)] <= cfg_read_trigger_cfg;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*15)-1:(WIDTH*14)] <= concat_cmd[(WIDTH*13)-1:(WIDTH*12)];
            
            // WORD 12 : DESTRIGIN
            if (chn_destrigin_wr_en_reg)
            mux_out_reg[(WIDTH*16)-1:(WIDTH*15)] <= cfg_write_trigger_cfg;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*16)-1:(WIDTH*15)] <= concat_cmd[(WIDTH*14)-1:(WIDTH*13)];
            
            // WORD 13 : TRIGOUT
            if (chn_trigout_wr_en_reg)
            mux_out_reg[(WIDTH*17)-1:(WIDTH*16)] <= cfg_trigger_out_cfg;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*17)-1:(WIDTH*16)] <= concat_cmd[(WIDTH*15)-1:(WIDTH*14)];
            
             if (chn_autocfg_wr_en_reg)
            mux_out_reg[(WIDTH*18)-1:(WIDTH*17)] <= cfg_auto_restart_config;
            else if (/*(link_en && data_done) || */cmd_done)
            mux_out_reg[(WIDTH*18)-1:(WIDTH*17)] <= concat_cmd[(WIDTH*16)-1:(WIDTH*15)];
            
            // WORD 14 : next_cmd_addr
            if (chn_next_cmd_addr_wr_en_reg)
            mux_out_reg[(WIDTH*19)-1:(WIDTH*18)] <= cfg_next_cmd_addr;
            else if (/*(link_en && data_done) ||*/ cmd_done ||rst_posedge )
            mux_out_reg[(WIDTH*19)-1:(WIDTH*18)] <= concat_cmd[(WIDTH*17)-1:(WIDTH*16)];
        end
    end
endmodule
 
 
