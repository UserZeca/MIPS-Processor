library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FP_Register_File is
    port (
        -- Clock e Reset
        Clk         : in  std_logic;
        Rst         : in  std_logic; -- Reset (para limpar registradores)
        
        -- Sinal de Controle (vem da Control_Unit)
        Write_Enable: in  std_logic; -- O 'FP_RegWrite' da Control_Unit
        
        -- Portas de Leitura (para os operandos da FP_ALU)
        Read_Addr_1 : in  std_logic_vector(4 downto 0); -- Endereço do registrador 1 (ex: $f0)
        Read_Addr_2 : in  std_logic_vector(4 downto 0); -- Endereço do registrador 2 (ex: $f1)
        Data_Out_1  : out std_logic_vector(31 downto 0); -- Saída do registrador 1
        Data_Out_2  : out std_logic_vector(31 downto 0); -- Saída do registrador 2
        
        -- Porta de Escrita (para o resultado da FP_ALU ou da Memória)
        Write_Addr  : in  std_logic_vector(4 downto 0); -- Endereço de escrita (ex: $f2)
        Data_In     : in  std_logic_vector(31 downto 0)  -- Dado a ser escrito
    );
end entity FP_Register_File;

architecture Behavioral of FP_Register_File is

    -- Tipo de dado para a nossa memória de 32 registradores
    -- (32 palavras de 32 bits cada)
    type RegFile_Type is array (0 to 31) of std_logic_vector(31 downto 0);
    
    -- O sinal principal que armazena todos os 32 registradores de Ponto Flutuante
    signal Registers : RegFile_Type;

begin

    -- === Processo de Leitura (Combinacional/Assíncrona) ===
    -- Lê os dois registradores o tempo todo.
    -- (Nota: O MIPS FPU não tem um registrador '$f0' hard-coded para zero
    --  como o '$zero' de inteiros, então lemos normalmente.)
    Data_Out_1 <= Registers(to_integer(unsigned(Read_Addr_1)));
    Data_Out_2 <= Registers(to_integer(unsigned(Read_Addr_2)));


    -- === Processo de Escrita (Síncrono) ===
    -- SÓ escreve no registrador na borda de subida do clock
    -- E APENAS SE o 'Write_Enable' estiver ativo.
    process(Clk)
    begin
        if rising_edge(Clk) then
            if Rst = '1' then
                -- Se o Reset estiver ativo, limpa todos os registradores (bom para simulação)
                Registers <= (others => (others => '0'));
            elsif (Write_Enable = '1') then
                -- Escreve o novo dado no registrador selecionado
                Registers(to_integer(unsigned(Write_Addr))) <= Data_In;
            end if;
        end if;
    end process;

end architecture Behavioral;