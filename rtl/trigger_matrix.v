module trigger_matrix_new (
    // form internal register  
    input [2:0]STAT_ERR,
	
	
	// from peripherals
    // External Trigger INPUTS (from peripherals)
    input  wire [5:0]      trig_req,
    input  wire [11:0]  trig_req_type,
    output reg  [5:0]   trig_ack,
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
reg trig_in_use [0:5];
reg [1:0] trig_allocated_to [0:5];
reg trig_out_use [0:5];
reg [1:0] trigout_allocated_to [0:5];
reg [1:0] trig_ack_type1 [0:5];

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
//function [2:0] onehot8_to_bin;
//    input [7:0] val;
//    begin
//        case (val)
//            8'b00000001: onehot8_to_bin = 3'd0;
//            8'b00000010: onehot8_to_bin = 3'd1;
//            8'b00000100: onehot8_to_bin = 3'd2;
//            8'b00001000: onehot8_to_bin = 3'd3;
//            8'b00010000: onehot8_to_bin = 3'd4;
//            8'b00100000: onehot8_to_bin = 3'd5;
//            8'b01000000: onehot8_to_bin = 3'd6;
//            8'b10000000: onehot8_to_bin = 3'd7;
//            default:     onehot8_to_bin = 3'd0;
//        endcase
//    end
//endfunction

//function [2:0] onehot6_to_bin;
//    input [5:0] val;
//    begin
//        case (val)
//            6'b000001: onehot6_to_bin = 3'd0;
//            6'b000010: onehot6_to_bin = 3'd1;
//            6'b000100: onehot6_to_bin = 3'd2;
//            6'b001000: onehot6_to_bin = 3'd3;
//            6'b010000: onehot6_to_bin = 3'd4;
//            6'b100000: onehot6_to_bin = 3'd5;
//            default:   onehot6_to_bin = 3'd0;
//        endcase
//    end
//endfunction

//assign src_sel[0] = onehot8_to_bin(src_trigin_sel[7:0]);
//assign src_sel[1] = onehot8_to_bin(src_trigin_sel[15:8]);
//assign src_sel[2] = onehot8_to_bin(src_trigin_sel[23:16]);

//assign des_sel[0] = onehot8_to_bin(des_trigin_sel[7:0]);
//assign des_sel[1] = onehot8_to_bin(des_trigin_sel[15:8]);
//assign des_sel[2] = onehot8_to_bin(des_trigin_sel[23:16]);

//assign trigout_sel1[0] = onehot6_to_bin(trigout_sel[5:0]);
//assign trigout_sel1[1] = onehot6_to_bin(trigout_sel[11:6]);
//assign trigout_sel1[2] = onehot6_to_bin(trigout_sel[17:12]);

//assign src_type[0] = src_trigin_type[1:0];
//assign src_type[1] = src_trigin_type[3:2];
//assign src_type[2] = src_trigin_type[5:4];

//assign des_type[0] = des_trigin_type[1:0];
//assign des_type[1] = des_trigin_type[3:2];
//assign des_type[2] = des_trigin_type[5:4];

always @(*) begin
	SRCTRIGINSELERR = 0;
	DESTRIGINSELERR = 0;
	for(j=0;j<6;j=j+1) begin
		trig_in_use[j] = 0;
		trig_allocated_to[j] = 0;
	end
	for(ch=0; ch<3; ch=ch+1) begin
		if(use_src_trigin[ch] && src_type[ch] == 2'b10)
		begin
			if(src_sel[ch] >= 6)
				SRCTRIGINSELERR[ch] = 1'b1;

			else if(trig_in_use[src_sel[ch]] && trig_allocated_to[src_sel[ch]] != ch)
				SRCTRIGINSELERR[ch] = 1'b1;

			else begin
				trig_in_use[src_sel[ch]] = 1'b1;
				trig_allocated_to[src_sel[ch]] = ch;
			end
		end
		
		if(use_des_trigin[ch] && des_type[ch] == 2'b10)
		begin
            if(des_sel[ch] >= 6)
                DESTRIGINSELERR[ch] = 1'b1;
            else if(trig_in_use[des_sel[ch]] &&	trig_allocated_to[des_sel[ch]] != ch)
                DESTRIGINSELERR[ch] = 1'b1;
            else begin
                trig_in_use[des_sel[ch]] = 1'b1;
                trig_allocated_to[des_sel[ch]] = ch;
                end
		end
		if(use_src_trigin[ch] && use_des_trigin[ch] && src_type[ch] == 2'b10 && des_type[ch] == 2'b10 && src_sel[ch] == des_sel[ch])
		begin
			SRCTRIGINSELERR[ch] = 1'b1;
			DESTRIGINSELERR[ch] = 1'b1;
		end
    end
end 


always @(*) begin

    src_trig_req      = 0;
    src_trig_req_type = 0;
	des_trig_req = 0;
	des_trig_req_type = 0;
	trig_ack = 0;
	for(p=0;p<6;p=p+1) begin
		trig_ack_type1[p] = 0;
	end
	for(i=0; i<3; i=i+1) begin
		case(src_sel[i] & !SRCTRIGINSELERR[i])

			0: begin
				src_trig_req[i]      = trig_req[0];
				src_trig_req_type[(2 * i) +: 2 ] = trig_req_type[1:0];
				trig_ack[src_sel[i]] = ch_src_ack [0];
				trig_ack_type1[src_sel[i]] = ch_src_ack_type [1:0];
			end

			1: begin
				src_trig_req[i]      = trig_req[1];
				src_trig_req_type[(2 * i) +: 2 ] = trig_req_type[3:2];
				trig_ack[src_sel[i]] = ch_src_ack [1];
				trig_ack_type1[src_sel[i]] = ch_src_ack_type [3:2];
			end

			2: begin
				src_trig_req[i]      = trig_req[2];
				src_trig_req_type[(2 * i) +: 2 ] = trig_req_type[5:4];
				trig_ack[src_sel[i]] = ch_src_ack [2];
				trig_ack_type1[src_sel[i]] = ch_src_ack_type [5:4];
			end
		endcase
		case(des_sel[i] & !DESTRIGINSELERR[i])

			0: begin
				des_trig_req[i]      = trig_req[0];
				des_trig_req_type[(2 * i) +: 2 ] = trig_req_type[1:0];
				trig_ack[des_sel[i]] = ch_des_ack [0];
				trig_ack_type1[des_sel[i]] = ch_des_ack_type [1:0];
			end

			1: begin
				des_trig_req[i]      = trig_req[1];
				des_trig_req_type[(2 * i) +: 2 ] = trig_req_type[3:2];
				trig_ack[des_sel[i]] = ch_des_ack [1];
				trig_ack_type1[des_sel[i]] = ch_des_ack_type [3:2];
			end

			2: begin
				des_trig_req[i]      = trig_req[2];
				des_trig_req_type[(2 * i) +: 2 ] = trig_req_type[5:4];
				trig_ack[des_sel[i]] = ch_des_ack [2];
				trig_ack_type1[des_sel[i]] = ch_des_ack_type [5:4];
			
			end
		endcase
	end
end
	
always@(*) begin
	TRIGOUTSELERR = 0;
	for(k=0;k<6;k=k+1) begin
		trig_out_use[k] = 0;
		trigout_allocated_to[k] = 0;
	end
	for(cn=0; cn<3; cn=cn+1) begin
		if(use_trigout[cn] && trigout_type[(2 * cn) +: 2 ]  == 2'b10)
		begin
			if(trigout_sel1[cn ] >= 6)
				TRIGOUTSELERR[cn] = 1'b1;

			else if(trig_in_use[trigout_sel1[trigout_sel1[cn]]] && trig_allocated_to[trigout_sel1[cn]] != cn)
				TRIGOUTSELERR[cn] = 1'b1;

			else begin
				trig_out_use[trigout_sel1[cn]] = 1'b1;
				trigout_allocated_to[trigout_sel1[cn]] = cn;
			end
		end
	end
end

always @(*) begin

    trig_out_req      = 0;
    ch_trigout_ack = 0;
	for(m=0; m<3; m=m+1) begin
		case(trigout_sel1[m] & !TRIGOUTSELERR[m])

			0: begin
				trig_out_req[m]      = ch_trigout_req[0];
				ch_trigout_ack[m] = trig_out_ack[1:0];
			end

			1: begin
				trig_out_req[m]      = ch_trigout_req[1];
				ch_trigout_ack[m] = trig_out_ack[3:2];
			end

			2: begin
				trig_out_req[m]      = ch_trigout_req[2];
				ch_trigout_ack[m] = trig_out_ack[5:4];
			end
		endcase
	end
end

endmodule
