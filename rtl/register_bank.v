module register_bank #(parameter WIDTH = 32,
    parameter ADDR_WIDTH = 32,
	parameter DEPTH = 256)
	(input wire clk,
	input wire resetn,
	input wire cfg_rd_en,cfg_wr_en,//reg_wr_en,// write enable from apb to reg, 
	input wire [ WIDTH-1 : 0] cfg_data_in,//from apb to reg
	input wire [ADDR_WIDTH-1:0 ] addr_in,// from apb
	input wire [(WIDTH*18)-1 : 0] chn_reg_in,// from channel
	input wire [WIDTH-1 : 0] wrkregval_rd,
	output wire [ WIDTH-1 : 0] cfg_data_out, // to apb
	//output wire chn_wr_en, //to channel
	output wire [WIDTH-1 : 0] cfg_channel_start,// to mux logic
	output wire [WIDTH-1 : 0] cfg_channel_status,
	output wire [WIDTH-1 : 0] cfg_interrupt_enable,
	output wire [WIDTH-1 : 0] cfg_control_config,
	output wire [WIDTH-1 : 0] cfg_read_base_addr,
	output wire [WIDTH-1 : 0] cfg_write_base_addr,
	output wire [WIDTH-1 : 0] cfg_x_transfer_count,
	output wire [WIDTH-1 : 0] cfg_read_transfer_cfg,
	output wire [WIDTH-1 : 0] cfg_write_transfer_cfg,
	output wire [WIDTH-1 : 0] cfg_addr_increment_cfg,
	output wire [WIDTH-1 : 0] cfg_fill_data,
	output wire [WIDTH-1 : 0] cfg_read_trigger_cfg,
	output wire [WIDTH-1 : 0] cfg_write_trigger_cfg,
	output wire [WIDTH-1 : 0] cfg_trigger_out_cfg,
	output wire [WIDTH-1 : 0] cfg_auto_restart_config,
	output wire [WIDTH-1 : 0] cfg_next_cmd_addr,// to mux logic
	output wire [WIDTH-1 : 0] cfg_work_reg_pointer,cfg_line_stride,cfg_y_transfer_count,
	output wire [31:0] cfg_read_template_data,
	output wire [31:0] cfg_write_template_data,
	output wire [31:0] cfg_template_config,
	output wire chn_cmd_wr_en_o, chn_stat_wr_en_o, chn_intren_wr_en_o,
	chn_ctrl_wr_en_o,chn_read_base_addr_wr_en_o, chn_write_base_addr_wr_en_o, chn_x_transfer_count_wr_en_o, chn_srctrans_wr_en_o,
	chn_destrans_wr_en_o,chn_xaddrinc_wr_en_o,chn_fillval_wr_en_o,chn_srctrigin_wr_en_o,chn_destrigin_wr_en_o,
	chn_trigout_wr_en_o,chn_autocfg_wr_en_o,chn_next_cmd_addr_wr_en_o,chn_work_reg_pointer_wr_en_o,chn_tmpltcfg_wr_en_o,chn_destmplt_wr_en_o,chn_srctmplt_wr_en_o,chn_yaddrestride_wr_en_o,chn_y_transfer_count_wr_en_o,//to channel   ,// to mux logic
	input wire [(WIDTH*3)-1 : 0]  src_des_x_transfer_count_updated
	);
	reg [WIDTH-1:0] cfg_data_out_reg;	
	reg [ WIDTH-1:0 ] reg_mem [ 0:DEPTH-1 ];
	
	wire [31:0] addr_w_32; 
	wire [7:0] addr_w = addr_w_32[7:0];
	integer i;

	assign addr_w_32 = ((addr_in & 32'hFFFFFFFC) - 'h1000)&8'hFF;
	assign cfg_channel_start = reg_mem[0];
	assign cfg_channel_status = reg_mem[4];
	assign cfg_interrupt_enable = reg_mem[8];
	assign cfg_control_config = reg_mem[12];
	assign cfg_read_base_addr = reg_mem[16];
	assign cfg_write_base_addr = reg_mem[24];
	assign cfg_x_transfer_count = reg_mem[32];
	assign cfg_read_transfer_cfg = reg_mem[40];
	assign cfg_write_transfer_cfg = reg_mem[44];
	assign cfg_addr_increment_cfg = reg_mem[48];
	assign cfg_fill_data = reg_mem[56];
	assign cfg_template_config = reg_mem[64];
	assign cfg_read_template_data = reg_mem[68];
	assign cfg_write_template_data = reg_mem[72];
	assign cfg_line_stride = reg_mem[52];
	assign cfg_y_transfer_count = reg_mem[60];
	assign cfg_read_trigger_cfg = reg_mem[76];
	assign cfg_write_trigger_cfg = reg_mem[80];
	assign cfg_trigger_out_cfg = reg_mem[84];
	assign cfg_auto_restart_config = reg_mem[116];
	assign cfg_next_cmd_addr = reg_mem[120];
	assign cfg_work_reg_pointer = reg_mem[136];

	assign chn_cmd_wr_en_o = cfg_wr_en && (addr_w == 0);
	assign chn_stat_wr_en_o = cfg_wr_en && ( addr_w == 8'h4);
	assign chn_intren_wr_en_o = cfg_wr_en && ( addr_w == 8'h8);
	assign chn_ctrl_wr_en_o = cfg_wr_en && ( addr_w == 8'hc) ;
	assign chn_read_base_addr_wr_en_o = cfg_wr_en && ( addr_w == 8'h10);
	assign chn_write_base_addr_wr_en_o = cfg_wr_en && ( addr_w == 8'h18);
	assign chn_x_transfer_count_wr_en_o = cfg_wr_en && ( addr_w == 8'h20);
	assign chn_srctrans_wr_en_o = cfg_wr_en && ( addr_w == 8'h28);
	assign chn_destrans_wr_en_o = cfg_wr_en && ( addr_w == 8'h2c);
	assign chn_xaddrinc_wr_en_o = cfg_wr_en && ( addr_w == 8'h30);
	assign chn_fillval_wr_en_o = cfg_wr_en && ( addr_w == 8'h38);
	assign chn_srctrigin_wr_en_o = cfg_wr_en && ( addr_w == 8'h4c);
	assign chn_destrigin_wr_en_o = cfg_wr_en &&( addr_w == 8'h50) ;
	assign chn_trigout_wr_en_o = cfg_wr_en && ( addr_w == 8'h54);
	assign chn_autocfg_wr_en_o = cfg_wr_en && (addr_w == 8'h74);
	assign chn_next_cmd_addr_wr_en_o = cfg_wr_en && ( addr_w == 8'h78);
	assign chn_work_reg_pointer_wr_en_o =  cfg_wr_en && ( addr_w == 8'h8C);
	assign chn_srctmplt_wr_en_o = cfg_wr_en && ( addr_w == 8'h44);
	assign chn_destmplt_wr_en_o = cfg_wr_en && ( addr_w == 8'h48);
	assign chn_tmpltcfg_wr_en_o = cfg_wr_en && ( addr_w == 8'h40);
	assign chn_yaddrestride_wr_en_o = cfg_wr_en && ( addr_w == 8'h34);
	assign chn_y_transfer_count_wr_en_o = cfg_wr_en && ( addr_w == 8'h3C);

	assign cfg_data_out = (cfg_rd_en) ? reg_mem[addr_w] : cfg_data_out_reg ;//'d0
	
	always @(posedge clk or negedge resetn)
	begin
	  if(!resetn) begin
	   for(i=0;i<DEPTH;i=i+1)
		reg_mem [i] <= {WIDTH{1'b0}};                       
	   
		cfg_data_out_reg <= 0;
	   end
	   
	  else 
	   begin
		
		cfg_data_out_reg <= cfg_data_out;
	   if(cfg_wr_en)
	   begin
		if (! (addr_w == 'h80 || addr_w == 'h8C || addr_w == 'h90 ))
				if((!(reg_mem [0][0]))|| addr_w == 'h0 || addr_w == 'h4 || addr_w == 'h88)
					reg_mem [addr_w] <= cfg_data_in;
	   end
	   else
	   begin
		{reg_mem[0],reg_mem[4] , reg_mem[12],reg_mem[40] , reg_mem[44],reg_mem[48] ,reg_mem[56],reg_mem[64] ,reg_mem[68] ,reg_mem[72] ,reg_mem[76] ,
						  reg_mem[80],reg_mem[84] ,reg_mem[116],reg_mem[120], reg_mem[144], reg_mem[52],reg_mem[60]} <= chn_reg_in;
		{reg_mem [16] , reg_mem[24],reg_mem [32]} <=src_des_x_transfer_count_updated;
		reg_mem[140] <= wrkregval_rd; 
		end
	   end
	end
endmodule 
