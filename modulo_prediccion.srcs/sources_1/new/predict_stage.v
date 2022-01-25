`timescale 1ns / 1ps

module predict_stage
    #(
      NB_MOD   =   8,
      NB_POS   =   8,
      NB_FASE  =   8,
      NB_O_CORDIC =   9,
      X_MAX    = 100,
      Y_MAX    = 100,
      X_INICIAL=  50,
      Y_INICIAL=  50,
      LATENCIA =   8
    )
    (
      input                    i_clock,
      input                    i_reset,
      input [NB_MOD-1:0]       i_modulo,
      input [NB_FASE-1:0]      i_fase,
      output reg [NB_FASE-1:0] o_orientacion, //(8.8) en radianes de 0 a 1, normalizado de 0 a 2pi
      output reg [NB_POS-1:0]  o_x,
      output reg [NB_POS-1:0]  o_y
    );
    //CAMBios
    wire [NB_FASE:0] orientacion_sum;
    assign orientacion_sum = (o_orientacion+i_fase); // FIXME

    always@(posedge i_clock)
    begin
        if(i_reset)
          o_orientacion <= 0;
        else
          o_orientacion <= orientacion_sum;
    end

    

    reg [NB_MOD-1:0] modulo_d [LATENCIA-1:0];
    reg               reset_d [LATENCIA-1:0];

    integer i;
    always @(posedge i_clock)
    begin
        modulo_d [0] <= i_modulo;
        reset_d [0] <= i_reset;
        for (i = 1; i < LATENCIA; i=i+1)
        begin
          modulo_d[i] <= modulo_d[i-1];
          reset_d[i] <= reset_d[i-1];
        end
    end

    //instanciar modulo CORDIC
    //entrada -> orientation 
    //salida -> coseno y seno

    wire signed [NB_O_CORDIC-1:0] coseno; 
    wire signed [NB_O_CORDIC-1:0] seno;   

    CORDIC_sincosin
        u_CORDIC_sincosin(.i_clock ( i_clock       ),
                          .i_tita  ( o_orientacion ),
                          .o_cosin ( coseno        ),
                          .o_sin   ( seno          ));

    //coseno,seno (S9.8) signado
    //modulo (8.0) no signado
    //x_mul,y_mul (17.8) signado
    
    wire signed [NB_MOD+NB_O_CORDIC-1:0] x_mul;
    wire signed [NB_MOD+NB_O_CORDIC-1:0] y_mul;

    assign x_mul = $signed(modulo_d[LATENCIA-1])*coseno;
    assign y_mul = $signed(modulo_d[LATENCIA-1])*seno;

    //x_sum,y_sum (10.0) signado
    wire signed [NB_POS+1:0] x_sum;
    wire signed [NB_POS+1:0] y_sum;
   
    assign x_sum = $signed(o_x) + $signed(x_mul[NB_MOD+NB_O_CORDIC-1-:NB_POS+1]);
    assign y_sum = $signed(o_y) + $signed(y_mul[NB_MOD+NB_O_CORDIC-1-:NB_POS+1]);

    always@(posedge i_clock)
    begin
      if(reset_d[LATENCIA-1])
      begin
        o_x<=X_INICIAL;
        o_y<=Y_INICIAL;
      end
      else
      begin
        if(x_sum < 0)
          o_x<=0;
        else if(x_sum > X_MAX)
          o_x<=X_MAX;
        else
          o_x<=x_sum; //asigna los LSB
            
        if(y_sum < 0)
          o_y<=0;
        else if(y_sum > Y_MAX)
          o_y<=Y_MAX;
        else
          o_y<=y_sum;
      end
    end
    
endmodule
