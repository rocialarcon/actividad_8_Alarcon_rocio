library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity ram_512x8_tb is
end ram_512x8_tb;

architecture tb of ram_512x8_tb is
    signal clk     : std_logic;
    signal we      : std_logic;
    signal addr    : std_logic_vector(8 downto 0);
    signal din     : std_logic_vector(7 downto 0);
    signal dout    : std_logic_vector(7 downto 0);

    constant periodo :time := 10 ns;
begin
    
    dut : entity ram_512x8 generic map (
        init_file => "../src/ram_512x8_tb_contenido.txt"
    ) port map(
        clk => clk,
        we => we,
        addr => addr,
        din => din,
        dout => dout
    );

    reloj : process
    begin
        clk <= '0';
        wait for periodo/2;
        clk <= '1';
        wait for periodo/2;
    end process;

    estimulo_y_evaluacion : process
        variable d : std_logic_vector (7 downto 0);
    begin
        we <= '0';
        addr <= 9x"0";
        din <= 8x"0";
        wait until rising_edge(clk);
        wait for periodo/4;
        addr <= 9x"8";
        wait for periodo;
        assert dout = x"6e"
            report "Valor inicial distinto al esperado" severity error;
        d := dout;
        din <= x"6f";
        we <= '1';
        wait for periodo;
        we <= '0';
        assert dout = d
            report "Al escribir el valor leido debe ser el original, no el nuevo" severity error;
        wait for periodo;
        assert dout = x"6f"
            report "Valor leido distinto al escrito" severity error;
        finish;
    end process;

end tb ; -- tb