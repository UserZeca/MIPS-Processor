library ieee;
use ieee.std_logic_1164.all;

entity IF_ID is
    port (
        Clk      : in  std_logic;
        Rst      : in  std_logic;
        Stall    : in  std_logic; -- Se '1', mantém o dado (não grava novo)
        Flush    : in  std_logic; -- Se '1', zera o conteúdo (para desvios)
        
        -- Entradas
        PC_Plus4_in    : in  std_logic_vector(31 downto 0);
        Instruction_in : in  std_logic_vector(31 downto 0);
        
        -- Saídas
        PC_Plus4_out    : out std_logic_vector(31 downto 0);
        Instruction_out : out std_logic_vector(31 downto 0)
    );
end entity IF_ID;

architecture Behavioral of IF_ID is
begin
    process(Clk, Rst)
    begin
        if Rst = '1' then
            PC_Plus4_out    <= (others => '0');
            Instruction_out <= (others => '0');
        elsif rising_edge(Clk) then
            if Flush = '1' then
                PC_Plus4_out    <= (others => '0');
                Instruction_out <= (others => '0');
            elsif Stall = '0' then
                -- Só atualiza se NÃO estiver em Stall
                PC_Plus4_out    <= PC_Plus4_in;
                Instruction_out <= Instruction_in;
            end if;
        end if;
    end process;
end architecture Behavioral;