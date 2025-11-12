library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use work.all;

entity top is
    port (
        clk     : in  std_logic;
        x       : in std_logic_vector(7 downto 0);
        display : out std_logic_vector(6 downto 0);
        h       : out std_logic
    );
end entity top;

architecture arch of top is
    signal addr_dout : std_logic;
    signal addr : std_logic_vector(3 downto 0);
    signal we : std_logic;
    signal din : std_logic_vector(3 downto 0);
    signal dout : std_logic_vector(3 downto 0);

    signal pulso_5, pulso_6 : std_logic;
    signal display_in : std_logic_vector(3 downto 0);
    signal addr_sig : std_logic_vector(3 downto 0);

    begin
        detector_X5 : entity detector_flanco 
        port map (
            clk => clk,
            entrada => x(5),
            pulso => pulso_5
        );

        detector_X6 : entity detector_flanco 
        port map (
            clk => clk,
            entrada => x(6),
            pulso => pulso_6
        );

        decodificador : entity deco_hexa 
        port map (
            D => display_in,
            S => display
        );

        memoria_ram : entity ram_16x4
        port map (
            clk => clk,
            addr => addr,
            we => we,
            din => din,
            dout => dout --arreglar  
        );

        addr_dout <= x(7);
        we <= pulso_5;
        din <= x(3 downto 0);
        addr_sig <= x(3 downto 0) when pulso_6 = '1' else addr;
        
        memoria: process(clk)
        begin
            if rising_edge(clk) then 
                addr <= addr_sig;
            end if;
        end process;

        display_in <= dout when addr_dout = '0' else addr;
        h <= x(7);

    end arch;