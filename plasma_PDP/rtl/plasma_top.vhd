---------------------------------------------------------------------
-- TITLE: Plamsa Interface (clock divider and interface to FPGA board)
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 9/15/07
-- FILENAME: plasma_top.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity is the platform top module
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
library unisim;
use unisim.vcomponents.all;

entity plasma_top is
	generic(log_file    : string := "UNUSED";
            use_cache   : std_logic := '0');
    port(SYS_CLK        : in std_logic;
        SYS_RESET      : in std_logic;
        RS232_DCE_RXD : in std_logic;
        RS232_DCE_TXD : out std_logic;

        SD_CK_P    : out std_logic;     --DDR SDRAM clock_positive
        SD_CK_N    : out std_logic;     --clock_negative
        SD_CKE     : out std_logic;     --clock_enable

        SD_BA      : out std_logic_vector(1 downto 0);  --bank_address
        SD_A       : out std_logic_vector(12 downto 0); --address(row or col)
        SD_CS      : out std_logic;     --chip_select
        SD_RAS     : out std_logic;     --row_address_strobe
        SD_CAS     : out std_logic;     --column_address_strobe
        SD_WE      : out std_logic;     --write_enable

        SD_DQ      : inout std_logic_vector(15 downto 0); --data
        SD_UDM     : out std_logic;     --upper_byte_enable
        SD_UDQS    : inout std_logic;   --upper_data_strobe
        SD_LDM     : out std_logic;     --low_byte_enable
        SD_LDQS    : inout std_logic;   --low_data_strobe

        LED        : out std_logic_vector(7 downto 0)
		  );
end; --entity plasma_top


architecture logic of plasma_top is

	component clk_gen
	  port(
			reset       : in  std_logic;
			sys_clk     : in  std_logic;
			dcm_lock    : out std_logic;
			clk_2x      : out std_logic;
			clk_o       : out std_logic
	  );
   end component;
	 
   component plasma
      generic(
              log_file    : string := "UNUSED";
              use_cache   : std_logic := '0');
      port(clk          : in std_logic;
           reset        : in std_logic;
           uart_write   : out std_logic;
           uart_read    : in std_logic;
   
           address      : out std_logic_vector(31 downto 2);
           byte_we      : out std_logic_vector(3 downto 0); 
           data_write   : out std_logic_vector(31 downto 0);
           data_read    : in std_logic_vector(31 downto 0);
           mem_pause_in : in std_logic;
           no_ddr_start : out std_logic;
           no_ddr_stop  : out std_logic;
        
           gpio0_out    : out std_logic_vector(31 downto 0);
           gpioA_in     : in std_logic_vector(31 downto 0));
   end component; --plasma
	
	component ddr_ctrl_top
		generic ( DDR_DLL : string := "DISABLE" );
      port(clk       : in std_logic;
           clk_2x    : in std_logic;
           reset_in  : in std_logic;
                     
           address   : in std_logic_vector(31 downto 2);
           byte_we   : in std_logic_vector(3 downto 0);
           data_w    : in std_logic_vector(31 downto 0);
           data_r    : out std_logic_vector(31 downto 0);
           no_start  : in std_logic;
           no_stop   : in std_logic;
           pause     : out std_logic;
           init_done : out std_logic;

           SD_CK_P   : out std_logic;     --clock_positive
           SD_CK_N   : out std_logic;     --clock_negative
           SD_CKE    : out std_logic;     --clock_enable
                     
           SD_BA     : out std_logic_vector(1 downto 0);  --bank_address
           SD_A      : out std_logic_vector(12 downto 0); --address(row or col)
           SD_CS     : out std_logic;     --chip_select
           SD_RAS    : out std_logic;     --row_address_strobe
           SD_CAS    : out std_logic;     --column_address_strobe
           SD_WE     : out std_logic;     --write_enable
                     
           SD_DQ     : inout std_logic_vector(15 downto 0); --data
           SD_UDM    : out std_logic;     --upper_byte_enable
           SD_UDQS   : inout std_logic;   --upper_data_strobe
           SD_LDM    : out std_logic;     --low_byte_enable
           SD_LDQS   : inout std_logic);  --low_data_strobe
   end component; --ddr_ctrl_top

   signal address      : std_logic_vector(31 downto 2);
   signal data_write   : std_logic_vector(31 downto 0);
   signal data_read    : std_logic_vector(31 downto 0);
   signal byte_we      : std_logic_vector(3 downto 0);
   signal pause        : std_logic;
   signal no_ddr_start : std_logic;
   signal no_ddr_stop  : std_logic;

   signal gpio0_out    : std_logic_vector(31 downto 0);
   signal gpio0_in     : std_logic_vector(31 downto 0);
	
	signal dcm_lock	   : std_logic;
	signal clk_2x	   : std_logic;
	signal clk	       : std_logic;
	signal init_done   : std_logic;
	
	signal sys_clk_in  : std_logic;
	signal reset_in	   : std_logic;
	signal reset	   : std_logic;
	signal reset_cpu   : std_logic;
   
begin  --architecture
    
	 SYS_CLK_INST : IBUF               -- Clock must be buffered with IBUF(G) before use.
    port map (
      I  => SYS_CLK,
      O  => sys_clk_in
      );
   
	 reset_in <= not SYS_RESET;
	
    u0_clk: clk_gen
        PORT MAP(
            reset       => reset_in,
            sys_clk     => sys_clk_in,
            dcm_lock    => dcm_lock,
            clk_2x      => clk_2x,
            clk_o       => clk
        );
		  	
	reset <= reset_in or (not dcm_lock);
	reset_cpu <= reset or (not init_done);
	
   LED <= gpio0_out(7 downto 0);
	gpio0_in <= X"00000000";

   u1_plasma: plasma 
      generic map (
                   log_file    => log_file,
                   use_cache   => use_cache)
      PORT MAP (
         clk          => clk,
         reset        => reset_cpu,
         uart_write   => RS232_DCE_TXD,
         uart_read    => RS232_DCE_RXD,
 
         address      => address,
         byte_we      => byte_we,
         data_write   => data_write,
         data_read    => data_read,
         mem_pause_in => pause,
         no_ddr_start => no_ddr_start,
         no_ddr_stop  => no_ddr_stop, 

         gpio0_out    => gpio0_out,
         gpioA_in     => gpio0_in);

		u2_ddr: ddr_ctrl_top
      generic map ( DDR_DLL => "DISABLE" )
      port map (
         clk       => clk,
         clk_2x    => clk_2x,
         reset_in  => reset,
                   
         address   => address,
         byte_we   => byte_we,
         data_w    => data_write,
         data_r    => data_read,
         no_start  => no_ddr_start,
         no_stop   => no_ddr_stop,
         pause     => pause,
         init_done => init_done,

         SD_CK_P   => SD_CK_P,    --clock_positive
         SD_CK_N   => SD_CK_N,    --clock_negative
         SD_CKE    => SD_CKE,     --clock_enable
                   
         SD_BA     => SD_BA,      --bank_address
         SD_A      => SD_A,       --address(row or col)
         SD_CS     => SD_CS,      --chip_select
         SD_RAS    => SD_RAS,     --row_address_strobe
         SD_CAS    => SD_CAS,     --column_address_strobe
         SD_WE     => SD_WE,      --write_enable
                   
         SD_DQ     => SD_DQ,      --data
         SD_UDM    => SD_UDM,     --upper_byte_enable
         SD_UDQS   => SD_UDQS,    --upper_data_strobe
         SD_LDM    => SD_LDM,     --low_byte_enable
         SD_LDQS   => SD_LDQS);   --low_data_strobe	
			
         
end; --architecture logic

