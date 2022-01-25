`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2021 02:05:26 PM
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench
#(
    NB_MOD=8,
    NB_POS=8,
    NB_FASE=8,
    NB_CONST=8,
    X_MAX=100,
    Y_MAX=100
);
    
    reg clock;
    reg reset;
    reg start;
    reg [NB_MOD-1:0]modulo;
    reg [NB_FASE-1:0]fase;
    
    initial
      clock = 0;
  
    always
       #2 clock = ~clock;
       
    initial
        #2000 $finish;
     
    initial 
        #50 modulo=8'd5;
    
    //giros 
    //2pi=11111111 
    //pi=10000000 
    //pi/2=01000000 
    //pi/4=00100000
    //#4 fase=8'b11100000;  //7pi/4 
    initial
    begin
        //mov inicial de fase=0
        fase=8'b00100000; //pi/4
        #54 fase=8'b00000000;     //0
        #4 fase=8'b11100000;    //7pi/4
        #4 fase=8'b00100000; //pi/4 
        #4 fase=8'b00100000; //pi/4 
        #4 fase=8'b00100000; //pi/4 
        #4 fase=8'b11100000;    //7pi/4 
        #4 fase=8'b11100000;    //7pi/4
        #4 fase=8'b11100000;    //7pi/4 
        #4 fase=8'b11100000;    //7pi/4 
        #4 fase=8'b00100000; //pi/4 
        #4 fase=8'b00100000; //pi/4 
        #4 fase=8'b00000000;     //0
        #4 fase=8'b00000000;     //0
    end
        
    
    //always 
     // #4 fase=(fase+1); 
    
        
    initial
    begin
        reset = 1;
        #50 reset = 0;
    end
    
    always
    begin
        #5 start = 0;
        #60 start= 1;
    end
    
    predict_stage
    u_predict_stage(.i_clock(clock),
                  .i_reset(reset),
                  .i_modulo(modulo),
                  .i_fase(fase),
                  .o_orientacion(),
                  .o_x(),
                  .o_y()
                  );
             
    
endmodule
