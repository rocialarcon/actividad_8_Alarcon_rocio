library ieee;
use ieee.std_logic_1164.all;

entity detector_flanco is
    port (
        clk : in std_logic;
        entrada : in std_logic;
        pulso : out std_logic
    );
end entity detector_flanco;

architecture arch of detector_flanco is 
signal s1 : std_logic := '0';
signal s2 : std_logic := '0';
begin 
 memoria_detec : process(clk)
 begin
    if rising_edge(clk) then
       s2 <= s1;
       s1 <= entrada;
    end if;
 end process;
 pulso <= s1 and (not s2);
 end arch;