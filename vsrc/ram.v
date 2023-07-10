`timescale 1ns / 1ps
`define STRINGIFY(x) `"x`"

module IROM # (
    ADDR_BITS = 16
)(
    input [ADDR_BITS - 1:0] a,
    output [31:0] spo
);

    integer i, j, mem_file;
    // (* RAM_STYLE="BLOCK" *)
    reg [32-1:0] mem[(2**20)-1:0];
    reg [32-1:0] mem_rd[(2**20)-1:0];
    initial begin
        // two nested loops for smaller number of iterations per loop
        // workaround for synthesizer complaints about large loop counts
        for (i = 0; i < 2**20; i = i + 2**(20/2)) begin
            for (j = i; j < i + 2**(20/2); j = j + 1) begin
                mem[j] = 0;
            end
        end
        mem_file = $fopen(`STRINGIFY(`PATH), "r");
        if(mem_file == 0) begin
            $display("[ERROR] Open file %s failed, please check whether file exists!\n", `STRINGIFY(`PATH));
            $fatal;
        end
        $display("[INFO] Instruction ROM initialized with %s", `STRINGIFY(`PATH));
        $fread(mem_rd, mem_file);
        for (i = 0; i < 2**20; i = i + 2**(20/2)) begin
            for (j = i; j < i + 2**(20/2); j = j + 1) begin
                mem[j] = {{mem_rd[j][07:00]}, {mem_rd[j][15:08]}, {mem_rd[j][23:16]}, {mem_rd[j][31:24]}};
            end
        end
    end

    assign spo = mem[a];

endmodule

module Controller_ROM (
    input [10:0] a,
    output [16:0] spo
);

    integer i, j, mem_file;
    localparam coe_bin = "controller.bin";
    // (* RAM_STYLE="BLOCK" *)
    reg [16:0] mem[2047: 0];
    reg [31:0] mem_rd[2047: 0];
    initial begin
        for(i = 0; i < 2048; i = i+1) begin
            mem[i] = 0;
            mem_rd[i] = 0;
        end
        mem_file = $fopen(coe_bin, "r");
        if(mem_file == 0) begin
            $display("[ERROR] Open file %s failed, please check whether file exists!\n", coe_bin);
            $fatal;
        end
        $display("[INFO] Controller ROM initialized with %s", `STRINGIFY(`PATH));
        $fread(mem_rd, mem_file);
        for(i = 0; i < 2048; i = i+1) begin
            // $display("%d => %b", i, mem_rd[i]);
            mem[i] = mem_rd[i][16: 0];
        end
    end

    assign spo = mem[a];

    always @(a) begin
        $display("opcode %b, funct3 %b, funct7 %b", a[10: 4], a[3: 1], a[0]);
        $display("spo %b", spo);
    end

endmodule


module DRAM # (
    ADDR_BITS = 16
)(
    input clk,
    input [ADDR_BITS - 1: 0] a,
    input [3:0] we,
    input [31:0] d,
    output [31:0] spo
);

    integer i, j, mem_file;
    // (* RAM_STYLE="BLOCK" *)
    reg [32-1:0] mem[(2**20)-1:0];
    reg [32-1:0] mem_rd[(2**20)-1:0];
    initial begin
        // two nested loops for smaller number of iterations per loop
        // workaround for synthesizer complaints about large loop counts
        for (i = 0; i < 2**20; i = i + 2**(20/2)) begin
            for (j = i; j < i + 2**(20/2); j = j + 1) begin
                mem[j] = 0;
            end
        end
        mem_file = $fopen(`STRINGIFY(`PATH), "r");
        if(mem_file == 0) begin
            $display("[ERROR] Open file %s failed, please check whether file exists!\n", `STRINGIFY(`PATH));
            $fatal;
        end
        $display("[INFO] Data RAM initialized with %s", `STRINGIFY(`PATH));
        $fread(mem_rd, mem_file);
        for (i = 0; i < 2**20; i = i + 2**(20/2)) begin
            for (j = i; j < i + 2**(20/2); j = j + 1) begin
                mem[j] = {{mem_rd[j][07:00]}, {mem_rd[j][15:08]}, {mem_rd[j][23:16]}, {mem_rd[j][31:24]}};
            end
        end
    end

    assign spo = mem[a];

    always @(posedge clk) begin
        if (we[0]) mem[a][ 7: 0] <= d[ 7: 0];
        if (we[1]) mem[a][15: 8] <= d[15: 8];
        if (we[2]) mem[a][23:16] <= d[23:16];
        if (we[3]) mem[a][31:24] <= d[31:24];
    end

endmodule
