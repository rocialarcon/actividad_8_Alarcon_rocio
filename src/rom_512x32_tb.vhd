library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all; -- Para hread y to_hstring
use std.textio.all; -- Para manejo de archivos
use std.env.finish; -- Para terminar la simulación

entity tb_rom_512x32 is
end entity tb_rom_512x32;

architecture tb of tb_rom_512x32 is
    
    -- Constantes del sistema
    constant C_ADDR_DEPTH : natural := 512;
    constant CLK_PERIOD   : time    := 10 ns; 
    constant C_INIT_FILE  : string  := "rom_data_512x32.hex";

    -- 1. Señales de interfaz (Conexión al DUT)
    signal s_clk    : std_logic := '0';
    signal s_addr   : std_logic_vector(8 downto 0) := (others => '0');
    signal s_dout   : std_logic_vector(31 downto 0);
    
    -- 2. Declaración del Tipo y Carga de Referencia (Idéntico a la ROM)
    type rom_type is array (C_ADDR_DEPTH - 1 downto 0) of std_logic_vector(31 downto 0);
    
    -- Función para cargar la referencia (es idéntica a init_rom)
    impure function init_ref return rom_type is
        file rom_file      : text;
        variable rom_data  : rom_type := (others => (others => '0'));
        variable line_content: line;
        variable addr_index  : integer := 0;
        variable valid       : boolean;
        variable status      : file_open_status;
    begin
        file_open(status, rom_file, C_INIT_FILE, read_mode);
        if status = open_ok then
            while not endfile(rom_file) loop
                readline(rom_file, line_content);
                hread(line_content, rom_data(addr_index), valid);
                if valid then
                    addr_index := addr_index + 1;
                end if;
                exit when addr_index = C_ADDR_DEPTH; 
            end loop;
            file_close(rom_file);
        end if;
        return rom_data;
    end function init_ref;

    constant REF_ROM : rom_type := init_ref; -- Arreglo de datos correctos
    
begin
    
    -- 3. Instanciación del Dispositivo Bajo Prueba (DUT)
    dut : entity work.rom_512x32 -- Uso de 'work' para referenciar la entidad
        generic map (
            INIT_FILE => C_INIT_FILE
        ) 
        port map(
            clk   => s_clk,
            addr  => s_addr,
            dout  => s_dout
        );

    -- 4. Generador de Reloj
    reloj : process
        constant HALF_PERIOD : time := CLK_PERIOD / 2;
    begin
        s_clk <= '0';
        wait for HALF_PERIOD;
        s_clk <= '1';
        wait for HALF_PERIOD;
    end process reloj;

    -- 5. Proceso de Estímulo y Evaluación Automática
    estimulo_y_evaluacion : process
    begin
        -- Espera para la inicialización (reseteo simulado)
        wait for 100 ns; 
        
        report "--- INICIO DE PRUEBA DE LECTURA SECUENCIAL ---" severity note;

        -- Bucle para recorrer todas las 512 direcciones
        for i in 0 to C_ADDR_DEPTH - 1 loop
            
            -- Pone la dirección 'i' en el bus s_addr
            s_addr <= std_logic_vector(to_unsigned(i, 9)); 

            -- Espera un ciclo de reloj para la lectura síncrona
            wait until rising_edge(s_clk); 

            -- VERIFICACIÓN AUTOMÁTICA
            assert s_dout = REF_ROM(i)
            report "ERROR en Direccion " & integer'image(i) & 
                   " | Esperado: " & to_hstring(REF_ROM(i)) & 
                   " | Obtenido: " & to_hstring(s_dout)
            severity error; 
            
        end loop;

        report "--- PRUEBA COMPLETADA SIN ERRORES EN LAS 512 POSICIONES ---" severity note;
        
        -- Finaliza la simulación
        finish;
        
    end process estimulo_y_evaluacion;

end architecture tb;