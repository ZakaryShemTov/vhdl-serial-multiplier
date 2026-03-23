-- =============================================================
-- Entity   : CU (Control Unit)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-16)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   FSM-based sequencer for radix-(2^CHUNK_BITS) multiplication.
--   Parameterized via generics: WIDTH and CHUNK_BITS.
--   Number of steps = ceil(WIDTH / CHUNK_BITS).
--   For WIDTH=4, CHUNK_BITS=4 => 1 step (Radix-16).
--   States: S_IDLE -> S_LOAD -> S_ISSUE -> S_RUN -> S_DONE
--   Reset: Synchronous, active high.
--   Note: Reset is synchronous (contrast with Radix-2 CU which
--   uses asynchronous reset). Both are valid RTL strategies.
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CU is
  generic (
    WIDTH      : positive := 4;  -- Operand width in bits
    CHUNK_BITS : positive := 4   -- Bits processed per cycle (4 = Radix-16)
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    start        : in  std_logic;
    eqz          : in  std_logic;     -- '1' when RB = 0 (OU feedback)
    load_clear   : out std_logic;     -- Pulse: load A,B into RA,RB and clear P
    shift_enable : out std_logic;     -- Asserted during S_ISSUE and S_RUN
    clear        : out std_logic;     -- Reserved: held '0' (spec parity)
    done         : out std_logic      -- One-cycle pulse: multiplication complete
  );
end entity;

architecture rtl of CU is

  type state_t is (S_IDLE, S_LOAD, S_ISSUE, S_RUN, S_DONE);
  signal state, next_state : state_t;

  -- Total number of radix steps required
  constant STEPS : natural := (WIDTH + CHUNK_BITS - 1) / CHUNK_BITS;

  -- Iteration counter: tracks completed steps
  signal iter_cnt : natural range 0 to STEPS := 0;

begin

  -- -------------------------
  -- Combinational output logic
  -- Glitch-free: outputs derived directly from state register
  -- -------------------------
  load_clear   <= '1' when state = S_LOAD                     else '0';
  shift_enable <= '1' when (state = S_ISSUE or state = S_RUN) else '0';
  clear        <= '0';  -- Held low; P is cleared via load_clear
  done         <= '1' when state = S_DONE                     else '0';

  -- -------------------------
  -- State register + iteration counter
  -- Synchronous reset, active high
  -- -------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state    <= S_IDLE;
        iter_cnt <= 0;
      else
        state <= next_state;

        case state is
          when S_IDLE =>
            iter_cnt <= 0;

          when S_LOAD =>
            iter_cnt <= 0;

          when S_ISSUE =>
            -- First chunk processed on this edge; count as step 1
            iter_cnt <= 1;

          when S_RUN =>
            -- Increment while chunks remain and RB not exhausted
            if (eqz = '0') and (iter_cnt < STEPS) then
              iter_cnt <= iter_cnt + 1;
            end if;

          when S_DONE =>
            iter_cnt <= 0;
        end case;
      end if;
    end if;
  end process;

  -- -------------------------
  -- Next-state logic
  -- Pure combinational process
  -- -------------------------
  process(state, start, eqz, iter_cnt)
  begin
    next_state <= state;

    case state is
      when S_IDLE =>
        if start = '1' then
          next_state <= S_LOAD;
        end if;

      when S_LOAD =>
        next_state <= S_ISSUE;   -- One-cycle load/clear pulse

      when S_ISSUE =>
        next_state <= S_RUN;     -- First chunk step executed

      when S_RUN =>
        -- Terminate when all chunks done or RB exhausted
        if (iter_cnt >= STEPS) or (eqz = '1') then
          next_state <= S_DONE;
        else
          next_state <= S_RUN;
        end if;

      when S_DONE =>
        next_state <= S_IDLE;    -- One-cycle done pulse, return to idle
    end case;
  end process;

end architecture;
