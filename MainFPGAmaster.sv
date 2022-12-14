`timescale 1ns / 1ps

parameter num_nuc = 6'd5; // N?mero de n?cleos de ejecuci?n
parameter lenM = 7'd60; // Localidades de memoria

module MainFPGAmaster(
        input logic rst, // Bot?n de reinicio
        input logic rx,
        input logic clk_100MHzboard, 
        input logic sAOsw,
        input logic SI,
        input logic [3:0] led_sel, // Para escoger visualizar la parte entera o fracc.
        input logic [1:0] sw_Pout,
        input logic startReor, 
        // SPI
        input logic SPIclk, SPIdat, SPIss,
        //input logic startcfg,
        output logic [7:0] val_leds, // 16 bits visualizados en los LED
        output logic tx, // Bit de transmisi?n   
        output logic clkPS1, outPS1, clkRegDec,
        output logic clkPS2, outPS2, 
        output logic clkPS3, outPS3,    
        //output logic clktest,
        //output logic clkPS1reg,
        output logic flagEjec, 
        output logic [4:0] Pout,
        output logic received_SPI                   
    );

logic clktest;
logic sAO;
logic reconfig = 0;
logic flagcfg, flagparam;
logic clkfast, clkslow, clkIU,clkslowIU, clkcfg;
logic clkAOrecep;
logic [31:0] R, d, B, alfa, Ax, Ay, Az, ext, lambda_inv, sena32, cosa32; 

logic [23:0] teta0, phi0; // ?ngulos de orientaci?n

assign clktest = clkfast;

logic clk_mem, ena_mem, wen_mem;
logic [799:0] din_mem, dout_mem;
logic [6:0] dir_mem;
logic [10:0] n_elem; // n?mero de elementos
logic [7:0] C, F; // ?ndices de columna y fila    

logic flagsendmem;
logic [6:0] addrmcfg; 
logic [799:0] datos_incfg;
logic clk_memcfg, en_memcfg, wen_memcfg;
logic SFFC;

logic [6:0] dir_memejec;
logic clk_memejec, en_memejec;

logic [799:0] dat_mem; 
logic ena_memui;
logic [6:0] dir_memui;

logic [7:0] VFF, VFC; 
logic [2:0] ba; // Bits del arreglo
assign VFC = ext[31:24];
assign VFF = ext[23:16];
assign ba = ext[10:8];
logic [3:0] eprescfg; 
logic [5:0] lenMcfg;
logic CF;

logic clkRD;
logic rstRD;

always_comb begin
    if (~flagcfg) begin // Etapa de configuraci?n tiene el control de la memoria
        clk_mem = clkcfg;
        ena_mem = en_memcfg;
        wen_mem = wen_memcfg;
        dir_mem = addrmcfg;
        din_mem = datos_incfg;
    end
    else if (flagsendmem) begin
        clk_mem = clkIU;
        ena_mem = ena_memui;
        wen_mem = 0;
        dir_mem = dir_memui;
        din_mem = 0;    
    end else begin    
        clk_mem = clk_memejec;
        ena_mem = 1'b1;
        wen_mem = 1'b0;
        dir_mem = dir_memejec;
        din_mem = 0;        
    end
end

clkgennv (
    .clk_in1(clk_100MHzboard),
    .clk_out1(clkfast), // reloj puertos seriales
    .clk_out2(clkslow), // reloj n?cleos ejecuci?n
    .clk_out3(clkcfg), // reloj m?quina de config.
    .clk_out4(clkIU), // reloj r?pido m?quina de recepc. comandos
    .clk_out5(clkslowIU),  // reloj lento para m?dulo uart
    .clk_out6(clkAOrecep)  
);

//logic received_SPI;
logic [7:0] SPI_byte, SPI_byte_fixed;
 
SPI_Slave AORecep (
    .i_Clk(clkAOrecep),
    .i_Rst(rst),
    .o_RX_DV(received_SPI),
    .o_RX_Byte(SPI_byte), 
    .SPI_byte_fixed(SPI_byte_fixed),
    .sAO(sAO),   
    .teta0(teta0), .phi0(phi0),
    .i_SPI_Clk(SPIclk), .i_SPI_MOSI(SPIdat), .i_SPI_CS_n(SPIss)
);
  
InterfazUsuario InterfazUsuario (
    .clkfast(clkIU), .clkslow(clkslowIU),
    .rst(rst), .rx(rx), .reconfig(reconfig),
    .flagcfg(flagcfg), .lenM(adrmcfg),
    .R(R), .d(d), .B(B), .alfa(alfa), .Ax(Ax), .Ay(Ay), .Az(Az), .ext(ext), .lambda_inv(lambda_inv),
    .tx(tx), .flagparam(flagparam), .flagsendmem(flagsendmem),
    .dat_mem(dout_mem), .ena_memui(ena_memui), .dir_memui(dir_memui)
);


EtapaConfiguracion EtapaConfiguracion (
    .VFF(VFF), .VFC(VFC), .R(R), .d(d), .B(B), .alfa(alfa[18:0]), // modif 5 ago 2022 
    .xa(Ax), .ya(Ay), .za(Az), .lambda_inv(lambda_inv), .clkcfg(clkcfg), .rst(rst), .flagparam(flagparam),
    .SI(SI), .nNucleos(num_nuc), .lenM(lenM), .sena32(sena32), .cosa32(cosa32), .SFFC(SFFC),
    .CM(clk_memcfg), .ENM(en_memcfg), .WEM(wen_memcfg), .addrM(addrmcfg), .datos_in(datos_incfg), .FFCfg(flagcfg),
    .N(n_elem), .C(C), .F(F), .eprescfg(eprescfg), .CF(CF), .lenMcfg(lenMcfg)
);

logic sAOtotal;
assign sAOtotal = sAO & sAOsw;
EtapaEjecucion EtapaEjecucion (
    .teta0in(teta0[18:0]), .phi0in(phi0[18:0]),
    .d(d), .cosa(cosa32), .sena(sena32), .lambda_inv(lambda_inv), .B(B),
    .ba(ba), .lenM(lenMcfg), .clkPS(clkfast), .clkMC(clkslow), .rst(rst),
    .sAO(sAO), .sAOsw(sAOsw), .sCfg(flagcfg), .sw_nuc(led_sel[2:0]), .sw_Pout(sw_Pout), .addr_mem(dir_mem), .datomem(dout_mem),
    .clkPS1(clkPS1), .outPS1(outPS1), .clkRegDec(clkRegDec), 
    .clkPS2(clkPS2), .outPS2(outPS2),
    .clkPS3(clkPS3), .outPS3(outPS3),
    .clkPS1reg(clkPS1reg), .Pout(Pout),
    .regdir(dir_memejec), .clkMem(clk_memejec), .clkRD(clkRD), .rstRD(rstRD), .flagEjec(flagEjec), .startReor(startReor)
);

logic rsta_busy;
blk_mem_gen_0 MemElementos (
    .clka(clk_mem),
    .ena(ena_mem),
    .wea(wen_mem),
    .rsta(rst),
    .addra(dir_mem),
    .dina(din_mem),
    .douta(dout_mem),
    .rsta_busy(rsta_busy)
);

always_comb begin

    case(led_sel)
        4'b0000:
            val_leds = addrmcfg;
        4'b0001:
            val_leds = lenMcfg;
        4'b0010: 
            val_leds = d[7:0];
        4'b0011:
            val_leds = d[31:24];
        4'b0100: 
            val_leds = B[7:0];
        4'b0101:
            val_leds = B[31:24];
        4'b0110: 
            val_leds = {0, SFFC};
        4'b0111:
            val_leds = {0, CF}; 
        4'b1000: 
            val_leds = SPI_byte_fixed;
        4'b1001:
            val_leds = SPI_byte;                                      
        4'b1010: 
            val_leds = teta0[7:0];
        4'b1011:
            val_leds = teta0[15:8];     
        4'b1100: 
            val_leds = teta0[23:16];
        4'b1101:
            val_leds = phi0[7:0];    
        4'b1110: 
            val_leds = phi0[15:8];
        4'b1111:
            val_leds = phi0[23:16];                                         
    endcase
end

endmodule

