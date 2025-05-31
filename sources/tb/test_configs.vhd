configuration behavioral of dp_mem_tb is
    for tb
        for dut: dp_mem
            use entity work.dp_mem(dp_mem_a);
        end for;
    end for;
end behavioral;

configuration inferred of dp_mem_tb is
    for tb
        for dut: dp_mem
            use entity work.dp_mem(dp_mem_inferred);
        end for;
    end for;
end inferred;