module Counter
(
    input clk,
    input res,
    input pl,
    
    input encnt,
    input inc,
    input dec,

    input cin, // counter in e negat
    input [7: 0] di,

    output reg con, // counter out e negat
    output reg [7: 0] do
);

    always @(posedge clk) begin
        con <= 1;

        if (res)
            do <= 0;

        else if (pl)
            do <= di;
        
              else if (encnt & ~ cin)
        	if (inc) begin
              if (do==8'b11111111)
        			con <= 0;
        		
            	do <= do + 1;
            	
            end
        	else if (dec) begin
              if (do==8'b00000000)
        			con <= 0;
            	do <= do - 1;
            end
    end

endmodule // Counter

module Mux1_2
(
    input sel,

    input [7: 0] di0,
    input [7: 0] di1,

    output [7: 0] do
);

    assign do = sel ? di1 : di0;

endmodule // Mux1_2

module Mux1_3 
(
    input [1: 0] sel,

    input [7: 0] di0,
    input [7: 0] di1,
    input [7: 0] di2,

    output [7: 0] do
);

      assign do = sel[0] ? di1 : 
        sel[1] ? di2 : di0;

endmodule // Mux1_3

module Register8b 
(
    input clk,
    input pl,
    
    input [7: 0] di,
    output reg [7: 0] do
);

    always @(posedge clk)
        if (pl)
            do <= di;

endmodule // Register8b
              
module Register3b
(
    input clk,
    input pl,
    
    input [2: 0] di,
    output reg [2: 0] do
);

    always @(posedge clk)
        if (pl)
            do <= di;

endmodule // Register3b


module TransferCompleteCircuitry
(
    input [7: 0] doac,
    input [7: 0] dowc,
    input [7: 0] dowr,
    
    input [1: 0] mode,
    input cinwc,

    output reg done
);

    always @(dowc or dowr or doac or cinwc or mode)
        casex ({mode, cinwc})
            'b00_0: done <= dowc == 1;
            'b00_1: done <= ~| dowc;
            'b01_0: done <= dowc + 1 == dowr;
            'b01_1: done <= dowc == dowr;
            'b10_x: done <= dowc == doac;
            'b11_x: done <= 1'b0;
        endcase

endmodule // TransferCompleteCircuitry


module InstructionDecoder (
    input [2 : 0] instruction,
    input [2: 0] control,
	
    output plar, // parallel load address reg
    output plwcr, // parallel load word count reg
    output plcr, // parallel load control reg
    
    output sela, // select address
    output selw, // select word count
    output [1: 0] seld, // select data
    
    output resac, // reset address counter
    output plac, // parallel load address counter
    output enac, // enable count address counter
    output incac, // increment address counter
    output decac, // decrement address counter

    output reswc, // reset word counter
    output plwc, // parallel load word counter
    output enwc, // enable count word counter
    output incwc, // increment word counter
    output decwc // decrement word counter
);

    wire [1: 0] mode;
    
    assign mode = control[1: 0];

	// REGS
    assign plar = instruction == 5;
    assign plwcr = instruction == 6;
    assign plcr = instruction == 0;
    
    // MUXS
    assign sela = instruction == 4;
    assign selw = instruction == 4;
    assign seld = instruction[1: 0] - 1;
    
    // ADDR CNT
    assign resac = 0;
    assign plac = instruction[2: 1] == 'b10;
    assign enac = instruction == 7;
    assign incac = ~ control[2];
    assign decac = control[2];
    
    // WORD CNT
    assign reswc = instruction == 4 & mode == 1
    				| instruction == 6 & mode == 1;
    assign plwc = instruction[2] & ~ instruction[0];
    assign enwc = instruction == 7 & mode != 2;
    assign incwc = mode[0];
    assign decwc = mode == 0;

endmodule // InstructionDecoder

              
module AM2940 (
    input clk,
    input oena, // output enable neg address
    
    input cinac, // carry in neg address counter
    input cinwc, // carry in neg word counter
     
    input [2: 0] instruction,
    
    inout [7: 0] data,
     
    output [7: 0] output_address,
    
    output conac, // carry out neg address counter
    output conwc, // carry out neg word counter
    
    output done
);
    
    wire [7: 0] address;
    wire [7: 0] dowr;//output word register
    wire [2: 0] control;

    wire [7: 0] sel_address; // selected address
    wire [7: 0] sel_word_cnt; // selected word counter
    
    wire [7: 0] doaddr;//output address counter
    wire [7: 0] dowc;//output word counter
    
    wire plar; // parallel load address reg
    wire plwcr; // parallel load word count reg
    wire plcr; // parallel load control reg
    
    wire sela; // select address
    wire selw; // select word count
    wire [1: 0] seld; // select data
    
    wire resac; // reset address counter
    wire plac; // parallel load address counter
    wire enac; // enable count address counter
    wire incac; // increment address counter
    wire decac; // decrement address counter

    wire reswc; // reset word count counter
    wire plwc; // parallel load word counter
    wire enwc; // enable count word counter
    wire incwc; // increment word counter
    wire decwc; // decrement word counter
    
    wire oed;
    wire oend;
    wire [7: 0] sel_data;
    wire [7: 0] next_data;
    
    
    assign oed = instruction == 1
    				| instruction == 2
    				| instruction == 3;
  
    assign data = oed ? sel_data : 'hZZ;
    
    assign oend = instruction == 0
    				| instruction == 5
    				| instruction == 6;
    				
    assign next_data = oend ? data: sel_data;
    
	assign output_address = oena ? 'hZZ : doaddr;

	// MODULES
	InstructionDecoder InstructionDecoder (
		.instruction(instruction),
		.control(control),
		// OUTPUTS
		.plar(plar),
		.plwcr(plwcr),
		.plcr(plcr),
		.sela(sela),
		.selw(selw),
		.seld(seld),
		.resac(resac),
		.plac(plac),
		.enac(enac),
		.incac(incac),
		.decac(decac),
		.reswc(reswc),
		.plwc(plwc),
		.enwc(enwc),
		.incwc(incwc),
		.decwc(decwc)
	);
	
    Register8b AddressRegister (
        .clk(clk),
        .pl(plar),
        .di(next_data),
        // OUTPUT
        .do(address)
    );

    Register8b WordCountRegister (
        .clk(clk),
        .pl(plwcr),
        .di(next_data),
        // OUTPUT
        .do(dowr)
    );

    Register3b ControlRegister (
        .clk(clk),
        .pl(plcr),
        .di(next_data[2:0]),
        // OUTPUT
        .do(control)
    );

    Mux1_2 AddressMux (
        .sel(sela),
        .di0(next_data),
        .di1(address),
        // OUTPUT
        .do(sel_address)
    );

    Mux1_2 WordCountMux (
        .sel(selw),
        .di0(next_data),
        .di1(dowr),
        // OUTPUT
        .do(sel_word_cnt)
    );

    Mux1_3 DataMux (
        .sel(seld),
        .di0({5'b11111, control}),
        .di1(dowc),
        .di2(doaddr),
        // OUTPUT
        .do(sel_data)
    );

    Counter AddressCounter (
        .clk(clk),
        .res(resac),
        .pl(plac),
        .encnt(enac),
        .inc(incac),
        .dec(decac),
        .cin(cinac),
        .di(sel_address),
        // OUTPUTS
        .con(conac),
        .do(doaddr)
    );

    Counter WordCounter (
        .clk(clk),
        .res(reswc),
        .pl(plwc),
        .encnt(enwc),
        .inc(incwc),
        .dec(decwc),
        .cin(cinwc),
        .di(sel_word_cnt),
        // OUTPUTS
        .con(conwc),
        .do(dowc)
    );
    
    TransferCompleteCircuitry TransferCompleteCircuitry (
        .doac(doaddr),
        .dowc(dowc),
        .dowr(dowr),
    	.mode(control[1: 0]),
    	.cinwc(cinwc),
    	// OUTPUT
    	.done(done)
    );

endmodule // AM2940