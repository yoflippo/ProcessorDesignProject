prTest         : process (Clk)
variable vTest : std_logic;
begin
    if rising_edge(Clk) then
        if (Rst = '1') then
            vTest := '0';
        else
            --vTest := Input -- creates combinatory circuit or a wire in this case

            if (vTest = '1') then
                Output <= not Input;
            end if;

            vTest := Input; -- Creates a register
        end if;
    end if;
end process prTest;

signal Test : std_logic;

prTest2     : process (Clk)
begin
    if rising_edge(Clk) then
        if (Rst = '1') then
            Test <= '0';
        else
            -- Test <= Input; -- position doesn't matter, Test is always a register (because it is a signal)

            if (Test = '1') then
                Output <= not Input;
            end if;

            Test <= Input;
        end if;
    end if;
end process prTest2;

-- Example of sequentiality of a process:
-- The following process creates a 1 clock wide pulse on the Pulse signal at every rising edge of the input signal
signal Pulse     : std_logic;
signal InputPrev : std_logic;

prTest3          : process (Clk)
begin
    if rising_edge(Clk) then
        if (Rst = '1') then
            Pulse     <= '0';
            InputPrev <= '0';
        else
            Pulse     <= '0'; -- At first assign 0 to signal
            InputPrev <= Input;
            if (Input = '1' and InputPrev = '0') then
                Pulse <= '1'; -- But then overrule it
            end if;
        end if;
    end if;
end process; -- Actual signal assignment takes place at the end of the process