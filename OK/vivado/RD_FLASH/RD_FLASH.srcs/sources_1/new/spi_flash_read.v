`timescale  1ns/1ns

/*������OK*/

module  spi_flash_read(

    input   wire    sys_clk     ,   //ϵͳʱ�ӣ�Ƶ��100MHz
    input   wire    sys_rst   ,   //��λ�ź�,�͵�ƽ��Ч
    input   [3:0]   key      ,   //���������ź�
    input   wire    miso        ,   //����flash����

    output  wire    cs_n        ,   //Ƭѡ�ź�
    output  wire    sck         ,   //����ʱ��
    output  wire    mosi        ,   //���������������
    output  wire    tx              

);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   CNT_MAX     =   20'd999_999     ;   //�������������ֵ
parameter   UART_BPS    =   14'd9600        ,   //������
            CLK_FREQ    =   26'd10_000_000  ;   //ʱ��Ƶ��


//wire  defin5
wire            pi_key  ;
wire            po_key  ;   //���������İ����ź�
wire            tx_flag ;   //���봮�ڷ���ģ�����ݱ�־�ź�
wire    [7:0]   tx_data ;   //���봮�ڷ���ģ������
wire            clk_10M;
wire            ila_clk;
wire            sys_rst_n;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//

assign pi_key = ~key[0];

clk_wiz_0 instance_name (
    // Clock out ports
    .clk_50M(clk_50M),     // output clk_50M   ��Ϊ10M
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
    .CNT_MAX    (CNT_MAX    )   //�������������ֵ
)
key_filter_inst
(
    .sys_clk    (clk_50M    ),  //ϵͳʱ�ӣ�Ƶ��50MHz
    .sys_rst_n  (sys_rst_n  ),  //��λ�ź�,�͵�ƽ��Ч
    .key_in     (pi_key     ),  //���������ź�

    .key_flag   (po_key     )   //�������ź�
);

//-------------flash_read_ctrl_inst-------------
flash_read_ctrl  
#(
    .NUM_DATA    (16'd100    )   //�������ݸ���
)
flash_read_ctrl_inst
(
    .sys_clk    (clk_50M    ),  //ϵͳʱ�ӣ�Ƶ��50MHz
    .ila_clk    (ila_clk)   ,
    .sys_rst_n  (sys_rst_n  ),  //��λ�ź�,�͵�ƽ��Ч
    .key        (po_key     ),  //���������ź�
    .miso       (miso       ),  //����flash����

    .sck        (sck        ),  //Ƭѡ�ź�
    .cs_n       (cs_n       ),  //����ʱ��
    .mosi       (mosi       ),  //���������������
    .tx_flag    (tx_flag    ),  //������ݱ�־�ź�
    .tx_data    (tx_data    )   //�������

);

//-------------uart_tx_inst-------------
uart_tx
#(
    .UART_BPS    (UART_BPS ),         //���ڲ�����
    .CLK_FREQ    (CLK_FREQ )          //ʱ��Ƶ��
)
uart_tx_inst(
    .sys_clk     (clk_50M  ),   //ϵͳʱ��50Mhz
    .sys_rst_n   (sys_rst_n),   //ȫ�ָ�λ
    .pi_data     (tx_data  ),   //��������
    .pi_flag     (tx_flag  ),   //����������Ч��־�ź�
                                
    .tx          (tx       )    //���ڷ�������
);

endmodule
