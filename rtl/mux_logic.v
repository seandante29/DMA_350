module mux_logic #(parameter WIDTH = 32)
	(
	input wire [31:0] cmd_data,
	input wire clk,resetn,
	input wire link_en,data_done,
	input wire [4:0] wptr,//input from cmd fsm
	input wire [31:0] header_in,// from cmd fsm
	input  wire [31:0] CH_STATUS,	
	input  wire [31:0] CH_CTRL,
	input  wire [31:0] CH_INTREN,
    input  wire [31:0] CH_XSIZE,
    input  wire [31:0] CH_LINKADDR,
    input  wire [31:0] CH_XADDRINC,
	input  wire [31:0] CH_SRCTRANSCFG,// previous values
	input  wire [31:0] CH_DESTRANSCFG,
    input  wire [31:0] CH_SRCTRIGINCFG,
    input  wire [31:0] CH_DESTRIGINCFG,
    input  wire [31:0] CH_TRIGOUTCFG,
    input  wire [31:0] CH_SRCADDR,
    input  wire [31:0] CH_DESADDR,
    input  wire [31:0] CH_FILLVAL,
	//reg bank input
    input wire cmd_done,// from cmd fsm after rlast and count!=0 and only for a cycle(+1cyc delay)
    input wire [31:0] SRCADDR_UPDATED,
    input wire [31:0]  DESADDR_UPDATED,
    input wire [31:0]  XSIZE_UPDATED,
    input wire  wr_en_for_updated,
     input wire [31:0] SRCADDR_INITIAL,
     input wire [31:0] DESADDR_INITIAL,
     input wire [31:0] SRCXSIZE_INITIAL,
     input wire [31:0] DESXSIZE_INITIAL,//inputs from data fsm
    input wire [WIDTH-1 : 0] cfg_CH_CMD,// cmd fsm values
    input wire [WIDTH-1 : 0] cfg_CH_STATUS,
    input wire [WIDTH-1 : 0] cfg_CH_INTREN,
    input wire [WIDTH-1 : 0] cfg_CH_CTRL,
    input wire [WIDTH-1 : 0] cfg_CH_SRCADDR,
    input wire [WIDTH-1 : 0] cfg_CH_DESADDR,
    input wire [WIDTH-1 : 0] cfg_CH_XSIZE,
    input wire [WIDTH-1 : 0] cfg_CH_SRCTRANSCFG,
    input wire [WIDTH-1 : 0] cfg_CH_DESTRANSCFG,
    input wire [WIDTH-1 : 0] cfg_CH_XADDRINC,
    input wire [WIDTH-1 : 0] cfg_CH_FILLVAL,
    input wire [WIDTH-1 : 0] cfg_CH_SRCTRIGINCFG,
    input wire [WIDTH-1 : 0] cfg_CH_DESTRIGINCFG,
    input wire [WIDTH-1 : 0] cfg_CH_TRIGOUTCFG,
    input wire [WIDTH-1 : 0] cfg_LINKADDR,
    input wire chn_cmd_wr_en_o,//wr en for all registers from apb(paddr && pwrite) - only in access state
    input wire chn_stat_wr_en_o,
    input wire chn_intren_wr_en_o,
    input wire chn_ctrl_wr_en_o,
    input wire chn_srcaddr_wr_en_o,
    input wire chn_desaddr_wr_en_o,
    input wire chn_xsize_wr_en_o,
    input wire chn_srctrans_wr_en_o,
    input wire chn_destrans_wr_en_o,
    input wire chn_xaddrinc_wr_en_o,
    input wire chn_fillval_wr_en_o,
    input wire chn_srctrigin_wr_en_o,
    input wire chn_destrigin_wr_en_o,
    input wire chn_trigout_wr_en_o,
    input wire chn_linkaddr_wr_en_o,
	// internal reg
	output reg [(WIDTH * 15) -1:0] mux_out_reg//to internal reg 
	);
	
    reg [31:0] cmd_data_mem [0:31];
    
    reg [1023:0] cmd_data_in;
    reg [4:0] rd_ptr;
    reg chn_cmd_wr_en_reg;//for delay
    reg chn_stat_wr_en_reg;
    reg chn_intren_wr_en_reg;
    reg chn_ctrl_wr_en_reg;
    reg chn_srcaddr_wr_en_reg;
    reg chn_desaddr_wr_en_reg;
    reg chn_xsize_wr_en_reg;
    reg chn_srctrans_wr_en_reg;
    reg chn_destrans_wr_en_reg;
    reg chn_xaddrinc_wr_en_reg;
    reg chn_fillval_wr_en_reg;
    reg chn_srctrigin_wr_en_reg;
    reg chn_destrigin_wr_en_reg;
    reg chn_trigout_wr_en_reg;
    reg chn_linkaddr_wr_en_reg;
    wire [31:0] HEADER_CMD =header_in ;
    wire [31:0] CH_INTREN_CMD = cmd_data_in [(WIDTH*3)-1:(WIDTH*2)];
    wire [31:0] CH_CTRL_CMD   = cmd_data_in [(WIDTH*4)-1:(WIDTH*3)];
    wire [31:0] CH_SRCADDR_CMD   = cmd_data_in [(WIDTH*5)-1:(WIDTH*4)];
    wire [31:0] CH_DESADDR_CMD   = cmd_data_in [(WIDTH*7)-1:(WIDTH*6)];
    wire [31:0] CH_XSIZE_CMD   = cmd_data_in [(WIDTH*9)-1:(WIDTH*8)];
    wire [31:0] CH_SRCTRANSCFG_CMD   = cmd_data_in [(WIDTH*11)-1:(WIDTH*10)];
    wire [31:0] CH_DESTRANSCFG_CMD   = cmd_data_in [(WIDTH*12)-1:(WIDTH*11)];
    wire [31:0] CH_XADDRINC_CMD   = cmd_data_in [(WIDTH*13)-1:(WIDTH*12)];
    wire [31:0] CH_FILLVAL_CMD   = cmd_data_in [(WIDTH*15)-1:(WIDTH*14)];
    wire [31:0] CH_SRCTRIGINCFG_CMD   = cmd_data_in [(WIDTH*20)-1:(WIDTH*19)];
    wire [31:0] CH_DESTRIGINCFG_CMD   = cmd_data_in [(WIDTH*21)-1:(WIDTH*20)];
    wire [31:0] CH_TRIGOUTCFG_CMD   = cmd_data_in [(WIDTH*22)-1:(WIDTH*21)];
    wire [31:0] CH_LINKADDR_CMD = cmd_data_in [(WIDTH*31)-1:(WIDTH*30)];
    wire [31:0] DEFAULT_VALUE = 32'd0;
    wire REGCLEAR = HEADER_CMD[0];
    wire [(WIDTH * 13) -1:0] concat_cmd;
    integer i,j;
    
    mux m0 (CH_CTRL,DEFAULT_VALUE,CH_CTRL_CMD,REGCLEAR,HEADER_CMD[3],concat_cmd[(WIDTH*2)-1:(WIDTH*1)]);
    mux m1 (CH_INTREN,DEFAULT_VALUE,CH_INTREN_CMD,REGCLEAR,HEADER_CMD[2],concat_cmd[(WIDTH*1)-1:0]);
    mux m2 (SRCADDR_INITIAL,DEFAULT_VALUE,CH_SRCADDR_CMD,REGCLEAR,HEADER_CMD[4],concat_cmd[(WIDTH*3)-1:(WIDTH*2)]);
    mux m3 (DESADDR_INITIAL,DEFAULT_VALUE,CH_DESADDR_CMD,REGCLEAR,HEADER_CMD[6],concat_cmd[(WIDTH*4)-1:(WIDTH*3)]);
    mux m4 ({DESXSIZE_INITIAL[15:0],SRCXSIZE_INITIAL[15:0]},DEFAULT_VALUE,CH_XSIZE_CMD,REGCLEAR,HEADER_CMD[8],concat_cmd[(WIDTH*5)-1:(WIDTH*4)]);
    mux m5 (CH_SRCTRANSCFG,DEFAULT_VALUE,CH_SRCTRANSCFG_CMD,REGCLEAR,HEADER_CMD[10],concat_cmd[(WIDTH*6)-1:(WIDTH*5)]);
    mux m6 (CH_DESTRANSCFG,DEFAULT_VALUE,CH_DESTRANSCFG_CMD,REGCLEAR,HEADER_CMD[11],concat_cmd[(WIDTH*7)-1:(WIDTH*6)]);
    mux m7 (CH_XADDRINC,DEFAULT_VALUE,CH_XADDRINC_CMD,REGCLEAR,HEADER_CMD[12],concat_cmd[(WIDTH*8)-1:(WIDTH*7)]);
    mux m8 (CH_FILLVAL,DEFAULT_VALUE,CH_FILLVAL_CMD,REGCLEAR,HEADER_CMD[14],concat_cmd[(WIDTH*9)-1:(WIDTH*8)]);
    mux m9 (CH_SRCTRIGINCFG,DEFAULT_VALUE,CH_SRCTRIGINCFG_CMD,REGCLEAR,HEADER_CMD[19],concat_cmd[(WIDTH*10)-1:(WIDTH*9)]);
    mux m10 (CH_DESTRIGINCFG,DEFAULT_VALUE,CH_DESTRIGINCFG_CMD,REGCLEAR,HEADER_CMD[20],concat_cmd[(WIDTH*11)-1:(WIDTH*10)]);
    mux m11 (CH_TRIGOUTCFG,DEFAULT_VALUE,CH_TRIGOUTCFG_CMD,REGCLEAR,HEADER_CMD[21],concat_cmd[(WIDTH*12)-1:(WIDTH*11)]);
    mux m12 (CH_LINKADDR,DEFAULT_VALUE,CH_LINKADDR_CMD,REGCLEAR,HEADER_CMD[30],concat_cmd[(WIDTH*13)-1:(WIDTH*12)]);
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            chn_cmd_wr_en_reg       <= 1'b0;
            chn_stat_wr_en_reg      <= 1'b0;
            chn_intren_wr_en_reg    <= 1'b0;
            chn_ctrl_wr_en_reg      <= 1'b0;
            chn_srcaddr_wr_en_reg   <= 1'b0;
            chn_desaddr_wr_en_reg   <= 1'b0;
            chn_xsize_wr_en_reg     <= 1'b0;
            chn_srctrans_wr_en_reg  <= 1'b0;
            chn_destrans_wr_en_reg  <= 1'b0;
            chn_xaddrinc_wr_en_reg  <= 1'b0;
            chn_fillval_wr_en_reg   <= 1'b0;
            chn_srctrigin_wr_en_reg <= 1'b0;
            chn_destrigin_wr_en_reg <= 1'b0;
            chn_trigout_wr_en_reg   <= 1'b0;
            chn_linkaddr_wr_en_reg  <= 1'b0;
        end
        else begin
            chn_cmd_wr_en_reg       <= chn_cmd_wr_en_o;
            chn_stat_wr_en_reg      <= chn_stat_wr_en_o;
            chn_intren_wr_en_reg    <= chn_intren_wr_en_o;
            chn_ctrl_wr_en_reg      <= chn_ctrl_wr_en_o;
            chn_srcaddr_wr_en_reg   <= chn_srcaddr_wr_en_o;
            chn_desaddr_wr_en_reg   <= chn_desaddr_wr_en_o;
            chn_xsize_wr_en_reg     <= chn_xsize_wr_en_o;
            chn_srctrans_wr_en_reg  <= chn_srctrans_wr_en_o;
            chn_destrans_wr_en_reg  <= chn_destrans_wr_en_o;
            chn_xaddrinc_wr_en_reg  <= chn_xaddrinc_wr_en_o;
            chn_fillval_wr_en_reg   <= chn_fillval_wr_en_o;
            chn_srctrigin_wr_en_reg <= chn_srctrigin_wr_en_o;
            chn_destrigin_wr_en_reg <= chn_destrigin_wr_en_o;
            chn_trigout_wr_en_reg   <= chn_trigout_wr_en_o;
            chn_linkaddr_wr_en_reg  <= chn_linkaddr_wr_en_o;
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
            if(HEADER_CMD[i]) 
            begin
                cmd_data_in [(WIDTH * i) +: WIDTH ] = cmd_data_mem [rd_ptr];
                rd_ptr = rd_ptr+1'b1; 
            end
            else
            cmd_data_in [(WIDTH * i) +: WIDTH ] = 'd0;
    end
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            mux_out_reg [(WIDTH*15)-1 :0]  <= 'd0;
        end
        else begin
            // WORD 0 : CMD
            if (chn_cmd_wr_en_reg)
            mux_out_reg[(WIDTH*1)-1:0] <= cfg_CH_CMD;
            else
            mux_out_reg[5:0] <= 0  ;
            
            // WORD 1 : STATUS
            if (chn_stat_wr_en_reg)
            mux_out_reg[(WIDTH*2)-1:(WIDTH*1)] <= cfg_CH_STATUS;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[51:48] <= 0;
            
            // WORD 2 : INTREN
            if (chn_intren_wr_en_reg)
            mux_out_reg[(WIDTH*3)-1:(WIDTH*2)] <= cfg_CH_INTREN;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*3)-1:(WIDTH*2)] <= concat_cmd[(WIDTH*1)-1:(WIDTH*0)];
            
            // WORD 3 : CTRL
            if (chn_ctrl_wr_en_reg)
            mux_out_reg[(WIDTH*4)-1:(WIDTH*3)] <= cfg_CH_CTRL;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*4)-1:(WIDTH*3)] <= concat_cmd[(WIDTH*2)-1:(WIDTH*1)];
            
            // WORD 4 : SRCADDR
            if (chn_srcaddr_wr_en_reg)
            mux_out_reg[(WIDTH*5)-1:(WIDTH*4)] <= cfg_CH_SRCADDR;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*5)-1:(WIDTH*4)]  <= SRCADDR_UPDATED;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*5)-1:(WIDTH*4)] <= concat_cmd[(WIDTH*3)-1:(WIDTH*2)];
            
            // WORD 5 : DESADDR
            if (chn_desaddr_wr_en_reg)
            mux_out_reg[(WIDTH*6)-1:(WIDTH*5)] <= cfg_CH_DESADDR;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*6)-1:(WIDTH*5)]  <= DESADDR_UPDATED;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*6)-1:(WIDTH*5)] <= concat_cmd[(WIDTH*4)-1:(WIDTH*3)];
            
            // WORD 6 : XSIZE
            if (chn_xsize_wr_en_reg)
            mux_out_reg[(WIDTH*7)-1:(WIDTH*6)] <= cfg_CH_XSIZE;
            else if (wr_en_for_updated)  mux_out_reg[(WIDTH*7)-1:(WIDTH*6)]  <= XSIZE_UPDATED;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*7)-1:(WIDTH*6)] <= concat_cmd[(WIDTH*5)-1:(WIDTH*4)];
            
            // WORD 7 : SRCTRANS
            if (chn_srctrans_wr_en_reg)
            mux_out_reg[(WIDTH*8)-1:(WIDTH*7)] <= cfg_CH_SRCTRANSCFG;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*8)-1:(WIDTH*7)] <= concat_cmd[(WIDTH*6)-1:(WIDTH*5)];
            
            // WORD 8 : DESTRANS
            if (chn_destrans_wr_en_reg)
            mux_out_reg[(WIDTH*9)-1:(WIDTH*8)] <= cfg_CH_DESTRANSCFG;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*9)-1:(WIDTH*8)] <= concat_cmd[(WIDTH*7)-1:(WIDTH*6)];
            
            // WORD 9 : XADDRINC
            if (chn_xaddrinc_wr_en_reg)
            mux_out_reg[(WIDTH*10)-1:(WIDTH*9)] <= cfg_CH_XADDRINC;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*10)-1:(WIDTH*9)] <= concat_cmd[(WIDTH*8)-1:(WIDTH*7)];
            
            // WORD 10 : FILLVAL
            if (chn_fillval_wr_en_reg)
            mux_out_reg[(WIDTH*11)-1:(WIDTH*10)] <= cfg_CH_FILLVAL;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*11)-1:(WIDTH*10)] <= concat_cmd[(WIDTH*9)-1:(WIDTH*8)];
            
            // WORD 11 : SRCTRIGIN
            if (chn_srctrigin_wr_en_reg)
            mux_out_reg[(WIDTH*12)-1:(WIDTH*11)] <= cfg_CH_SRCTRIGINCFG;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*12)-1:(WIDTH*11)] <= concat_cmd[(WIDTH*10)-1:(WIDTH*9)];
            
            // WORD 12 : DESTRIGIN
            if (chn_destrigin_wr_en_reg)
            mux_out_reg[(WIDTH*13)-1:(WIDTH*12)] <= cfg_CH_DESTRIGINCFG;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*13)-1:(WIDTH*12)] <= concat_cmd[(WIDTH*11)-1:(WIDTH*10)];
            
            // WORD 13 : TRIGOUT
            if (chn_trigout_wr_en_reg)
            mux_out_reg[(WIDTH*14)-1:(WIDTH*13)] <= cfg_CH_TRIGOUTCFG;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*14)-1:(WIDTH*13)] <= concat_cmd[(WIDTH*12)-1:(WIDTH*11)];
            
            // WORD 14 : LINKADDR
            if (chn_linkaddr_wr_en_reg)
            mux_out_reg[(WIDTH*15)-1:(WIDTH*14)] <= cfg_LINKADDR;
            else if ((link_en && data_done) || cmd_done)
            mux_out_reg[(WIDTH*15)-1:(WIDTH*14)] <= concat_cmd[(WIDTH*13)-1:(WIDTH*12)];
        end
    end
endmodule
	
