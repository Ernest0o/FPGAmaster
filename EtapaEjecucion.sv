`timescale 1ns / 1ps
//parameter B = 32'h0008_0000;
//parameter d = 32'h0008_0000;
//parameter cosa = 32'h0000_9303; // coseno de alfa
//parameter sena = 32'h0000_D193; //seno de alfa
//parameter lambda_inv = 32'h0000_0A3F; //valor inverso de la longitud de onda
//parameter ba = 3'd5;
//parameter lenM = 6'd21;

//parameter phi0in = 19'h0_A551; //37°
//parameter teta0in = 19'h1_0C15; //60°
//parameter phi0in = 19'h0_0000; //0°
//parameter teta0in = 19'h0_0000; //0°

//parameter teta0in = 19'h0_4305; // 15°
//parameter phi0in = 19'h3_243F; // 180°

//parameter teta0in = 19'h0_860A; // 30°
//parameter phi0in = 19'h3_50ED; // 190°

module EtapaEjecucion(
        input logic [18:0] teta0in, phi0in, 
        input logic [31:0] d, cosa, sena,
        input logic [31:0] lambda_inv, B,
        //input logic [18:0] teta0in, phi0in,
        input logic [2:0] ba, // Número de bits del arreglo
        input logic [6:0] lenM, // 3 veces el número de elementos por esclavo
        input logic clkPS, clkMC, // Reloj de cien megas
        input logic rst, //reset maestro
        input logic sAO, sAOsw, sCfg, // Señal de ángulos de orientación y de configuración
        input logic [1:0] sw_Pout, //~~
        input logic [2:0] sw_nuc, 
        input logic [6:0] addr_mem,
        input logic [799:0] datomem,
        input logic clk_mem, startReor,
        output logic clkPS1, outPS1, clkRegDec,
        output logic clkPS2, outPS2, 
        output logic clkPS3, outPS3,
        output logic clkPS1reg,
        output logic [4:0] Pout,
        output logic [6:0] regdir = 0,        
        output logic clkMem,
        output logic clkRD,
        output logic rstRD,
        output logic flagEjec
    );


//logic clkMC;
logic [4:0] Pcod, inPS1reg;
//assign Pout = Pcod;
logic [4:0] Pout_1, Pout_2, Pout_3, Pout_4, Pout_5;

//Salidas para 5 núcleos
logic outPS1_1, outPS2_1, outPS3_1; 
logic outPS1_2, outPS2_2, outPS3_2;
logic outPS1_3, outPS2_3, outPS3_3;
logic outPS1_4, outPS2_4, outPS3_4;
logic outPS1_5, outPS2_5, outPS3_5;
// relojes para 5 núcleos
logic clkPS1_1, clkPS2_1, clkPS3_1; 
logic clkPS1_2, clkPS2_2, clkPS3_2;
logic clkPS1_3, clkPS2_3, clkPS3_3;
logic clkPS1_4, clkPS2_4, clkPS3_4;
logic clkPS1_5, clkPS2_5, clkPS3_5;
// señales de finalización 5 núcleos
logic sPS1_1, sPS2_1, sPS3_1;
logic sPS1_2, sPS2_2, sPS3_2;
logic sPS1_3, sPS2_3, sPS3_3;
logic sPS1_4, sPS2_4, sPS3_4;
logic sPS1_5, sPS2_5, sPS3_5;

logic [17:0] a, b, g;
logic [17:0] c, f, h; // Productos únicos

// para 5 núcleos
logic [7:0] n_1, m_1, n_2, m_2, n_3, m_3, n_4, m_4, n_5, m_5; // índices de fila y columna
logic [16:0] rn_lambda_1, rn_lambda_2, rn_lambda_3, rn_lambda_4, rn_lambda_5; //  rn/lambda

// concatenación bits dato memoria
assign n_1 = datomem[7:0];
assign m_1 = datomem[15:8];
assign rn_lambda_1 = {1'b0, datomem[31:16]};

assign n_2 = datomem[39:32];
assign m_2 = datomem[47:40];
assign rn_lambda_2 = {1'b0, datomem[63:48]};

assign n_3 = datomem[71:64];
assign m_3 = datomem[79:72];
assign rn_lambda_3 = {1'b0, datomem[95:80]};

assign n_4 = datomem[103:96];
assign m_4 = datomem[111:104];
assign rn_lambda_4 = {1'b0, datomem[127:112]};

assign n_5 = datomem[135:128];
assign m_5 = datomem[143:136];
assign rn_lambda_5 = {1'b0, datomem[159:144]};

//logic clkMem; // Reloj de la memoria y del reg. de dir.
//logic rstRD; // reset del registro de direcciones
//logic [5:0] regdir; // Registro de direcciones
logic sCMP; // Señal de comparador registro de direcciones


// ---Lógica del registro de direcciones
logic [6:0] regdirinc, regdirmux;
//assign regdirinc = regdir + 7'h01;
//logic clkRD; 
assign clkRD = ~(clkMC | clkPS);

//CLAsum7b regdirp1 (
//    .a(addr_mem),
//    .b(7'h01),
//    .s(regdirinc)
//);

assign regdirinc = addr_mem + 7'h01;

always_comb begin
    if (~enclkRD)
        regdirmux = regdir;
    else
        regdirmux = regdirinc;
end

always_ff @(posedge clkRD or posedge rstRD) begin
    if (rstRD)
        regdir <= 7'h00;
    else if (enclkRD)
        regdir <= regdirinc; //regresarlo a cero
end

// ---Lógica del comparador de direcciones
always_comb begin
    if (regdir >= lenM)
        sCMP = 1;
    else
        sCMP = 0;
end
// ---Lógica de los registros AO
logic [18:0] teta0, phi0;
always_ff @(posedge sAO or posedge rst) begin
    if (rst) begin
        teta0 <= 0;
        phi0 <= 0;
    end else begin
        teta0 <= teta0in;
        phi0 <= phi0in;
    end
end

//--- Importación unidad trigonométrica
logic [17:0] senphi, cosphi, sentetneg;

UnidadTrigonometrica UT (
    .teta0(teta0), .phi0(phi0),
    .senphi(senphi), .cosphi(cosphi), .sentetneg(sentetneg)
);

//--- Importación de los productos constantes
ProductosConstantes X_cte (
    .d(d), .cosa(cosa), .sena(sena), .lambda_inv(lambda_inv), .B(B),
    .a(a), .b_p(b), .g(g)
);


//--- Importación de los productos únicos
ProductosUnicos X_u (
    .senphi(senphi), .cosphi(cosphi), .sentetneg(sentetneg),
    .a(a), .b(b), .g(g),
    .c(c), .f(f), .h(h)
);



logic [1:0] selDM; // selector demultiplexor
logic rstDM; // reset del demux etapa final
logic clkDM; // reloj demux

// ---Lógica del selector demultiplexor
always_ff @(negedge clkDM or posedge rstDM) begin
    if(rstDM) selDM <= 2'd0;
    else begin
        if (selDM > 2'd1)// valor máximo = 2
            selDM <= 2'd0;
        else
            selDM <= selDM + 1;
    end
end



logic enPS2, enPS3; // activadores de puertos seriales
logic clkE1, clkE2; // relojes etapas 1 y 2
logic sPS1, sPS2, sPS3;
assign sPS1 = sPS1_1 & sPS1_2 & sPS1_3 & sPS1_4 & sPS1_5;
assign sPS2 = sPS2_1 & sPS2_2 & sPS2_3 & sPS2_4 & sPS2_5;
assign sPS3 = sPS3_1 & sPS3_2 & sPS3_3 & sPS3_4 & sPS3_5;

logic clkPS2reg, clkPS3reg;
logic enclkRD;
MaquinaControlEjecucion MaqControl (
        .sAO(sAO), .sAOsw(sAOsw), .sCfg(sCfg), // Señal de ángulos de orientación, señal de configuración
        .sCMP(sCMP), // señal de comparador de registro de direcciones
        .sPS1(sPS1), .sPS2(sPS2), .sPS3(sPS3), //señales de finalización de los puertos seriales
        .clk(clkMC) , .clkPS(clkPS), .rst(rst), // reloj y reset maestros
        .clkMem(clkMem), .clkAO(clkAO), .rstRD(rstRD), .rstDM(rstDM),
        .clkPS1reg(clkPS1reg), .clkPS2reg(clkPS2reg), .clkPS3reg(clkPS3reg),
        .clkE1(clkE1), .clkE2(clkE2), .clkDM(clkDM),
        .enPS1(enPS1), .enPS2(enPS2), .enPS3(enPS3), .clkRegDec(clkRegDec),
        .enclkRD(enclkRD), .flagEjec(flagEjec), .startReor(startReor),
        .epres(epres) 
);

//logic clkPS2, clkPS3;
//logic outPS2, outPS3; 
NucleoEjecucion Nucleo_1(
    .n(n_1), .m(m_1),
    .rn_lambda(rn_lambda_1), .c(c[16:0]), .f(f[16:0]), .h(h[16:0]),
    .selDM(selDM), .ba(ba),
    .clkPS(clkPS),
    .enclkE1(clkE1), .enclkE2(clkE2),
    .rst(rst),
    .clkMC(clkMC),
    .enPS1(enPS1), .enPS2(enPS2), .enPS3(enPS3),
    .clkPS1(clkPS1_1), .clkPS2(clkPS2_1), .clkPS3(clkPS3_1),
    .outPS1(outPS1_1), .outPS2(outPS2_1), .outPS3(outPS3_1),
    .enclkPS1reg(clkPS1reg), .enclkPS2reg(clkPS2reg), .enclkPS3reg(clkPS3reg),
    .sPS1(sPS1_1), .sPS2(sPS2_1), .sPS3(sPS3_1),
    .Pout(Pout_1), .sw(sw_Pout)
);

NucleoEjecucion Nucleo_2(
    .n(n_2), .m(m_2),
    .rn_lambda(rn_lambda_2), .c(c[16:0]), .f(f[16:0]), .h(h[16:0]),
    .selDM(selDM), .ba(ba),
    .clkPS(clkPS),
    .enclkE1(clkE1), .enclkE2(clkE2),
    .rst(rst),
    .clkMC(clkMC),
    .enPS1(enPS1), .enPS2(enPS2), .enPS3(enPS3),
    .clkPS1(clkPS1_2), .clkPS2(clkPS2_2), .clkPS3(clkPS3_2),
    .outPS1(outPS1_2), .outPS2(outPS2_2), .outPS3(outPS3_2),
    .enclkPS1reg(clkPS1reg), .enclkPS2reg(clkPS2reg), .enclkPS3reg(clkPS3reg),
    .sPS1(sPS1_2), .sPS2(sPS2_2), .sPS3(sPS3_2),
    .Pout(Pout_2), .sw(sw_Pout)
);

NucleoEjecucion Nucleo_3(
    .n(n_3), .m(m_3),
    .rn_lambda(rn_lambda_3), .c(c[16:0]), .f(f[16:0]), .h(h[16:0]),
    .selDM(selDM), .ba(ba),
    .clkPS(clkPS),
    .enclkE1(clkE1), .enclkE2(clkE2),
    .rst(rst),
    .clkMC(clkMC),
    .enPS1(enPS1), .enPS2(enPS2), .enPS3(enPS3),
    .clkPS1(clkPS1_3), .clkPS2(clkPS2_3), .clkPS3(clkPS3_3),
    .outPS1(outPS1_3), .outPS2(outPS2_3), .outPS3(outPS3_3),
    .enclkPS1reg(clkPS1reg), .enclkPS2reg(clkPS2reg), .enclkPS3reg(clkPS3reg),
    .sPS1(sPS1_3), .sPS2(sPS2_3), .sPS3(sPS3_3), 
    .Pout(Pout_3), .sw(sw_Pout)
);

NucleoEjecucion Nucleo_4(
    .n(n_4), .m(m_4),
    .rn_lambda(rn_lambda_4), .c(c[16:0]), .f(f[16:0]), .h(h[16:0]),
    .selDM(selDM), .ba(ba),
    .clkPS(clkPS),
    .enclkE1(clkE1), .enclkE2(clkE2),
    .rst(rst),
    .clkMC(clkMC),
    .enPS1(enPS1), .enPS2(enPS2), .enPS3(enPS3),
    .clkPS1(clkPS1_4), .clkPS2(clkPS2_4), .clkPS3(clkPS3_4),
    .outPS1(outPS1_4), .outPS2(outPS2_4), .outPS3(outPS3_4),
    .enclkPS1reg(clkPS1reg), .enclkPS2reg(clkPS2reg), .enclkPS3reg(clkPS3reg),
    .sPS1(sPS1_4), .sPS2(sPS2_4), .sPS3(sPS3_4),
    .Pout(Pout_4), .sw(sw_Pout)
);

NucleoEjecucion Nucleo_5(
    .n(n_5), .m(m_5),
    .rn_lambda(rn_lambda_5), .c(c[16:0]), .f(f[16:0]), .h(h[16:0]),
    .selDM(selDM), .ba(ba),
    .clkPS(clkPS),
    .enclkE1(clkE1), .enclkE2(clkE2),
    .rst(rst),
    .clkMC(clkMC),
    .enPS1(enPS1), .enPS2(enPS2), .enPS3(enPS3),
    .clkPS1(clkPS1_5), .clkPS2(clkPS2_5), .clkPS3(clkPS3_5),
    .outPS1(outPS1_5), .outPS2(outPS2_5), .outPS3(outPS3_5),
    .enclkPS1reg(clkPS1reg), .enclkPS2reg(clkPS2reg), .enclkPS3reg(clkPS3reg),
    .sPS1(sPS1_5), .sPS2(sPS2_5), .sPS3(sPS3_5),
    .Pout(Pout_5), .sw(sw_Pout)
);

always_comb begin
    case (sw_nuc)
        3'd0: begin
            Pout = Pout_1;
            outPS1 = outPS1_1; 
            clkPS1 = clkPS1_1;
            outPS2 = outPS2_1;
            clkPS2 = clkPS2_1;
            outPS3 = outPS3_1;
            clkPS3 = clkPS3_1; 
        end
        3'd1: begin    
            Pout = Pout_2;
            outPS1 = outPS1_2; 
            clkPS1 = clkPS1_2;
            outPS2 = outPS2_2;
            clkPS2 = clkPS2_2;
            outPS3 = outPS3_2;
            clkPS3 = clkPS3_2; 
        end
        3'd2: begin
            Pout = Pout_3;
            outPS1 = outPS1_3; 
            clkPS1 = clkPS1_3;
            outPS2 = outPS2_3;
            clkPS2 = clkPS2_3;
            outPS3 = outPS3_3;
            clkPS3 = clkPS3_3;        
        end
        3'd3: begin
            Pout = Pout_4;
            outPS1 = outPS1_4; 
            clkPS1 = clkPS1_4;
            outPS2 = outPS2_4;
            clkPS2 = clkPS2_4;
            outPS3 = outPS3_4;
            clkPS3 = clkPS3_4;         
        end
        3'd4: begin
            Pout = Pout_5;
            outPS1 = outPS1_5; 
            clkPS1 = clkPS1_5;
            outPS2 = outPS2_5;
            clkPS2 = clkPS2_5;
            outPS3 = outPS3_5;
            clkPS3 = clkPS3_5;         
        end
        default: begin
            Pout = 0;
            outPS1 = 0; 
            clkPS1 = 0;
            outPS2 = 0;
            clkPS2 = 0;
            outPS3 = 0;
            clkPS3 = 0;            
        end        
    endcase
end

endmodule
