library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lutmr3 is
    generic (
        BLOCK_WIDTH : integer := 8; -- Block width (6 or 8)
        M_WIDTH      : integer := 512; -- Input size (m is 512 bits)
        P_WIDTH      : integer := 255 -- Modulus size (p is 255 bits)
    );
    port (
        m        : in  STD_LOGIC_VECTOR(M_WIDTH-1 downto 0); -- Input value
        reset    : in  STD_LOGIC; -- Reset signal
        clk      : in  STD_LOGIC; -- Clock signal
        result   : out STD_LOGIC_VECTOR(P_WIDTH-1 downto 0) -- Result of m % p
    );
end lutmr3;

architecture Behavioral of lutmr3 is

    constant NUM_BLOCKS : integer := (M_WIDTH + BLOCK_WIDTH - 1) / BLOCK_WIDTH;
    constant P : integer := 2**255 - 19; -- Modulus

    type temp_array is array (0 to 255) of integer;
    type LUT_ARRAY is array (0 to NUM_BLOCKS-1) of temp_array; -- LUT structure
    signal lookup_table : LUT_ARRAY := (others => (others => 0)); -- Initialize with zeros

    signal partial_sums : unsigned(P_WIDTH-1 downto 0) := (others => '0');
    signal block_values : STD_LOGIC_VECTOR(BLOCK_WIDTH-1 downto 0);
    signal sum_result   : STD_LOGIC_VECTOR(P_WIDTH-1 downto 0) := (others => '0');
    signal temp_result  : unsigned(P_WIDTH-1 downto 0);
    signal block_index  : integer := 0;

begin

    -- LUT Initialization Process
    LUT_INIT: process(clk, reset)
        variable i, j : integer; -- Indices for blocks and values
        variable power_of_two : unsigned((2*P_WIDTH)-1 downto 0);
        variable temp_value : unsigned((4*P_WIDTH)-1 downto 0);
    begin
        if reset = '1' then
            for i in 0 to NUM_BLOCKS-1 loop
                for j in 0 to 255 loop
                    lookup_table(i)(j) <= 0;
                end loop;
            end loop;
        elsif rising_edge(clk) then
            for i in 0 to NUM_BLOCKS-1 loop
                power_of_two := to_unsigned(2**(BLOCK_WIDTH * i), P_WIDTH*2); -- Precompute 2^(BLOCK_WIDTH * i)
                for j in 0 to 255 loop
                    temp_value := to_unsigned(j, 2*P_WIDTH) * power_of_two;
                    lookup_table(i)(j) <= to_integer(temp_value mod to_unsigned(P, P_WIDTH)); -- Store value in LUT with explicit conversion
                end loop;
            end loop;
        end if;
    end process LUT_INIT;

    -- Block extraction and lookup
    BLOCK_EXTRACTION: process(clk, reset)
        variable local_sum : unsigned(P_WIDTH-1 downto 0) := (others => '0');
    begin
        if reset = '1' then
            partial_sums <= (others => '0');
            block_index <= 0;
        elsif rising_edge(clk) then
            if block_index < NUM_BLOCKS then
                -- Extract block and look up precomputed value
                block_values <= m((block_index+1)*BLOCK_WIDTH-1 downto block_index*BLOCK_WIDTH);
                local_sum := local_sum + unsigned(to_unsigned(lookup_table(block_index)(to_integer(unsigned(block_values))), P_WIDTH));
                block_index <= block_index + 1;
            else
                partial_sums <= local_sum;
            end if;
        end if;
    end process BLOCK_EXTRACTION;

    -- Final adjustment to ensure the result is within the modulus
    ADJUSTMENT: process(clk, reset)
    begin
        if reset = '1' then
            temp_result <= (others => '0');
        elsif rising_edge(clk) then
            temp_result <= partial_sums;
            if temp_result >= to_unsigned(P, P_WIDTH) then
                sum_result <= std_logic_vector(temp_result - to_unsigned(P, P_WIDTH));
            else
                sum_result <= std_logic_vector(temp_result);
            end if;
        end if;
    end process ADJUSTMENT;

    -- Output assignment
    result <= sum_result;

end Behavioral;
