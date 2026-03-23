-- =============================================================
-- Entity   : MulTop (Top Level)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-2)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   Structural top-level entity connecting CU and OU.
--   CU generates control signals; OU executes datapath operations.
--   EQZ feedback from OU to CU signals end of multiplication loop.
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MulTop is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        start   : in  std_logic;
        A, B    : in  std_logic_vector(3 downto 0);
        Product : out std_logic_vector(7 downto 0);
        done    : out std_logic
    );
end MulTop;

architecture rtl of MulTop is

    -- Internal control signals: CU outputs -> OU inputs
    signal load_sig, clear_sig  : std_logic;
    signal add_sig,  shift_sig  : std_logic;
    signal done_sig             : std_logic;

    -- Feedback: OU -> CU (RB exhaustion flag)
    signal EQZ_sig : std_logic;

begin

    -- Control Unit instantiation
    CU_inst : entity work.CU
        port map (
            clk       => clk,
            rst       => rst,
            start     => start,
            EQZ       => EQZ_sig,
            load_sig  => load_sig,
            clear_sig => clear_sig,
            add_sig   => add_sig,
            shift_sig => shift_sig,
            done_sig  => done_sig
        );

    -- Operational Unit instantiation
    OU_inst : entity work.OU
        port map (
            clk      => clk,
            rst      => rst,
            load     => load_sig,
            clear    => clear_sig,
            shift_en => shift_sig,
            add_en   => add_sig,
            A        => A,
            B        => B,
            P_out    => Product,
            EQZ      => EQZ_sig
        );

    -- Forward done signal to top-level output
    done <= done_sig;

end rtl;
