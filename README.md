使用須知：
　本專案用ISE 14.7 做開發，若使用不同的ISE版本需要重建專案
　目前使用的FPGA是Xilinx Spartan-6系列的XC6SLX75T

專案須包含
　1. 資料夾下的所有 .v 檔
　2. 利用ISE 的 IP core generator生成 xilinx_ram_65536 module，此module 為一 width 32 bit，depth 65536 的 block memory
　3. pin腳設定檔 ( top.ucf )

版本：
　OpenRISC：OR1200 Rev. 1
　Wishbone Bus：Opencores 提供的 wb_conmax ( Wishbone Rev. B2 )

特色：
　將address 65535 mapping 到FPGA上提供的LED、button與 GPIO
　不須接 RS232，可透過 USB 線做 UART 的輸出

Feature work：
　OpenRISC更新到 Rev. 2 ( 或更新版本 )
　　新版core將可提供cache write through / back 的選擇
　　( Rev. 1 僅實作 write through )

　Wishbone Bus 更新到 Rev. B3 ( 或更新版本 )