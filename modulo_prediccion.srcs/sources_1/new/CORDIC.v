// Módulo para cálculo de seno y coseno con algoritmo CORDIC
// las 
// Tiene mucho pipeline, podria relajar los paths y reducir los registros (o hacerlo iterativo y usar slo una iteracion para todas).
// TODO: Revisar las operaciones (tema fraccionarios y tal)
// TODO: Verificar que funcione correctamente.

`define K_n 8'd155  // = 0.6072529350088814  8.8

module CORDIC_sincosin
  #(
    NB_INPUT   = 8,
    NBF_INPUT  = 8,
    NB_OUTPUT  = 9,
    NBF_OUTPUT = 8,
    ITERATIONS = 8
    )
   (
    input [NB_INPUT-1:0]         	  i_tita, //(U8.6) 0 - 2 pi

    input 		                      i_clock,

    output reg signed [NB_OUTPUT-1:0] o_sin, // (S8.7) signado
    output reg signed [NB_OUTPUT-1:0] o_cosin// (S8.7) signado
    );
    
   integer jj;

   wire [1:0] cuadrante = i_tita[NB_INPUT-1-:2]; // Obtenemos el cuadrante
   reg [1:0] cuadrante_d[ITERATIONS-1:0]; // delay para sincronizar con la salida
   always @(posedge i_clock)
   begin
     cuadrante_d[0] <= cuadrante;
     for ( jj = 1; jj < ITERATIONS; jj=jj+1 )
       cuadrante_d[jj] <= cuadrante_d[jj-1];
   end

   // Tabla Arcotangente (podria ser un archivo e incluirlo)
   wire [8-1:0] atan_lut [8-1:0];

   // 8.11
   assign atan_lut[0] = 8'd255; // = atan 2^0     = 0.7853981633974483   45°    U8.8
   assign atan_lut[1] = 8'd150; // = atan 2^(-1)  = 0.4636476090008061   26.57°
   assign atan_lut[2] = 8'd79 ; // = atan 2^(-2)  = 0.24497866312686414  14.04°
   assign atan_lut[3] = 8'd40 ; // = atan 2^(-3)  = 0.12435499454676144  7.125° 
   assign atan_lut[4] = 8'd20 ; // = atan 2^(-4)  = 0.06241880999595735  3.57°
   assign atan_lut[5] = 8'd10  ; // = atan 2^(-5)  = 0.031239833430268277 1.79°
   assign atan_lut[6] = 8'd5  ; // = atan 2^(-6)  = 0.015623728620476831 0.89°
   assign atan_lut[7] = 8'd2  ; // = atan 2^(-7)  = 0.007812341060101111 0.44°

   reg [NB_INPUT-1:0] x_n [ITERATIONS-1:0]; //U8.8
   reg [NB_INPUT-1:0] y_n [ITERATIONS-1:0]; //U8.8
   reg signed [NB_INPUT:0] z_n [ITERATIONS-1:0]; //S11.8
   
   // Primera Iteracion (proyectamos todo a y=0, inicializamos x_0 con 1/a_n)
   always @(posedge i_clock)
     begin
	   x_n[0] <= `K_n; // 8.8 
	   y_n[0] <= 0;
	   z_n[0] <= {2'b00,i_tita[NB_INPUT-3:0]};
     end
   
   // Etapas del Algoritmo de CORDIC (formula de x_{i+1},y_{i+1},z_{i+1})

   wire [NB_INPUT-1:0] X_rot [ITERATIONS-2:0]; // S9.8
   wire [NB_INPUT-1:0] Y_rot [ITERATIONS-2:0]; // S9.8
    
   genvar 			  ii;
   generate
      for ( ii = 0; ii < ITERATIONS-1; ii=ii+1)
	   begin:rotaciones
	       wire                       d_i;
	   
	       assign X_rot[ii] = x_n[ii] >> ii; // Desplazamiento a la derecha
	       assign Y_rot[ii] = y_n[ii] >> ii;
	   
	       assign d_i = z_n[ii][NB_INPUT]; // Signo de z

           wire signed [NB_INPUT:0] y_n_full; 
           wire signed [NB_INPUT:0] x_n_full; 
           assign y_n_full = d_i ? y_n[ii] - X_rot[ii] : y_n[ii] + X_rot[ii];
           assign x_n_full = d_i ? x_n[ii] + Y_rot[ii] : x_n[ii] - Y_rot[ii];

	       always @ ( posedge i_clock )
	       begin
		      // Sumar o restar según el signo
		      x_n[ii+1] <= x_n_full[NB_INPUT] ? 0 : x_n_full[NB_INPUT-1:0];
		      y_n[ii+1] <= y_n_full[NB_INPUT] ? 0 : y_n_full[NB_INPUT-1:0];
		      z_n[ii+1] <= d_i ? z_n[ii] + (atan_lut[ii]>>3) : z_n[ii] - (atan_lut[ii]>>3);
	       end
	   end
   endgenerate

   // Acomodar los cuadrantes
   // Mapeo: 0   - pi/2   || cos = cos  / sen = sen
   //      pi/2  - pi     || cos = -sen / sen = cos
   //      pi    - 3/2 pi || cos = -cos / sen = -sen 
   //      3/2pi - 2pi    || cos = sen  / sen = -cos
   
    always @(*)
    begin
        if ( cuadrante_d[ITERATIONS-1] == 0 )
        begin
          o_cosin = x_n[ITERATIONS-1];
          o_sin   = y_n[ITERATIONS-1];
        end
        else if ( cuadrante_d[ITERATIONS-1] == 1 )
        begin
          o_cosin = -y_n[ITERATIONS-1];
          o_sin   = x_n[ITERATIONS-1];
        end
        else if ( cuadrante_d[ITERATIONS-1] == 2 )
        begin
          o_cosin = -x_n[ITERATIONS-1];
          o_sin   = -y_n[ITERATIONS-1];
        end
        else if ( cuadrante_d[ITERATIONS-1] == 3 )
        begin
          o_cosin = y_n[ITERATIONS-1];
          o_sin   = -x_n[ITERATIONS-1];
        end
    end
   
   
   
   
   endmodule
