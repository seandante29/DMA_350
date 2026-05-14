module register_bank #(parameter WIDTH = 32,
    parameter ADDR_WIDTH = 32,
	parameter DEPTH = 256 ,
	parameter NUM_CH = 3)
	(input wire clk,
	input wire resetn,
	input wire [NUM_CH*(WIDTH*3)-1:0] src_des_x_transfer_count_updated,
	input wire cfg_rd_en,cfg_wr_en,//reg_wr_en,// write enable from apb to reg, 
	input wire [ WIDTH-1 : 0] cfg_data_in,//from apb to reg
	input wire [ADDR_WIDTH-1:0 ] addr_in,// from apb
	input  wire [NUM_CH*(WIDTH*18)-1:0] chn_reg_in,
	input  wire [NUM_CH*WIDTH-1:0]      wrkregval_rd,

	output wire [WIDTH-1:0] cfg_data_out,
	output wire [NUM_CH-1:0]       chn_wr_en,

	output wire [NUM_CH*WIDTH-1:0] cfg_channel_start,
	output wire [NUM_CH*WIDTH-1:0] cfg_channel_status,
	output wire [NUM_CH*WIDTH-1:0] cfg_interrupt_enable,
	output wire [NUM_CH*WIDTH-1:0] cfg_control_config,
	output wire [NUM_CH*WIDTH-1:0] cfg_read_base_addr,
	output wire [NUM_CH*WIDTH-1:0] cfg_write_base_addr,
	output wire [NUM_CH*WIDTH-1:0] cfg_x_transfer_count,
	output wire [NUM_CH*WIDTH-1:0] cfg_read_transfer_cfg,
	output wire [NUM_CH*WIDTH-1:0] cfg_write_transfer_cfg,
	output wire [NUM_CH*WIDTH-1:0] cfg_addr_increment_cfg,
	output wire [NUM_CH*WIDTH-1:0] cfg_fill_data,
	output wire [NUM_CH*WIDTH-1:0] cfg_read_trigger_cfg,
	output wire [NUM_CH*WIDTH-1:0] cfg_write_trigger_cfg,
	output wire [NUM_CH*WIDTH-1:0] cfg_trigger_out_cfg,
	output wire [NUM_CH*WIDTH-1:0] cfg_auto_restart_config,
	output wire [NUM_CH*WIDTH-1:0] cfg_next_cmd_addr,
	output wire [NUM_CH*WIDTH-1:0] cfg_work_reg_pointer,
	output wire [NUM_CH*WIDTH-1:0] cfg_line_stride,
	output wire [NUM_CH*WIDTH-1:0] cfg_y_transfer_count,
	output wire [NUM_CH*32-1:0] cfg_read_template_data ,
	output wire [NUM_CH*32-1:0] cfg_write_template_data,
	output wire [NUM_CH*32-1:0] cfg_template_config,
	output wire [NUM_CH-1:0] chn_cmd_wr_en_o,
	output wire [NUM_CH-1:0] chn_stat_wr_en_o,
	output wire [NUM_CH-1:0] chn_intren_wr_en_o,
	output wire [NUM_CH-1:0] chn_ctrl_wr_en_o,
	output wire [NUM_CH-1:0] chn_read_base_addr_wr_en_o,
	output wire [NUM_CH-1:0] chn_write_base_addr_wr_en_o,
	output wire [NUM_CH-1:0] chn_x_transfer_count_wr_en_o,
	output wire [NUM_CH-1:0] chn_srctrans_wr_en_o,
	output wire [NUM_CH-1:0] chn_destrans_wr_en_o,
	output wire [NUM_CH-1:0] chn_xaddrinc_wr_en_o,
	output wire [NUM_CH-1:0] chn_fillval_wr_en_o,
	output wire [NUM_CH-1:0] chn_srctrigin_wr_en_o,
	output wire [NUM_CH-1:0] chn_destrigin_wr_en_o,
	output wire [NUM_CH-1:0] chn_trigout_wr_en_o,
	output wire [NUM_CH-1:0] chn_autocfg_wr_en_o,
	output wire [NUM_CH-1:0] chn_next_cmd_addr_wr_en_o,
	output wire [NUM_CH-1:0] chn_work_reg_pointer_wr_en_o,
	output wire [NUM_CH-1:0] chn_tmpltcfg_wr_en_o,
	output wire [NUM_CH-1:0] chn_destmplt_wr_en_o,
	output wire [NUM_CH-1:0] chn_srctmplt_wr_en_o,
	output wire [NUM_CH-1:0] chn_yaddrestride_wr_en_o,
	output wire [NUM_CH-1:0] chn_y_transfer_count_wr_en_o
	);
	reg [WIDTH-1:0] reg_mem [0:DEPTH* NUM_CH-1];

wire [$clog2(NUM_CH)-1:0] ch_idx;
wire [7:0] addr_w;
wire [$clog2(NUM_CH*DEPTH)-1:0] addr_idx;

assign ch_idx   = (addr_in - 32'h1000) >> 8;
assign addr_w   = (addr_in & 32'hFF);
assign addr_idx = ch_idx*DEPTH + addr_w;

assign cfg_channel_start      = {reg_mem[2*DEPTH + 8'h00], reg_mem[1*DEPTH + 8'h00], reg_mem[0*DEPTH + 8'h00]};
assign cfg_channel_status   = {reg_mem[2*DEPTH + 8'h04], reg_mem[1*DEPTH + 8'h04], reg_mem[0*DEPTH + 8'h04]};
assign cfg_interrupt_enable   = {reg_mem[2*DEPTH + 8'h08], reg_mem[1*DEPTH + 8'h08], reg_mem[0*DEPTH + 8'h08]};
assign cfg_control_config     = {reg_mem[2*DEPTH + 8'h0C], reg_mem[1*DEPTH + 8'h0C], reg_mem[0*DEPTH + 8'h0C]};
assign cfg_read_base_addr  = {reg_mem[2*DEPTH + 8'h10], reg_mem[1*DEPTH + 8'h10], reg_mem[0*DEPTH + 8'h10]};
assign cfg_write_base_addr  = {reg_mem[2*DEPTH + 8'h18], reg_mem[1*DEPTH + 8'h18], reg_mem[0*DEPTH + 8'h18]};
assign cfg_x_transfer_count    = {reg_mem[2*DEPTH + 8'h20], reg_mem[1*DEPTH + 8'h20], reg_mem[0*DEPTH + 8'h20]};
assign cfg_read_transfer_cfg = {reg_mem[2*DEPTH + 8'h28], reg_mem[1*DEPTH + 8'h28], reg_mem[0*DEPTH + 8'h28]};
assign cfg_write_transfer_cfg = {reg_mem[2*DEPTH + 8'h2C], reg_mem[1*DEPTH + 8'h2C], reg_mem[0*DEPTH + 8'h2C]};
assign cfg_addr_increment_cfg = {reg_mem[2*DEPTH + 8'h30], reg_mem[1*DEPTH + 8'h30], reg_mem[0*DEPTH + 8'h30]};
assign cfg_line_stride = {reg_mem[2*DEPTH + 8'h34], reg_mem[1*DEPTH + 8'h34], reg_mem[0*DEPTH + 8'h34]};
assign cfg_fill_data  = {reg_mem[2*DEPTH + 8'h38], reg_mem[1*DEPTH + 8'h38], reg_mem[0*DEPTH + 8'h38]};
assign cfg_y_transfer_count    = {reg_mem[2*DEPTH + 8'h3C], reg_mem[1*DEPTH + 8'h3C], reg_mem[0*DEPTH + 8'h3C]};
assign cfg_template_config = {reg_mem[2*DEPTH + 8'h40], reg_mem[1*DEPTH + 8'h40], reg_mem[0*DEPTH + 8'h40]};
assign cfg_read_template_data  = {reg_mem[2*DEPTH + 8'h44], reg_mem[1*DEPTH + 8'h44], reg_mem[0*DEPTH + 8'h44]};
assign cfg_write_template_data = {reg_mem[2*DEPTH + 8'h48], reg_mem[1*DEPTH + 8'h48], reg_mem[0*DEPTH + 8'h48]};
assign cfg_read_trigger_cfg = {reg_mem[2*DEPTH + 8'h4C], reg_mem[1*DEPTH + 8'h4C], reg_mem[0*DEPTH + 8'h4C]};
assign cfg_write_trigger_cfg = {reg_mem[2*DEPTH + 8'h50], reg_mem[1*DEPTH + 8'h50], reg_mem[0*DEPTH + 8'h50]};
assign cfg_trigger_out_cfg   = {reg_mem[2*DEPTH + 8'h54], reg_mem[1*DEPTH + 8'h54], reg_mem[0*DEPTH + 8'h54]};
assign cfg_auto_restart_config = {reg_mem[2*DEPTH + 8'h74], reg_mem[1*DEPTH + 8'h74], reg_mem[0*DEPTH + 8'h74]};
assign cfg_next_cmd_addr   = {reg_mem[2*DEPTH + 8'h78], reg_mem[1*DEPTH + 8'h78], reg_mem[0*DEPTH + 8'h78]};
assign cfg_work_reg_pointer  = {reg_mem[2*DEPTH + 8'h8C], reg_mem[1*DEPTH + 8'h8C], reg_mem[0*DEPTH + 8'h8C]};

assign chn_cmd_wr_en_o       = (cfg_wr_en && (addr_w == 8'h00)) << ch_idx;
assign chn_stat_wr_en_o      = (cfg_wr_en && (addr_w == 8'h04)) << ch_idx;
assign chn_intren_wr_en_o    = (cfg_wr_en && (addr_w == 8'h08)) << ch_idx;
assign chn_ctrl_wr_en_o      = (cfg_wr_en && (addr_w == 8'h0C)) << ch_idx;

assign chn_read_base_addr_wr_en_o    = (cfg_wr_en && (addr_w == 8'h10)) << ch_idx;
assign chn_write_base_addr_wr_en_o   = (cfg_wr_en && (addr_w == 8'h18)) << ch_idx;

assign chn_x_transfer_count_wr_en_o  = (cfg_wr_en && (addr_w == 8'h20)) << ch_idx;

assign chn_srctrans_wr_en_o          = (cfg_wr_en && (addr_w == 8'h28)) << ch_idx;
assign chn_destrans_wr_en_o          = (cfg_wr_en && (addr_w == 8'h2C)) << ch_idx;

assign chn_xaddrinc_wr_en_o          = (cfg_wr_en && (addr_w == 8'h30)) << ch_idx;
assign chn_yaddrestride_wr_en_o      = (cfg_wr_en && (addr_w == 8'h34)) << ch_idx;

assign chn_fillval_wr_en_o           = (cfg_wr_en && (addr_w == 8'h38)) << ch_idx;
assign chn_y_transfer_count_wr_en_o  = (cfg_wr_en && (addr_w == 8'h3C)) << ch_idx;

assign chn_tmpltcfg_wr_en_o          = (cfg_wr_en && (addr_w == 8'h40)) << ch_idx;
assign chn_srctmplt_wr_en_o          = (cfg_wr_en && (addr_w == 8'h44)) << ch_idx;
assign chn_destmplt_wr_en_o          = (cfg_wr_en && (addr_w == 8'h48)) << ch_idx;

assign chn_srctrigin_wr_en_o         = (cfg_wr_en && (addr_w == 8'h4C)) << ch_idx;
assign chn_destrigin_wr_en_o         = (cfg_wr_en && (addr_w == 8'h50)) << ch_idx;
assign chn_trigout_wr_en_o           = (cfg_wr_en && (addr_w == 8'h54)) << ch_idx;

assign chn_autocfg_wr_en_o           = (cfg_wr_en && (addr_w == 8'h74)) << ch_idx;
assign chn_next_cmd_addr_wr_en_o     = (cfg_wr_en && (addr_w == 8'h78)) << ch_idx;

assign chn_work_reg_pointer_wr_en_o  = (cfg_wr_en && (addr_w == 8'h8C)) << ch_idx;

assign cfg_data_out = (cfg_rd_en) ? reg_mem[addr_idx] : {WIDTH{1'b0}};

integer i;

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        for (i = 0; i < NUM_CH*DEPTH; i = i + 1)
            reg_mem[i] <= {WIDTH{1'b0}};
    end
    else begin
        if (cfg_wr_en) begin
            if (!(addr_w == 8'h80 || addr_w == 8'h8C || addr_w == 8'h90))
                if ((!reg_mem[ch_idx*DEPTH][0]) || addr_w == 8'h00 || addr_w == 8'h04 || addr_w == 8'h88)
                    reg_mem[addr_idx] <= cfg_data_in;
        end
        else begin
            reg_mem[ch_idx*DEPTH + 8'h00] <= chn_reg_in[((18*ch_idx)+17)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h04] <= chn_reg_in[((18*ch_idx)+16)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h0C] <= chn_reg_in[((18*ch_idx)+15)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h28] <= chn_reg_in[((18*ch_idx)+14)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h2C] <= chn_reg_in[((18*ch_idx)+13)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h30] <= chn_reg_in[((18*ch_idx)+12)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h38] <= chn_reg_in[((18*ch_idx)+11)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h40] <= chn_reg_in[((18*ch_idx)+10)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h44] <= chn_reg_in[((18*ch_idx)+9)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h48] <= chn_reg_in[((18*ch_idx)+8)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h4C] <= chn_reg_in[((18*ch_idx)+7)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h50] <= chn_reg_in[((18*ch_idx)+6)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h54] <= chn_reg_in[((18*ch_idx)+5)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h74] <= chn_reg_in[((18*ch_idx)+4)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h78] <= chn_reg_in[((18*ch_idx)+3)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h90] <= chn_reg_in[((18*ch_idx)+2)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h34] <= chn_reg_in[((18*ch_idx)+1)*WIDTH +: WIDTH];
            reg_mem[ch_idx*DEPTH + 8'h3C] <= chn_reg_in[(18*ch_idx)*WIDTH +: WIDTH];

            {reg_mem[ch_idx*DEPTH + 8'h10],
             reg_mem[ch_idx*DEPTH + 8'h18],
             reg_mem[ch_idx*DEPTH + 8'h20]}
             <= src_des_x_transfer_count_updated;

            reg_mem[ch_idx*DEPTH + 8'h8C] <= wrkregval_rd;
        end
    end
end
endmodule 
