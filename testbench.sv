module TestBench;
    reg clk;
	wire oed;
	reg oena;
	reg cinac;
	reg cinwc;
    reg [2: 0] instruction;
    reg [7: 0] load_data;
    wire [7: 0] data;
    wire [7: 0] output_address;
	wire conac;
	wire conwc;
	wire done;
    
    AM2940 AM2940(
        .clk(clk),
        .oena(oena),
        .cinac(cinac),
        .cinwc(cinwc),
        .instruction(instruction),
        // INOUT
        .data(data),
        // OUTPUTS
        .output_address(output_address),
        .conac(conac),
        .conwc(conwc),
        .done(done)
    );


    initial begin
        clk <= 0;
        forever #10 clk = ~clk;
    end
    
    assign oed = instruction == 0
    				| instruction == 5
    				| instruction == 6;
    				
    assign data = oed ? load_data : 'hZZ;
   
    
    initial begin
    	oena <= 1;
    	cinac <= 0;
    	cinwc <= 0;
    	
    	// 0 -> control
    	instruction <= 0;
    	load_data <= 0;
    	
    	#10
    	// citeste control
    	instruction <= 1;
    	
    	#20
    	// 9 -> wc, wcr
    	instruction <= 6;
    	load_data <= 9;
    	
    	#20
    	// 1 -> ac, ar
    	instruction <= 5;
    	load_data <= 1;
       	
       	#20
       	// citeste word counter
       	instruction <= 2;
       	
       	#20
       	// citeste address counter
       	instruction <= 3;
    	
    	#20
    	// enable counters
    	instruction <= 7;
    	oena <= 0;
    	
    	// de la 1 la 9 si semnaleaza done odata cu 9
      
       	#180
    	// 1 -> control
    	instruction <= 0;
    	load_data <= 1;
       	oena <= 1;

	    #20
    	// 9 -> wc, wcr
    	instruction <= 6;
    	load_data <= 9;
      	
    	#20
    	// F -> ac, ar
    	instruction <= 5;
    	load_data <= 'hf;
       
      
    	#20
    	// enable counters
    	instruction <= 7;
    	oena <= 0;
    	
    	#180
       	// 5 -> control
       	instruction <= 0;
    	load_data <= 5;
       	oena <= 1;
	
	    #20 
       	// reinitializare counters
       	instruction <= 4;
       
    	
    	#20
        // enable counters
    	instruction <= 7;
    	oena <= 0;
    	
    	#180
    	// 2 -> control
       	instruction <= 0;
    	load_data <= 2;
       	oena <= 1;
       	
       	#20
       	// FE -> address counter
       	instruction <= 5;
       	load_data <= 'hfe;
       	
       	#20
       	// 2 -> word counter
       	instruction <= 6;
       	load_data <= 2;
    	
    	#20
        // enable counters
    	instruction <= 7;
    	oena <= 0;
    	
    	#100
    	// 7 -> control
       	instruction <= 0;
    	load_data <= 7;
       	oena <= 1;
       	
       	#20
       	// F1 -> address counter
       	instruction <= 5;
       	load_data <= 'hf1;
       	
       	#20
       	// F8 -> word counter
       	instruction <= 6;
       	load_data <= 'hF8;
    	
    	#20
       // enable counters
    	instruction <= 7;
    	oena <= 0;
    	
    	#180
    	instruction <= 0;
    	load_data <= 1;
    	oena <= 1;
    	
    end

    initial begin
        $dumpfile("TestBench.vcd");
        $dumpvars(0, TestBench);
        
        #1800
        $finish;
    end
endmodule // TestBench
