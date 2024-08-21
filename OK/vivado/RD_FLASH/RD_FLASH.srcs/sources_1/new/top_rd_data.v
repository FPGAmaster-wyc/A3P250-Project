`timescale 1ns / 1ps


module top_rd_data(

    input   wire    sys_clk     ,   //ϵͳʱ�ӣ�Ƶ��50MHz
    input   wire    sys_rst   ,   //��λ�ź�,�͵�ƽ��Ч
    input   [3:0]   key      ,   //���������ź�
    input   wire    miso        ,   //����flash����

    output  wire    cs_n        ,   //Ƭѡ�ź�
    output  wire    sck         ,   //����ʱ��
    output  wire    mosi        ,   //���������������
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
    .CNT_MAX    (20'd999_999    )   //�������������ֵ
)
key_filter_inst
(
    .sys_clk    (clk_50M    ),  //ϵͳʱ�ӣ�Ƶ��50MHz
    .sys_rst_n  (locked  ),  //��λ�ź�,�͵�ƽ��Ч
    .key_in     (~key[0]     ),  //���������ź�(����Ч)

    .key_flag   (po_key     )   //�������ź�
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
    .UART_BPS    (14'd9600 ),         //���ڲ�����
    .CLK_FREQ    (26'd50_000_000 )          //ʱ��Ƶ��
)
uart_tx_inst(
    .sys_clk     (clk_50M  ),   //ϵͳʱ��50Mhz
    .sys_rst_n   (locked),   //ȫ�ָ�λ
    .pi_data     (data  ),   //��������
    .pi_flag     (data_flag  ),   //����������Ч��־�ź�
                                
    .tx          (tx       )    //���ڷ�������
);


endmodule
