module mux_logic_tb();

    parameter WIDTH = 32;
	reg [31:0] cmd_data;
	reg clk,resetn;
	reg link_en;
	reg [31:0] header_in;
	reg  [7:0] wptr;//input from cmd fsm
	//previous data
	reg [31:0] CH_CTRL;
	reg [31:0] CH_INTREN;
   reg [31:0] CH_XSIZE;
    reg [31:0] CH_LINKADDR;
    reg [31:0] CH_XADDRINC;
	reg [31:0] CH_SRCTRANSCFG;
	reg [31:0] CH_DESTRANSCFG;
    reg [31:0] CH_SRCTRIGINCFG;
    reg [31:0] CH_DESTRIGINCFG;
    reg [31:0] CH_TRIGOUTCFG;
    reg [31:0] CH_SRCADDR;
    reg [31:0] CH_DESADDR;
    reg [31:0] CH_FILLVAL;
	//reg bank input
	reg [(WIDTH * 14) -1:0] reg_bank_in;

	// internal reg
	wire LINKHDERR;
	wire [(WIDTH * 14) -1:0] mux_out_reg;
	
	mux_logic dut ( .clk(clk),.resetn(resetn),
	                            .cmd_data(cmd_data),
	                            .link_en(link_en),
	                            .wptr(wptr),
	                            .header_in(header_in),
	                            .CH_CTRL(CH_CTRL),
	                            .CH_INTREN(CH_INTREN),
	                            .CH_XSIZE(CH_XSIZE),
	                            .CH_LINKADDR(CH_LINKADDR),
	                            .CH_XADDRINC(CH_XADDRINC),
	                            .CH_SRCTRANSCFG(CH_SRCTRANSCFG),
	                            .CH_DESTRANSCFG(CH_DESTRANSCFG),
	                            .CH_SRCTRIGINCFG(CH_SRCTRIGINCFG),
	                            .CH_DESTRIGINCFG(CH_DESTRIGINCFG),
	                            .CH_TRIGOUTCFG(CH_TRIGOUTCFG),
	                            .CH_SRCADDR(CH_SRCADDR),
	                            .CH_DESADDR(CH_DESADDR),
	                            .CH_FILLVAL(CH_FILLVAL),
	                            .reg_bank_in(reg_bank_in),
	                            .LINKHDERR(LINKHDERR),
	                            .mux_out_reg(mux_out_reg)
	);
	
	always #5 clk = !clk;
	
	initial begin
	clk = 0;
	resetn = 0;
	#20
	 CH_CTRL = 32'd60;
	 CH_INTREN = 32'd70;
     CH_XSIZE = 32'd80;
     reg_bank_in = 'hAA_AA_AA_AA_BB_BB_BB_BB_CC_CC_CC_CC_CC ;
   	 resetn = 1;
	 link_en = 1;
	#10;
	header_in = 32'h40_38_5D_5D;// (0100 0000_0011 1000_0101 1101_0101 1101)
	wptr = 0;
	cmd_data = 32'd10;
	#10;
	wptr = 1;
	cmd_data = 32'd20;
	#10;
	wptr = 2;
	cmd_data = 32'd30;
		#10;
	wptr = 3;
	cmd_data = 32'd40;
		#10;
	wptr = 4;
	cmd_data = 32'd50;
		#10;
	wptr = 5;
	cmd_data = 32'd60;
		#10;
	wptr = 6;
	cmd_data = 32'd70;
		#10;
	wptr = 7;
	cmd_data = 32'd80;
		#10;
	wptr = 8;
	cmd_data = 32'd90;	
	#10;
	wptr = 9;
	cmd_data = 32'd100;
		#10;
	wptr = 10;
	cmd_data = 32'd110;
		#10;
	wptr = 11;
	cmd_data = 32'd120;
		#10;
	wptr = 12;
	cmd_data = 32'd130;
	
	
	#500
	
	$finish;
	end
	
endmodule

