library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ddr_init is
	generic ( DDR_DLL : string := "DISABLE" );
   port(
      clk          : in  std_logic;
      reset        : in  std_logic;
      pause        : in  std_logic;
      address      : out std_logic_vector(31 downto 2);
      byte_we      : out std_logic_vector(3 downto 0);
      initiating   : out std_logic;
      init_done    : out std_logic
      );

end; --entity ddr_init

architecture logic of ddr_init is
    
    subtype command_type is std_logic_vector(31 downto 2);
    constant GND            : command_type := "000000000000000000000000000000";
    constant NOP            : command_type := "000100000000000000000000011100";         -- (0x000 << 12) | (0 << 10) | (7 << 4),  //CKE=1; NOP="111"
    constant PRECHARGE_ALL  : command_type := "000100000100000000000000001000";         -- (0x400 << 12) | (0 << 10) | (2 << 4),  //A10=1; PRECHARGE ALL="010"
    constant ENABLE_DLL     : command_type := "000100000000000000000100000000";         -- (0x000 << 12) | (1 << 10) | (0 << 4),  //enable DLL; BA="01"; LMR="000"
    constant DISABLE_DLL    : command_type := "000100000000000000010100000000";         -- (0x001 << 12) | (1 << 10) | (0 << 4),  //disable DLL; BA="01"; LMR="000"
    constant RESET_DLL      : command_type := "000100000001001000010000000000";         -- (0x121 << 12) | (0 << 10) | (0 << 4),  //reset DLL, CL=2, BL=2; LMR="000"
    constant AUTO_REFRESH   : command_type := "000100000000000000000000000100";         -- (0x000 << 12) | (0 << 10) | (1 << 4),  //AUTO REFRESH="001"
    constant CLEAR_DLL      : command_type := "000100000000001000010000000000";         -- (0x021 << 12) | (0 << 10) | (0 << 4)   //clear DLL, CL=2, BL=2; LMR="000"  
    constant ACTIVE_DDR		 : command_type := "000100000000000000000000000000";
	 
    subtype state_type is std_logic_vector(3 downto 0);
    constant IDLE       : state_type := "0000";
    constant STEP_1     : state_type := "0001";
    constant STEP_2     : state_type := "0010";
    constant STEP_3     : state_type := "0011";
    constant STEP_4     : state_type := "0100";
    constant STEP_5     : state_type := "0101";
    constant STEP_6     : state_type := "0110";
    constant STEP_7     : state_type := "0111";
    constant STEP_8     : state_type := "1000";
    constant STEP_9     : state_type := "1001";
    constant STEP_10    : state_type := "1010";
    constant STEP_11    : state_type := "1011";
    constant STEP_12    : state_type := "1100";
    constant STEP_13    : state_type := "1101";
    constant STEP_14    : state_type := "1110";
    constant STEP_15    : state_type := "1111";
 
    signal  init_step   : std_logic_vector(3 downto 0);
    signal  next_step   : std_logic_vector(3 downto 0);
    signal  wait_cnt    : std_logic_vector(7 downto 0);
    signal  wait_cycle  : std_logic_vector(7 downto 0);
    signal  cnt_done    : std_logic;
    signal  address_wire : std_logic_vector(31 downto 2);
    signal  byte_we_wire : std_logic_vector(3 downto 0);
    signal  select_flag  : std_logic;
begin

    init_proc:  process (clk,reset,init_step,next_step,wait_cnt,wait_cycle,cnt_done)       -- state machine to init ddr
    begin
        byte_we_wire <= "0000";
        case init_step is 
            when IDLE =>                          -- Do nothing when reset
                init_done <= '0';
                initiating <= '0';
                address_wire <= GND;
                byte_we_wire <= "0000";
                wait_cycle <= X"0A";
                next_step <= STEP_1;
            when STEP_1 =>                          -- write NOP command 
                init_done <= '0';
                initiating <= '1';
                address_wire <= NOP;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_2;
            when STEP_2 =>                          -- write PRECHARGE_ALL command
                init_done <= '0';
                initiating <= '1';
				    address_wire <= PRECHARGE_ALL;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_3;
            when STEP_3 =>                          
                init_done <= '0';
				    initiating <= '1';
					 if DDR_DLL = "DISABLE" then
						address_wire <= DISABLE_DLL;
					 else
						address_wire <= ENABLE_DLL;
					 end if;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_4;
            when STEP_4 =>
                init_done <= '0';
                initiating <= '1';
                address_wire <= RESET_DLL;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_5;
            when STEP_5 =>                          
                init_done <= '0';
				initiating <= '1';
				address_wire <= NOP;
                byte_we_wire <= "1111";
                wait_cycle <= X"C8";
                next_step <= STEP_6;
            when STEP_6 =>
                init_done <= '0';
				initiating <= '1';
				address_wire <= PRECHARGE_ALL;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_7;
            when STEP_7 =>
                init_done <= '0';
				initiating <= '1';
				address_wire <= AUTO_REFRESH;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_8;
            when STEP_8 =>
                init_done <= '0';
				initiating <= '1';
				address_wire <= AUTO_REFRESH;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_9;
            when STEP_9 =>
                init_done <= '0';
				initiating <= '1';
                address_wire <= CLEAR_DLL;
                byte_we_wire <= "1111";
                wait_cycle <= X"0A";
                next_step <= STEP_10;
            when STEP_10 =>
                init_done <= '0';
				initiating <= '1';
				address_wire <= ACTIVE_DDR;
                byte_we_wire <= "0000";
                wait_cycle <= X"0A";
                next_step <= STEP_11;
            when STEP_11 =>                           -- Init done
                init_done <= '1';
				initiating <= '0';
				address_wire <= GND;
                wait_cycle <= X"00";
                next_step <= STEP_11;
            when others =>
                null;
        end case;            

        if reset = '1' then                         
            init_step <= IDLE;
        elsif rising_edge(clk) then
            if cnt_done = '1' then
                init_step <= next_step;
            else
                init_step <= init_step;
            end if;
        end if;

        if reset = '1' then                     -- counter
            wait_cnt <= X"00";
        elsif rising_edge(clk) then
            if pause = '1' then
                wait_cnt <= X"00";
            else
                if cnt_done = '0' then
                    wait_cnt <= wait_cnt + X"01";
                else
                    wait_cnt <= X"00";
                end if;
            end if;
        end if;

    end process;
    
    cnt_done <= '1' when wait_cnt = wait_cycle else '0';
    select_flag <= '1' when wait_cnt = X"00" else '0';
        
    address <= address_wire when select_flag = '1' else GND;
    byte_we <= byte_we_wire when select_flag = '1' else "0000";

end;