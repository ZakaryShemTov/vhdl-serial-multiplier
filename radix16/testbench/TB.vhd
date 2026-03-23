-- =============================================================
-- Entity   : Tb (Testbench)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-16)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   Exhaustive self-checking testbench for Top (Radix-16).
--   Covers all 256 unsigned input combinations: A,B in [0..15].
--   Uses severity FAILURE: simulation halts on first mismatch,
--   ensuring no silent errors pass undetected.
--   On full pass: reports "ALL TESTS PASSED" (severity NOTE).
--   Clock period: 10 ns (100 MHz).
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Tb is
end entity;

architecture sim of Tb is

  constant WIDTH_C      : positive := 4;
  constant CHUNK_BITS_C : positive := 4;
  constant ACC_WIDTH_C  : positive := 2*WIDTH_C;

  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal start : std_logic := '0';
  signal A     : std_logic_vector(WIDTH_C-1 downto 0) := (others => '0');
  signal B     : std_logic_vector(WIDTH_C-1 downto 0) := (others => '0');
  signal P     : std_logic_vector(ACC_WIDTH_C-1 downto 0);
  signal done  : std_logic;

  constant MAXV : natural := 2**WIDTH_C - 1;  -- 15 for WIDTH=4

begin

  -- Clock: 100 MHz (10 ns period)
  clk <= not clk after 5 ns;

  -- Device Under Test
  DUT: entity work.Top
    generic map (
      WIDTH      => WIDTH_C,
      CHUNK_BITS => CHUNK_BITS_C,
      ACC_WIDTH  => ACC_WIDTH_C
    )
    port map (
      clk     => clk,
      rst     => rst,
      start   => start,
      A       => A,
      B       => B,
      Product => P,
      done    => done
    );

  -- Stimulus + exhaustive self-checking
  stim: process
    variable ia, ib    : integer;
    variable a_u, b_u  : unsigned(WIDTH_C-1 downto 0);
    variable prod_full : unsigned(2*WIDTH_C-1 downto 0);
    variable exp_u     : unsigned(ACC_WIDTH_C-1 downto 0);
  begin
    -- Validate generic configuration
    assert CHUNK_BITS_C <= WIDTH_C
      report "CHUNK_BITS must be <= WIDTH"
      severity failure;

    -- Apply reset for 3 cycles
    rst <= '1'; start <= '0';
    for i in 1 to 3 loop
      wait until rising_edge(clk);
    end loop;
    rst <= '0';

    -- 2-cycle settling time
    for i in 1 to 2 loop
      wait until rising_edge(clk);
    end loop;

    -- Exhaustive test: all 256 combinations (unsigned 0..15 x 0..15)
    for ia in 0 to MAXV loop
      for ib in 0 to MAXV loop

        -- Apply operands
        A <= std_logic_vector(to_unsigned(ia, WIDTH_C));
        B <= std_logic_vector(to_unsigned(ib, WIDTH_C));
        wait until rising_edge(clk);

        -- One-cycle start pulse
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- Wait for multiplication to complete
        while done = '0' loop
          wait until rising_edge(clk);
        end loop;

        -- Compute reference product
        a_u       := to_unsigned(ia, WIDTH_C);
        b_u       := to_unsigned(ib, WIDTH_C);
        prod_full := a_u * b_u;
        exp_u     := prod_full(ACC_WIDTH_C-1 downto 0);

        -- Verify: halt on first mismatch (severity FAILURE)
        assert unsigned(P) = exp_u
          report "FAIL | A=" & integer'image(ia) &
                 " | B=" & integer'image(ib) &
                 " | Got="      & integer'image(to_integer(unsigned(P))) &
                 " | Expected=" & integer'image(to_integer(exp_u))
          severity failure;

        wait until rising_edge(clk);
      end loop;
    end loop;

    report "=========== ALL TESTS PASSED ===========" severity note;
    wait until false;
  end process;

end architecture;
