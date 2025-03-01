library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LUTMR_Modulo is
    port (
        clk          : in  STD_LOGIC; -- Clock signal
        reset        : in  STD_LOGIC; -- Reset signal
        m            : in  STD_LOGIC_VECTOR(511 downto 0); -- Input value
        result       : out STD_LOGIC_VECTOR(254 downto 0) -- Result of m % p
    );
end LUTMR_Modulo;

architecture Behavioral of LUTMR_Modulo is

    constant NUM_BLOCKS : integer := 64; -- Number of 8-bit blocks
    constant P : integer := 2**255 - 19; -- Modulus

    type LUT_ARRAY is array (0 to 255) of integer; -- Lookup table (8-bit blocks)
    signal lookup_table : LUT_ARRAY := (
        -- Precomputed values for each block
        0 => 0, 1 => 8 mod P, 2 => 16 mod P, -- Extend manually or programmatically
        others => 0
    );

    signal partial_sums : integer := 0; -- Accumulated result
    signal block_index  : integer := 0; -- Current block being processed
    signal done         : STD_LOGIC := '0'; -- Flag to indicate completion

begin

    -- Sequential processing of blocks
    process(clk)
        variable block_value : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                partial_sums <= 0;
                block_index <= 0;
                done <= '0';
            elsif done = '0' then
                -- Extract current block (8 bits)
                block_value := to_integer(unsigned(m((block_index+1)*8-1 downto block_index*8)));

                -- Add corresponding lookup table value
                partial_sums <= partial_sums + lookup_table(block_value);

                -- Move to next block
                if block_index = NUM_BLOCKS - 1 then
                    done <= '1'; -- All blocks processed
                else
                    block_index <= block_index + 1;
                end if;
            end if;
        end if;
    end process;

    -- Final adjustment to ensure result < P
    process(clk)
    begin
        if rising_edge(clk) then
            if done = '1' then
                if partial_sums >= P then
                    result <= std_logic_vector(to_unsigned(partial_sums - P, 255));
                else
                    result <= std_logic_vector(to_unsigned(partial_sums, 255));
                end if;
            end if;
        end if;
    end process;

end Behavioral;