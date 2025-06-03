library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity dp_mem_tb is
end dp_mem_tb;

architecture tb of dp_mem_tb is
    constant INP_FNAME:         string                          := "dp_mem.psc";

    constant PERIOD_A:          time                            := 10 ns;
    constant PERIOD_B:          time                            := 4 * 3.14159 ns;
    constant SETUP_TIME:        time                            := 2 ns;
    constant MEAS_TIME:         time                            := 6 ns;

    signal clk_a, clk_b, we_a:  std_logic                       := '0';
    signal addr_a, addr_b:      std_logic_vector(3 downto 0)    := (others => 'U');
    signal din_a, dout_b:       std_logic_vector(15 downto 0)   := (others => 'U');

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
        clkb        => clk_b,
        dina        => din_a,
        dinb        => (others => '0'),     -- unidirectional data flow
        -- douta NC                         -- unidirectional data flow
        doutb       => dout_b,
        wea         => we_a,
        web         => '0'                  -- unidirectional data flow
    );

    clk_a <= not clk_a after (PERIOD_A / 2);
    clk_b <= not clk_b after (PERIOD_B / 2);

    stim: process is
        file f:             text;
        variable instr:     line;
        variable space:     character;
        variable op:        string(1 to 2);
        -- variable str_addr:  character;
        variable addr:      std_logic_vector(3 downto 0);
        -- variable str_data:  string(0 to 3);
        variable data:      std_logic_vector(15 downto 0);
    begin
        file_open(f, INP_FNAME, READ_MODE);
        -- allow memory to initialize in timing sims
        wait for 10 * PERIOD_A;

        while op /= "QQ" loop
            readline(f, instr);
            read(instr, op);
            case op is
                when "--" =>
                    -- comment line
                    next;
                when "QQ" =>
                    report "Simulation complete." severity failure;
                when "WR" =>
                    read(instr, space);
                    hread(instr, addr);
                    read(instr, space);
                    hread(instr, data);
                    -- start SETUP_TIME before the rising edge
                    wait until falling_edge(clk_a);
                    wait for (0.5 * PERIOD_A - SETUP_TIME);
                    we_a <= '1';
                    addr_a <= addr;
                    din_a <= data;
                    wait for PERIOD_A;
                    we_a <= '0';
                when "RD" =>
                    read(instr, space);
                    hread(instr, addr);
                    read(instr, space);
                    hread(instr, data);
                    -- start SETUP_TIME before the rising edge
                    wait until falling_edge(clk_b);
                    wait for (0.5 * PERIOD_B - SETUP_TIME);
                    addr_b <= addr;
                    -- go to MEAS_TIME after the second rising edge
                    wait until rising_edge(clk_b);
                    wait until rising_edge(clk_b);
                    wait for MEAS_TIME;
                    assert dout_b = data;
                    wait for PERIOD_B - MEAS_TIME;
                when others =>
                    report "Invalid op: " & op severity error;
            end case;
        end loop;
    end process;
end tb;