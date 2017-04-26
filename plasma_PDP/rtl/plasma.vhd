---------------------------------------------------------------------
-- TITLE: Plasma (CPU core with memory)
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 6/4/02
-- FILENAME: plasma.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity combines the CPU core with memory and a UART.
--
-- Memory Map:
--   0x00000000 - 0x00000fff   Internal RAM (4KB)
--   0x10000000 - 0x11ffffff   External RAM (32MB)
--   Access all Misc registers with 32-bit accesses
--   0x20000000  Uart Write (will pause CPU if busy)
--   0x20000000  Uart Read
--   0x20000010  IRQ Mask
--   0x20000020  IRQ Status
--   0x20000030  GPIO0 Out Set bits
--   0x20000040  GPIO0 Out Clear bits
--   0x20000050  GPIOA In
--   0x20000060  Counter HI - for measuring cpu cycles
--   0x20000068  Counter LO - for measuring cpu cycles
--   IRQ bits:
--      7   GPIO31
--      6  ^GPIO31
--      5   Counter(31)
--      4  ^Counter(31)
--      3   Counter(18)
--      2  ^Counter(18)
--      1  ^UartWriteBusy
--      0   UartDataAvailable
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.mlite_pack.all;

entity plasma is
   generic(log_file    : string := "UNUSED";
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
end; --entity plasma

architecture logic of plasma is
   signal address_next      : std_logic_vector(31 downto 2);
   signal byte_we_next      : std_logic_vector(3 downto 0);
   signal cpu_address       : std_logic_vector(31 downto 0);
   signal cpu_byte_we       : std_logic_vector(3 downto 0);
   signal cpu_data_w        : std_logic_vector(31 downto 0);
   signal cpu_data_r        : std_logic_vector(31 downto 0);
   signal cpu_pause         : std_logic;

   signal data_read_uart    : std_logic_vector(7 downto 0);
   signal write_enable      : std_logic;
   signal mem_busy          : std_logic;

   signal enable_misc       : std_logic;
   signal enable_uart       : std_logic;
   signal enable_uart_read  : std_logic;
   signal enable_uart_write : std_logic;

   signal gpio0_reg         : std_logic_vector(31 downto 0);
   signal uart_write_busy   : std_logic;
   signal uart_data_avail   : std_logic;
   signal irq_mask_reg      : std_logic_vector(7 downto 0);
   signal irq_status        : std_logic_vector(7 downto 0);
   signal irq               : std_logic;
   signal counter_reg       : std_logic_vector(39 downto 0);
   signal counter_hi_reg    : std_logic_vector(39 downto 32);

   signal cache_ram_enable  : std_logic;
   signal cache_ram_byte_we : std_logic_vector(3 downto 0);
   signal cache_ram_address : std_logic_vector(31 downto 2);
   signal cache_ram_data_w  : std_logic_vector(31 downto 0);
   signal cache_ram_data_r  : std_logic_vector(31 downto 0);
   
   signal boot_ram_enable   : std_logic;
   signal boot_ram_byte_we  : std_logic_vector(3 downto 0);
   signal boot_ram_address  : std_logic_vector(31 downto 2);
   signal boot_ram_data_w   : std_logic_vector(31 downto 0);
   signal boot_ram_data_r   : std_logic_vector(31 downto 0);

   signal cache_access      : std_logic;
   signal cache_checking    : std_logic;
   signal cache_miss        : std_logic;
   signal cache_hit         : std_logic;

begin  --architecture
   write_enable <= '1' when cpu_byte_we /= "0000" else '0';
   mem_busy <= mem_pause_in;
   cache_hit <= cache_checking and not cache_miss;
   cpu_pause <= (uart_write_busy and enable_uart and write_enable) or  --UART busy
      cache_miss or                                                    --Cache wait
      (cpu_address(28) and not cache_hit and mem_busy);                --DDR
   irq_status <= gpioA_in(31) & not gpioA_in(31) &
                 counter_reg(31) & not counter_reg(31) & 
                 counter_reg(18) & not counter_reg(18) &
                 not uart_write_busy & uart_data_avail;
   irq <= '1' when (irq_status and irq_mask_reg) /= ZERO(7 downto 0) else '0';
   gpio0_out(31 downto 29) <= gpio0_reg(31 downto 29);
   gpio0_out(23 downto 0) <= gpio0_reg(23 downto 0);

   enable_misc <= '1' when cpu_address(30 downto 28) = "010" else '0';
   enable_uart <= '1' when enable_misc = '1' and cpu_address(7 downto 4) = "0000" else '0';
   enable_uart_read <= enable_uart and not write_enable;
   enable_uart_write <= enable_uart and write_enable;
   cpu_address(1 downto 0) <= "00";

   u1_cpu: mlite_cpu 			-- plasma cpu core
      PORT MAP (
         clk          => clk,
         reset_in     => reset,
         intr_in      => irq,
 
         address_next => address_next,             --before rising_edge(clk)
         byte_we_next => byte_we_next,

         address      => cpu_address(31 downto 2), --after rising_edge(clk)
         byte_we      => cpu_byte_we,
         data_w       => cpu_data_w,
         data_r       => cpu_data_r,
         mem_pause    => cpu_pause);

   opt_cache: if use_cache = '0' generate
      cache_access <= '0';
      cache_checking <= '0';
      cache_miss <= '0';
   end generate;
   
   opt_cache2: if use_cache = '1' generate
   -- 4KB unified cache. Only lowest 2MB of DDR is cached.
   u_cache: cache       -- check check unit
      PORT MAP (
         clk            => clk,
         reset          => reset,
         address_next   => address_next,
         byte_we_next   => byte_we_next,
         cpu_address    => cpu_address(31 downto 2),
         mem_busy       => mem_busy,
		 
		 cache_ram_enable  => cache_ram_enable,
		 cache_ram_byte_we => cache_ram_byte_we,
		 cache_ram_address => cache_ram_address,
         cache_ram_data_w  => cache_ram_data_w,
         cache_ram_data_r  => cache_ram_data_r,
		 
		 cache_access   => cache_access,    --access 4KB cache
         cache_checking => cache_checking,  --checking if cache hit
         cache_miss     => cache_miss);     --cache miss
         
   
         
   end generate; --opt_cache2

   no_ddr_start <= cache_checking;
   no_ddr_stop <= cache_miss;

   misc_proc: process(clk, reset, cpu_address, enable_misc,
      boot_ram_data_r, cache_ram_data_r, data_read, data_read_uart, cpu_pause,
      irq_mask_reg, irq_status, gpio0_reg, write_enable,
      cache_checking,
      gpioA_in, counter_reg, counter_hi_reg, cpu_data_w)
      variable  save_cnt_hi : boolean;
   begin
      save_cnt_hi := false;
      case cpu_address(30 downto 28) is
      when "000" =>         --internal RAM
         cpu_data_r <= boot_ram_data_r;
      when "001" =>         --external RAM
         if cache_checking = '1' then
            cpu_data_r <= cache_ram_data_r; --cache
         else
            cpu_data_r <= data_read; --DDR
         end if;
      when "010" =>         --misc
         case cpu_address(6 downto 4) is
         when "000" =>      --uart
            cpu_data_r <= ZERO(31 downto 8) & data_read_uart;
         when "001" =>      --irq_mask
            cpu_data_r <= ZERO(31 downto 8) & irq_mask_reg;
         when "010" =>      --irq_status
            cpu_data_r <= ZERO(31 downto 8) & irq_status;
         when "011" =>      --gpio0
            cpu_data_r <= gpio0_reg;
         when "101" =>      --gpioA
            cpu_data_r <= gpioA_in;
         when "110" =>      --counter
            if ( cpu_address(3) = '1' ) then
                cpu_data_r     <= counter_reg(31 downto  0);    
                save_cnt_hi    := true;
            else
                cpu_data_r(counter_hi_reg'length-1 downto 0) <= counter_hi_reg;
                cpu_data_r(31 downto counter_hi_reg'length)  <= (others=>'0');        
            end if;
         when others =>
            cpu_data_r <= gpioA_in;
         end case;
      when others =>
         cpu_data_r <= ZERO;
      end case;

      if reset = '1' then
         irq_mask_reg   <= ZERO(7 downto 0);
         gpio0_reg      <= ZERO;
         counter_reg    <= (others => '0');
         counter_hi_reg <= (others => '0');
      elsif rising_edge(clk) then
         if cpu_pause = '0' then
            if enable_misc = '1' and write_enable = '1' then
               if cpu_address(6 downto 4) = "001" then
                  irq_mask_reg <= cpu_data_w(7 downto 0);
               elsif cpu_address(6 downto 4) = "011" then
                  gpio0_reg <= gpio0_reg or cpu_data_w;
               elsif cpu_address(6 downto 4) = "100" then
                  gpio0_reg <= gpio0_reg and not cpu_data_w;
               end if;
            end if;
         end if;
         counter_reg <= bv_inc(counter_reg);
         if (save_cnt_hi = true ) then 
             counter_hi_reg <= counter_reg(39 downto 32);
         end if;
      end if;
   end process;

   cache_ram_proc: process(cache_access, cache_miss,
                     address_next, cpu_address,
                     byte_we_next, cpu_data_w, data_read)
   begin
      if cache_access = '1' then    --Check if cache hit or write through
         cache_ram_enable <= '1';
         cache_ram_byte_we <= byte_we_next;
         cache_ram_address(31 downto 2) <= ZERO(31 downto 12) & address_next(11 downto 2);
         cache_ram_data_w <= cpu_data_w;
      elsif cache_miss = '1' then  --Update cache after cache miss
         cache_ram_enable <= '1';
         cache_ram_byte_we <= "1111";
         cache_ram_address(31 downto 2) <= ZERO(31 downto 12) & address_next(11 downto 2);
         cache_ram_data_w <= data_read;
      else                         --Disable cache ram when Normal non-cache access
         cache_ram_enable <= '0';
         cache_ram_byte_we <= byte_we_next;
         cache_ram_address(31 downto 2) <= address_next(31 downto 2);
         cache_ram_data_w <= cpu_data_w;
      end if;
   end process;

   boot_ram_enable <= '1' when address_next(30 downto 28) = "000" else '0';  -- read/wirte to boot mem
   boot_ram_byte_we <= byte_we_next;
   boot_ram_address(31 downto 2) <= address_next(31 downto 2);
   boot_ram_data_w <= cpu_data_w;

   u2_boot_ram: boot_ram 
      port map (
         clk               => clk,
         enable            => boot_ram_enable,
         write_byte_enable => boot_ram_byte_we,
         address           => boot_ram_address,
         data_write        => boot_ram_data_w,
         data_read         => boot_ram_data_r);

   u3_uart: uart
      generic map (log_file => log_file)
      port map(
         clk          => clk,		
         reset        => reset,
         enable_read  => enable_uart_read,
         enable_write => enable_uart_write,
         data_in      => cpu_data_w(7 downto 0),
         data_out     => data_read_uart,
         uart_read    => uart_read,
         uart_write   => uart_write,
         busy_write   => uart_write_busy,
         data_avail   => uart_data_avail);

      address <= cpu_address(31 downto 2);
      byte_we <= cpu_byte_we;
      data_write <= cpu_data_w;
      gpio0_out(28 downto 24) <= ZERO(28 downto 24);

end; --architecture logic

