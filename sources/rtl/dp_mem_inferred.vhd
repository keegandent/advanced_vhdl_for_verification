library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture dp_mem_inferred of dp_mem is
    type mem_t is array(0 to (2 ** 4) - 1) of std_logic_vector(15 downto 0);
    shared variable mem: mem_t;
    attribute ram_style : string;
    attribute ram_style of mem: variable is "block";

    signal wea_reg, web_reg:        std_logic                       := '0';
    signal addra_reg, addrb_reg:    std_logic_vector(3 downto 0)    := (others => '0');
    signal dina_reg, dinb_reg:      std_logic_vector(15 downto 0)   := (others => '0');
begin
    set_regs_a: process (clka) is
    begin
        if rising_edge(clka) then
            wea_reg     <= wea;
            dina_reg    <= dina;
            addra_reg   <= addra;
        end if;
    end process;

    set_mem_a: process (clka) is
    begin
        if rising_edge(clka) and wea_reg = '1' then
                mem(to_integer(unsigned(addra_reg))) := dina_reg;
        end if;
    end process;

    set_out_a: process (clka) is
    begin
        if rising_edge(clka) then
            douta <= mem(to_integer(unsigned(addra_reg)));
        end if;
    end process;

    set_regs_b: process (clkb) is
    begin
        if rising_edge(clkb) then
            web_reg     <= web;
            dinb_reg    <= dinb;
            addrb_reg   <= addrb;
        end if;
    end process;

    set_mem_b: process (clkb) is
    begin
        if rising_edge(clkb) and web_reg = '1' then
                mem(to_integer(unsigned(addrb_reg))) := dinb_reg;
        end if;
    end process;

    set_out_b: process (clkb) is
    begin
        if rising_edge(clkb) then
            doutb <= mem(to_integer(unsigned(addrb_reg)));
        end if;
    end process;
end dp_mem_inferred;