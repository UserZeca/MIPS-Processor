library ieee;
use ieee.std_logic_1164.all;

entity Control_Unit is
    port (
        -- Entrada
        Opcode : in  std_logic_vector(5 downto 0);
        Funct  : in  std_logic_vector(5 downto 0);
        
        -- Saídas
        RegWrite    : out std_logic;
        FP_RegWrite : out std_logic;
        RegDst      : out std_logic;
        Branch      : out std_logic;
        Branch_Cond : out std_logic; -- NOVO: '0' para BEQ, '1' para BNE
        Jump        : out std_logic;
        MemWrite    : out std_logic;
        MemRead     : out std_logic;
        ALUSrc      : out std_logic;
        ALU_Sel     : out std_logic_vector(3 downto 0);
        FP_Op_Sel   : out std_logic;
        WriteBack_Sel : out std_logic_vector(1 downto 0) 
        -- "00" = ALU Inteiros
        -- "01" = Memória
        -- "10" = ALU Ponto Flutuante
        -- "11" = LUI (Load Upper Immediate)
    );
end entity Control_Unit;

architecture Behavioral of Control_Unit is
begin
    
    process(Opcode, Funct)
    begin
        -- 1. Inicializa com valores "seguros" (NOP)
        RegWrite      <= '0';
        FP_RegWrite   <= '0';
        RegDst        <= '0';
        Branch        <= '0';
        Branch_Cond   <= '0'; -- Padrão para BEQ
        Jump          <= '0';
        MemWrite      <= '0';
        MemRead       <= '0';
        ALUSrc        <= '0';
        ALU_Sel       <= "XXXX";
        FP_Op_Sel     <= 'X';
        WriteBack_Sel <= "XX";

        -- 2. Decodifica o OPcode
        case Opcode is
        
            -- === TIPO-R (add, sub, etc.) ===
            when "000000" => 
                RegWrite      <= '1';
                RegDst        <= '1';
                WriteBack_Sel <= "00";
                case Funct is
                    when "100000" => ALU_Sel <= "0010"; -- add
                    when "100010" => ALU_Sel <= "0110"; -- sub
                    when "100100" => ALU_Sel <= "0000"; -- and
                    when "100101" => ALU_Sel <= "0001"; -- or
                    when "101010" => ALU_Sel <= "0111"; -- slt
                    when "100111" => ALU_Sel <= "1100"; -- nor
                    when others   => ALU_Sel <= "XXXX"; 
                end case;
                
            -- === TIPO-I (Inteiros) ===
            
            -- lw
            when "100011" =>
                RegWrite      <= '1';
                ALUSrc        <= '1';
                MemRead       <= '1';
                ALU_Sel       <= "0010"; 
                WriteBack_Sel <= "01"; 

            -- sw
            when "101011" =>
                MemWrite      <= '1';
                ALUSrc        <= '1';
                ALU_Sel       <= "0010"; 

            -- beq
            when "000100" =>
                Branch        <= '1';
                Branch_Cond   <= '0'; -- Condição: Zero = 1
                ALUSrc        <= '0';
                ALU_Sel       <= "0110"; -- SUB

            -- addi
            when "001000" =>
                RegWrite      <= '1';
                ALUSrc        <= '1';
                ALU_Sel       <= "0010"; -- ADD
                WriteBack_Sel <= "00"; 
                
            -- NOVO: andi
            when "001100" =>
                RegWrite      <= '1';
                RegDst        <= '0'; -- Destino é 'rt'
                ALUSrc        <= '1'; -- Usa o imediato
                ALU_Sel       <= "0000"; -- AND
                WriteBack_Sel <= "00";
            
            -- NOVO: ori
            when "001101" =>
                RegWrite      <= '1';
                RegDst        <= '0'; -- Destino é 'rt'
                ALUSrc        <= '1'; -- Usa o imediato
                ALU_Sel       <= "0001"; -- OR
                WriteBack_Sel <= "00";
            
            -- NOVO: lui
            when "001111" =>
                RegWrite      <= '1';
                RegDst        <= '0'; -- Destino é 'rt'
                WriteBack_Sel <= "11"; -- Seleciona o caminho do LUI
                -- (ALU não é usada)
            
            -- NOVO: bne
            when "000101" =>
                Branch        <= '1';
                Branch_Cond   <= '1'; -- Condição: Zero = 0
                ALUSrc        <= '0';
                ALU_Sel       <= "0110"; -- SUB
            
            -- === TIPO-J (jump) ===
            when "000010" =>
                Jump <= '1';

            -- === PONTO FLUTUANTE (cop1) ===
            
            -- add.s / mul.s
            when "010001" =>
                FP_RegWrite   <= '1';
                RegDst        <= '1'; 
                ALUSrc        <= '0';
                WriteBack_Sel <= "10";
                
                case Funct is
                    when "000000" => FP_Op_Sel <= '0'; -- add.s
                    when "000010" => FP_Op_Sel <= '1'; -- mul.s
                    when others   => FP_Op_Sel <= 'X';
                end case;

            -- l.s (lwc1)
            when "110001" =>
                FP_RegWrite   <= '1';
                RegDst        <= '0';
                ALUSrc        <= '1';
                MemRead       <= '1';
                ALU_Sel       <= "0010"; 
                WriteBack_Sel <= "01";
            
            when others =>
                null;
                
        end case;
    end process;

end architecture Behavioral;