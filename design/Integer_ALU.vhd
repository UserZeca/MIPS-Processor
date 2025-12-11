library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Biblioteca padrão para aritmética

entity Integer_ALU is
    port (
        -- Entradas de dados (32 bits cada)
        A       : in  std_logic_vector(31 downto 0);
        B       : in  std_logic_vector(31 downto 0);
        
        -- Sinal de controle para selecionar a operação
        ALU_Sel : in  std_logic_vector(3 downto 0);
        
        -- Saída do resultado (32 bits)
        R       : out std_logic_vector(31 downto 0);
        
        -- Flag 'Zero' (para desvios como 'beq')
        Zero    : out std_logic
    );
end entity Integer_ALU;

architecture Behavioral of Integer_ALU is

    -- Sinal interno para o resultado. (Não podemos ler uma porta 'out')
    signal s_R : std_logic_vector(31 downto 0);

begin

    -- Este processo combinacional calcula o resultado da ALU
    process(A, B, ALU_Sel)
    begin
        case ALU_Sel is
            when "0000" => -- AND
                s_R <= A and B;
                
            when "0001" => -- OR
                s_R <= A or B;
                
            when "0010" => -- ADD (para add, addi, addu, addiu)
                -- A soma/subtração de 2s complemento é a mesma
                -- para inteiros com e sem sinal.
                s_R <= std_logic_vector(signed(A) + signed(B));
                
            when "0110" => -- SUB (para sub, subu)
                s_R <= std_logic_vector(signed(A) - signed(B));
                
            when "0111" => -- SLT (Set on Less Than, COM SINAL)
                if signed(A) < signed(B) then
                    -- Define o resultado como 1 (em 32 bits)
                    s_R <= std_logic_vector(to_unsigned(1, 32));
                else
                    -- Define o resultado como 0 (em 32 bits)
                    s_R <= (others => '0');
                end if;
                
            when "1100" => -- NOR
                s_R <= A nor B;

            -- (NOTA: sltu é comumente implementado no MIPS
            --  usando o mesmo 'ALU_Sel' 0111 do slt, mas com
            --  um circuito externo ou uma ULA mais complexa.
            --  Para este projeto, seguimos o padrão básico.)

            when others => -- Operação indefinida
                s_R <= (others => 'X');
                
        end case;
    end process;

    -- Atribui o resultado final à porta de saída
    R <= s_R;
    
    -- Gera a flag 'Zero'. É '1' se o resultado for 0, senão '0'.
    Zero <= '1' when s_R = x"00000000" else '0';

end architecture Behavioral;