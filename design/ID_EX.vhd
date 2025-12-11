library ieee;
use ieee.std_logic_1164.all;

entity ID_EX is
    port (
        Clk   : in std_logic;
        Rst   : in std_logic;
        Flush : in std_logic; -- Usado se houver erro de predição ou stall
        
        -- === SINAIS DE CONTROLE ===
        -- WB (Write Back)
        RegWrite_in     : in std_logic;
        FP_RegWrite_in  : in std_logic;
        WriteBack_Sel_in: in std_logic_vector(1 downto 0);
        -- MEM (Memory)
        MemWrite_in     : in std_logic;
        MemRead_in      : in std_logic;
        Branch_in       : in std_logic;
        Branch_Cond_in  : in std_logic;
        -- EX (Execute)
        ALUSrc_in       : in std_logic;
        ALU_Sel_in      : in std_logic_vector(3 downto 0);
        FP_Op_Sel_in    : in std_logic;
        RegDst_in       : in std_logic;
        
        -- === DADOS ===
        PC_Plus4_in     : in std_logic_vector(31 downto 0);
        ReadData1_in    : in std_logic_vector(31 downto 0); -- Inteiro Rs
        ReadData2_in    : in std_logic_vector(31 downto 0); -- Inteiro Rt
        FP_ReadData1_in : in std_logic_vector(31 downto 0); -- Float Fs
        FP_ReadData2_in : in std_logic_vector(31 downto 0); -- Float Ft
        Immediate_in    : in std_logic_vector(31 downto 0);
        LUI_Data_in     : in std_logic_vector(31 downto 0);
        
        -- === ENDEREÇOS (Para Forwarding e WriteBack) ===
        Rs_Addr_in      : in std_logic_vector(4 downto 0);
        Rt_Addr_in      : in std_logic_vector(4 downto 0);
        Rd_Addr_in      : in std_logic_vector(4 downto 0);
        
        -- === SAÍDAS (Cópia exata das entradas com sufixo _out) ===
        RegWrite_out    : out std_logic;
        FP_RegWrite_out : out std_logic;
        WriteBack_Sel_out: out std_logic_vector(1 downto 0);
        MemWrite_out    : out std_logic;
        MemRead_out     : out std_logic;
        Branch_out      : out std_logic;
        Branch_Cond_out : out std_logic;
        ALUSrc_out      : out std_logic;
        ALU_Sel_out     : out std_logic_vector(3 downto 0);
        FP_Op_Sel_out   : out std_logic;
        RegDst_out      : out std_logic;
        
        PC_Plus4_out    : out std_logic_vector(31 downto 0);
        ReadData1_out   : out std_logic_vector(31 downto 0);
        ReadData2_out   : out std_logic_vector(31 downto 0);
        FP_ReadData1_out: out std_logic_vector(31 downto 0);
        FP_ReadData2_out: out std_logic_vector(31 downto 0);
        Immediate_out   : out std_logic_vector(31 downto 0);
        LUI_Data_out    : out std_logic_vector(31 downto 0);
        
        Rs_Addr_out     : out std_logic_vector(4 downto 0);
        Rt_Addr_out     : out std_logic_vector(4 downto 0);
        Rd_Addr_out     : out std_logic_vector(4 downto 0)
    );
end entity ID_EX;

architecture Behavioral of ID_EX is
begin
    process(Clk, Rst)
    begin
        if Rst = '1' then
            -- Reset Total
            RegWrite_out <= '0'; FP_RegWrite_out <= '0'; 
            MemWrite_out <= '0'; MemRead_out <= '0'; -- <--- RESET IMPORTANTE
            Branch_out <= '0'; Branch_Cond_out <= '0';
            WriteBack_Sel_out <= (others => '0'); 
            
        elsif rising_edge(Clk) then
            if Flush = '1' then
                 -- ZERAR TUDO (BOLHA)
                 RegWrite_out <= '0'; 
                 FP_RegWrite_out <= '0'; 
                 MemWrite_out <= '0'; 
                 MemRead_out <= '0';  -- <--- ADICIONE ESTA LINHA!!! (Crucial)
                 Branch_out <= '0';
                 Branch_Cond_out <= '0'; -- Adicionar por segurança
                 
                 -- Os dados podem ser qualquer coisa (lixo), pois os controles estão zerados
                 WriteBack_Sel_out <= (others => '0');
                 ALUSrc_out <= '0';
                 RegDst_out <= '0';
                 FP_Op_Sel_out <= '0';
                 
            else
                -- Passagem Normal (Não mexa aqui)
                RegWrite_out <= RegWrite_in; FP_RegWrite_out <= FP_RegWrite_in; WriteBack_Sel_out <= WriteBack_Sel_in;
                MemWrite_out <= MemWrite_in; MemRead_out <= MemRead_in; Branch_out <= Branch_in; Branch_Cond_out <= Branch_Cond_in;
                ALUSrc_out <= ALUSrc_in; ALU_Sel_out <= ALU_Sel_in; FP_Op_Sel_out <= FP_Op_Sel_in; RegDst_out <= RegDst_in;
                
                PC_Plus4_out <= PC_Plus4_in;
                ReadData1_out <= ReadData1_in; ReadData2_out <= ReadData2_in;
                FP_ReadData1_out <= FP_ReadData1_in; FP_ReadData2_out <= FP_ReadData2_in;
                Immediate_out <= Immediate_in; LUI_Data_out <= LUI_Data_in;
                
                Rs_Addr_out <= Rs_Addr_in; Rt_Addr_out <= Rt_Addr_in; Rd_Addr_out <= Rd_Addr_in;
            end if;
        end if;
    end process;
end architecture Behavioral;