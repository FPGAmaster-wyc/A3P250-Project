`timescale 1ns / 1ps


module top_rd_data(

    input   wire    sys_clk     ,   //系统时钟，频率50MHz
    input   wire    sys_rst   ,   //复位信号,低电平有效
    input   [3:0]   key      ,   //按键输入信号
    input   wire    miso        ,   //读出flash数据

    output  wire    cs_n        ,   //片选信号
    output  wire    sck         ,   //串行时钟
    output  wire    mosi        ,   //主输出从输入数据
    output  wire    tx              

);

    wire    clk_50M;
    wire    locked;
    wire    po_key;
    wire    [7:0] data;
    wire    data_flag;


clk_wiz_0 PLL (
    // Clock out ports
    .clk_50M(clk_50M),     // output clk_50M
    // Status and control signals
    .reset(sys_rst), // input resetn
    .locked(locked),       // output locked
    // Clock in ports
    .clk_in1(sys_clk)
); 

//------------- key_filter_inst -------------
key_filter
#(
    .CNT_MAX    (20'd999_999    )   //计数器计数最大值
)
key_filter_inst
(
    .sys_clk    (clk_50M    ),  //系统时钟，频率50MHz
    .sys_rst_n  (locked  ),  //复位信号,低电平有效
    .key_in     (~key[0]     ),  //按键输入信号(低有效)

    .key_flag   (po_key     )   //消抖后信号
);

    
    read_data u_read_data(
        .i_clk    ( clk_50M    ),
        .i_rst_n  ( locked  ),
        .key_flag ( po_key ),
        .tx_data       (data),
        .tx_flag(data_flag),
        .spi_clk  ( sck  ),
        .cs_n     ( cs_n     ),
        .miso     ( miso     ),
        .mosi     ( mosi     )
    );


    uart_tx
#(
    .UART_BPS    (14'd9600 ),         //串口波特率
    .CLK_FREQ    (26'd50_000_000 )          //时钟频率
)
uart_tx_inst(
    .sys_clk     (clk_50M  ),   //系统时钟50Mhz
    .sys_rst_n   (locked),   //全局复位
    .pi_data     (data  ),   //并行数据
    .pi_flag     (data_flag  ),   //并行数据有效标志信号
                                
    .tx          (tx       )    //串口发送数据
);


endmodule
