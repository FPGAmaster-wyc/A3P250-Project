`timescale  1ns/1ns

/*读数据OK*/

module  spi_flash_read(

    input   wire    sys_clk     ,   //系统时钟，频率100MHz
    input   wire    sys_rst   ,   //复位信号,低电平有效
    input   [3:0]   key      ,   //按键输入信号
    input   wire    miso        ,   //读出flash数据

    output  wire    cs_n        ,   //片选信号
    output  wire    sck         ,   //串行时钟
    output  wire    mosi        ,   //主输出从输入数据
    output  wire    tx              

);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   CNT_MAX     =   20'd999_999     ;   //计数器计数最大值
parameter   UART_BPS    =   14'd9600        ,   //比特率
            CLK_FREQ    =   26'd10_000_000  ;   //时钟频率


//wire  defin5
wire            pi_key  ;
wire            po_key  ;   //消抖处理后的按键信号
wire            tx_flag ;   //输入串口发送模块数据标志信号
wire    [7:0]   tx_data ;   //输入串口发送模块数据
wire            clk_10M;
wire            ila_clk;
wire            sys_rst_n;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

assign pi_key = ~key[0];

clk_wiz_0 instance_name (
    // Clock out ports
    .clk_50M(clk_50M),     // output clk_50M   换为10M
    .ila_clk(ila_clk),     // output ila_clk
    // Status and control signals
    .reset(sys_rst), // input resetn
    .locked(sys_rst_n),       // output locked
    // Clock in ports
    .clk_in1(sys_clk)
);      

//------------- key_filter_inst -------------
key_filter
#(
    .CNT_MAX    (CNT_MAX    )   //计数器计数最大值
)
key_filter_inst
(
    .sys_clk    (clk_50M    ),  //系统时钟，频率50MHz
    .sys_rst_n  (sys_rst_n  ),  //复位信号,低电平有效
    .key_in     (pi_key     ),  //按键输入信号

    .key_flag   (po_key     )   //消抖后信号
);

//-------------flash_read_ctrl_inst-------------
flash_read_ctrl  
#(
    .NUM_DATA    (16'd100    )   //读出数据个数
)
flash_read_ctrl_inst
(
    .sys_clk    (clk_50M    ),  //系统时钟，频率50MHz
    .ila_clk    (ila_clk)   ,
    .sys_rst_n  (sys_rst_n  ),  //复位信号,低电平有效
    .key        (po_key     ),  //按键输入信号
    .miso       (miso       ),  //读出flash数据

    .sck        (sck        ),  //片选信号
    .cs_n       (cs_n       ),  //串行时钟
    .mosi       (mosi       ),  //主输出从输入数据
    .tx_flag    (tx_flag    ),  //输出数据标志信号
    .tx_data    (tx_data    )   //输出数据

);

//-------------uart_tx_inst-------------
uart_tx
#(
    .UART_BPS    (UART_BPS ),         //串口波特率
    .CLK_FREQ    (CLK_FREQ )          //时钟频率
)
uart_tx_inst(
    .sys_clk     (clk_50M  ),   //系统时钟50Mhz
    .sys_rst_n   (sys_rst_n),   //全局复位
    .pi_data     (tx_data  ),   //并行数据
    .pi_flag     (tx_flag  ),   //并行数据有效标志信号
                                
    .tx          (tx       )    //串口发送数据
);

endmodule
