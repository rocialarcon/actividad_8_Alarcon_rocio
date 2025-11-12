library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all; 
use std.textio.all;            
use std.env.finish; 
use work.all;

entity rom_512x32_tb is
end entity rom_512x32_tb;

architecture tb of rom_512x32_tb is
    signal clk  : std_logic;
    signal addr : std_logic_vector(8 downto 0);
    signal dout : std_logic_vector(31 downto 0);

    constant valor_0 : std_logic_vector(31 downto 0) := x"00000000";
    constant valor_8 : std_logic_vector(31 downto 0) := x"ABCDEF01";

    constant periodo : time := 10 ns;
begin
    dut: entity rom_512x32
        generic map (
            init_file => "../src/rom_512x32_tb_contenido.txt"
        )
        port map(
            clk  => clk,
            addr => addr,
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
        variable prev : std_logic_vector(31 downto 0);
    begin
        -- Estado inicial: direccion 0 y primer flanco
        addr <= (others => '0');
        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout = valor_0
            report "Dir 0: valor distinto al esperado" severity error;

        -- Pedimos dir 8 y verificamos salida registrada
        prev := dout;
        addr <= std_logic_vector(to_unsigned(8, addr'length));
        wait for periodo/2;  
        assert dout = prev
            report "La salida cambio antes del flanco (debe ser registrada)"
            severity error;

        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout = valor_8
            report "Dir 8: valor distinto al esperado" severity error;

        --barrido
        for a in 0 to 29 loop
            addr <= std_logic_vector(to_unsigned(a, addr'length));
            wait until rising_edge(clk);
            wait for 1 ns;
        end loop;

        report "Test ROM 512x32 finalizado OK" severity note;
        finish;
    end process;

end tb;
