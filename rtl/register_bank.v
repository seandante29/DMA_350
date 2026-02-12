module register_bank #(parameter WIDTH = 32,
      parameter DEPTH = 145)
     (input wire clk,
      input wire resetn,
      input wire cfg_rd_en,cfg_wr_en,//reg_wr_en,// write enable from apb to reg, 
      input wire [ WIDTH-1 : 0] cfg_data_in,//from apb to reg
      input wire [ WIDTH-1 : 0 ] addr_in,// from apb
      input wire [(WIDTH*12)-1 : 0] chn_reg_in,// from channel
      input wire [WIDTH-1 : 0] wrkregval_rd,
      output wire [ WIDTH-1 : 0] cfg_data_out, // to apb
	  output wire [WIDTH-1 : 0] cfg_CH_CMD,// to mux logic
	  output wire [WIDTH-1 : 0] cfg_CH_STATUS,
	  output wire [WIDTH-1 : 0] cfg_CH_INTREN,
	  output wire [WIDTH-1 : 0] cfg_CH_CTRL,
      output wire [WIDTH-1 : 0] cfg_CH_SRCADDR,
	  output wire [WIDTH-1 : 0] cfg_CH_DESADDR,
	  output wire [WIDTH-1 : 0] cfg_CH_XSIZE,
	  output wire [WIDTH-1 : 0] cfg_CH_SRCTRANSCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_DESTRANSCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_XADDRINC,
	  output wire [WIDTH-1 : 0] cfg_CH_FILLVAL,
	  output wire [WIDTH-1 : 0] cfg_CH_SRCTRIGINCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_DESTRIGINCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_TRIGOUTCFG,
	  output wire [WIDTH-1 : 0] cfg_LINKADDR,// to mux logic
	  output wire [WIDTH-1 : 0] cfg_WRKREGPTR,
	  output wire chn_cmd_wr_en_o, chn_stat_wr_en_o, chn_intren_wr_en_o,
      chn_ctrl_wr_en_o,chn_srcaddr_wr_en_o, chn_desaddr_wr_en_o, chn_xsize_wr_en_o, chn_srctrans_wr_en_o,
      chn_destrans_wr_en_o,chn_xaddrinc_wr_en_o,chn_fillval_wr_en_o,chn_srctrigin_wr_en_o,chn_destrigin_wr_en_o,
      chn_trigout_wr_en_o,chn_linkaddr_wr_en_o,
	  input wire [(WIDTH*3)-1 : 0]  src_des_xsize_updated
	  );
	  
    reg [ WIDTH-1:0 ] reg_mem [ 0:DEPTH-1 ];
    wire [7:0] addr_w; 
    integer i;
    
    assign addr_w = addr_in & 32'hFFFFFFFC;
    assign cfg_CH_CMD = reg_mem[0];
    assign cfg_CH_STATUS = reg_mem[4];
    assign cfg_CH_INTREN = reg_mem[8];
    assign cfg_CH_CTRL = reg_mem[12];
    assign cfg_CH_SRCADDR = reg_mem[16];
    assign cfg_CH_DESADDR = reg_mem[24];
    assign cfg_CH_XSIZE = reg_mem[32];
    assign cfg_CH_SRCTRANSCFG = reg_mem[40];
    assign cfg_CH_DESTRANSCFG = reg_mem[44];
    assign cfg_CH_XADDRINC = reg_mem[48];
    assign cfg_CH_FILLVAL = reg_mem[56];
    assign cfg_CH_SRCTRIGINCFG = reg_mem[76];
    assign cfg_CH_DESTRIGINCFG = reg_mem[80];
    assign cfg_CH_TRIGOUTCFG = reg_mem[84];
    assign cfg_LINKADDR = reg_mem[120];
    assign cfg_WRKREGPTR = reg_mem[136];
    
    assign chn_cmd_wr_en_o = cfg_wr_en && (addr_w == 0);
    assign chn_stat_wr_en_o = cfg_wr_en && ( addr_w == 8'h4);
    assign chn_intren_wr_en_o = cfg_wr_en && ( addr_w == 8'h8);
    assign chn_ctrl_wr_en_o = cfg_wr_en && ( addr_w == 8'hc) ;
    assign chn_srcaddr_wr_en_o = cfg_wr_en && ( addr_w == 8'h10);
    assign chn_desaddr_wr_en_o = cfg_wr_en && ( addr_w == 8'h18);
    assign chn_xsize_wr_en_o = cfg_wr_en && ( addr_w == 8'h20);
    assign chn_srctrans_wr_en_o = cfg_wr_en && ( addr_w == 8'h28);
    assign chn_destrans_wr_en_o = cfg_wr_en && ( addr_w == 8'h2c);
    assign chn_xaddrinc_wr_en_o = cfg_wr_en && ( addr_w == 8'h30);
    assign chn_fillval_wr_en_o = cfg_wr_en && ( addr_w == 8'h38);
    assign chn_srctrigin_wr_en_o = cfg_wr_en && ( addr_w == 8'h4c);
    assign chn_destrigin_wr_en_o = cfg_wr_en &&( addr_w == 8'h50) ;
    assign chn_trigout_wr_en_o = cfg_wr_en && ( addr_w == 8'h54);
    assign chn_linkaddr_wr_en_o = cfg_wr_en && ( addr_w == 8'h78);
    assign cfg_data_out = (cfg_rd_en) ? reg_mem[addr_w] : 'd0;
    
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn) begin
            for(i=0;i<DEPTH;i=i+1)
                reg_mem [i] <= {WIDTH{1'b0}};
        end
        
        else 
        begin
            if(cfg_wr_en)
            begin
                if (! (addr_w == 'h80 || addr_w == 'h8C || addr_w == 'h90 ))
                    if((!(reg_mem [0][0]))|| addr_w == 'h0 || addr_w == 'h4 || addr_w == 'h88)
                        reg_mem [addr_w] <= cfg_data_in;
            end
            else
            begin
                {reg_mem [0],reg_mem [4] , reg_mem[12],reg_mem [40] , reg_mem[44],reg_mem [48] , reg_mem[56],reg_mem [76] ,
                                reg_mem[80],reg_mem [84] ,reg_mem[120], reg_mem[144]} <= chn_reg_in;
                {reg_mem [16] , reg_mem[24],reg_mem [32]} <=src_des_xsize_updated;
                reg_mem[140] <= wrkregval_rd; 
            end
        end
    end
endmodule 
