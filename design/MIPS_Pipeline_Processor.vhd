library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MIPS_Pipeline_Processor is
    port (
        Clk : in  std_logic;
        Rst : in  std_logic
    );
end entity MIPS_Pipeline_Processor;

architecture Structural of MIPS_Pipeline_Processor is

    -- =========================================================================
    -- 1. COMPONENTES (Blocos Funcionais + Registradores de Pipeline)
    -- =========================================================================

    -- --- Blocos Funcionais Básicos ---
    component Program_Counter is
        port (Clk, Rst : in std_logic; Branch_Addr : in std_logic_vector(31 downto 0); PC_Sel : in std_logic; PC_Out : out std_logic_vector(31 downto 0));
    end component;

    component Instruction_Memory is
        port (Address : in std_logic_vector(31 downto 0); Instruction : out std_logic_vector(31 downto 0));
    end component;

    component Control_Unit is
        port (
            Opcode : in std_logic_vector(5 downto 0); Funct : in std_logic_vector(5 downto 0);
            RegWrite, FP_RegWrite, RegDst, Branch, Branch_Cond, Jump, MemWrite, MemRead, ALUSrc, FP_Op_Sel : out std_logic;
            ALU_Sel : out std_logic_vector(3 downto 0); WriteBack_Sel : out std_logic_vector(1 downto 0)
        );
    end component;

    component register_file is
        port (Clock, RegWrite : in std_logic; ReadReg1, ReadReg2, WriteReg : in std_logic_vector(4 downto 0); WriteData : in std_logic_vector(31 downto 0); ReadData1, ReadData2 : out std_logic_vector(31 downto 0));
    end component;

    component FP_Register_File is
        port (Clk, Rst, Write_Enable : in std_logic; Read_Addr_1, Read_Addr_2, Write_Addr : in std_logic_vector(4 downto 0); Data_In : in std_logic_vector(31 downto 0); Data_Out_1, Data_Out_2 : out std_logic_vector(31 downto 0));
    end component;

    component Integer_ALU is
        port (A, B : in std_logic_vector(31 downto 0); ALU_Sel : in std_logic_vector(3 downto 0); R : out std_logic_vector(31 downto 0); Zero : out std_logic);
    end component;

    component FP_ALU_Wrapper is
        port (X_in, Y_in : in std_logic_vector(31 downto 0); Op_sel : in std_logic; R_out : out std_logic_vector(31 downto 0));
    end component;

    component Data_Memory is
        port (Clk, MemWrite, MemRead : in std_logic; Address, DataIn : in std_logic_vector(31 downto 0); DataOut : out std_logic_vector(31 downto 0));
    end component;

    -- --- Registradores de Pipeline ---
    component IF_ID is
        port (Clk, Rst, Stall, Flush : in std_logic; PC_Plus4_in, Instruction_in : in std_logic_vector(31 downto 0); PC_Plus4_out, Instruction_out : out std_logic_vector(31 downto 0));
    end component;

    component ID_EX is
        port (
            Clk, Rst, Flush : in std_logic;
            RegWrite_in, FP_RegWrite_in, MemWrite_in, MemRead_in, Branch_in, Branch_Cond_in, ALUSrc_in, FP_Op_Sel_in, RegDst_in : in std_logic;
            WriteBack_Sel_in : in std_logic_vector(1 downto 0); ALU_Sel_in : in std_logic_vector(3 downto 0);
            PC_Plus4_in, ReadData1_in, ReadData2_in, FP_ReadData1_in, FP_ReadData2_in, Immediate_in, LUI_Data_in : in std_logic_vector(31 downto 0);
            Rs_Addr_in, Rt_Addr_in, Rd_Addr_in : in std_logic_vector(4 downto 0);
            
            RegWrite_out, FP_RegWrite_out, MemWrite_out, MemRead_out, Branch_out, Branch_Cond_out, ALUSrc_out, FP_Op_Sel_out, RegDst_out : out std_logic;
            WriteBack_Sel_out : out std_logic_vector(1 downto 0); ALU_Sel_out : out std_logic_vector(3 downto 0);
            PC_Plus4_out, ReadData1_out, ReadData2_out, FP_ReadData1_out, FP_ReadData2_out, Immediate_out, LUI_Data_out : out std_logic_vector(31 downto 0);
            Rs_Addr_out, Rt_Addr_out, Rd_Addr_out : out std_logic_vector(4 downto 0)
        );
    end component;

    component EX_MEM is
        port (
            Clk, Rst : in std_logic;
            RegWrite_in, FP_RegWrite_in, MemWrite_in, MemRead_in, Branch_in, Branch_Cond_in : in std_logic;
            WriteBack_Sel_in : in std_logic_vector(1 downto 0);
            Zero_in : in std_logic; ALU_Result_in, FP_ALU_Result_in, WriteData_Mem_in, LUI_Data_in, Branch_Target_in : in std_logic_vector(31 downto 0);
            WriteReg_Addr_in : in std_logic_vector(4 downto 0);
            
            RegWrite_out, FP_RegWrite_out, MemWrite_out, MemRead_out, Branch_out, Branch_Cond_out : out std_logic;
            WriteBack_Sel_out : out std_logic_vector(1 downto 0);
            Zero_out : out std_logic; ALU_Result_out, FP_ALU_Result_out, WriteData_Mem_out, LUI_Data_out, Branch_Target_out : out std_logic_vector(31 downto 0);
            WriteReg_Addr_out : out std_logic_vector(4 downto 0)
        );
    end component;

    component MEM_WB is
        port (
            Clk, Rst : in std_logic;
            RegWrite_in, FP_RegWrite_in : in std_logic; WriteBack_Sel_in : in std_logic_vector(1 downto 0);
            Mem_ReadData_in, ALU_Result_in, FP_ALU_Result_in, LUI_Data_in : in std_logic_vector(31 downto 0);
            WriteReg_Addr_in : in std_logic_vector(4 downto 0);
            
            RegWrite_out, FP_RegWrite_out : out std_logic; WriteBack_Sel_out : out std_logic_vector(1 downto 0);
            Mem_ReadData_out, ALU_Result_out, FP_ALU_Result_out, LUI_Data_out : out std_logic_vector(31 downto 0);
            WriteReg_Addr_out : out std_logic_vector(4 downto 0)
        );
    end component;

	component Hazard_Detection_Unit is
        port (
            -- Entradas (Para detectar Load-Use)
            ID_EX_MemRead : in std_logic;
            ID_EX_Rt      : in std_logic_vector(4 downto 0);
            IF_ID_Rs      : in std_logic_vector(4 downto 0);
            IF_ID_Rt      : in std_logic_vector(4 downto 0);
            
            -- Entrada (Para detectar Branch)
            Branch_Taken  : in std_logic;
            
            -- Saídas de Controle
            PC_Write      : out std_logic;
            IF_ID_Write   : out std_logic;
            
            -- Saídas de Flush (Limpeza)
            IF_ID_Flush   : out std_logic;
            ID_EX_Flush   : out std_logic;
            EX_MEM_Flush  : out std_logic
        );
    end component;
    
    component Cache_Controller is
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            
            -- Interface com a CPU (Vem do Pipeline)
            CPU_Address   : in  std_logic_vector(31 downto 0);
            CPU_WriteData : in  std_logic_vector(31 downto 0);
            CPU_MemWrite  : in  std_logic;
            CPU_MemRead   : in  std_logic;
            CPU_ReadData  : out std_logic_vector(31 downto 0);
            CPU_Stall     : out std_logic; -- Sinal de Stall (Opcional por enquanto)
            
            -- Interface com a RAM (Vai para a Data_Memory)
            RAM_ReadData  : in  std_logic_vector(31 downto 0);
            RAM_Address   : out std_logic_vector(31 downto 0);
            RAM_WriteData : out std_logic_vector(31 downto 0);
            RAM_MemWrite  : out std_logic;
            RAM_MemRead   : out std_logic
        );
    end component;
    
    -- =========================================================================
    -- 2. SINAIS (Organizados por Estágio)
    -- =========================================================================
    
    -- Sinais Globais de Controle de Hazard (Por enquanto '0')
    signal s_Stall_IF_ID : std_logic := '0';
    signal s_Flush_IF_ID : std_logic := '0';
    signal s_Flush_ID_EX : std_logic := '0';

	-- Sinais da Unidade de Detecção de Hazard
    signal s_PC_Write        : std_logic;
    signal s_IF_ID_Write     : std_logic;
    signal s_Hazard_IF_ID_Flush : std_logic;
    signal s_Hazard_ID_EX_Flush : std_logic;
    signal s_Hazard_EX_MEM_Flush: std_logic;
    
    -- Sinais combinados de Stall/Flush (Lógica final)
    signal s_Final_IF_ID_Stall : std_logic;
    signal s_Final_IF_ID_Flush : std_logic;
    signal s_Final_ID_EX_Flush : std_logic;

    -- === ESTÁGIO IF (Instruction Fetch) ===
    signal s_IF_PC_Current    : std_logic_vector(31 downto 0);
    signal s_IF_PC_Plus4      : std_logic_vector(31 downto 0);
    signal s_IF_Instruction   : std_logic_vector(31 downto 0);
    signal s_IF_PC_Next       : std_logic_vector(31 downto 0); -- Saída do MUX do PC

    -- === ESTÁGIO ID (Decode) ===
    -- Saídas do IF/ID
    signal s_ID_PC_Plus4      : std_logic_vector(31 downto 0);
    signal s_ID_Instruction   : std_logic_vector(31 downto 0);
    -- Sinais internos ID
    signal s_ID_RegWrite, s_ID_FP_RegWrite, s_ID_RegDst, s_ID_Branch, s_ID_Branch_Cond, s_ID_Jump, s_ID_MemWrite, s_ID_MemRead, s_ID_ALUSrc, s_ID_FP_Op_Sel : std_logic;
    signal s_ID_WriteBack_Sel : std_logic_vector(1 downto 0);
    signal s_ID_ALU_Sel       : std_logic_vector(3 downto 0);
    signal s_ID_ReadData1, s_ID_ReadData2, s_ID_FP_ReadData1, s_ID_FP_ReadData2 : std_logic_vector(31 downto 0);
    signal s_ID_Extended_Imm  : std_logic_vector(31 downto 0);
    signal s_ID_LUI_Data      : std_logic_vector(31 downto 0);
    signal s_ID_Jump_Address  : std_logic_vector(31 downto 0); -- Endereço Jump calculado

    -- === ESTÁGIO EX (Execute) ===
	-- Sinais da Unidade de Forwarding
    signal s_ForwardA, s_ForwardB : std_logic_vector(1 downto 0);
    signal s_Forwarded_A_Val      : std_logic_vector(31 downto 0); -- Saída do MUX A
    signal s_Forwarded_B_Val      : std_logic_vector(31 downto 0); -- Saída do MUX B    

    -- Saídas do ID/EX
    signal s_EX_RegWrite, s_EX_FP_RegWrite, s_EX_MemWrite, s_EX_MemRead, s_EX_Branch, s_EX_Branch_Cond, s_EX_ALUSrc, s_EX_FP_Op_Sel, s_EX_RegDst : std_logic;
    signal s_EX_WriteBack_Sel : std_logic_vector(1 downto 0);
    signal s_EX_ALU_Sel       : std_logic_vector(3 downto 0);
    signal s_EX_PC_Plus4, s_EX_ReadData1, s_EX_ReadData2, s_EX_FP_ReadData1, s_EX_FP_ReadData2, s_EX_Extended_Imm, s_EX_LUI_Data : std_logic_vector(31 downto 0);
    signal s_EX_Rs, s_EX_Rt, s_EX_Rd : std_logic_vector(4 downto 0);
    -- Sinais internos EX
    signal s_EX_ALU_Input_B   : std_logic_vector(31 downto 0);
    signal s_EX_Int_Result    : std_logic_vector(31 downto 0);
    signal s_EX_FP_Result     : std_logic_vector(31 downto 0);
    signal s_EX_Zero          : std_logic;
    signal s_EX_Branch_Target : std_logic_vector(31 downto 0);
    signal s_EX_WriteReg_Addr : std_logic_vector(4 downto 0); -- MUX RegDst resolvido aqui

    -- === ESTÁGIO MEM (Memory) ===
    -- Saídas do EX/MEM
    signal s_MEM_RegWrite, s_MEM_FP_RegWrite, s_MEM_MemWrite, s_MEM_MemRead, s_MEM_Branch, s_MEM_Branch_Cond : std_logic;
    signal s_MEM_WriteBack_Sel : std_logic_vector(1 downto 0);
    signal s_MEM_Zero          : std_logic;
    signal s_MEM_ALU_Result, s_MEM_FP_Result, s_MEM_WriteData_Mem, s_MEM_LUI_Data, s_MEM_Branch_Target : std_logic_vector(31 downto 0);
    signal s_MEM_WriteReg_Addr : std_logic_vector(4 downto 0);
    -- Sinais internos MEM
    signal s_MEM_ReadData      : std_logic_vector(31 downto 0);
    signal s_MEM_PCSrc         : std_logic; -- Decisão do Branch

	-- =========================================================================
    -- SINAIS INTERNOS: CACHE <-> RAM
    -- =========================================================================
    signal s_Cache_to_RAM_Addr  : std_logic_vector(31 downto 0);
    signal s_Cache_to_RAM_Data  : std_logic_vector(31 downto 0);
    signal s_Cache_to_RAM_Write : std_logic;
    signal s_Cache_to_RAM_Read  : std_logic;
    signal s_RAM_to_Cache_Data  : std_logic_vector(31 downto 0);
    signal s_Cache_Stall        : std_logic; -- (Por enquanto não vamos usar na lógica de stall)

    -- === ESTÁGIO WB (Write Back) ===
    -- Saídas do MEM/WB
    signal s_WB_RegWrite, s_WB_FP_RegWrite : std_logic;
    signal s_WB_WriteBack_Sel  : std_logic_vector(1 downto 0);
    signal s_WB_Mem_ReadData, s_WB_ALU_Result, s_WB_FP_Result, s_WB_LUI_Data : std_logic_vector(31 downto 0);
    signal s_WB_WriteReg_Addr  : std_logic_vector(4 downto 0);
    -- Sinais internos WB
    signal s_WB_WriteData_Final: std_logic_vector(31 downto 0); -- Dado final a ser escrito

begin

	-- =========================================================================
    -- UNIDADE DE DETECÇÃO DE HAZARD
    -- =========================================================================
    u_Hazard_Unit: entity work.Hazard_Detection_Unit
        port map (
            -- Load-Use Inputs
            ID_EX_MemRead => s_EX_MemRead,      -- Instrução anterior é Load?
            ID_EX_Rt      => s_EX_Rt,           -- Qual registrador ela vai carregar?
            IF_ID_Rs      => s_ID_Instruction(25 downto 21), -- Quem eu preciso (A)?
            IF_ID_Rt      => s_ID_Instruction(20 downto 16), -- Quem eu preciso (B)?
            
            -- Branch Input (Vem do estágio MEM)
            Branch_Taken  => s_MEM_PCSrc, 
            
            -- Outputs
            PC_Write      => s_PC_Write,
            IF_ID_Write   => s_IF_ID_Write,
            IF_ID_Flush   => s_Hazard_IF_ID_Flush,
            ID_EX_Flush   => s_Hazard_ID_EX_Flush,
            EX_MEM_Flush  => s_Hazard_EX_MEM_Flush
        );

    -- Lógica de Inversão e Combinação
    -- O PC_Write da unidade é '1' para escrever, mas o Stall é '1' para parar.
    -- O componente PC usa 'PC_Sel' onde '1' carrega (se sua lógica for essa).
    -- Vamos assumir que seu PC carrega novo valor sempre que PC_Sel='1'.
    
    -- Ajustes Finais:
    s_Stall_IF_ID <= not s_IF_ID_Write; -- Se Write=0, Stall=1
    
    s_Flush_IF_ID <= s_Hazard_IF_ID_Flush;
    s_Flush_ID_EX <= s_Hazard_ID_EX_Flush;
    

    -- =========================================================================
    -- ESTÁGIO 1: IF (Instruction Fetch)
    -- =========================================================================

    -- MUX do PC (Lógica de Desvio: Vem do Estágio MEM para Branch ou ID para Jump)
    -- Por simplicidade nesta fase, vamos assumir que Branch é resolvido no MEM
    s_IF_PC_Next <= s_MEM_Branch_Target when (s_MEM_PCSrc = '1') else
                    s_ID_Jump_Address   when (s_ID_Jump = '1') else -- Jumps são resolvidos no ID
                    s_IF_PC_Plus4;

    u_PC: Program_Counter
        port map (Clk => Clk, Rst => Rst, Branch_Addr => s_IF_PC_Next, PC_Sel => s_PC_Write, PC_Out => s_IF_PC_Current);

    s_IF_PC_Plus4 <= std_logic_vector(signed(s_IF_PC_Current) + 4);

    u_IMem: Instruction_Memory
        port map (Address => s_IF_PC_Current, Instruction => s_IF_Instruction);

    -- REGISTRADOR IF/ID
    u_IF_ID: IF_ID
        port map (
            Clk => Clk, Rst => Rst, Stall => s_Stall_IF_ID, Flush => s_Flush_IF_ID,
            PC_Plus4_in => s_IF_PC_Plus4, Instruction_in => s_IF_Instruction,
            PC_Plus4_out => s_ID_PC_Plus4, Instruction_out => s_ID_Instruction
        );

    -- =========================================================================
    -- ESTÁGIO 2: ID (Decode)
    -- =========================================================================

    u_Ctrl: Control_Unit
        port map (
            Opcode => s_ID_Instruction(31 downto 26), Funct => s_ID_Instruction(5 downto 0),
            RegWrite => s_ID_RegWrite, FP_RegWrite => s_ID_FP_RegWrite, RegDst => s_ID_RegDst,
            Branch => s_ID_Branch, Branch_Cond => s_ID_Branch_Cond, Jump => s_ID_Jump,
            MemWrite => s_ID_MemWrite, MemRead => s_ID_MemRead, ALUSrc => s_ID_ALUSrc,
            ALU_Sel => s_ID_ALU_Sel, FP_Op_Sel => s_ID_FP_Op_Sel, WriteBack_Sel => s_ID_WriteBack_Sel
        );

    -- Bancos de Registradores (ATENÇÃO: Write vem do estágio WB!)
    u_Int_Reg_File: register_file
        port map (
            Clock => Clk, RegWrite => s_WB_RegWrite, -- Sinal do WB
            ReadReg1 => s_ID_Instruction(25 downto 21), ReadReg2 => s_ID_Instruction(20 downto 16),
            WriteReg => s_WB_WriteReg_Addr, -- Endereço do WB
            WriteData => s_WB_WriteData_Final, -- Dado do WB
            ReadData1 => s_ID_ReadData1, ReadData2 => s_ID_ReadData2
        );

    u_FP_Reg_File: FP_Register_File
        port map (
            Clk => Clk, Rst => Rst, Write_Enable => s_WB_FP_RegWrite, -- Sinal do WB
            Read_Addr_1 => s_ID_Instruction(25 downto 21), Read_Addr_2 => s_ID_Instruction(20 downto 16),
            Write_Addr => s_WB_WriteReg_Addr, -- Endereço do WB
            Data_In => s_WB_WriteData_Final, -- Dado do WB
            Data_Out_1 => s_ID_FP_ReadData1, Data_Out_2 => s_ID_FP_ReadData2
        );

    -- Extensão de Sinal e Cálculos Auxiliares
    s_ID_Extended_Imm <= std_logic_vector(resize(signed(s_ID_Instruction(15 downto 0)), 32));
    s_ID_LUI_Data <= s_ID_Instruction(15 downto 0) & x"0000";
    -- Cálculo do Jump (PC+4[31:28] & Instr[25:0] & 00)
    s_ID_Jump_Address <= s_ID_PC_Plus4(31 downto 28) & s_ID_Instruction(25 downto 0) & "00";

    -- REGISTRADOR ID/EX
    u_ID_EX: ID_EX
        port map (
            Clk => Clk, Rst => Rst, Flush => s_Flush_ID_EX,
            -- Controle
            RegWrite_in => s_ID_RegWrite, FP_RegWrite_in => s_ID_FP_RegWrite, WriteBack_Sel_in => s_ID_WriteBack_Sel,
            MemWrite_in => s_ID_MemWrite, MemRead_in => s_ID_MemRead, Branch_in => s_ID_Branch, Branch_Cond_in => s_ID_Branch_Cond,
            ALUSrc_in => s_ID_ALUSrc, ALU_Sel_in => s_ID_ALU_Sel, FP_Op_Sel_in => s_ID_FP_Op_Sel, RegDst_in => s_ID_RegDst,
            -- Dados
            PC_Plus4_in => s_ID_PC_Plus4, ReadData1_in => s_ID_ReadData1, ReadData2_in => s_ID_ReadData2,
            FP_ReadData1_in => s_ID_FP_ReadData1, FP_ReadData2_in => s_ID_FP_ReadData2,
            Immediate_in => s_ID_Extended_Imm, LUI_Data_in => s_ID_LUI_Data,
            -- Endereços
            Rs_Addr_in => s_ID_Instruction(25 downto 21), Rt_Addr_in => s_ID_Instruction(20 downto 16), Rd_Addr_in => s_ID_Instruction(15 downto 11),
            
            -- Saídas para EX
            RegWrite_out => s_EX_RegWrite, FP_RegWrite_out => s_EX_FP_RegWrite, WriteBack_Sel_out => s_EX_WriteBack_Sel,
            MemWrite_out => s_EX_MemWrite, MemRead_out => s_EX_MemRead, Branch_out => s_EX_Branch, Branch_Cond_out => s_EX_Branch_Cond,
            ALUSrc_out => s_EX_ALUSrc, ALU_Sel_out => s_EX_ALU_Sel, FP_Op_Sel_out => s_EX_FP_Op_Sel, RegDst_out => s_EX_RegDst,
            PC_Plus4_out => s_EX_PC_Plus4, ReadData1_out => s_EX_ReadData1, ReadData2_out => s_EX_ReadData2,
            FP_ReadData1_out => s_EX_FP_ReadData1, FP_ReadData2_out => s_EX_FP_ReadData2,
            Immediate_out => s_EX_Extended_Imm, LUI_Data_out => s_EX_LUI_Data,
            Rs_Addr_out => s_EX_Rs, Rt_Addr_out => s_EX_Rt, Rd_Addr_out => s_EX_Rd
        );


-- =========================================================================
    -- ESTÁGIO 3: EX (Execute) - COM FORWARDING
    -- =========================================================================

    -- 1. Instância da Unidade de Forwarding
    u_Forwarding: entity work.Forwarding_Unit
        port map (
            Rs_EX => s_EX_Rs,
            Rt_EX => s_EX_Rt,
            Rd_MEM => s_MEM_WriteReg_Addr,
            RegWrite_MEM => s_MEM_RegWrite,
            Rd_WB => s_WB_WriteReg_Addr,
            RegWrite_WB => s_WB_RegWrite,
            ForwardA => s_ForwardA,
            ForwardB => s_ForwardB
        );

    -- 2. MUX de Forwarding A (Entrada A da ALU)
    -- Seleciona entre: Dado Original, Dado do MEM (Atalho), Dado do WB (Atalho)
    with s_ForwardA select
        s_Forwarded_A_Val <= s_EX_ReadData1       when "00", -- Original
                             s_MEM_ALU_Result     when "10", -- Veio do MEM (O mais recente)
                             s_WB_WriteData_Final when "01", -- Veio do WB
                             s_EX_ReadData1       when others;

    -- 3. MUX de Forwarding B (Para ALU Input B ou Mem Write Data)
    with s_ForwardB select
        s_Forwarded_B_Val <= s_EX_ReadData2       when "00",
                             s_MEM_ALU_Result     when "10",
                             s_WB_WriteData_Final when "01",
                             s_EX_ReadData2       when others;

    -- 4. MUX da ALU Inteira (Immediate vs Register/Forwarded)
    -- ATENÇÃO: O Mux ALUSrc agora recebe o valor JÁ processado pelo Forwarding B!
    s_EX_ALU_Input_B <= s_Forwarded_B_Val when s_EX_ALUSrc = '0' else s_EX_Extended_Imm;

    -- 5. ALU Inteira
    u_Int_ALU: Integer_ALU
        port map (
            A => s_Forwarded_A_Val,  -- Usa o valor com Forwarding
            B => s_EX_ALU_Input_B,   -- Usa o valor escolhido (Forwarding ou Imediato)
            ALU_Sel => s_EX_ALU_Sel,
            R => s_EX_Int_Result,
            Zero => s_EX_Zero
        );

    -- 6. ALU de Ponto Flutuante (Por enquanto sem forwarding dedicado, usa original)
    -- Nota: Para pipeline completo com float, precisaríamos duplicar a Forwarding Unit para registradores F
    u_FP_ALU: FP_ALU_Wrapper
        port map (
            X_in => s_EX_FP_ReadData1, 
            Y_in => s_EX_FP_ReadData2, 
            Op_sel => s_EX_FP_Op_Sel, 
            R_out => s_EX_FP_Result
        );

    -- 7. MUX do RegDst
    s_EX_WriteReg_Addr <= s_EX_Rt when s_EX_RegDst = '0' else s_EX_Rd;

    -- 8. Cálculo do Branch
    s_EX_Branch_Target <= std_logic_vector(signed(s_EX_PC_Plus4) + signed(s_EX_Extended_Imm(29 downto 0) & "00"));

    -- 9. REGISTRADOR EX/MEM (Atualizado)
    -- Importante: 'WriteData_Mem_in' deve receber s_Forwarded_B_Val para corrigir casos de SW logo após cálculo
    u_EX_MEM: EX_MEM
        port map (
            Clk => Clk, Rst => Rst,
            RegWrite_in => s_EX_RegWrite, FP_RegWrite_in => s_EX_FP_RegWrite, WriteBack_Sel_in => s_EX_WriteBack_Sel,
            MemWrite_in => s_EX_MemWrite, MemRead_in => s_EX_MemRead, Branch_in => s_EX_Branch, Branch_Cond_in => s_EX_Branch_Cond,
            
            Zero_in => s_EX_Zero, 
            ALU_Result_in => s_EX_Int_Result, 
            FP_ALU_Result_in => s_EX_FP_Result,
            
            WriteData_Mem_in => s_Forwarded_B_Val, -- <<< MUDANÇA CRÍTICA AQUI (Usa o dado forwarded para SW)
            
            LUI_Data_in => s_EX_LUI_Data, 
            Branch_Target_in => s_EX_Branch_Target,
            WriteReg_Addr_in => s_EX_WriteReg_Addr,
            
            RegWrite_out => s_MEM_RegWrite, FP_RegWrite_out => s_MEM_FP_RegWrite, WriteBack_Sel_out => s_MEM_WriteBack_Sel,
            MemWrite_out => s_MEM_MemWrite, MemRead_out => s_MEM_MemRead, Branch_out => s_MEM_Branch, Branch_Cond_out => s_MEM_Branch_Cond,
            Zero_out => s_MEM_Zero, ALU_Result_out => s_MEM_ALU_Result, FP_ALU_Result_out => s_MEM_FP_Result,
            WriteData_Mem_out => s_MEM_WriteData_Mem, LUI_Data_out => s_MEM_LUI_Data, Branch_Target_out => s_MEM_Branch_Target,
            WriteReg_Addr_out => s_MEM_WriteReg_Addr
        );
    -- =========================================================================
    -- ESTÁGIO 4: MEM (Memory Access)
    -- =========================================================================

    -- =========================================================================
    -- CONTROLADOR DE CACHE (Intercepta o acesso à memória)
    -- =========================================================================
    u_Cache: Cache_Controller
        port map (
            Clk => Clk,
            Rst => Rst,
            
            -- LADO DA CPU (Conectado ao Pipeline)
            CPU_Address   => s_MEM_ALU_Result,     -- O endereço calculado na ALU
            CPU_WriteData => s_MEM_WriteData_Mem,  -- O dado a ser escrito (sw)
            CPU_MemWrite  => s_MEM_MemWrite,       -- Sinal de controle de escrita
            CPU_MemRead   => s_MEM_MemRead,        -- Sinal de controle de leitura
            
            CPU_ReadData  => s_MEM_ReadData,       -- O dado lido VOLTA para o Pipeline
            CPU_Stall     => s_Cache_Stall,        -- Sinal de pausa (se houver Miss lento)
            
            -- LADO DA RAM (Conectado aos sinais novos que criamos)
            RAM_ReadData  => s_RAM_to_Cache_Data,  -- Dado que volta da RAM física
            RAM_Address   => s_Cache_to_RAM_Addr,  -- Endereço repassado à RAM
            RAM_WriteData => s_Cache_to_RAM_Data,  -- Dado repassado à RAM
            RAM_MemWrite  => s_Cache_to_RAM_Write, -- Controle repassado
            RAM_MemRead   => s_Cache_to_RAM_Read   -- Controle repassado
        );
        
    -- =========================================================================
    -- MEMÓRIA PRINCIPAL (FÍSICA)
    -- =========================================================================
    u_DMem: Data_Memory
        port map (
            Clk      => Clk,
            -- Agora controlada pelos sinais que saem da Cache!
            MemWrite => s_Cache_to_RAM_Write, 
            MemRead  => s_Cache_to_RAM_Read,
            Address  => s_Cache_to_RAM_Addr,
            DataIn   => s_Cache_to_RAM_Data,
            DataOut  => s_RAM_to_Cache_Data -- Envia o dado para a Cache
        );

    -- Lógica de Branch: (Branch AND Zero) ou (Branch AND Not Zero) dependendo de BNE/BEQ
    s_MEM_PCSrc <= s_MEM_Branch and ( (s_MEM_Zero and not s_MEM_Branch_Cond) or (not s_MEM_Zero and s_MEM_Branch_Cond) );

    -- Se o Branch for tomado, precisamos "Flushar" os registradores anteriores (Fase 2)
    -- s_Flush_IF_ID <= s_MEM_PCSrc; -- Descomentar na Fase 2

    -- REGISTRADOR MEM/WB
    u_MEM_WB: MEM_WB
        port map (
            Clk => Clk, Rst => Rst,
            RegWrite_in => s_MEM_RegWrite, FP_RegWrite_in => s_MEM_FP_RegWrite, WriteBack_Sel_in => s_MEM_WriteBack_Sel,
            Mem_ReadData_in => s_MEM_ReadData, ALU_Result_in => s_MEM_ALU_Result,
            FP_ALU_Result_in => s_MEM_FP_Result, LUI_Data_in => s_MEM_LUI_Data,
            WriteReg_Addr_in => s_MEM_WriteReg_Addr,
            
            -- Saídas para WB
            RegWrite_out => s_WB_RegWrite, FP_RegWrite_out => s_WB_FP_RegWrite, WriteBack_Sel_out => s_WB_WriteBack_Sel,
            Mem_ReadData_out => s_WB_Mem_ReadData, ALU_Result_out => s_WB_ALU_Result,
            FP_ALU_Result_out => s_WB_FP_Result, LUI_Data_out => s_WB_LUI_Data,
            WriteReg_Addr_out => s_WB_WriteReg_Addr
        );

    -- =========================================================================
    -- ESTÁGIO 5: WB (Write Back)
    -- =========================================================================

    -- MUX Final de Write Back
    with s_WB_WriteBack_Sel select
        s_WB_WriteData_Final <= s_WB_ALU_Result     when "00", -- Inteiros
                                s_WB_Mem_ReadData   when "01", -- Load
                                s_WB_FP_Result      when "10", -- Ponto Flutuante
                                s_WB_LUI_Data       when "11", -- LUI
                                (others => 'X')     when others;

end architecture Structural;