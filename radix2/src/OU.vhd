-- =============================================================
-- Entity   : OU (Operational Unit)
-- Project  : Synchronous Serial 4-bit Multiplier (Radix-2)
-- Author   : Zakary Shem Tov | Afeka College of Engineering
-- Date     : 2025
-- Description:
--   Datapath for the shift-accumulate multiplication algorithm.
--   Supports signed operands via sign extraction and abs_val.
--   RA: multiplicand register (8-bit extended)
--   RB: multiplier register  (4-bit)
--   P:  accumulator (partial product)
--   EQZ: '1' when RB = 0, signals CU to terminate loop.
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OU is
    port(
        clk      : in  std_logic;
        rst      : in  std_logic;
        load     : in  std_logic;    -- Load operands A, B into RA, RB
        clear    : in  std_logic;    -- Reset accumulator P to zero
        shift_en : in  std_logic;    -- Enable shift: RA << 1, RB >> 1
        add_en   : in  std_logic;    -- Enable conditional addition
        A        : in  std_logic_vector(3 downto 0);
        B        : in  std_logic_vector(3 downto 0);
        P_out    : out std_logic_vector(7 downto 0);
        EQZ      : out std_logic     -- '1' when RB = 0
    );
end OU;

architecture rtl of OU is

    signal RA       : unsigned(7 downto 0); -- Multiplicand (zero-extended)
    signal RB       : unsigned(3 downto 0); -- Multiplier
    signal P        : unsigned(7 downto 0); -- Accumulator (partial product)
    signal sign_A   : std_logic;            -- Sign bit of operand A
    signal sign_B   : std_logic;            -- Sign bit of operand B
    signal sign_res : std_logic;            -- Sign of result (A xor B)

    -- Returns absolute value of a signed input as unsigned
    function abs_val(x : signed) return unsigned is
    begin
        if x < 0 then
            return unsigned(-x);
        else
            return unsigned(x);
        end if;
    end function;

begin

    -- -------------------------
    -- Main datapath process
    -- Asynchronous reset, active high
    -- -------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            RA       <= (others => '0');
            RB       <= (others => '0');
            P        <= (others => '0');
            sign_A   <= '0';
            sign_B   <= '0';
            sign_res <= '0';

        elsif rising_edge(clk) then
            if load = '1' then
                -- Extract and store sign bits
                sign_A   <= A(3);
                sign_B   <= B(3);
                sign_res <= A(3) xor B(3); -- Negative result if signs differ

                -- Load absolute values into registers
                RA <= resize(abs_val(signed(A)), 8);
                RB <= resize(abs_val(signed(B)), 4);

                -- Clear accumulator on load
                P <= (others => '0');

            elsif clear = '1' then
                P <= (others => '0');

            else
                -- Conditional addition: PP <- PP + RA if RB(0) = '1'
                if add_en = '1' and RB(0) = '1' then
                    P <= P + RA;
                end if;

                -- Shift: RA left, RB right (advance to next bit)
                if shift_en = '1' then
                    RA <= shift_left(RA, 1);
                    RB <= shift_right(RB, 1);
                end if;
            end if;
        end if;
    end process;

    -- -------------------------
    -- Output: apply sign correction
    -- Negate result if operands had opposite signs
    -- -------------------------
    process(P, sign_res)
    begin
        if sign_res = '1' then
            P_out <= std_logic_vector(-signed(P));
        else
            P_out <= std_logic_vector(P);
        end if;
    end process;

    -- EQZ: multiplication complete when RB is fully shifted out
    EQZ <= '1' when RB = 0 else '0';

end rtl;
