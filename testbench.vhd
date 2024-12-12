library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity testbench is
end testbench;

architecture Behavioral of testbench is
    -- Constants for the test
    constant CLK_PERIOD : time := 10 ns;

    -- Signal declarations
    signal reset   : STD_LOGIC := '0';
    signal m       : STD_LOGIC_VECTOR(511 downto 0) := (others => '0'); -- Ensure this matches the M_WIDTH
    signal result  : STD_LOGIC_VECTOR(254 downto 0); -- Ensure this matches the P_WIDTH

    -- Component declaration
    component lutmr3 is
        generic (
            BLOCK_WIDTH : integer := 6;
            M_WIDTH     : integer := 512;
            P_WIDTH     : integer := 255
        );
        port (
            reset   : in  STD_LOGIC;
            m       : in  STD_LOGIC_VECTOR(M_WIDTH-1 downto 0);
            result  : out STD_LOGIC_VECTOR(P_WIDTH-1 downto 0)
        );
    end component;

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: lutmr3
        port map (
            reset   => reset,
            m       => m,
            result  => result
        );

    -- Test process
    stim_proc: process
    begin
        -- Reset the system
        reset <= '1';
        wait for CLK_PERIOD * 2;
        reset <= '0';
        wait for CLK_PERIOD;

        -- Test case 1 (512 bits = 128 hex digits)
		  m <= X"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF";
		  wait for CLK_PERIOD * 10;

        -- Test case 2 (512 bits = 128 hex digits)
        m <= X"FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210FEDCBA9876543210";
        wait for CLK_PERIOD * 10;

        -- Add more test cases as needed

        -- End of test
        wait;
    end process;
end Behavioral;
