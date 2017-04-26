library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

entity clk_gen is
    port(
            reset       : in  std_logic;
            sys_clk     : in  std_logic;
            dcm_lock    : out std_logic;
            clk_2x      : out std_logic;
            clk_o       : out std_logic
        );
end;

architecture logic of clk_gen is

    signal clk0_bufg_in      :   std_logic;
    signal clk0_bufg_out     :   std_logic;
    signal clk_2x_bufg_in    :   std_logic;
    signal clk_2x_bufg_out   :   std_logic;
    signal clk_bufg_in       :   std_logic;
    signal clk_bufg_out      :   std_logic;
   
begin

  clk_2x   <= clk_2x_bufg_out;     -- clk_2x after a BUFG. Refer to Xilinx UG619 for detail information
  clk_o    <= clk_bufg_out;        -- clk after a BUFG. Refer to Xilinx UG619 for detail information

  DCM_BASE0 : DCM_BASE              -- use DCM to generate the 50 MHz clock. Refer to Xilinx UG070 page 55 or UG619 page 36 for more information about DCMs
    generic map(
      DLL_FREQUENCY_MODE    => "LOW",
      DUTY_CYCLE_CORRECTION => TRUE,
      CLKFX_DIVIDE          => 24,
      CLKFX_MULTIPLY        => 19,
      FACTORY_JF            => X"F0F0"
      )
    port map(
      CLK0      => clk0_bufg_in,
      CLK180    => open,
      CLK270    => open,
      CLK2X     => open,
      CLK2X180  => open,
      CLK90     => open,
      CLKDV     => open,
      CLKFX     => clk_2x_bufg_in,
      CLKFX180  => open,
      LOCKED    => dcm_lock,
      CLKFB     => clk0_bufg_out,
      CLKIN     => sys_clk,
      RST       => reset
      );

    CLK0_BUF : BUFG                  
    port map 
    (
      O => clk0_bufg_out,           
      I => clk0_bufg_in
    );
      
    CLK2X_BUF : BUFG                   
    port map 
    (
      O => clk_2x_bufg_out,           
      I => clk_2x_bufg_in
    );
    
    --Divide clk_2x_bufg_out clock by two. DDR controller needs two clocks: clk and clk_2x. The latter one is twice faster than the former one. 
    --When other clock speed is used, it is strongly suggested always to generate clk by dividing clk_2x by 2 to avoid any timing issues.
    --A manual timing constraint for clk_bufg_out is in the ucf file. If the divider is replaced with a DCM that constraint should be removed.
   clk_div: process(reset, clk_2x_bufg_out)
   begin
      if reset = '1' then
         clk_bufg_in <= '0';
      elsif rising_edge(clk_2x_bufg_out) then
         clk_bufg_in <= not clk_bufg_in;
      end if;
   end process; --clk_div
    
    CLK_BUF : BUFG                   
    port map 
    (
      O => clk_bufg_out,           
      I => clk_bufg_in
    );
end;