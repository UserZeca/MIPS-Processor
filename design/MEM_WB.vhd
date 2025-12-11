library ieee;
use ieee.std_logic_1164.all;

entity MEM_WB is
    port (
        Clk   : in std_logic;
        Rst   : in std_logic;
        
        -- === CONTROLE (Apenas WB sobrou) ===
        RegWrite_in      : in std_logic;
        FP_RegWrite_in   : in std_logic;
        WriteBack_Sel_in : in std_logic_vector(1 downto 0);
        
        -- === DADOS ===
        Mem_ReadData_in  : in std_logic_vector(31 downto 0); -- Dado lido da memória
        ALU_Result_in    : in std_logic_vector(31 downto 0); -- Passado adiante
        FP_ALU_Result_in : in std_logic_vector(31 downto 0); -- Passado adiante
        LUI_Data_in      : in std_logic_vector(31 downto 0); -- Passado adiante
        
        -- === ENDEREÇO DE ESCRITA ===
        WriteReg_Addr_in : in std_logic_vector(4 downto 0);
        
        -- === SAÍDAS ===
        RegWrite_out     : out std_logic;
        FP_RegWrite_out  : out std_logic;
        WriteBack_Sel_out: out std_logic_vector(1 downto 0);
        
        Mem_ReadData_out : out std_logic_vector(31 downto 0);
        ALU_Result_out   : out std_logic_vector(31 downto 0);
        FP_ALU_Result_out: out std_logic_vector(31 downto 0);
        LUI_Data_out     : out std_logic_vector(31 downto 0);
        
        WriteReg_Addr_out: out std_logic_vector(4 downto 0)
    );
end entity MEM_WB;

architecture Behavioral of MEM_WB is
begin
    process(Clk, Rst)
    begin
        if Rst = '1' then
            RegWrite_out <= '0'; FP_RegWrite_out <= '0';
        elsif rising_edge(Clk) then
            RegWrite_out <= RegWrite_in; FP_RegWrite_out <= FP_RegWrite_in; WriteBack_Sel_out <= WriteBack_Sel_in;
            
            Mem_ReadData_out <= Mem_ReadData_in;
            ALU_Result_out <= ALU_Result_in;
            FP_ALU_Result_out <= FP_ALU_Result_in;
            LUI_Data_out <= LUI_Data_in;
            
            WriteReg_Addr_out <= WriteReg_Addr_in;
        end if;
    end process;
end architecture Behavioral;