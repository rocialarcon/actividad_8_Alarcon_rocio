library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.all;

entity registro_32x32_tb is
end entity registro_32x32_tb;

architecture tb of registro_32x32_tb is
    -- DUT signals
    signal clk    : std_logic := '0';
    signal addr_1 : std_logic_vector(4 downto 0) := (others => '0');
    signal dout_1 : std_logic_vector(31 downto 0);
    signal addr_2 : std_logic_vector(4 downto 0) := (others => '0');
    signal dout_2 : std_logic_vector(31 downto 0);
    signal we_w   : std_logic;
    signal addr_w : std_logic_vector(4 downto 0) := (others => '0');
    signal din_w  : std_logic_vector(31 downto 0) := (others => '0');

    constant periodo : time := 10 ns;

    constant valor_0 : std_logic_vector(31 downto 0) := x"00000000"; -- reg0
    constant valor_1 : std_logic_vector(31 downto 0) := x"DEADBEEF"; -- reg1
    constant valor_8 : std_logic_vector(31 downto 0) := x"ABCDEF01"; -- reg8
begin
    
    dut : entity registro_32x32
        generic map ( init_file =>"../src/rom_512x32_tb_contenido.txt")
        port map(
            clk    => clk,
            addr_1 => addr_1,
            dout_1 => dout_1,
            addr_2 => addr_2,
            dout_2 => dout_2,
            we_w   => we_w,
            addr_w => addr_w,
            din_w  => din_w
        );

    -- Reloj
    reloj : process
    begin
        clk <= '0'; 
        wait for periodo/2;
        clk <= '1'; 
        wait for periodo/2;
    end process;

    -- Estímulos
    estimulo_y_evaluacion : process
        variable prev1, prev2 : std_logic_vector(31 downto 0);
    begin
        -- Estado inicial
        we_w   <= '0';
        addr_w <= (others => '0');
        din_w  <= (others => '0');
        addr_1 <= (others => '0');
        addr_2 <= (others => '0');

        --Lecturas dobles asincronas desde init_file

        addr_1 <= std_logic_vector(to_unsigned(0, addr_1'length));
        addr_2 <= std_logic_vector(to_unsigned(1, addr_2'length));
        wait for 1 ns;  -- lectura asincrona
        assert dout_1 = valor_0 report "reg[0] incorrecto" severity error;
        assert dout_2 = valor_1 report "reg[1] incorrecto" severity error;

        -- Cambiamos a otra direccion en el segundo puerto
        addr_2 <= std_logic_vector(to_unsigned(8, addr_2'length));
        wait for 1 ns;
        assert dout_2 = valor_8 report "reg[8] incorrecto" severity error;

        --Escribir en reg2 (sincronico). Antes del flanco no debe cambiar.

        -- Preparar write a reg2 con 0x55667788
        addr_w <= std_logic_vector(to_unsigned(2, addr_w'length));
        din_w  <= x"55667788";
        we_w   <= '1';
        wait until rising_edge(clk);
        -- Fijamos puerto de lectura 1 en reg2 y el 2 en reg1
        addr_1 <= std_logic_vector(to_unsigned(2, addr_1'length));
        addr_2 <= std_logic_vector(to_unsigned(1, addr_2'length));
        wait for 1 ns;                -- lectura asincrona previa
        prev1 := dout_1;              -- valor viejo de reg2 (desde archivo o 0)
        prev2 := dout_2;              -- DEADBEEF

        -- Antes del flanco, nada debe cambiar
        wait for periodo/2;
        assert dout_1 = prev1 report "reg[2] cambió antes del flanco" severity error;
        assert dout_2 = prev2 report "reg[1] cambió antes del flanco" severity error;

        -- Flanco: se realiza la escritura
        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout_1 = x"55667788" report "reg[2] tras write incorrecto" severity error;
        we_w <= '0';

        --Intentar escribir en reg0: debe permanecer en 0

        --fijamos lectura de reg0 en ambos puertos para vigilar
        addr_1 <= std_logic_vector(to_unsigned(0, addr_1'length));
        addr_2 <= std_logic_vector(to_unsigned(0, addr_2'length));
        wait for 1 ns;
        assert dout_1 = x"00000000" report "reg[0] deberia ser 0 (antes de write)" severity error;
        assert dout_2 = x"00000000" report "reg[0] deberia ser 0 (antes de write)" severity error;

        -- programamos write a reg0 con todo 1s (debe ignorarse/forzarse a 0)
        addr_w <= std_logic_vector(to_unsigned(0, addr_w'length));
        din_w  <= x"FFFFFFFF";
        we_w   <= '1';

        -- antes del flanco no cambia (obvio)
        wait for periodo/2;
        assert dout_1 = x"00000000" report "reg[0] cambió antes del flanco" severity error;

        -- flanco: el diseño fuerza reg0 a 0
        wait until rising_edge(clk);
        wait for 1 ns;
        assert dout_1 = x"00000000" report "reg[0] no debe aceptar escrituras" severity error;
        assert dout_2 = x"00000000" report "reg[0] no debe aceptar escrituras" severity error;
        we_w <= '0';

        --Lecturas cruzadas simultaneas (dos puertos leyendo distintas dir)
   
        addr_1 <= std_logic_vector(to_unsigned(2, addr_1'length)); -- reg2 ya escrito
        addr_2 <= std_logic_vector(to_unsigned(8, addr_2'length)); -- del init
        wait for 1 ns;  -- asncrono
        assert dout_1 = x"55667788" report "reg[2] lectura cruzada incorrecta" severity error;
        assert dout_2 = valor_8       report "reg[8] lectura cruzada incorrecta" severity error;

        report "Test registro_32x32 finalizado OK" severity note;
        finish;
    end process;

end tb;
