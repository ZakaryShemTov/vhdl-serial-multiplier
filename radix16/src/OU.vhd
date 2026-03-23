-- =============================================================
-- Entity   : OU (Operational Unit)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-16)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   Parameterized datapath for radix-(2^CHUNK_BITS) multiplication.
--   Each cycle processes CHUNK_BITS bits of RB simultaneously,
--   reducing total cycles by factor CHUNK_BITS vs Radix-2.
--   For WIDTH=4, CHUNK_BITS=4: completes in 1 cycle.
--   RA: multiplicand register (ACC_WIDTH bits, shifted left)
--   RB: multiplier register   (WIDTH bits, shifted right)
--   P:  accumulator (unsigned product)
--   Per-cycle operation: P <- P + (RA * RB[CHUNK_BITS-1:0])
--                        RA << CHUNK_BITS, RB >> CHUNK_BITS
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OU is
  generic (
    WIDTH      : positive := 4;   -- Operand width in bits
    CHUNK_BITS : positive := 4;   -- Bits per step (4 = Radix-16)
    ACC_WIDTH  : positive := 8    -- Accumulator width (must be >= 2*WIDTH)
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    load_clear   : in  std_logic; -- Load A,B and clear P in one cycle
    shift_enable : in  std_logic; -- Execute one accumulate+shift step
    clear        : in  std_logic; -- Optional standalone accumulator clear
    A_in         : in  std_logic_vector(WIDTH-1 downto 0);
    B_in         : in  std_logic_vector(WIDTH-1 downto 0);
    eqz          : out std_logic; -- '1' when RB = 0 (feedback to CU)
    P_out        : out std_logic_vector(ACC_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of OU is

  constant SHIFT_C : natural := CHUNK_BITS;

  signal RA : std_logic_vector(ACC_WIDTH-1 downto 0); -- Multiplicand (extended)
  signal RB : std_logic_vector(WIDTH-1 downto 0);     -- Multiplier (shifted out)
  signal P  : std_logic_vector(ACC_WIDTH-1 downto 0); -- Partial product accumulator

begin

  -- EQZ: all chunks of B have been processed
  eqz   <= '1' when unsigned(RB) = 0 else '0';
  P_out <= P;

  process(clk)
    -- Extended-width intermediates to prevent overflow during chunk multiply
    variable nibble    : unsigned(CHUNK_BITS-1 downto 0);
    variable mult_temp : unsigned(ACC_WIDTH+CHUNK_BITS-1 downto 0);
    variable sum_ext   : unsigned(ACC_WIDTH+CHUNK_BITS-1 downto 0);
    variable p_ext     : unsigned(ACC_WIDTH+CHUNK_BITS-1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        RA <= (others => '0');
        RB <= (others => '0');
        P  <= (others => '0');

      elsif load_clear = '1' then
        -- Load absolute-value operands and reset accumulator
        RA <= std_logic_vector(resize(unsigned(A_in), ACC_WIDTH));
        RB <= B_in;
        P  <= (others => '0');

      else
        -- Optional standalone clear
        if clear = '1' then
          P <= (others => '0');
        end if;

        if shift_enable = '1' then
          -- Extract current chunk (LSBs of RB)
          nibble := unsigned(RB(CHUNK_BITS-1 downto 0));

          -- Chunk multiply: (ACC_WIDTH bits) * (CHUNK_BITS bits)
          -- Result width = ACC_WIDTH + CHUNK_BITS to prevent overflow
          mult_temp := unsigned(RA) * nibble;

          -- Accumulate: resize P up, add, truncate back to ACC_WIDTH
          p_ext   := resize(unsigned(P), ACC_WIDTH+CHUNK_BITS);
          sum_ext := p_ext + mult_temp;
          P       <= std_logic_vector(sum_ext(ACC_WIDTH-1 downto 0));

          -- Advance to next chunk
          RA <= std_logic_vector(shift_left (unsigned(RA), SHIFT_C));
          RB <= std_logic_vector(shift_right(unsigned(RB), SHIFT_C));
        end if;
      end if;
    end if;
  end process;

end architecture;
