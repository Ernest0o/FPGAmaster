`timescale 1ns / 1ps


module NucleoEjecucion(
        input logic [7:0] n, m, // índices de fila y columna
        input logic [16:0] rn_lambda, // rn sobre lambda
        input logic [16:0] c, f, h, // subproductos
        input logic [1:0] selDM, //selector del demultiplexor
        input logic [2:0] ba, // Número de bits del arreglo
        input logic clkPS, // Reloj de entrada para puertos seriales+
        input logic clkMC,
        input logic enclkE1, enclkE2, // relojes etapas
        input logic rst, // reset puertos seriales
        input logic enPS1, enPS2, enPS3, //señal de activación para puertos seriales
        input logic enclkPS1reg, enclkPS2reg, enclkPS3reg,        
        input logic [1:0] sw, 
        output logic clkPS1, clkPS2, clkPS3, // Relojes de salida para puertos seriales
        output logic outPS1, outPS2, outPS3, // bits de salida de los puertos seriales
        output logic sPS1, sPS2, sPS3, // Señales de finalización de puertos seriales
        output logic [4:0] Pout // Bus de salida para monitoreo
      
    );
    
logic [4:0] Pcod; //fase codificada     


//logic [7:0] n, m;
//logic [16:0] rn_lambda;
//logic [16:0] c, f, h;

//logic [4:0] Pcod;


//always_ff @(posedge clk) begin
//    n <= nc; m <= mc;
//    rn_lambda <= rn_lambdac;
//    c <= cc; f <= fc; h <= hc;
//    Pcodreg <= Pcod;
//end


logic [16:0] n_c, m_f, Y, rn_lambdareg; 

Etapa1NucEjec E1(
    .n(n), .m(m),
    .c(c), .f(f), .h(h), .rn_lambda(rn_lambda),
    .enclkE1(enclkE1), .rst(rst),
    .n_creg(n_c), .m_freg(m_f), .Yreg(Y), .rn_lambdareg(rn_lambdareg), .clkMC(clkMC)
);

logic [16:0] Pcoef, Pcpos;

Etapa2NucEjec E2(
    .n_c(n_c), .m_f(m_f), 
    .Y(Y), .rn_lambda(rn_lambdareg),
    .enclkE2(enclkE2),
    .Pcoefreg(Pcoef), 
    .clkMC(clkMC),
    .Pcposreg(Pcpos)
);

Etapa3NucEjec E3(
    .Pcoef(Pcoef),
    .Pcpos(Pcpos),
    .ba(ba),
    .Pcod(Pcod)
);

logic [4:0] inPS1, inPS2, inPS3; //salida del demux
//logic [4:0] inPS1reg, inPS2reg, inPS3reg; //salida del demux registrada
// lógica del demultiplexor
assign inPS1 = Pcod;
assign inPS2 = Pcod;
assign inPS3 = Pcod;

//always_comb begin
//    case(selDM)
//        2'b00: begin
//            inPS1 = Pcod;
//            inPS2 = 5'b10101;
//            inPS3 = 5'b10101;
//        end
//        2'b01: begin
//            inPS1 = 5'b10101;
//            inPS2 = Pcod;
//            inPS3 = 5'b10101;        
//        end
//        2'b10: begin
//            inPS1 = 5'b10101;
//            inPS2 = 5'b10101;
//            inPS3 = Pcod;         
//        end
//        2'b11: begin
//            inPS1 = 5'b10101;
//            inPS2 = 5'b10101;
//            inPS3 = 5'b10101;         
//        end
//     endcase
//end

// lógica de registros última etapa
//always_ff @(posedge clkPS1reg) begin
//    inPS1reg <= inPS1;
//end

//always_ff @(posedge clkPS2reg) begin
//    inPS2reg <= inPS2;
//end

//always_ff @(posedge clkPS3reg) begin
//    inPS3reg <= inPS3;
//end

// importación puertos seriales

logic [4:0] inPS1reg, inPS2reg, inPS3reg;
PuertoSerial PS1 (
    .enPS(enPS1), .clk(clkPS), .rst(rst),
    .inPS(inPS1),
    .enclkPSreg(enclkPS1reg),
    .ba(ba),
    .clkPS(clkPS1),
    .outPS(outPS1),
    .sPS(sPS1),
    .inPSreg(inPS1reg)
);

PuertoSerial PS2 (
    .enPS(enPS2), .clk(clkPS), .rst(rst),
    .inPS(inPS2),
    .enclkPSreg(enclkPS2reg),
    .ba(ba),
    .clkPS(clkPS2),
    .outPS(outPS2),
    .sPS(sPS2),
    .inPSreg(inPS2reg)
);

PuertoSerial PS3 (
    .enPS(enPS3), .clk(clkPS), .rst(rst),
    .inPS(inPS3),
    .enclkPSreg(enclkPS3reg),
    .ba(ba),
    .clkPS(clkPS3),
    .outPS(outPS3),
    .sPS(sPS3),
    .inPSreg(inPS3reg)
);

always_comb begin
    case(sw)
        2'd0: 
            Pout = Pcod;
        2'd1:
            Pout = inPS1reg;
        2'd2:
            Pout = inPS2reg;
        2'd3:
            Pout = inPS3reg;    
     endcase    
end


endmodule

