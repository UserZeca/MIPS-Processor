library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Corrigido

entity IntAdder_27_f400_uid8 is
    port ( X : in  std_logic_vector(26 downto 0);
           Y : in  std_logic_vector(26 downto 0);
           Cin : in  std_logic;
           R : out  std_logic_vector(26 downto 0)   );
end entity;

architecture arch of IntAdder_27_f400_uid8 is
begin
    -- Corrigido para usar numeric_std (mesmo padrão do FPMult)
    R <= std_logic_vector(unsigned(X) + unsigned(Y) + unsigned'('0' & Cin));
end architecture;