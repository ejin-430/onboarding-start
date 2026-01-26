`default_nettype none

module spi_peripheral (
    input  wire       clk,
    input  wire       rst_n,

    // SPI (Mode 0): sample COPI on SCLK rising edge while nCS low
    input  wire       spi_sclk,
    input  wire       spi_copi,
    input  wire       spi_ncs,   // active-low chip select

    output reg  [7:0] en_reg_out_7_0,
    output reg  [7:0] en_reg_out_15_8,
    output reg  [7:0] en_reg_pwm_7_0,
    output reg  [7:0] en_reg_pwm_15_8,
    output reg  [7:0] pwm_duty_cycle
);

    // -------------------------
    // CDC: sync SPI pins to clk
    // -------------------------
    reg sclk_ff1, sclk_ff2;
    reg copi_ff1, copi_ff2;
    reg ncs_ff1,  ncs_ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_ff1 <= 1'b0; sclk_ff2 <= 1'b0;
            copi_ff1 <= 1'b0; copi_ff2 <= 1'b0;
            ncs_ff1  <= 1'b1; ncs_ff2  <= 1'b1;
        end else begin
            sclk_ff1 <= spi_sclk; sclk_ff2 <= sclk_ff1;
            copi_ff1 <= spi_copi; copi_ff2 <= copi_ff1;
            ncs_ff1  <= spi_ncs;  ncs_ff2  <= ncs_ff1;
        end
    end

    wire sclk_sync = sclk_ff2;
    wire copi_sync = copi_ff2;
    wire ncs_sync  = ncs_ff2;

    // Edge detect (in clk domain)
    reg sclk_prev, ncs_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_prev <= 1'b0;
            ncs_prev  <= 1'b1;
        end else begin
            sclk_prev <= sclk_sync;
            ncs_prev  <= ncs_sync;
        end
    end

    wire sclk_rise = (sclk_sync && !sclk_prev);
    wire ncs_fall  = (!ncs_sync &&  ncs_prev);
    wire ncs_rise  = ( ncs_sync && !ncs_prev);

    // -------------------------
    // Shift in 16 bits, MSB-first
    // packet: [15]=rw, [14:8]=addr, [7:0]=data
    // -------------------------
    reg [15:0] shift_reg;
    reg [4:0]  bit_count; // counts 0..16

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 16'h0000;
            bit_count <= 5'd0;

            en_reg_out_7_0   <= 8'h00;
            en_reg_out_15_8  <= 8'h00;
            en_reg_pwm_7_0   <= 8'h00;
            en_reg_pwm_15_8  <= 8'h00;
            pwm_duty_cycle   <= 8'h00;
        end else begin
            // Start of transaction
            if (ncs_fall) begin
                shift_reg <= 16'h0000;
                bit_count <= 5'd0;
            end

            // Shift bits only while selected
            if (!ncs_sync && sclk_rise) begin
                if (bit_count < 5'd16) begin
                    shift_reg <= {shift_reg[14:0], copi_sync};
                    bit_count <= bit_count + 1'b1;
                end
            end

            // End of transaction: commit only if exactly 16 bits and it's a valid write
            if (ncs_rise) begin
                if (bit_count == 5'd16) begin
                    if (shift_reg[15] == 1'b1) begin // rw=1 => write
                        case (shift_reg[14:8])       // addr
                            7'h00: en_reg_out_7_0  <= shift_reg[7:0];
                            7'h01: en_reg_out_15_8 <= shift_reg[7:0];
                            7'h02: en_reg_pwm_7_0  <= shift_reg[7:0];
                            7'h03: en_reg_pwm_15_8 <= shift_reg[7:0];
                            7'h04: pwm_duty_cycle  <= shift_reg[7:0];
                            default: begin end // ignore invalid address
                        endcase
                    end
                end
            end
        end
    end

endmodule

`default_nettype wire
