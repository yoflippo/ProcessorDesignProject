library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity sim_tb_top is

end entity sim_tb_top;

architecture arch of sim_tb_top is
    
    constant CLK_PERIOD_NS      : real := 10000.0 / 1000.0;
    constant TCYC_SYS           : real := CLK_PERIOD_NS/2.0;
    constant TCYC_SYS_DIV2      : time := TCYC_SYS * 1 ns;

	constant log_file  : string :=                  -- UART output is stored in output.txt
	--   "UNUSED";
   "output.txt";
   
  constant sdramfile : string := "ddr_content/opcodes.srec";
  
  component plasma_top
       generic(log_file     : string := "UNUSED";
               use_cache    : std_logic := '1');
       port(SYS_CLK         : in    std_logic;
            SYS_RESET       : in    std_logic;
            RS232_DCE_RXD   : in    std_logic;
            RS232_DCE_TXD   : out   std_logic;

            SD_CK_P         : out   std_logic;     --DDR SDRAM clock_positive
            SD_CK_N         : out   std_logic;     --clock_negative
            SD_CKE          : out   std_logic;     --clock_enable
        
            SD_BA           : out   std_logic_vector(1 downto 0);  --bank_address
            SD_A            : out   std_logic_vector(12 downto 0); --address(row or col)
            SD_CS           : out   std_logic;     --chip_select
            SD_RAS          : out   std_logic;     --row_address_strobe
            SD_CAS          : out   std_logic;     --column_address_strobe
            SD_WE           : out   std_logic;     --write_enable
        
            SD_DQ           : inout std_logic_vector(15 downto 0); --data
            SD_UDM          : out   std_logic;     --upper_byte_enable
            SD_UDQS         : inout std_logic;   --upper_data_strobe
            SD_LDM          : out   std_logic;     --low_byte_enable
            SD_LDQS         : inout std_logic;   --low_data_strobe
            
            LED             : out   std_logic_vector(7 downto 0)
				);
   end component; --plasma_top

    component mt46v16m16 is
    generic (                               -- Timing for -75Z CL2
        fname     : string := "ram.srec";	-- File to read from
        bbits     : INTEGER :=  16
    );
    port (
        Dq    : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        Dqs   : INOUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        Addr  : IN    STD_LOGIC_VECTOR (12 DOWNTO 0);
        Ba    : IN    STD_LOGIC_VECTOR (1 DOWNTO 0);
        Clk   : IN    STD_LOGIC;
        Clk_n : IN    STD_LOGIC;
        Cke   : IN    STD_LOGIC;
        Cs_n  : IN    STD_LOGIC;
        Ras_n : IN    STD_LOGIC;
        Cas_n : IN    STD_LOGIC;
        We_n  : IN    STD_LOGIC;
        Dm    : IN    STD_LOGIC_VECTOR (1 DOWNTO 0)
    );
    end component;

    signal sys_clk      : std_logic := '0';
    signal sys_rst_n    : std_logic := '0';

    signal ddr_dq       : std_logic_vector(15 downto 0);
    signal ddr_dqs      : std_logic_vector(1 downto 0);
    signal ddr_address  : std_logic_vector(12 downto 0);
    signal ddr_ba       : std_logic_vector(1 downto 0);
    signal ddr_clk      : std_logic;
    signal ddr_clk_n    : std_logic;
    signal ddr_cke      : std_logic;
    signal ddr_cs_n     : std_logic;
    signal ddr_ras_n    : std_logic;
    signal ddr_cas_n    : std_logic;
    signal ddr_we_n     : std_logic;
    signal ddr_dm       : std_logic_vector(1 downto 0);

begin

  --***************************************************************************
  -- Clock generation and reset
  --***************************************************************************
  process           -- Generate 100 MHz, i.e., the clk on FPGA board
  begin
    wait for (TCYC_SYS_DIV2);
    sys_clk <= not sys_clk;
  end process;

  process           -- The reset on FPGA board is active low
  begin
    sys_rst_n <= '0';
    wait for 200 ns;
    sys_rst_n <= '1';
    wait;
  end process;
      
    
  --***************************************************************************
  -- Plasma & DDR controller
  --*************************************************************************** 

	u1_plasma_top: plasma_top                                                          
      generic map (log_file    => log_file,
                   use_cache   => '1')                                           
      port map (                                                                       
        SYS_CLK         =>  sys_clk,                                                    
        SYS_RESET       =>  sys_rst_n,                                                      
        RS232_DCE_RXD   =>  '0',    
        RS232_DCE_TXD   =>  open,    
                            
        SD_CK_P         =>  ddr_clk,    
        SD_CK_N         =>  ddr_clk_n, 
        SD_CKE          =>  ddr_cke,   
                                
        SD_BA           =>  ddr_ba,  
        SD_A            =>  ddr_address,     
        SD_CS           =>  ddr_cs_n,    
        SD_RAS          =>  ddr_ras_n,   
        SD_CAS          =>  ddr_cas_n,   	
        SD_WE           =>  ddr_we_n,    
                               
        SD_DQ           =>  ddr_dq, 
        SD_UDM          =>  ddr_dm(1),     
        SD_UDQS         =>  ddr_dqs(1),    
        SD_LDM          =>  ddr_dm(0),     
        SD_LDQS         =>  ddr_dqs(0),
        
        LED             =>  open
		 );

--  DDR model
    u1_ddr_model : mt46v16m16 
    generic map (fname => sdramfile, bbits => 16)
    PORT MAP(
      Dq    => ddr_dq, 
      Dqs   => ddr_dqs, 
      Addr  => ddr_address,
      Ba    => ddr_ba, 
      Clk   => ddr_clk,  
      Clk_n => ddr_clk_n, 
      Cke   => ddr_cke,
      Cs_n  => ddr_cs_n, 
      Ras_n => ddr_ras_n, 
      Cas_n => ddr_cas_n, 
      We_n  => ddr_we_n,
      Dm    => ddr_dm
      );

end architecture;
