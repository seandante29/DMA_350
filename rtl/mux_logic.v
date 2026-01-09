module mux_logic #(parameter WIDTH = 32)
	(
	input wire [31:0] cmd_data,
	input wire clk,resetn,
	input wire link_en,
	input wire [5:0] wptr,//input from cmd fsm
	input wire [31:0] header_in,
	//previous data
	input  wire [31:0] CH_CTRL,
	input  wire [31:0] CH_INTREN,
    input  wire [31:0] CH_XSIZE,
    input  wire [31:0] CH_LINKADDR,
    input  wire [31:0] CH_XADDRINC,
	input  wire [31:0] CH_SRCTRANSCFG,
	input  wire [31:0] CH_DESTRANSCFG,
    input  wire [31:0] CH_SRCTRIGINCFG,
    input  wire [31:0] CH_DESTRIGINCFG,
    input  wire [31:0] CH_TRIGOUTCFG,
    input  wire [31:0] CH_SRCADDR,
    input  wire [31:0] CH_DESADDR,
    input  wire [31:0] CH_FILLVAL,
	//reg bank input
	input wire [(WIDTH * 14) -1:0] reg_bank_in,

	// internal reg
	//output wire LINKHDERR,
	output wire [(WIDTH * 14) -1:0] mux_out_reg
	);
	
	reg [31:0] cmd_data_mem [0:31];

	reg [1023:0] cmd_data_in;
	
	wire [31:0] HEADER_CMD = header_in;
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
	wire REGCLEAR = header_in[0];
	
	wire [(WIDTH * 13) -1:0] concat_cmd;
	reg [5:0] rd_ptr;
	
	integer i;
	
	mux m0 (CH_CTRL,DEFAULT_VALUE,CH_CTRL_CMD,REGCLEAR,HEADER_CMD[3],concat_cmd[(WIDTH*2)-1:(WIDTH*1)]);
	mux m1 (CH_INTREN,DEFAULT_VALUE,CH_INTREN_CMD,REGCLEAR,HEADER_CMD[2],concat_cmd[(WIDTH*1)-1:0]);
	mux m2 (CH_SRCADDR,DEFAULT_VALUE,CH_SRCADDR_CMD,REGCLEAR,HEADER_CMD[4],concat_cmd[(WIDTH*3)-1:(WIDTH*2)]);
	mux m3 (CH_DESADDR,DEFAULT_VALUE,CH_DESADDR_CMD,REGCLEAR,HEADER_CMD[6],concat_cmd[(WIDTH*4)-1:(WIDTH*3)]);
	mux m4 (CH_XSIZE,DEFAULT_VALUE,CH_XSIZE_CMD,REGCLEAR,HEADER_CMD[8],concat_cmd[(WIDTH*5)-1:(WIDTH*4)]);
	mux m5 (CH_SRCTRANSCFG,DEFAULT_VALUE,CH_SRCTRANSCFG_CMD,REGCLEAR,HEADER_CMD[10],concat_cmd[(WIDTH*6)-1:(WIDTH*5)]);
	mux m6 (CH_DESTRANSCFG,DEFAULT_VALUE,CH_DESTRANSCFG_CMD,REGCLEAR,HEADER_CMD[11],concat_cmd[(WIDTH*7)-1:(WIDTH*6)]);
	mux m7 (CH_XADDRINC,DEFAULT_VALUE,CH_XADDRINC_CMD,REGCLEAR,HEADER_CMD[12],concat_cmd[(WIDTH*8)-1:(WIDTH*7)]);
	mux m8 (CH_FILLVAL,DEFAULT_VALUE,CH_FILLVAL_CMD,REGCLEAR,HEADER_CMD[14],concat_cmd[(WIDTH*9)-1:(WIDTH*8)]);
	mux m9 (CH_SRCTRIGINCFG,DEFAULT_VALUE,CH_SRCTRIGINCFG_CMD,REGCLEAR,HEADER_CMD[19],concat_cmd[(WIDTH*10)-1:(WIDTH*9)]);
	mux m10 (CH_DESTRIGINCFG,DEFAULT_VALUE,CH_DESTRIGINCFG_CMD,REGCLEAR,HEADER_CMD[20],concat_cmd[(WIDTH*11)-1:(WIDTH*10)]);
	mux m11 (CH_TRIGOUTCFG,DEFAULT_VALUE,CH_TRIGOUTCFG_CMD,REGCLEAR,HEADER_CMD[21],concat_cmd[(WIDTH*12)-1:(WIDTH*11)]);
	mux m12 (CH_LINKADDR,DEFAULT_VALUE,CH_LINKADDR_CMD,REGCLEAR,HEADER_CMD[30],concat_cmd[(WIDTH*13)-1:(WIDTH*12)]);
	
	always @(posedge clk or negedge resetn)
	begin
		cmd_data_mem [wptr] <= cmd_data; 
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
		else if(i==31)
		rd_ptr = 1;
		else
		rd_ptr = rd_ptr;
	
	end
	
	//assign LINKHDERR = !(|(HEADER_CMD));
	assign mux_out_reg = (link_en) ? {concat_cmd,reg_bank_in[31:0]} : reg_bank_in;
	
	endmodule
	
