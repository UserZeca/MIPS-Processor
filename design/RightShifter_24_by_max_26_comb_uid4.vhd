library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Corrigido

entity RightShifter_24_by_max_26_comb_uid4 is
    port ( X : in  std_logic_vector(23 downto 0);
           S : in  std_logic_vector(4 downto 0);
           R : out  std_logic_vector(49 downto 0)   );
end entity;

architecture arch of RightShifter_24_by_max_26_comb_uid4 is
signal level0 :  std_logic_vector(23 downto 0);
signal ps :  std_logic_vector(4 downto 0);
signal level1 :  std_logic_vector(24 downto 0);
signal level2 :  std_logic_vector(26 downto 0);
signal level3 :  std_logic_vector(30 downto 0);
signal level4 :  std_logic_vector(38 downto 0);
signal level5 :  std_logic_vector(54 downto 0);
begin
    level0<= X;
    ps<= S;
    level1<=  (0 downto 0 => '0') & level0 when ps(0) = '1' else    level0 & (0 downto 0 => '0');
    level2<=  (1 downto 0 => '0') & level1 when ps(1) = '1' else    level1 & (1 downto 0 => '0');
    level3<=  (3 downto 0 => '0') & level2 when ps(2) = '1' else    level2 & (3 downto 0 => '0');
    level4<=  (7 downto 0 => '0') & level3 when ps(3) = '1' else    level3 & (7 downto 0 => '0');
    level5<=  (15 downto 0 => '0') & level4 when ps(4) = '1' else    level4 & (15 downto 0 => '0');
    R <= level5(54 downto 5);
end architecture;