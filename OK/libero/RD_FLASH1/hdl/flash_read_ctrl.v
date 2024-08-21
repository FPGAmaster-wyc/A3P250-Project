`timescale  1ns/1ns


module  flash_read_ctrl(

    input   wire            sys_clk     ,   //ϵͳʱ�ӣ�Ƶ��50MHz
    input   wire            ila_clk     ,
    input   wire            sys_rst_n   ,   //��λ�ź�,�͵�ƽ��Ч
    input   wire            key         ,   //���������ź�
    input   wire            miso        ,   //����flash����

    output  reg             sck         ,   //����ʱ��
    output  reg             cs_n        ,   //Ƭѡ�ź�
    output  reg             mosi        ,   //���������������
    output  reg             tx_flag     ,   //������ݱ�־�ź�
    output  wire    [7:0]   tx_data         //�������

);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//

//parameter define
parameter   IDLE    =   3'b001  ,   //��ʼ״̬
            READ    =   3'b010  ,   //���ݶ�״̬
            SEND    =   3'b100  ;   //���ݷ���״̬

parameter   READ_INST   =   8'b0000_0011;   //��ָ��
parameter   NUM_DATA    =   16'd100     ;   //�������ݸ���
parameter   SECTOR_ADDR =   8'b0000_0000,   //������ַ
            PAGE_ADDR   =   8'b0000_0000,   //ҳ��ַ
            BYTE_ADDR   =   8'b0000_0000;   //�ֽڵ�ַ
//parameter   CNT_WAIT_MAX=   16'd6_0000 ;       //50M
parameter   CNT_WAIT_MAX=   16'd2_0000 ;       //10M   10_0000_0000 / 9600 *10

//wire  define
reg    [7:0]   fifo_data_num   ;   //fifo�����ݸ���
//reg   define
reg     [4:0]   cnt_clk         ;   //ϵͳʱ�Ӽ�����
reg     [2:0]   state           ;   //״̬��״̬
reg     [15:0]  cnt_byte        ;   //�ֽڼ�����
reg     [1:0]   cnt_sck         ;   //����ʱ�Ӽ�����
reg     [2:0]   cnt_bit         ;   //���ؼ�����
reg             miso_flag       ;   //miso��ȡ��־�ź�
reg     [7:0]   data            ;   //ƴ������
reg             po_flag_reg     ;   //������ݱ�־�ź�
reg             po_flag         ;   //�������
reg     [7:0]   po_data         ;   //�������
reg             fifo_read_valid ;   //fifo����Ч�ź�
reg     [15:0]  cnt_wait        ;   //�ȴ�������
reg             fifo_read_en    ;   //fifo��ʹ��
reg     [7:0]   read_data_num   ;   //����fifo���ݸ���

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//cnt_clk��ϵͳʱ�Ӽ����������Լ�¼�����ֽ�
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_clk  <=  5'd0;
    else    if(state == READ)
        cnt_clk  <=  cnt_clk + 1'b1;

//cnt_byte����¼����ֽڸ����͵ȴ�ʱ��
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_byte    <=  16'd0;
    else    if((cnt_clk == 5'd31) && (cnt_byte == NUM_DATA + 16'd3))
        cnt_byte    <=  16'd0;
    else    if(cnt_clk == 5'd31)
        cnt_byte    <=  cnt_byte + 1'b1;

//cnt_sck������ʱ�Ӽ��������������ɴ���ʱ��
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_sck <=  2'd0;
    else    if(state == READ)
        cnt_sck <=  cnt_sck + 1'b1;

//cs_n��Ƭѡ�ź�
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cs_n    <=  1'b1;
    else    if(key == 1'b1)
        cs_n    <=  1'b0;
    else    if((cnt_byte == NUM_DATA + 16'd3) && (cnt_clk == 5'd31) && (state == READ))
        cs_n    <=  1'b1;

//sck���������ʱ��
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        sck <=  1'b0;
    else    if(cnt_sck == 2'd0)
        sck <=  1'b0;
    else    if(cnt_sck == 2'd2)
        sck <=  1'b1;

//cnt_bit���ߵ�λ�Ե�������mosi���
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_bit <=  3'd0;
    else    if(cnt_sck == 2'd2)
        cnt_bit <=  cnt_bit + 1'b1;

//state������ʽ״̬����һ�Σ�״̬��ת
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        state   <=  IDLE;
    else
    case(state)
        IDLE:   if(key == 1'b1)
                    state   <=  READ;
        READ:   if((cnt_byte == NUM_DATA + 16'd3) && (cnt_clk == 5'd31))
                    state   <=  SEND;
        SEND:   if((read_data_num == NUM_DATA)
                && ((cnt_wait == (CNT_WAIT_MAX - 1'b1))))
                    state   <=  IDLE;
        default:    state   <=  IDLE;
    endcase

//mosi������ʽ״̬���ڶ��Σ��߼����
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        mosi    <=  1'b0;
    else    if((state == READ) && (cnt_byte>= 16'd4))
        mosi    <=  1'b0;
    else    if((state == READ) && (cnt_byte == 16'd0) && (cnt_sck == 2'd0))
        mosi    <=  READ_INST[7 - cnt_bit];  //��ָ��
    else    if((state == READ) && (cnt_byte == 16'd1) && (cnt_sck == 2'd0))
        mosi    <=  SECTOR_ADDR[7 - cnt_bit];  //������ַ
    else    if((state == READ) && (cnt_byte == 16'd2) && (cnt_sck == 2'd0))
        mosi    <=  PAGE_ADDR[7 - cnt_bit];    //ҳ��ַ
    else    if((state == READ) && (cnt_byte == 16'd3) && (cnt_sck == 2'd0))
        mosi    <=  BYTE_ADDR[7 - cnt_bit];    //�ֽڵ�ַ

//miso_flag��miso��ȡ��־�ź�
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        miso_flag   <=  1'b0;
    else    if((cnt_byte >= 16'd4) && (cnt_sck == 2'd1))
        miso_flag   <=  1'b1;
    else
        miso_flag   <=  1'b0;

//data��ƴ������
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data    <=  8'd0;
    else    if(miso_flag == 1'b1)
        data    <=  {data[6:0],miso};

//po_flag_reg:������ݱ�־�ź�
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        po_flag_reg <=  1'b0;
    else    if((cnt_bit == 3'd7) && (miso_flag == 1'b1))
        po_flag_reg <=  1'b1;
    else
        po_flag_reg <=  1'b0;

//po_flag:������ݱ�־�ź�
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        po_flag <=  1'b0;
    else
        po_flag <=  po_flag_reg;

//po_data:�������
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        po_data <=  8'd0;
    else    if(po_flag_reg == 1'b1)
        po_data <=  data;
    else
        po_data <=  po_data;

//fifo_read_valid:fifo����Ч�ź�
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        fifo_read_valid <=  1'b0;
    else    if((read_data_num == NUM_DATA)
                && ((cnt_wait == (CNT_WAIT_MAX - 1'b1))))
        fifo_read_valid <=  1'b0;
    else    if(fifo_data_num == NUM_DATA)
        fifo_read_valid <=  1'b1;

//cnt_wait:�����ݶ�ȡʱ����
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_wait    <=  16'd0;
    else    if(fifo_read_valid == 1'b0)
        cnt_wait    <=  16'd0;
    else    if(cnt_wait == (CNT_WAIT_MAX - 1'b1))
        cnt_wait    <=  16'd0;
    else    if(fifo_read_valid == 1'b1)
        cnt_wait    <=  cnt_wait + 1'b1;

//fifo_read_en:fifo��ʹ���ź�
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        fifo_read_en <=  1'b0;
    else    if((cnt_wait == (CNT_WAIT_MAX - 1'b1))
                && (read_data_num < NUM_DATA))
        fifo_read_en <=  1'b1;
    else
        fifo_read_en <=  1'b0;

//read_data_num:��fifo�ж������ݸ�������
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        read_data_num <=  8'd0;
    else    if(fifo_read_valid == 1'b0)
        read_data_num <=  8'd0;
    else    if(fifo_read_en == 1'b1)
        read_data_num <=  read_data_num + 1'b1;

//tx_flag
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        tx_flag <=  1'b0;
    else
        tx_flag <=  fifo_read_en;

always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        fifo_data_num <=  1'b0;
    else if (po_flag)
        fifo_data_num <=  fifo_data_num + 1;
    else if (fifo_read_en)
        fifo_data_num <=  fifo_data_num - 1;
    

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//
//-------------fifo_data_inst--------------

fifo8b2048 FIFO(
    .DATA  ( po_data  ),
    .Q     ( tx_data     ),
    .WE    ( po_flag    ),
    .RE    ( fifo_read_en    ),
    .CLK   ( sys_clk   ),
    .FULL  (    ),
    .EMPTY (   ),
    .RESET  ( ~sys_rst_n  )
);


endmodule
