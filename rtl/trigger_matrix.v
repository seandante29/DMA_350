module trigger_matrix (
    // form internal register  
    input STAT_ERR,
    // External Trigger INPUTS (from peripherals)
    input  wire        trig0_req,
    output reg         trig0_ack,
    input  wire        trig1_req,
    output reg         trig1_ack,
    // External Trigger OUTPUTS (to peripherals)
    output reg         trig0_out_req,
    input  wire        trig0_out_ack,
    output reg         trig1_out_req,
    input  wire        trig1_out_ack,
    // From CH_SRCTRIGINCFG
    input  wire        use_src_trigin,
    input  wire [1:0]  src_trigin_type,   // 2'b10 = HW
    input  wire [7:0]  src_trigin_sel,    // 0 = trig0, 1 = trig1  for peripheral 1 and 2 respectively
    // From CH_DESTRIGINCFG
    input  wire        use_des_trigin,
    input  wire [1:0]  des_trigin_type,   // 2'b10 = HW
    input  wire [7:0]  des_trigin_sel,    // 0 = trig0, 1 = trig1
    // From CH_TRIGOUTCFG
    input  wire        use_trigout,
    input  wire [1:0]  trigout_type,       // 2'b10 = HW
    input  wire [5:0]  trigout_sel,        // 0 = trig0, 1 = trig1
    // To DMA Channel (REQ view)
    output reg         src_trig_req,
    output reg         des_trig_req,
    // From DMA Channel (ACK decisions)
    input  wire        ch_src_ack,
    input  wire        ch_des_ack,
    // From DMA Channel (Trigger OUT request)
    input  wire        ch_trigout_req,
    // To DMA Channel (Trigger OUT ACK)
    output reg         ch_trigout_ack,
    output reg SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR
);

    always @(*) begin
        src_trig_req      = 1'b0;
        des_trig_req      = 1'b0;
        trig0_ack         = 1'b0;
        trig1_ack         = 1'b0;
        trig0_out_req     = 1'b0;
        trig1_out_req     = 1'b0;
        ch_trigout_ack      = 1'b0;
        if(!STAT_ERR) begin
            SRCTRIGINSELERR = 1'b0;
            DESTRIGINSELERR = 1'b0;
            TRIGOUTSELERR   = 1'b0;
        end
        
        // Source trigger select error
        if (use_src_trigin && src_trigin_type == 2'b10 && src_trigin_sel > 1)
            SRCTRIGINSELERR = 1'b1;
        
        // Destination trigger select error
        if (use_des_trigin && des_trigin_type == 2'b10 && des_trigin_sel > 1)
            DESTRIGINSELERR = 1'b1;
        
        // Trigger OUT select error
        if (use_trigout && trigout_type == 2'b10 && trigout_sel > 1)
            TRIGOUTSELERR = 1'b1;
        
        //  same trigger for src & des
        if (use_src_trigin && use_des_trigin && src_trigin_type == 2'b10 && des_trigin_type == 2'b10 &&
                                                                            src_trigin_sel == des_trigin_sel)
        begin
            SRCTRIGINSELERR = 1'b1;
            DESTRIGINSELERR = 1'b1;
        end
        
        
        // SOURCE trigger routing
        if (use_src_trigin && src_trigin_type == 2'b10 && !SRCTRIGINSELERR) begin
            if (src_trigin_sel == 'b0) begin
                src_trig_req      = trig0_req;
                trig0_ack         = ch_src_ack;
            end
            else if (src_trigin_sel == 'b1) begin
                src_trig_req      = trig1_req;
                trig1_ack         = ch_src_ack;
            end
        end
        
        // DESTINATION trigger routing
        if (use_des_trigin && des_trigin_type == 2'b10 && !DESTRIGINSELERR) begin
            if (des_trigin_sel == 'b0) begin
                des_trig_req      = trig0_req;
                trig0_ack         = ch_des_ack;
            end
            else if (des_trigin_sel == 'b1) begin
                des_trig_req      = trig1_req;
                trig1_ack         = ch_des_ack;
            end
        end
        // TRIGGER OUT routing (DMA → Peripheral)
        if (use_trigout && ch_trigout_req && trigout_type == 2'b10 && !TRIGOUTSELERR) begin
            if (trigout_sel == 1'b0) begin
                trig0_out_req       = 1'b1;
                ch_trigout_ack      = trig0_out_ack;
            end
            else begin
                trig1_out_req       = 1'b1;
                ch_trigout_ack      = trig1_out_ack;
        end
        end
    end
    
endmodule
 
