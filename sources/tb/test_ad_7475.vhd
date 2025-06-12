library ieee;
use ieee.std_logic_1164.all;
use work.ad_7475_pkg.all;

entity ad_7475_tb is
end ad_7475_tb;

architecture tb of ad_7475_tb is
    constant S_PD:  time        :=  100 ns;

    signal sclk:    std_logic   := '1';
    signal csn:     std_logic   := '1';
    signal sdata:   std_logic;

    component ad_7475 is
    generic (
        NUM_PRE_BITS:   integer := DEFAULT_NUM_PRE_BITS;
        NUM_RES_BITS:   integer := DEFAULT_NUM_RES_BITS
    );
    port (
        sclk:   in  std_logic;
        csn:    in  std_logic;
        sdata:  out std_logic
    );
    end component;
begin
    dut: ad_7475
    port map (
        sclk    => sclk,
        csn     => csn,
        sdata   => sdata
    );

    process is
    begin
        wait for 100 ns;

        csn <= '0';

        wait for (DEFAULT_NUM_PRE_BITS + DEFAULT_NUM_RES_BITS) * S_PD;

        csn <= '1';
    end process;

    process is
    begin
        sclk <= '1';
        wait until csn = '0';
        while csn = '0' loop
            wait for S_PD/2;
            sclk <= not sclk;
        end loop;
    end process;
end tb;