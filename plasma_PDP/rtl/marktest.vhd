--====================================================================================================================--
--  Title:        Testbench for name module
--  File Name:    name_tb.vhd
--  Author:        Snippet1
 
--  Date:         zaterdag 6 mei 2017
--
--  Description:
--                * Provides stimuli to name
--                * Verifies the output in response to the stimuli
--                * Reports the outcome of the verification on the console
--
--====================================================================================================================--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.TxtUtil_pkg.all;

entity  name_tb is
end entity  name_tb;

architecture sim of name_tb is

   ---------------------------------------------------------------------------------------------------------------------
   -- Simulation parameters and signals
   ---------------------------------------------------------------------------------------------------------------------
   constant cCLOCK_FREQ    : integer   := {FreqHz};
   constant cCLOCK_PERIOD  : time      := 1 sec / cCLOCK_FREQ;

   signal SimFinished      : boolean   := false;

   ---------------------------------------------------------------------------------------------------------------------
   -- Clocks and Resets
   ---------------------------------------------------------------------------------------------------------------------
   signal Clk              : std_logic := '0';
   signal Rst              : std_logic := '0';

   ---------------------------------------------------------------------------------------------------------------------
   -- Unit under test connections
   ---------------------------------------------------------------------------------------------------------------------
   signal


begin

   ---------------------------------------------------------------------------------------------------------------------
   -- Clock generation
   ---------------------------------------------------------------------------------------------------------------------
   prClockGen: process is
   begin
      Clk <= '0';
      while NOT SimFinished loop
         Clk <= NOT Clk;
         wait for (cCLOCK_PERIOD / 2);
      end loop;
      echo("Simulation ended at: " & time'IMAGE(now));
      wait;
   end process prClockGen;

   ---------------------------------------------------------------------------------------------------------------------
   -- Unit under test
   ---------------------------------------------------------------------------------------------------------------------
   UUT: entity work.name

   ---------------------------------------------------------------------------------------------------------------------
   -- Target model(s)
   ---------------------------------------------------------------------------------------------------------------------

   ---------------------------------------------------------------------------------------------------------------------
   -- Stimulation
   ---------------------------------------------------------------------------------------------------------------------
   prStimuli: process
      variable vSimResult : boolean := true;
   begin
      Rst   <= '0';

      wait until rising_edge(Clk);
      Rst   <= '1';
      wait until rising_edge(Clk);
      wait for cCLOCK_PERIOD * 10;
      wait until rising_edge(Clk);
      Rst   <= '0';
      wait until rising_edge(Clk);

      

      if (vSimResult) then
         echo("-----------------------------------------------------------------");
         echo("");
         echo(" SIMULATION PASSED            :-)");
         echo("");
         echo("-----------------------------------------------------------------");
      else
         echo("-----------------------------------------------------------------");
         echo("");
         echo("SIMULATION FAILED             :-(");
         echo("");
         echo("-----------------------------------------------------------------");
      end if;

      SimFinished  <= true;
      wait;
   end process prStimuli;

end architecture sim;
