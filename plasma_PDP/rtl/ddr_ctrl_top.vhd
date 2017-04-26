library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.mlite_pack.all;

entity ddr_ctrl_top is
	generic ( DDR_DLL : string := "DISABLE" );
   port(
      clk       : in std_logic;
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
end; --entity ddr_ctrl_top

architecture logic of ddr_ctrl_top is

    component ddr_init
	 generic (DDR_DLL : string := "DISABLE");
     port(  clk          : in  std_logic;
            reset        : in  std_logic;
            pause        : in  std_logic;
            address      : out std_logic_vector(31 downto 2);
            byte_we      : out std_logic_vector(3 downto 0);
            initiating   : out std_logic;
            init_done    : out std_logic
         );
   end component; -- ddr init

    component ddr_ctrl
	  generic (DDR_DLL : string := "DISABLE");
      port(clk      : in std_logic;
           clk_2x   : in std_logic;
           reset_in : in std_logic;

           address  : in std_logic_vector(26 downto 2);
           byte_we  : in std_logic_vector(3 downto 0);
           data_w   : in std_logic_vector(31 downto 0);
           data_r   : out std_logic_vector(31 downto 0);
           active   : in std_logic;
           no_start : in std_logic;
           no_stop  : in std_logic;
           pause    : out std_logic;

           SD_CK_P  : out std_logic;     --clock_positive
           SD_CK_N  : out std_logic;     --clock_negative
           SD_CKE   : out std_logic;     --clock_enable

           SD_BA    : out std_logic_vector(1 downto 0);  --bank_address
           SD_A     : out std_logic_vector(12 downto 0); --address(row or col)
           SD_CS    : out std_logic;     --chip_select
           SD_RAS   : out std_logic;     --row_address_strobe
           SD_CAS   : out std_logic;     --column_address_strobe
           SD_WE    : out std_logic;     --write_enable

           SD_DQ    : inout std_logic_vector(15 downto 0); --data
           SD_UDM   : out std_logic;     --upper_byte_enable
           SD_UDQS  : inout std_logic;   --upper_data_strobe
           SD_LDM   : out std_logic;     --low_byte_enable
           SD_LDQS  : inout std_logic);  --low_data_strobe
   end component; --ddr controller
	
   signal initiating    : std_logic;
   signal address_init  : std_logic_vector(31 downto 2);
   signal byte_we_init  : std_logic_vector(3 downto 0);
   
   signal address_ddr   : std_logic_vector(31 downto 2);
   signal byte_we_ddr   : std_logic_vector(3 downto 0);
   signal SD_CKE_ddr    : std_logic;
   signal active_ddr    : std_logic;
   signal pause_ddr     : std_logic;
	

begin
      
      u1_ddr_init: ddr_init
		generic map (DDR_DLL => DDR_DLL)
        port map(  
            clk          => clk,
            reset        => reset_in,
            pause        => pause_ddr,
            address      => address_init,
            byte_we      => byte_we_init,
            initiating   => initiating,
            init_done    => init_done
         );

      address_ddr <= address_init when initiating = '1' else address;
      byte_we_ddr <= byte_we_init when initiating = '1' else byte_we;
      SD_CKE <= '1' when initiating = '1' else SD_CKE_ddr; 
		active_ddr <= '1' when address_ddr(31 downto 28) = "0001" else '0';
		
		pause <= pause_ddr;
         
      u2_ddr: ddr_ctrl
        generic map (DDR_DLL => DDR_DLL)
        port map (
         clk      => clk,
         clk_2x   => clk_2x,
         reset_in => reset_in,

         address  => address_ddr(26 downto 2),
         byte_we  => byte_we_ddr,
         data_w   => data_w,
         data_r   => data_r,
         active   => active_ddr,
         no_start => no_start,
         no_stop  => no_stop,
         pause    => pause_ddr,

         SD_CK_P  => SD_CK_P,    --clock_positive
         SD_CK_N  => SD_CK_N,    --clock_negative
         SD_CKE   => SD_CKE_ddr,     --clock_enable
   
         SD_BA    => SD_BA,      --bank_address
         SD_A     => SD_A,       --address(row or col)
         SD_CS    => SD_CS,      --chip_select
         SD_RAS   => SD_RAS,     --row_address_strobe
         SD_CAS   => SD_CAS,     --column_address_strobe
         SD_WE    => SD_WE,      --write_enable

         SD_DQ    => SD_DQ,      --data
         SD_UDM   => SD_UDM,     --upper_byte_enable
         SD_UDQS  => SD_UDQS,    --upper_data_strobe
         SD_LDM   => SD_LDM,     --low_byte_enable
         SD_LDQS  => SD_LDQS);   --low_data_strobe	
			
end;
