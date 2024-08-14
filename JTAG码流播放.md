# 硬件环境

实现板卡：A3P250

外FLASH：ｗ25Q128 （spi协议）



# 大体步骤

1、如何下载文件到flash，擦除flash

2、读取flash是否需要缓存

3、读出来的数据传到jtag端口





# SPI协议总结

根据从机设备的个数，SPI通讯设备之间的连接方式可分为一主一从和一主多从，全双工通信协议

![SPIFla003](https://doc.embedfire.com/fpga/altera/ep4ce10_pro/zh/latest/_images/SPIFla003.png)

## **四个信号线：**

SCK (Serial Clock)：时钟信号线，用于同步通讯数据。

MOSI (Master Output， Slave Input)：主设备输出/从设备输入引脚。

MISO (Master Input，Slave Output)：主设备输入/从设备输出引脚。

(Chip Select)：片选信号线，也称为CS_N，以下用CS_N表示。当有多个SPI从设备与SPI主机相连时，设备的其它信号线SCK、MOSI及MISO同时并联到相同的SPI总线上，即无论有多少个从设备，都共同使用这3条总线；而每个从设备都有独立的这一条CS_N信号线，本信号线独占主机 的一个引脚，即有多少个从设备，就有多少条片选信号线。当主机要选择从设备时，把该从设备的CS_N信号线设置为低电平，所以**SPI通讯以CS_N线置低电平为开始信号，以CS_N线被拉高作为结束信号**。



## **四种模式**

SPI通讯协议一共有四种通讯模式，模式0、模式1、模式2以及模式3，这4种模式分别由**时钟极性**(CPOL，Clock Polarity)和**时钟相位**(CPHA，Clock Phase)来定义

CPOL参数规定了空闲状态(CS_N为高电平，设备未被选中)时SCK时钟信号的电平状态

CPHA规定了数据采样是在SCK时钟的奇数边沿还是偶数边沿。



模式0：CPOL= 0，CPHA=0。空闲状态时SCK串行时钟为低电平；数据采样在SCK时钟的奇数边沿，本模式中，奇数边沿为上升沿；数据更新在SCK时钟的偶数边沿，本模式中，偶数边沿为下降沿。

模式1：CPOL= 0，CPHA=1。空闲状态时SCK串行时钟为低电平；数据采样在SCK时钟的偶数边沿，本模式中，偶数边沿为下降沿；数据更新在SCK时钟的奇数边沿，本模式中，偶数边沿为上升沿。

模式2：CPOL= 1，CPHA=0。空闲状态时SCK串行时钟为高电平；数据采样在SCK时钟的奇数边沿，本模式中，奇数边沿为下降沿；数据更新在SCK时钟的偶数边沿，本模式中，偶数边沿为上升沿。

模式3：CPOL= 1，CPHA=1。空闲状态时SCK串行时钟为高电平；数据采样在SCK时钟的偶数边沿，本模式中，偶数边沿为上升沿；数据更新在SCK时钟的奇数边沿，本模式中，偶数边沿为下降沿。

**注意采集数据和更新数据不是同一个时钟沿**

![img](https://doc.embedfire.com/fpga/altera/ep4ce10_pro/zh/latest/_images/SPIFla004.png)

![img](https://doc.embedfire.com/fpga/altera/ep4ce10_pro/zh/latest/_images/SPIFla005.png)

![SPIFla006](https://doc.embedfire.com/fpga/altera/ep4ce10_pro/zh/latest/_images/SPIFla006.png)

## 采用模式0设计

SPI通讯协议的4中通讯模式，其中模式0和模式3比较常用，下面我们以模式0为例

![SPIFla007](https://doc.embedfire.com/fpga/altera/ep4ce10_pro/zh/latest/_images/SPIFla007.png)



# SPI-FLASH擦除设计























