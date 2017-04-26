---------------------------------------------------------------------
-- TITLE: Plasma Interface to FPGA ML410 board
-- AUTHOR: George R. Voicu (razvanvg@hotmail.com)
-- DATE CREATED: 3/24/14
-- FILENAME: top_ml410.vhd
-- PROJECT: Processor Design Lab
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity divides the clock by two and interfaces to the 
--    Xilinx ML410 board with Virtex-4 XC4VFX60-FF1152 FPGA and 2x32MB DDR.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
--use work.mlite_pack.all;

entity top_ml410 is
   port(sys_clk_pin                              : in std_logic;
        sys_rst_pin                              : in std_logic;     -- reset, active low
        fpga_0_RS232_Uart_1_ctsN_pin             : in std_logic;
        fpga_0_RS232_Uart_1_rtsN_pin             : out std_logic;
        fpga_0_RS232_Uart_1_sin_pin              : in std_logic;
        fpga_0_RS232_Uart_1_sout_pin             : out std_logic;

        fpga_0_DDR_SDRAM_32Mx64_DDR_Clk_pin      : out std_logic;     --DDR SDRAM clock_positive
        fpga_0_DDR_CLK_FB                        : in  std_logic;     --DDR clk feedback
        fpga_0_DDR_SDRAM_32Mx64_DDR_Clkn_pin     : out std_logic;     --clock_negative
        fpga_0_DDR_SDRAM_32Mx64_DDR_CKE_pin      : out std_logic;     --clock_enable

        fpga_0_DDR_SDRAM_32Mx64_DDR_BankAddr_pin : out std_logic_vector(1 downto 0);  --bank_address
        fpga_0_DDR_SDRAM_32Mx64_DDR_Addr_pin     : out std_logic_vector(12 downto 0); --address(row or col)
        fpga_0_DDR_SDRAM_32Mx64_DDR_CSn_pin      : out std_logic;     --chip_select
        fpga_0_DDR_SDRAM_32Mx64_DDR_RASn_pin     : out std_logic;     --row_address_strobe
        fpga_0_DDR_SDRAM_32Mx64_DDR_CASn_pin     : out std_logic;     --column_address_strobe
        fpga_0_DDR_SDRAM_32Mx64_DDR_WEn_pin      : out std_logic;     --write_enable

        fpga_0_DDR_SDRAM_32Mx64_DDR_DQ_pin       : inout std_logic_vector(31 downto 0); --data
        fpga_0_DDR_SDRAM_32Mx64_DDR_DM_pin       : out std_logic_vector(3 downto 0);     --byte_enable
        fpga_0_DDR_SDRAM_32Mx64_DDR_DQS_pin      : inout std_logic_vector(3 downto 0);   --data_strobe


        fpga_0_LEDs_8Bit_GPIO_IO_pin       : out std_logic_vector(7 downto 0) );
end; --entity top_ml410


architecture logic of top_ml410 is

   component plasma_top
       generic(log_file    : string := "UNUSED";
       use_cache   : std_logic := '0');
       port(SYS_CLK            : in std_logic;
            SYS_RESET          : in std_logic;
            RS232_DCE_RXD  : in std_logic;
            RS232_DCE_TXD  : out std_logic;

            SD_CK_P         : out std_logic;     --DDR SDRAM clock_positive
            SD_CK_N         : out std_logic;     --clock_negative
            SD_CKE          : out std_logic;     --clock_enable
        
            SD_BA           : out std_logic_vector(1 downto 0);  --bank_address
            SD_A            : out std_logic_vector(12 downto 0); --address(row or col)
            SD_CS           : out std_logic;     --chip_select
            SD_RAS          : out std_logic;     --row_address_strobe
            SD_CAS          : out std_logic;     --column_address_strobe
            SD_WE           : out std_logic;     --write_enable
        
            SD_DQ           : inout std_logic_vector(15 downto 0); --data
            SD_UDM          : out std_logic;     --upper_byte_enable
            SD_UDQS         : inout std_logic;   --upper_data_strobe
            SD_LDM          : out std_logic;     --low_byte_enable
            SD_LDQS         : inout std_logic;   --low_data_strobe
        
            LED             : out std_logic_vector(7 downto 0));
   end component; --plasma_top
      
begin  --architecture                   

   -- Default values for unused signals on the board
   -- Although the ML410 board has 2 x 32MB DDR chips we only use one chip for the sake of simplicity
   fpga_0_DDR_SDRAM_32Mx64_DDR_DM_pin(3 downto 2)   <= "00";
   fpga_0_DDR_SDRAM_32Mx64_DDR_DQ_pin(31 downto 16) <= (others => '0'); 
   fpga_0_DDR_SDRAM_32Mx64_DDR_DQS_pin(3 downto 2)  <= "00";   
   fpga_0_RS232_Uart_1_rtsN_pin <= '0';
                                                                                     
   u1_plasma_top: plasma_top                                                          
      generic map (log_file    => "UNUSED",  
                   use_cache   => '1')                                           
      port map (                                                                       
        SYS_CLK             =>  sys_clk_pin,                                                    
        SYS_RESET           =>  sys_rst_pin,                                                      
        RS232_DCE_RXD   =>  fpga_0_RS232_Uart_1_sin_pin,    
        RS232_DCE_TXD   =>  fpga_0_RS232_Uart_1_sout_pin,    
                            
        SD_CK_P         =>  fpga_0_DDR_SDRAM_32Mx64_DDR_Clk_pin,    
        SD_CK_N         =>  fpga_0_DDR_SDRAM_32Mx64_DDR_Clkn_pin, 
        SD_CKE          =>  fpga_0_DDR_SDRAM_32Mx64_DDR_CKE_pin,   
                                
        SD_BA           =>  fpga_0_DDR_SDRAM_32Mx64_DDR_BankAddr_pin,  
        SD_A            =>  fpga_0_DDR_SDRAM_32Mx64_DDR_Addr_pin,     
        SD_CS           =>  fpga_0_DDR_SDRAM_32Mx64_DDR_CSn_pin,    
        SD_RAS          =>  fpga_0_DDR_SDRAM_32Mx64_DDR_RASn_pin,   
        SD_CAS          =>  fpga_0_DDR_SDRAM_32Mx64_DDR_CASn_pin,   
        SD_WE           =>  fpga_0_DDR_SDRAM_32Mx64_DDR_WEn_pin,    
                               
        SD_DQ           =>  fpga_0_DDR_SDRAM_32Mx64_DDR_DQ_pin(15 downto 0), 
        SD_UDM          =>  fpga_0_DDR_SDRAM_32Mx64_DDR_DM_pin(1),     
        SD_UDQS         =>  fpga_0_DDR_SDRAM_32Mx64_DDR_DQS_pin(1),    
        SD_LDM          =>  fpga_0_DDR_SDRAM_32Mx64_DDR_DM_pin(0),     
        SD_LDQS         =>  fpga_0_DDR_SDRAM_32Mx64_DDR_DQS_pin(0),
       
        LED             =>  fpga_0_LEDs_8Bit_GPIO_IO_pin(7 downto 0)
		  );
        
         
end; --architecture logic

