library ieee;
use ieee.std_logic_1164.all;

entity dp_mem_tb is
end dp_mem_tb;

architecture Behavior of dp_mem_tb is
    constant PERIOD_A:      time                            := 10 ns;

    signal clk_a, we_a:     std_logic                       := '0';
    signal addr_a, addr_b:  std_logic_vector(3 downto 0)    := (others => '0');
    signal din_a, dout_b:   std_logic_vector(15 downto 0)   := (others => '0');

    component dp_mem is
    port (
        addra:  in  std_logic_vector(3 downto 0);
        addrb:  in  std_logic_vector(3 downto 0);
        clka:   in  std_logic;
        clkb:   in  std_logic;
        dina:   in  std_logic_vector(15 downto 0);
        dinb:   in  std_logic_vector(15 downto 0);
        douta:  out std_logic_vector(15 downto 0);
        doutb:  out std_logic_vector(15 downto 0);
        wea:    in  std_logic;
        web:    in  std_logic
    );
    end component;
begin
    dut: dp_mem
    port map (
        addra       => addr_a,
        addrb       => addr_b,
        clka        => clk_a,
        clkb        => clk_a,               -- no CDC
        dina        => din_a,
        dinb        => (others => '0'),     -- unidirectional data flow
        -- douta NC                         -- unidirectional data flow
        doutb       => dout_b,
        wea         => we_a,
        web         => '0'                  -- unidirectional data flow
    );

    clk_a <= not clk_a after (PERIOD_A / 2);

    tb: process is
    begin
        wait for PERIOD_A;

        we_a <= '1';
        addr_a <= x"0";
        din_a <= x"DEAD";
        wait for PERIOD_A;
        addr_a <= x"1";
        din_a <= x"BEEF";
        wait for PERIOD_A;
        addr_a <= x"2";
        din_a <= x"BAAD";
        wait for PERIOD_A;
        addr_a <= x"3";
        din_a <= x"F00D";
        wait for PERIOD_A;
        we_a <= '0';

        addr_b <= x"0";
        wait for (PERIOD_A);
        assert dout_b = x"DEAD";
        addr_b <= x"1";
        wait for (PERIOD_A);
        assert dout_b = x"BEEF";
        addr_b <= x"2";
        wait for (PERIOD_A);
        assert dout_b = x"BAAD";
        addr_b <= x"3";
        wait for (PERIOD_A);
        assert dout_b = x"F00D";
    end process;
end Behavior;