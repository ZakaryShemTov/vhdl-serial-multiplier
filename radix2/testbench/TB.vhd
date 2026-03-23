-- =============================================================
-- Entity   : Tb (Testbench)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-2)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   Functional verification testbench for MulTop (Radix-2).
--   Tests 10 signed input pairs covering key cases:
--   negative x negative, negative x positive, edge values.
--   Uses assert/severity ERROR: simulation continues on failure,
--   all errors reported before termination.
--   Clock period: 20 ns.
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Tb is
end Tb;

architecture behavior of Tb is

    component MulTop
        port(
            clk     : in  std_logic;
            rst     : in  std_logic;
            start   : in  std_logic;
            A, B    : in  std_logic_vector(3 downto 0);
            Product : out std_logic_vector(7 downto 0);
            done    : out std_logic
        );
    end component;

    signal clk_tb     : std_logic := '0';
    signal rst_tb     : std_logic := '0';
    signal start_tb   : std_logic := '0';
    signal A_tb, B_tb : std_logic_vector(3 downto 0);
    signal Product_tb : std_logic_vector(7 downto 0);
    signal done_tb    : std_logic;

    constant clk_period : time := 20 ns;

begin

    -- Unit Under Test
    uut: MulTop
        port map (
            clk     => clk_tb,
            rst     => rst_tb,
            start   => start_tb,
            A       => A_tb,
            B       => B_tb,
            Product => Product_tb,
            done    => done_tb
        );

    -- Clock generator: 50 MHz
    clk_process : process
    begin
        while true loop
            clk_tb <= '0'; wait for clk_period/2;
            clk_tb <= '1'; wait for clk_period/2;
        end loop;
    end process;

    -- Stimulus: 10 signed test cases
    -- Covers: neg*neg, neg*pos, pos*neg, edge values (-8, 7)
    stim_proc: process
        type pair_array is array(0 to 9) of integer;
        variable testA   : pair_array := (-5, -5,  3,  2,  4, -7, -3,  6,  7, -8);
        variable testB   : pair_array := (-5,  3,  2, -2, -4,  5, -3, -1,  7, -8);
        variable Expected : integer;
    begin
        -- Apply reset
        rst_tb <= '1';
        wait for clk_period;
        rst_tb <= '0';

        for i in 0 to 9 loop
            -- Apply operands
            A_tb <= std_logic_vector(to_signed(testA(i), 4));
            B_tb <= std_logic_vector(to_signed(testB(i), 4));

            -- One-cycle start pulse
            start_tb <= '1';
            wait for clk_period;
            start_tb <= '0';

            -- Wait for multiplication to complete
            wait until rising_edge(clk_tb) and done_tb = '1';

            -- Compute reference result
            Expected := testA(i) * testB(i);

            -- Verify output (simulation continues on failure)
            assert to_integer(signed(Product_tb)) = Expected
                report "FAIL | Test " & integer'image(i) &
                       " | A=" & integer'image(testA(i)) &
                       " | B=" & integer'image(testB(i)) &
                       " | Got="      & integer'image(to_integer(signed(Product_tb))) &
                       " | Expected=" & integer'image(Expected)
                severity error;

        end loop;

        report "All 10 test cases completed.";
        wait;
    end process;

end behavior;
