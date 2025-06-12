package ad_7475_pkg is
    constant DEFAULT_NUM_PRE_BITS: integer := 4;
    constant DEFAULT_NUM_RES_BITS: integer := 12;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ad_7475_pkg.all;

entity ad_7475 is
generic (
    NUM_PRE_BITS:   integer := DEFAULT_NUM_PRE_BITS;
    NUM_RES_BITS:   integer := DEFAULT_NUM_RES_BITS
);
port (
    sclk:   in  std_logic;
    csn:    in  std_logic;
    sdata:  out std_logic
);
end ad_7475;

architecture Behavior of ad_7475 is
    constant    WAV_PERIOD:     time    := 50.0 us;

    signal      t:              time    := 0 ns;
    signal      sclk_en:        boolean := false;
    signal      dat_en:         boolean := false;
    signal      dat_vld:        boolean := true;
    signal      dat:            std_logic_vector((NUM_RES_BITS - 1) downto 0);
    signal      bit:            integer := NUM_PRE_BITS + NUM_RES_BITS - 1;
begin
    t <= t + 1 ns after 1 ns;

    set_sclk_en: process(csn) is
    begin
        sclk_en <= false;
        if falling_edge(csn) then
            sclk_en <= true after 10 ns;
        end if;
    end process;

    set_dat_en: process(csn, sclk) is
    begin
        if sclk_en and falling_edge(sclk) and (bit = 0 or csn = '1') then
            -- last bit
            dat_en <= false after 10 ns;
        end if;
        if falling_edge(csn) then
            dat_en <= true after 22 ns;
        elsif rising_edge(csn) then
            -- transmission cut short
            dat_en <= false after 20 ns;
        end if;
    end process;

    set_data_vld: process (csn, sclk) is
    begin
        if sclk_en and falling_edge(sclk) and (bit /= 0) then
            -- sdata uncertainty
            dat_vld <= false after 10 ns, true after 40 ns;
        end if;
        if falling_edge(csn) then
            dat_vld <= true;
        end if;
    end process;

    set_bit: process(csn, sclk) is
    begin
        if falling_edge(csn) then
            bit <= NUM_PRE_BITS + NUM_RES_BITS - 1;
        elsif sclk_en and falling_edge(sclk) and (bit > 0) then
            bit <= (bit - 1) after 25 ns; -- middle of sdata uncertainty time
        end if;
    end process;

    capture_dat: process(csn) is
        variable t_float: real;
        variable dat_float: real;
        variable dat_int: integer;
    begin
        if falling_edge(csn) then
            t_float   := real(t / 1 ns) / real(WAV_PERIOD / 1 ns);
            -- 1.0 is V_in = V_ref
            dat_float := 0.5 * sin(math_2_pi * t_float) + 0.5;
            dat_int   := integer(floor(real((2 ** NUM_RES_BITS) - 1) * dat_float));
            dat <= std_logic_vector(to_unsigned(integer(floor(real((2 ** NUM_RES_BITS) - 1) * dat_float)), NUM_RES_BITS));
        end if;
    end process;

    calc_sdata: process(dat_en, dat_vld, bit) is
    begin
        if not dat_en then
            sdata <= 'Z';
        elsif not dat_vld then
            sdata <= 'X';
        elsif (bit >= NUM_RES_BITS) then
            sdata <= '0';
        else
            sdata <= dat(bit);
        end if;
    end process;

    enforce_tquiet: process(csn, sclk) is
        variable last_transmit_t: time := -145 ns;
    begin
        if falling_edge(csn) then
            if (t < (last_transmit_t + 110 ns)) then
                report ("Conversion at " & time'image(t) & " occured within 110 ns of last conversion at " & time'image(last_transmit_t) & ".") severity error;
            elsif (t < (last_transmit_t + 145 ns)) then
                report ("Conversion at " & time'image(t) & " occured within 145 ns of last conversion at " & time'image(last_transmit_t) & ".") severity warning;
            end if;
        end if;
        if sclk_en and falling_edge(sclk) then
            last_transmit_t := t;
        end if;
    end process;

    enforce_fmax: process(sclk) is
        variable last_posedge_t: time := -50 ns;
        variable last_negedge_t: time := -50 ns;
    begin
        if rising_edge(sclk) then
            if (t < (last_posedge_t + 50 ns)) then
                report ("Measured clock period of " & time'image(t - last_posedge_t) & " is less than minimum 50 ns.") severity error;
            end if;
            last_posedge_t := t;
        elsif falling_edge(sclk) then
            if (t < (last_negedge_t + 50 ns)) then
                report ("Measured clock period of " & time'image(t - last_negedge_t) & " is less than minimum 50 ns.") severity error;
            end if;
            last_negedge_t := t;
        end if;
    end process;

    enforce_fmin: process(csn, sclk) is
        variable last_posedge_t: time := 0 ns;
        variable last_negedge_t: time := 0 ns;
    begin
        if falling_edge(csn) then
            last_posedge_t := t;
            last_negedge_t := t;
        end if;
        if csn = '0' and rising_edge(sclk) then
            if (t > (last_posedge_t + 100 us)) then
                report ("Measured clock period of " & time'image(t - last_posedge_t) & " is greater than maximum 100 us.") severity error;
            end if;
            last_posedge_t := t;
        elsif csn = '0' and falling_edge(sclk) then
            if (t > (last_negedge_t + 100 us)) then
                report ("Measured clock period of " & time'image(t - last_negedge_t) & " is greater than maximum 100 us.") severity error;
            end if;
            last_negedge_t := t;
        end if;
    end process;
end Behavior;