library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lutmr2 is
    generic (
        BLOCK_WIDTH : integer := 6; -- Block width (6 or 8)
        M_WIDTH      : integer := 512; -- Input size (m is 512 bits)
        P_WIDTH      : integer := 255 -- Modulus size (p is 255 bits)
    );
    port (
        m        : in  STD_LOGIC_VECTOR(M_WIDTH-1 downto 0); -- Input value
        reset    : in  STD_LOGIC; -- Reset signal
        result   : out STD_LOGIC_VECTOR(P_WIDTH-1 downto 0) -- Result of m % p
    );
end lutmr2;

architecture Behavioral of lutmr2 is

    constant NUM_BLOCKS : integer := (M_WIDTH + BLOCK_WIDTH - 1) / BLOCK_WIDTH;
    constant LUT_DEPTH  : integer := 2 ** BLOCK_WIDTH;

    -- Lookup table to store precomputed values for each block
    type LUT_ARRAY is array (0 to NUM_BLOCKS-1) of STD_LOGIC_VECTOR(P_WIDTH-1 downto 0);
    signal lookup_table : LUT_ARRAY := (others => (others => '0'));

    -- Registers for intermediate results
    signal partial_sums : unsigned(P_WIDTH-1 downto 0) := (others => '0');
    signal block_values : STD_LOGIC_VECTOR(BLOCK_WIDTH-1 downto 0);

    signal sum_result   : STD_LOGIC_VECTOR(P_WIDTH-1 downto 0) := (others => '0');
    signal temp_result  : unsigned(P_WIDTH-1 downto 0);

begin

    -- Lookup table initialization (precomputed values for each block)
    LUT_INIT: process
    begin
        for i in 0 to NUM_BLOCKS-1 loop
            lookup_table(i) <= std_logic_vector(to_unsigned((i * (2 * BLOCK_WIDTH)) mod ((2 ** P_WIDTH) - 19), P_WIDTH));
        end loop;
        wait until reset = '0'; -- Wait until the reset signal is deasserted
    end process;

    -- Block extraction and lookup
    BLOCK_EXTRACTION: process(reset)
        variable block_index : integer;
    begin
        if reset = '1' then
            partial_sums <= (others => '0');
        else
            -- For each block, retrieve its modular reduction
            for block_index in 0 to NUM_BLOCKS-1 loop
                if ((block_index+1)*BLOCK_WIDTH - 1) < M_WIDTH then
                    block_values <= m((block_index+1)*BLOCK_WIDTH-1 downto block_index*BLOCK_WIDTH);
                else
                    block_values <= (others => '0'); -- Assign a default value if out-of-bounds
                end if;
                partial_sums <= partial_sums + unsigned(lookup_table(to_integer(unsigned(block_values))));
            end loop;
        end if;
    end process;

    -- Final adjustment to ensure the result is within the modulus
    ADJUSTMENT: process(reset)
    begin
        temp_result <= partial_sums;
        if temp_result >= to_unsigned((2**P_WIDTH - 19), P_WIDTH) then
            sum_result <= std_logic_vector(temp_result - to_unsigned((2**P_WIDTH - 19), P_WIDTH));
        else
            sum_result <= std_logic_vector(temp_result);
        end if;
    end process;

    -- Output assignment
    result <= sum_result;

end Behavioral;
