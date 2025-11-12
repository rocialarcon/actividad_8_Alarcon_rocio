library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity ram_512x32_tb is
end entity ram_512x32_tb;

architecture tb of ram_512x32_tb is
    signal clk    : std_logic;
    -- Puerto A (lectura)
    signal addr_r : std_logic_vector(8 downto 0)  := (others => '0');
    signal dout_r : std_logic_vector(31 downto 0);
    -- Puerto B (escritura)
    signal we_w   : std_logic;
    signal addr_w : std_logic_vector(8 downto 0)  := (others => '0');
    signal din_w  : std_logic_vector(31 downto 0)  := (others => '0');
    signal mask_w : std_logic_vector(3 downto 0) := (others => '0');

    constant periodo : time := 10 ns;

    -- Valores esperados desde el archivo:
    constant valor_0 : std_logic_vector(31 downto 0) := x"00000000"; -- addr 0
    constant valor_8 : std_logic_vector(31 downto 0) := x"ABCDEF01"; -- addr 8
    constant valor_9 : std_logic_vector(31 downto 0) := x"00000008"; -- addr 9
begin
    dut : entity ram_512x32
        generic map ( init_file => "../src/rom_512x32_tb_contenido.txt")
        port map(
            clk    => clk,
            addr_r => addr_r,
            dout_r => dout_r,
            we_w   => we_w,
            addr_w => addr_w,
            din_w  => din_w,
            mask_w => mask_w
        );

    -- Reloj
    reloj : process
    begin
        clk <= '0';
        wait for periodo/2;
        clk <= '1';
        wait for periodo/2;
    end process;

    -- Estimulos y verificacion
    estimulo_y_evaluacion : process
        variable prev : std_logic_vector(31 downto 0); 
    begin
        -- Estado inicial
        we_w   <= '0';
        addr_w <= (others => '0');
        din_w  <= (others => '0');
        mask_w <= (others => '0');

        -- Lectura inicial direccion 0
        addr_r <= (others => '0');
        wait for periodo/10; 
        assert dout_r = valor_0
            report "Dir 0: valor distinto al esperado" severity error;

        -- Lectura dir 8 (del archivo)
        addr_r <= std_logic_vector(to_unsigned(8, addr_r'length));
        wait for periodo/10;
        assert dout_r = valor_8
            report "Dir 8: valor distinto al esperado (lectura inicial)" severity error;
        
        -- Escritura en la misma direccion 8 con máscara de byte, se cambia el byte (7 downto 0) de 01 a 6f
        wait until rising_edge(clk);
        prev := dout_r;                                
        addr_w <= std_logic_vector(to_unsigned(8, addr_w'length));
        din_w  <= x"0000006F";
        mask_w <= "0001";                               
        we_w   <= '1';

        -- Antes del flanco la lectura no debe cambiar
        wait for periodo/2;
        assert dout_r = prev
            report "Dir 8 cambio antes del flanco" severity error;

        -- En el flanco se realiza la escritura; luego la lectura debe reflejarla
        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout_r = x"ABCDEF6F"
            report "Dir 8 luego de cambiar los dos ultimos byte: se esperaba ABCDEF6F" severity error;

        -- Fin de la operacion de escritura
        we_w   <= '0';
        mask_w <= (others => '0');

        --Escritura COMPLETA en direccion 9 
        --Lectura actual de dir 9 (desde archivo)

        addr_r <= std_logic_vector(to_unsigned(9, addr_r'length));
        wait for periodo/10;
        assert dout_r = valor_9
            report "Dir 9: valor distinto al esperado (lectura inicial)" severity error;

        -- Escribimos 0x11223344 con mascara completa
        addr_w <= std_logic_vector(to_unsigned(9, addr_w'length));
        din_w  <= x"11223344";
        mask_w <= "1111";
        we_w   <= '1';

        -- Antes del flanco, la lectura sigue mostrando el valor viejo
        prev := dout_r;
        wait for periodo/2;
        assert dout_r = prev
            report "Dir 9 cambio antes del flanco (write debe ser sincronico)" severity error;

        -- Flanco de escritura
        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout_r = x"11223344"
            report "Dir 9 tras write completo: se esperaba 11223344" severity error;

        -- Termina la escritura
        we_w   <= '0';
        mask_w <= (others => '0');

        --Modificar SOLO el byte alto [31:24] en dir 9 a 0xAA

        addr_r <= std_logic_vector(to_unsigned(9, addr_r'length));
        wait for periodo/10;
        assert dout_r = x"11223344"
            report "Dir 9 previo a mascara MSB no coincide" severity error;

        addr_w <= std_logic_vector(to_unsigned(9, addr_w'length));
        din_w  <= x"AA000000";    
        mask_w <= "1000";
        we_w   <= '1';

        -- Antes del flanco, lectura estable
        prev := dout_r;
        wait for periodo/2;
        assert dout_r = prev
            report "Dir 9 cambio antes del flanco (mascara MSB)" severity error;

        -- Flanco: se actualiza MSB → AA223344
        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout_r = x"AA223344"
            report "dir 9 tras mascara MSB: se esperaba AA223344" severity error;

        -- Cierro
        we_w   <= '0';
        mask_w <= (others => '0');

        report "Test RAM 512x32 finalizado OK" severity note;
        finish;
    end process;

end architecture;
