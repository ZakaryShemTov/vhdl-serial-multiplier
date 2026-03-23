-- =============================================================
-- Entity   : CU (Control Unit)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-2)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   FSM-based sequencer implementing the Radix-2 shift-accumulate
--   algorithm. Controls the Operational Unit via 5 output signals.
--   States: Idle -> Load -> Check -> Add -> Shift -> Done
--   Reset: Asynchronous, active high.
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;

entity CU is
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
        start      : in  std_logic;
        EQZ        : in  std_logic;  -- '1' when RB = 0 (all bits processed)
        load_sig   : out std_logic;  -- Latch operands into RA, RB
        clear_sig  : out std_logic;  -- Reset accumulator (PP) to zero
        add_sig    : out std_logic;  -- Trigger conditional addition PP <- PP + RA
        shift_sig  : out std_logic;  -- Trigger RA << 1, RB >> 1
        done_sig   : out std_logic   -- Multiplication complete
    );
end CU;

architecture fsm of CU is

    type state_type is (Idle, Load, Check, Add, Shift, Done);
    signal state, next_state : state_type;

begin

    -- -------------------------
    -- State register process
    -- Asynchronous reset, active high
    -- -------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            state <= Idle;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- -------------------------
    -- Next-state logic
    -- Pure combinational process
    -- -------------------------
    process(state, start, EQZ)
    begin
        case state is
            when Idle =>
                if start = '1' then
                    next_state <= Load;
                else
                    next_state <= Idle;
                end if;

            when Load =>
                next_state <= Check;

            when Check =>
                -- EQZ='1' means RB exhausted, multiplication complete
                if EQZ = '1' then
                    next_state <= Done;
                else
                    next_state <= Add;
                end if;

            when Add =>
                next_state <= Shift;

            when Shift =>
                next_state <= Check;

            when Done =>
                next_state <= Idle;

            when others =>
                next_state <= Idle;
        end case;
    end process;

    -- -------------------------
    -- Output logic (Moore FSM)
    -- All outputs default to '0'
    -- to prevent inferred latches
    -- -------------------------
    process(state)
    begin
        load_sig   <= '0';
        clear_sig  <= '0';
        add_sig    <= '0';
        shift_sig  <= '0';
        done_sig   <= '0';

        case state is
            when Idle =>
                null;

            when Load =>
                load_sig  <= '1';  -- Latch A into RA, B into RB
                clear_sig <= '1';  -- Reset accumulator to zero

            when Add =>
                add_sig <= '1';    -- PP <- PP + RA (if RB(0) = '1')

            when Shift =>
                shift_sig <= '1';  -- RA << 1, RB >> 1

            when Done =>
                done_sig <= '1';   -- Signal completion to top level

            when others =>
                null;
        end case;
    end process;

end fsm;
