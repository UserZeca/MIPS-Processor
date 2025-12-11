library ieee;
use ieee.std_logic_1164.all;

entity EX_MEM is
    port (
        Clk   : in std_logic;
        Rst   : in std_logic;
        
        -- === CONTROLE ===
        -- WB
        RegWrite_in      : in std_logic;
        FP_RegWrite_in   : in std_logic;
        WriteBack_Sel_in : in std_logic_vector(1 downto 0);
        -- MEM
        MemWrite_in      : in std_logic;
        MemRead_in       : in std_logic;
        Branch_in        : in std_logic;
        Branch_Cond_in   : in std_logic;
        
        -- === DADOS ===
        Zero_in          : in std_logic; -- Resultado do Zero da ALU Inteira
        ALU_Result_in    : in std_logic_vector(31 downto 0); -- Endereço ou dado calculado
        FP_ALU_Result_in : in std_logic_vector(31 downto 0); -- Resultado Float
        WriteData_Mem_in : in std_logic_vector(31 downto 0); -- Dado para gravar na Memória (sw)
        LUI_Data_in      : in std_logic_vector(31 downto 0); -- Passando adiante
        Branch_Target_in : in std_logic_vector(31 downto 0); -- Endereço calculado do branch
        
        -- === ENDEREÇO DE ESCRITA (JÁ ESCOLHIDO) ===
        WriteReg_Addr_in : in std_logic_vector(4 downto 0);
        
        -- === SAÍDAS ===
        RegWrite_out     : out std_logic;
        FP_RegWrite_out  : out std_logic;
        WriteBack_Sel_out: out std_logic_vector(1 downto 0);
        MemWrite_out     : out std_logic;
        MemRead_out      : out std_logic;
        Branch_out       : out std_logic;
        Branch_Cond_out  : out std_logic;
        
        Zero_out         : out std_logic;
        ALU_Result_out   : out std_logic_vector(31 downto 0);
        FP_ALU_Result_out: out std_logic_vector(31 downto 0);
        WriteData_Mem_out: out std_logic_vector(31 downto 0);
        LUI_Data_out     : out std_logic_vector(31 downto 0);
        Branch_Target_out: out std_logic_vector(31 downto 0);
        
        WriteReg_Addr_out: out std_logic_vector(4 downto 0)
    );
end entity EX_MEM;

architecture Behavioral of EX_MEM is
begin
    process(Clk, Rst)
    begin
        if Rst = '1' then
            RegWrite_out <= '0'; MemWrite_out <= '0'; Branch_out <= '0';
        elsif rising_edge(Clk) then
            RegWrite_out <= RegWrite_in; FP_RegWrite_out <= FP_RegWrite_in; WriteBack_Sel_out <= WriteBack_Sel_in;
            MemWrite_out <= MemWrite_in; MemRead_out <= MemRead_in; Branch_out <= Branch_in; Branch_Cond_out <= Branch_Cond_in;
            
            Zero_out <= Zero_in;
            ALU_Result_out <= ALU_Result_in;
            FP_ALU_Result_out <= FP_ALU_Result_in;
            WriteData_Mem_out <= WriteData_Mem_in;
            LUI_Data_out <= LUI_Data_in;
            Branch_Target_out <= Branch_Target_in;
            
            WriteReg_Addr_out <= WriteReg_Addr_in;
        end if;
    end process;
end architecture Behavioral;