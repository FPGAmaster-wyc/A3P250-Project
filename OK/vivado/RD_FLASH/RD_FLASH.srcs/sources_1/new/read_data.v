`timescale 1ns / 1ps

module read_data(
    input       i_clk,
    input       i_rst_n,
    input       key_flag,

    output  [7:0] tx_data,
    output  reg     tx_flag,

    output  reg    spi_clk,
    output  reg    cs_n,
    input          miso,
    output  reg    mosi
);

    reg [3:0] n_state, c_state;
    parameter   IDLE =  4'd0,
                RD_DATA = 4'd1,
                SEND = 4'd2;

    parameter NUM_DATA = 100;       //读的数据个数
    parameter RD_DATA_CMD = 8'h03;

    reg [4:0] clk_cnt;
    reg [15:0] cnt_byte; //每640ns 计数一次
    reg [1:0] cnt_sck;  //对50M 四分频
    reg [2:0] bit_cnt;
    reg [7:0] tx_cmd;

    reg [23:0] rd_addr;
    reg [7:0]  wr_data;
    reg data_flag;
    reg [7:0] rx_data;
    reg [7:0] data;     //存入FIFO data
    reg [15:0] num_rd;  //收到的数据计数


    
    reg fifo_read_valid;
    reg [7:0] read_data_num;
    reg [15:0] cnt_wait;
    parameter   CNT_WAIT_MAX=   16'd6_00_00 ;
    reg fifo_read_en;
    wire [12:0] fifo_data_num;


    //时钟计数器
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            clk_cnt <= 0;
        else if (n_state == IDLE)
            clk_cnt <= 0;
        else if (n_state != IDLE)
            clk_cnt <= clk_cnt + 1;
    end

    //字节计数器
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            cnt_byte <= 0;
        else if (n_state == IDLE)
            cnt_byte <= 0;
        else if (n_state != IDLE && clk_cnt == 31)
            cnt_byte <= cnt_byte + 1;
    end

    //状态转换 FSM31
    always @ (posedge i_clk, negedge i_rst_n) begin  :   W_FMS1
        if (~i_rst_n)
            c_state <= 0;
        else
            c_state <= n_state;
    end

     //状态跳转条件 FSM32
    always @ (*) begin  :   W_FMS2
        case (c_state)
            IDLE    :   begin
                            if (key_flag)
                                n_state = RD_DATA;
                            else
                                n_state = IDLE;
            end

            RD_DATA   :   begin
                            if (cnt_byte == 5)
                                n_state = SEND;
                            else
                                n_state = RD_DATA;
            end

            SEND :   begin
                        if (num_rd >= 16'd100)
                            n_state = IDLE;
                        else
                            n_state = SEND;
            end 

            default :   n_state = 'bx;
        endcase
    end

     //状态执行的操作 FSM33
    always @ (posedge i_clk, negedge i_rst_n) begin  :   W_FMS3
        if (~i_rst_n)
            begin
                cs_n <= 1;
                mosi <= 0;
                rd_addr <= 0;
                rx_data <= 0;
            end
        else
            case (n_state)
                IDLE    :   begin
                                cs_n <= 1;
                end

                RD_DATA   :   begin
                                cs_n <= 0;
                                if (cnt_byte == 1 && cnt_sck == 0) 
                                    mosi <= RD_DATA_CMD[7 - bit_cnt];
                                else if (cnt_byte > 1 && cnt_byte < 5 && cnt_sck == 0) 
                                    begin
                                        mosi <= rd_addr[23];
                                        rd_addr <= {rd_addr[22:0], rd_addr[23]};
                                    end
                end

                SEND :   begin
                            if (cnt_sck == 2)
                                begin
                                    rx_data[7 - bit_cnt] <= miso;
                                end

                end
            endcase 
    end

    //rd flag
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n) begin
            data_flag <= 0;
            data <= 0;
        end           
        else if (n_state == SEND && clk_cnt == 31) begin
            data <= rx_data;
            data_flag <= 1;
        end           
        else
            data_flag <= 0;
    end 

    //收到数据计数
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            num_rd <= 0;
        else if (n_state == IDLE)
            num_rd <= 0;
        else if (data_flag)
            num_rd <= num_rd + 1;
    end 
    
    // bit 计数器
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            bit_cnt <= 0;
        else if (n_state == IDLE)
            bit_cnt <= 0;
        else if (cnt_sck == 2)
            bit_cnt <= bit_cnt + 1;
    end 

    // cnt_sck
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            cnt_sck <= 0;
        else if (n_state == IDLE)
            cnt_sck <= 0;
        else if (n_state == RD_DATA && cnt_byte >= 1)
            cnt_sck <= cnt_sck + 1;
        else if (n_state == SEND)
            cnt_sck <= cnt_sck + 1;
    end

    // spi clk
    always @ (posedge i_clk, negedge i_rst_n) begin
        if (~i_rst_n)
            spi_clk <= 0;
        else if (cnt_sck == 0)
            spi_clk <= 0;
        else if (cnt_sck == 2)
            spi_clk <= 1;
    end 

    /*FIFO 读数据*/
    //fifo_read_valid:fifo读有效信号
    always @ (posedge i_clk, negedge i_rst_n) begin
        if(i_rst_n == 1'b0)
            fifo_read_valid <=  1'b0;
        else    if((read_data_num == NUM_DATA)
                    && ((cnt_wait == (CNT_WAIT_MAX - 1'b1))))
            fifo_read_valid <=  1'b0;
        else    if(fifo_data_num == NUM_DATA)
            fifo_read_valid <=  1'b1;
    end

    //cnt_wait:两数据读取时间间隔
    always @ (posedge i_clk, negedge i_rst_n) begin
        if(i_rst_n == 1'b0)
            cnt_wait    <=  16'd0;
        else    if(fifo_read_valid == 1'b0)
            cnt_wait    <=  16'd0;
        else    if(cnt_wait == (CNT_WAIT_MAX - 1'b1))
            cnt_wait    <=  16'd0;
        else    if(fifo_read_valid == 1'b1)
            cnt_wait    <=  cnt_wait + 1'b1;
    end
    //fifo_read_en:fifo读使能信号
    always @ (posedge i_clk, negedge i_rst_n) begin
        if(i_rst_n == 1'b0)
            fifo_read_en <=  1'b0;
        else    if((cnt_wait == (CNT_WAIT_MAX - 1'b1))
                    && (read_data_num < NUM_DATA))
            fifo_read_en <=  1'b1;
        else
            fifo_read_en <=  1'b0;
    end

    //read_data_num:自fifo中读出数据个数计数
    always @ (posedge i_clk, negedge i_rst_n) begin
        if(i_rst_n == 1'b0)
            read_data_num <=  8'd0;
        else    if(fifo_read_valid == 1'b0)
            read_data_num <=  8'd0;
        else    if(fifo_read_en == 1'b1)
            read_data_num <=  read_data_num + 1'b1;
    end

    //tx_flag
    always @ (posedge i_clk, negedge i_rst_n) begin
        if(i_rst_n == 1'b0)
            tx_flag <=  1'b0;
        else
            tx_flag <=  fifo_read_en;
    end 

    uart_rx_data FIFO (
    .clk(i_clk),      // input wire clk
    .srst(~i_rst_n),              // input wire srst
    .din(data),      // input wire [7 : 0] din
    .wr_en(data_flag),  // input wire wr_en

    .rd_en(fifo_read_en),  // input wire rd_en
    .dout(tx_data),    // output wire [7 : 0] dout
    .full( ),    // output wire full
    .data_count(fifo_data_num),  // output wire [12 : 0] data_count
    .empty( )  // output wire empty
);

    ila_0 READ_ILA (
	.clk(i_clk), // input wire clk
	.probe0({data_flag, data, rx_data, n_state, c_state, key_flag, i_rst_n,
            spi_clk, cs_n, miso, mosi, cnt_byte, bit_cnt, num_rd, clk_cnt, fifo_read_en, tx_data,
            fifo_data_num, fifo_read_valid, cnt_sck}) // input wire [255:0] probe0
);

endmodule
