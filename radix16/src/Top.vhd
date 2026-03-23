-- =============================================================
-- Entity   : Top (Top Level)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-16)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   Structural top-level entity connecting CU and OU.
--   Parameterized via generics for operand width, chunk size,
--   and accumulator width. Default configuration: 4x4-bit
--   unsigned multiplication in Radix-16 (1 clock cycle).
--   EQZ: feedback from OU to CU signals RB exhaustion.
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;

entity Top is
  generic (
    WIDTH      : positive := 4;   -- Operand width (A, B)
    CHUNK_BITS : positive := 4;   -- Chunk size (4 = Radix-16)
    ACC_WIDTH  : positive := 8    -- Product width (set to 2*WIDTH)
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    start   : in  std_logic;
    A       : in  std_logic_vector(WIDTH-1 downto 0);
    B       : in  std_logic_vector(WIDTH-1 downto 0);
    Product : out std_logic_vector(ACC_WIDTH-1 downto 0);
    done    : out std_logic
  );
end entity;

architecture rtl of Top is

  -- Internal control/status signals: CU <-> OU
  signal s_load_clear   : std_logic;
  signal s_shift_enable : std_logic;
  signal s_clear        : std_logic;
  signal s_done         : std_logic;
  signal s_eqz          : std_logic;

begin

  -- Operational Unit (datapath)
  U_OU : entity work.OU
    generic map (
      WIDTH      => WIDTH,
      CHUNK_BITS => CHUNK_BITS,
      ACC_WIDTH  => ACC_WIDTH
    )
    port map (
      clk          => clk,
      rst          => rst,
      load_clear   => s_load_clear,
      shift_enable => s_shift_enable,
      clear        => s_clear,
      A_in         => A,
      B_in         => B,
      eqz          => s_eqz,
      P_out        => Product
    );

  -- Control Unit (FSM sequencer)
  U_CU : entity work.CU
    generic map (
      WIDTH      => WIDTH,
      CHUNK_BITS => CHUNK_BITS
    )
    port map (
      clk          => clk,
      rst          => rst,
      start        => start,
      eqz          => s_eqz,
      load_clear   => s_load_clear,
      shift_enable => s_shift_enable,
      clear        => s_clear,
      done         => s_done
    );

  done <= s_done;

end architecture;
