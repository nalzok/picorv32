module simpleusb (
	input clk,
	input resetn,

    inout pin_usb_p,
    inout pin_usb_n,
    output pin_pu,

    output user_led,

	input   [3:0] reg_div_we,
	input  [31:0] reg_div_di,
	output [31:0] reg_div_do,

	input         reg_dat_we,
	input         reg_dat_re,
	input  [31:0] reg_dat_di,
	output [31:0] reg_dat_do,
	output        reg_dat_wait
);
    assign reg_div_do = 32'hDEAD_BEEF;

    wire clk_48mhz;
    wire clk_locked;

    // Use an icepll generated pll
    pll pll48( .clock_in(clk), .clock_out(clk_48mhz), .locked( clk_locked ) );

    // Generate reset signal
    reg [5:0] reset_cnt = 0;
    wire reset = ~reset_cnt[5];
    always @(posedge clk_48mhz)
        if ( clk_locked )
            reset_cnt <= reset_cnt + reset;

    // Internal signals
    wire read_done;
    wire write_done;
    reg halt_read;
    reg halt_write;

    reg reg_dat_re_internal;
    reg reg_dat_we_internal;
    reg [31:0] reg_dat_di_internal;

    assign read_done = uart_out_valid_internal && reg_dat_re_internal;
    assign write_done = reg_dat_we_internal && uart_in_ready_internal;

    reg [22:0] user_led_cnt = 0;
    assign user_led = |user_led_cnt;
    always @(posedge clk_48mhz)
        user_led_cnt <= user_led_cnt + (user_led | uart_out_valid_internal);

    reg [31:0] reg_dat_do;
    wire [31:0] reg_dat_do_internal;

    wire uart_in_ready_internal;
    wire uart_out_valid_internal;

    assign reg_dat_wait = reg_dat_re_internal & ~uart_in_ready_internal;

    always @(posedge clk_48mhz) begin
        if (reset || !resetn) begin
            halt_read <= 0;
            halt_write <= 0;
            reg_dat_re_internal <= 0;
            reg_dat_we_internal <= 0;
            reg_dat_do <= 0;
        end else
        begin
            halt_read <= read_done;
            halt_write <= write_done;

            reg_dat_re_internal <= reg_dat_re;
            reg_dat_we_internal <= reg_dat_we;
            reg_dat_di_internal <= reg_dat_di;

            /*
            reg_dat_do <= (uart_out_valid_internal & ~reg_dat_re)
                          ? reg_dat_do_internal : ~0;
            */

           reg_dat_do <= "\r";

            if (read_done || halt_read)
            begin
                reg_dat_re_internal <= 0;
            end

            if (write_done || halt_write)
            begin
                reg_dat_we_internal <= 0;
            end
        end
    end

    // usb uart - this instanciates the entire USB device.
    usb_uart uart (
        .clk_48mhz  ( clk_48mhz ),
        .reset      ( reset ),

        // pins
        .pin_usb_p ( pin_usb_p ),
        .pin_usb_n ( pin_usb_n ),

        // uart pipeline in
        .uart_in_data( reg_dat_di_internal ),
        .uart_in_valid( reg_dat_we_internal ),
        .uart_in_ready( uart_in_ready_internal ),

        // uart pipeline out
        .uart_out_data( reg_dat_do_internal ),
        .uart_out_valid( uart_out_valid_internal ),
        .uart_out_ready( reg_dat_re_internal )
    );

    // USB Host Detect Pull Up
    assign pin_pu = 1'b1;

endmodule
