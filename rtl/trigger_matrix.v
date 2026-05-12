module trigger_matrix (

    input clk, resetn,
    // form internal register  
    input [2:0]STAT_ERR,
	
	
	// from peripherals
    // External Trigger INPUTS (from peripherals)
    input  wire [5:0]      trig_req,
    input  wire [11:0]  trig_req_type,
    output wire  [5:0]   trig_ack,
    output wire  [11:0]  trig_ack_type,
    // External Trigger OUTPUTS (to peripherals)
    output reg   [5:0]  trig_out_req,
    input  wire  [5:0]  trig_out_ack,
	
	
	//from channels
    // From read_trigger_cfg 
    input  wire [2:0]   use_src_trigin,
    input  wire [5:0]  src_trigin_type,   // 2'b10 = HW
    input  wire [23:0]  src_trigin_sel,    // 0 = trig0, 1 = trig1  for peripheral 1 and 2 respectively
    // From write_trigger_cfg
    input  wire [2:0]  use_des_trigin,
    input  wire [5:0]  des_trigin_type,   // 2'b10 = HW
    input  wire [23:0]  des_trigin_sel,    // 0 = trig0, 1 = trig1
    // From trigger_out_cfg
    input  wire [2:0]  use_trigout,
    input  wire [5:0]  trigout_type,       // 2'b10 = HW
    input  wire [17:0]  trigout_sel,        // 0 = trig0, 1 = trig1
    // To DMA Channel (REQ view)
    output reg  [2:0]   src_trig_req,
    output reg  [5:0]  src_trig_req_type,
    output reg   [2:0]  des_trig_req,
    output reg  [5:0]  des_trig_req_type,
    // From DMA Channel (ACK decisions)
    input  wire  [2:0]   ch_src_ack,
    input  wire [5:0]  ch_src_ack_type,
    input  wire  [2:0]  ch_des_ack,
    input  wire [5:0]  ch_des_ack_type,
    // From DMA Channel (Trigger OUT request)
    input  wire  [2:0]  ch_trigout_req,
    // To DMA Channel (Trigger OUT ACK)
    output reg    [2:0]  ch_trigout_ack,
    output reg [2:0] SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR
);

wire [7:0]src_sel[2:0] ;
wire [1:0] src_type [2:0];
wire [7:0]des_sel[2:0] ;
wire [5:0] trigout_sel1 [2:0];
wire [1:0] des_type [2:0];
integer i, j, k,m,p;
integer ch,cn;
reg trig_in_use [0:255];
reg [1:0] trig_allocated_to [0:255];
reg trig_out_use [0:255];
reg [1:0] trigout_allocated_to [0:255];
reg [1:0] trig_ack_type1 [0:255];
reg [255:0]trig_ack1 ;

assign trig_ack = trig_ack1;
assign trig_ack_type = {trig_ack_type1[5],trig_ack_type1[4],trig_ack_type1[3],trig_ack_type1[2],trig_ack_type1[1],trig_ack_type1[0]};
assign src_sel[0] = src_trigin_sel[7:0];
assign src_sel[1] = src_trigin_sel[15:8];
assign src_sel[2] = src_trigin_sel[23:16];

assign src_type[0] = src_trigin_type[1:0];
assign src_type[1] = src_trigin_type[3:2];
assign src_type[2] = src_trigin_type[5:4];

assign des_sel[0] = des_trigin_sel[7:0];
assign des_sel[1] = des_trigin_sel[15:8];
assign des_sel[2] = des_trigin_sel[23:16];

assign trigout_sel1[0] = trigout_sel[5:0];
assign trigout_sel1[1] = trigout_sel[11:6];
assign trigout_sel1[2] = trigout_sel[17:12];

assign des_type[0] = des_trigin_type[1:0];
assign des_type[1] = des_trigin_type[3:2];
assign des_type[2] = des_trigin_type[5:4];

always @(posedge clk or negedge resetn) begin
if(!resetn) begin
    SRCTRIGINSELERR <= 0;
    DESTRIGINSELERR <= 0;
    for(j=0;j<256;j=j+1) begin
        trig_in_use[j] <= 0;
        trig_allocated_to[j] <= 0;
    end 
end 

else begin
    for(ch=0; ch<3; ch=ch+1) begin
		if(use_src_trigin[ch] && src_type[ch] == 2'b10)
		begin
			if(src_sel[ch] >= 6)
				SRCTRIGINSELERR[ch] <= 1'b1;

			else if(trig_in_use[src_sel[ch]] && trig_allocated_to[src_sel[ch]] != ch)
				SRCTRIGINSELERR[ch] <= 1'b1;

			else begin
				trig_in_use[src_sel[ch]] <= 1'b1;
				trig_allocated_to[src_sel[ch]] <= ch;
			end
		end
		
		if(use_des_trigin[ch] && des_type[ch] == 2'b10)
		begin
            if(des_sel[ch] >= 6)
                DESTRIGINSELERR[ch] <= 1'b1;
            else if(trig_in_use[des_sel[ch]] &&	trig_allocated_to[des_sel[ch]] != ch)
                DESTRIGINSELERR[ch] <= 1'b1;
            else begin
                trig_in_use[des_sel[ch]] <= 1'b1;
                trig_allocated_to[des_sel[ch]] <= ch;
                end
		end
		if(use_src_trigin[ch] && use_des_trigin[ch] && src_type[ch] == 2'b10 && des_type[ch] == 2'b10 && src_sel[ch] == des_sel[ch])
		begin
			SRCTRIGINSELERR[ch] <= 1'b1;
			DESTRIGINSELERR[ch] <= 1'b1;
		end
    end
    end
end 


always @(posedge clk or negedge resetn) begin
if(!resetn) begin
    src_trig_req      <= 0;
    src_trig_req_type <= 0;
	des_trig_req <= 0;
	des_trig_req_type <= 0;
	trig_ack1 <= 0;
	for(p=0;p<256;p=p+1) begin
		trig_ack_type1[p] <= 0;
	end
end
else begin
	
	for(i=0; i<3; i=i+1) begin
		if ( !SRCTRIGINSELERR[i]) begin
		case(src_sel[i] )
			0: begin
				src_trig_req[i] <= trig_req[0];
				src_trig_req_type[(2*i)+:2] <= trig_req_type[1:0];
				trig_ack1[src_sel[i]] <= ch_src_ack[i];
				trig_ack_type1[src_sel[i]] <= ch_src_ack_type[(2*i)+:2];
			end

			1: begin
				src_trig_req[i] <= trig_req[1];
				src_trig_req_type[(2*i)+:2] <= trig_req_type[3:2];
				trig_ack1[src_sel[i]] <= ch_src_ack[i];
				trig_ack_type1[src_sel[i]] <= ch_src_ack_type[(2*i)+:2];
			end

			2: begin
				src_trig_req[i] <= trig_req[2];
				src_trig_req_type[(2*i)+:2] <= trig_req_type[5:4];
				trig_ack1[src_sel[i]] <= ch_src_ack[i];
				trig_ack_type1[src_sel[i]] <= ch_src_ack_type[(2*i)+:2];
			end

			3: begin
				src_trig_req[i] <= trig_req[3];
				src_trig_req_type[(2*i)+:2] <= trig_req_type[7:6];
				trig_ack1[src_sel[i]] <= ch_src_ack[i];
				trig_ack_type1[src_sel[i]] <= ch_src_ack_type[(2*i)+:2];
			end

			4: begin
				src_trig_req[i] <= trig_req[4];
				src_trig_req_type[(2*i)+:2] <= trig_req_type[9:8];
				trig_ack1[src_sel[i]] <= ch_src_ack[i];
				trig_ack_type1[src_sel[i]] <= ch_src_ack_type[(2*i)+:2];
			end

			5: begin
				src_trig_req[i] <= trig_req[5];
				src_trig_req_type[(2*i)+:2] <= trig_req_type[11:10];
				trig_ack1[src_sel[i]] <= ch_src_ack[i];
				trig_ack_type1[src_sel[i]] <= ch_src_ack_type[(2*i)+:2];
			end

			default: begin
				src_trig_req[i] <= 1'b0;
				src_trig_req_type[(2*i)+:2] <= 2'b00;
				trig_ack1[src_sel[i]] <= 1'b0;
				trig_ack_type1[src_sel[i]] <= 2'b00;
			end
		endcase
		end
		if(!DESTRIGINSELERR[i]) begin
		case(des_sel[i])

    0: begin
        des_trig_req[i] <= trig_req[0];
        des_trig_req_type[(2*i)+:2] <= trig_req_type[1:0];
        trig_ack1[des_sel[i]] <= ch_des_ack[i];
        trig_ack_type1[des_sel[i]] <= ch_des_ack_type[(2*i)+:2];
    end

    1: begin
        des_trig_req[i] <= trig_req[1];
        des_trig_req_type[(2*i)+:2] <= trig_req_type[3:2];
        trig_ack1[des_sel[i]] <= ch_des_ack[i];
        trig_ack_type1[des_sel[i]] <= ch_des_ack_type[(2*i)+:2];
    end

    2: begin
        des_trig_req[i] <= trig_req[2];
        des_trig_req_type[(2*i)+:2] <= trig_req_type[5:4];
        trig_ack1[des_sel[i]] <= ch_des_ack[i];
        trig_ack_type1[des_sel[i]] <= ch_des_ack_type[(2*i)+:2];
    end

    3: begin
        des_trig_req[i] <= trig_req[3];
        des_trig_req_type[(2*i)+:2] <= trig_req_type[7:6];
        trig_ack1[des_sel[i]] <= ch_des_ack[i];
        trig_ack_type1[des_sel[i]] <= ch_des_ack_type[(2*i)+:2];
    end

    4: begin
        des_trig_req[i] <= trig_req[4];
        des_trig_req_type[(2*i)+:2] <= trig_req_type[9:8];
        trig_ack1[des_sel[i]] <= ch_des_ack[i];
        trig_ack_type1[des_sel[i]] <= ch_des_ack_type[(2*i)+:2];
    end

    5: begin
        des_trig_req[i] <= trig_req[5];
        des_trig_req_type[(2*i)+:2] <= trig_req_type[11:10];
        trig_ack1[des_sel[i]] <= ch_des_ack[i];
        trig_ack_type1[des_sel[i]] <= ch_des_ack_type[(2*i)+:2];
    end

    default: begin
        des_trig_req[i] <= 1'b0;
        des_trig_req_type[(2*i)+:2] <= 2'b00;
        trig_ack1[des_sel[i]] <= 1'b0;
        trig_ack_type1[des_sel[i]] <= 2'b00;
    end

endcase
		end
	end
end
end
	
always@(posedge clk or negedge resetn) begin
    if (!resetn) begin
	TRIGOUTSELERR <= 0;
	for(k=0;k<256;k=k+1) begin
		trig_out_use[k] <= 0;
		trigout_allocated_to[k] <= 0;
	end
	end
	else begin
	for(cn=0; cn<3; cn=cn+1) begin
		if(use_trigout[cn] && trigout_type[(2 * cn) +: 2 ]  == 2'b10)
		begin
			if(trigout_sel1[cn ] >= 6)
				TRIGOUTSELERR[cn] <= 1'b1;

			else if(trig_out_use[trigout_sel1[cn]] && trigout_allocated_to[trigout_sel1[cn]] != cn)
				TRIGOUTSELERR[cn] <= 1'b1;

			else begin
				trig_out_use[trigout_sel1[cn]] <= 1'b1;
				trigout_allocated_to[trigout_sel1[cn]] <= cn;
			end
		end
	end
end
end

always @(posedge clk or negedge resetn) begin
if(!resetn) begin
    //for(k=0;k<6;k=k+1) 
    trig_out_req     <= 0;
    ch_trigout_ack <= 0;
end
else begin
	for(m=0; m<3; m=m+1) begin
		if( !TRIGOUTSELERR[m]) begin
		case(trigout_sel1[m] )

			0: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= ch_trigout_req[m];
				ch_trigout_ack[m] <= trig_out_ack[1:0];
			end

			1: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= ch_trigout_req[m];
				ch_trigout_ack[m] <= trig_out_ack[3:2];
			end

			2: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= ch_trigout_req[m];
				ch_trigout_ack[m] <= trig_out_ack[5:4];
			end
			3: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= ch_trigout_req[m];
				ch_trigout_ack[m] <= trig_out_ack[7:6];
			end

			4: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= ch_trigout_req[m];
				ch_trigout_ack[m] <= trig_out_ack[9:8];
			end

			5: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= ch_trigout_req[m];
				ch_trigout_ack[m] <= trig_out_ack[11:10];
			end
			default: begin
				trig_out_req[trigout_sel1[m][2:0]]      <= 0;
				ch_trigout_ack[m] <= 0;
			end
		endcase
		end
	end
end
end

endmodule
