library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =========================================================================
-- MIPS_Processor.vhd
-- Componente top-level para o processador MIPS de 32 bits
-- de ciclo único, com ISA estendida para Ponto Flutuante (Parte 1).
-- =========================================================================
entity MIPS_Processor is
    port (
        Clk : in  std_logic;
        Rst : in  std_logic
    );
end entity MIPS_Processor;

architecture Structural of MIPS_Processor is

    -- =========================================================================
    -- 1. DECLARAÇÃO DOS COMPONENTES
    -- =========================================================================

    component Program_Counter
        port (
            Clk         : in  std_logic;
            Rst         : in  std_logic;
            Branch_Addr : in  std_logic_vector(31 downto 0);
            PC_Sel      : in  std_logic; 
            PC_Out      : out std_logic_vector(31 downto 0)
        );
    end component;

    component Instruction_Memory
        port (
            Address     : in  std_logic_vector(31 downto 0);
            Instruction : out std_logic_vector(31 downto 0)
        );
    end component;

    component Control_Unit
        port (
            Opcode      : in  std_logic_vector(5 downto 0);
            Funct       : in  std_logic_vector(5 downto 0);
            RegWrite    : out std_logic;
            FP_RegWrite : out std_logic;
            RegDst      : out std_logic;
            Branch      : out std_logic;
            Branch_Cond : out std_logic; -- '0' para BEQ, '1' para BNE
            Jump        : out std_logic;
            MemWrite    : out std_logic;
            MemRead     : out std_logic;
            ALUSrc      : out std_logic;
            ALU_Sel     : out std_logic_vector(3 downto 0);
            FP_Op_Sel   : out std_logic;
            WriteBack_Sel : out std_logic_vector(1 downto 0) 
        );
    end component;

    component register_file -- Seu arquivo de registrador de inteiros
        port (
            Clock     : in  std_logic;
            RegWrite  : in  std_logic;
            ReadReg1  : in  std_logic_vector(4 downto 0);
            ReadReg2  : in  std_logic_vector(4 downto 0);
            WriteReg  : in  std_logic_vector(4 downto 0);
            WriteData : in  std_logic_vector(31 downto 0);
            ReadData1 : out std_logic_vector(31 downto 0);
            ReadData2 : out std_logic_vector(31 downto 0)
        );
    end component;

    component FP_Register_File
        port (
            Clk         : in  std_logic;
            Rst         : in  std_logic;
            Write_Enable: in  std_logic;
            Read_Addr_1 : in  std_logic_vector(4 downto 0);
            Read_Addr_2 : in  std_logic_vector(4 downto 0);
            Data_Out_1  : out std_logic_vector(31 downto 0);
            Data_Out_2  : out std_logic_vector(31 downto 0);
            Write_Addr  : in  std_logic_vector(4 downto 0);
            Data_In     : in  std_logic_vector(31 downto 0)
        );
    end component;

    component Integer_ALU
        port (
            A       : in  std_logic_vector(31 downto 0);
            B       : in  std_logic_vector(31 downto 0);
            ALU_Sel : in  std_logic_vector(3 downto 0);
            R       : out std_logic_vector(31 downto 0);
            Zero    : out std_logic
        );
    end component;

    component Data_Memory
        port (
            Clk         : in  std_logic;
            MemWrite    : in  std_logic;
            MemRead     : in  std_logic;
            Address     : in  std_logic_vector(31 downto 0);
            DataIn      : in  std_logic_vector(31 downto 0);
            DataOut     : out std_logic_vector(31 downto 0)
        );
    end component;

    component FP_ALU_Wrapper
        port (
            X_in    : in  std_logic_vector(31 downto 0);
            Y_in    : in  std_logic_vector(31 downto 0);
            Op_sel  : in  std_logic; 
            R_out   : out std_logic_vector(31 downto 0)
        );
    end component;

    -- =========================================================================
    -- 2. SINAIS (Os "fios" que conectam os componentes)
    -- =========================================================================

    -- Sinais de Controle
    signal s_RegWrite    : std_logic;
    signal s_FP_RegWrite : std_logic;
    signal s_RegDst      : std_logic;
    signal s_Branch      : std_logic;
    signal s_Branch_Cond : std_logic;
    signal s_Jump        : std_logic;
    signal s_MemWrite    : std_logic;
    signal s_MemRead     : std_logic;
    signal s_ALUSrc      : std_logic;
    signal s_ALU_Sel     : std_logic_vector(3 downto 0);
    signal s_FP_Op_Sel   : std_logic;
    signal s_WriteBack_Sel : std_logic_vector(1 downto 0);

    -- Sinais do Datapath
    signal s_PC_Addr          : std_logic_vector(31 downto 0);
    signal s_PC_Plus_4        : std_logic_vector(31 downto 0);
    signal s_Instruction      : std_logic_vector(31 downto 0);
    signal s_Extended_Immediate : std_logic_vector(31 downto 0);
    signal s_LUI_Data         : std_logic_vector(31 downto 0);
    signal s_Branch_Target_Addr : std_logic_vector(31 downto 0);
    signal s_Jump_Target_Addr   : std_logic_vector(31 downto 0);
    signal s_Next_PC_Addr_Mux   : std_logic_vector(31 downto 0);
    signal s_PC_Load_Enable   : std_logic;
    signal s_Branch_Decision  : std_logic;

    -- Sinais dos Bancos de Registradores
    signal s_Int_Read_Data_1    : std_logic_vector(31 downto 0);
    signal s_Int_Read_Data_2    : std_logic_vector(31 downto 0);
    signal s_FP_Read_Data_1     : std_logic_vector(31 downto 0);
    signal s_FP_Read_Data_2     : std_logic_vector(31 downto 0);
    signal s_Int_Write_Addr     : std_logic_vector(4 downto 0);
    signal s_FP_Write_Addr      : std_logic_vector(4 downto 0);
    signal s_Write_Back_Data    : std_logic_vector(31 downto 0);

    -- Sinais das ALUs
    signal s_ALU_Input_B        : std_logic_vector(31 downto 0);
    signal s_Int_ALU_Result     : std_logic_vector(31 downto 0);
    signal s_Int_ALU_Zero       : std_logic;
    signal s_FP_ALU_Result      : std_logic_vector(31 downto 0);

    -- Sinais da Memória
    signal s_Memory_Read_Data   : std_logic_vector(31 downto 0);

begin

    -- =========================================================================
    -- 3. LÓGICA DO DATAPATH (MUXes, Extensores de Sinal, etc.)
    -- =========================================================================

    -- --- Lógica de Decodificação e Extensão de Sinal ---
    
    -- Extensor de sinal de 16-bits (imediato) para 32-bits
    s_Extended_Immediate <= std_logic_vector(resize(signed(s_Instruction(15 downto 0)), 32));
    
    -- Caminho de dados para 'lui' (imediato << 16)
    s_LUI_Data <= s_Instruction(15 downto 0) & x"0000";
    
    -- MUX de seleção do registrador de escrita (RegDst)
    s_Int_Write_Addr <= s_Instruction(20 downto 16) when s_RegDst = '0' else s_Instruction(15 downto 11);
    s_FP_Write_Addr  <= s_Instruction(20 downto 16) when s_RegDst = '0' else s_Instruction(15 downto 11);

    -- --- Lógica da ALU de Inteiros ---
    
    -- MUX de seleção da 2ª entrada da ALU de inteiros (ALUSrc)
    s_ALU_Input_B <= s_Int_Read_Data_2 when s_ALUSrc = '0' else s_Extended_Immediate;
    
    -- --- Lógica de "Write Back" (Resultado Final) ---

    -- MUX de seleção do dado que será escrito de volta no registrador
    with s_WriteBack_Sel select
        s_Write_Back_Data <= s_Int_ALU_Result    when "00", -- Resultado da ALU Inteiros
                             s_Memory_Read_Data  when "01", -- Dado da Memória (lw ou l.s)
                             s_FP_ALU_Result     when "10", -- Resultado da ALU Ponto Flutuante
                             s_LUI_Data          when "11", -- Dado do LUI
                             (others => 'X')     when others;
                             
    -- --- Lógica de Atualização do PC (Desvios) ---
    
    -- Calcula PC + 4
    s_PC_Plus_4 <= std_logic_vector(signed(s_PC_Addr) + 4);
    
    -- Calcula o endereço de desvio (Branch Target)
    s_Branch_Target_Addr <= std_logic_vector(signed(s_PC_Plus_4) + signed(s_Extended_Immediate(29 downto 0) & "00"));
    
    -- Calcula o endereço de pulo (Jump Target)
    s_Jump_Target_Addr <= s_PC_Plus_4(31 downto 28) & s_Instruction(25 downto 0) & "00";
    
    -- MUX que escolhe o endereço de desvio (Branch ou Jump)
    s_Next_PC_Addr_Mux <= s_Jump_Target_Addr when s_Jump = '1' else s_Branch_Target_Addr;
    
    -- Lógica de decisão de desvio (Branch)
    -- '0' (beq): desvia se Zero=1
    -- '1' (bne): desvia se Zero=0
    s_Branch_Decision <= (s_Int_ALU_Zero and (not s_Branch_Cond)) or ((not s_Int_ALU_Zero) and s_Branch_Cond);
    
    -- Habilita o carregamento do PC (PC_Sel) se for Branch E a decisão for '1', OU se for Jump
    s_PC_Load_Enable <= (s_Branch and s_Branch_Decision) or s_Jump;

    -- =========================================================================
    -- 4. INSTÂNCIA DOS COMPONENTES (Conectando os fios)
    -- =========================================================================

    -- --- Estágio 1: IF (Instruction Fetch) ---
    
    u_PC: Program_Counter
        port map (
            Clk         => Clk,
            Rst         => Rst,
            Branch_Addr => s_Next_PC_Addr_Mux,
            PC_Sel      => s_PC_Load_Enable,
            PC_Out      => s_PC_Addr
        );

    u_IMem: Instruction_Memory
        port map (
            Address     => s_PC_Addr,
            Instruction => s_Instruction
        );
        
    -- --- Estágio 2: ID (Instruction Decode & Register Fetch) ---
    
    u_Ctrl: Control_Unit
        port map (
            Opcode        => s_Instruction(31 downto 26),
            Funct         => s_Instruction(5 downto 0),
            RegWrite      => s_RegWrite,
            FP_RegWrite   => s_FP_RegWrite,
            RegDst        => s_RegDst,
            Branch        => s_Branch,
            Branch_Cond   => s_Branch_Cond,
            Jump          => s_Jump,
            MemWrite      => s_MemWrite,
            MemRead       => s_MemRead,
            ALUSrc        => s_ALUSrc,
            ALU_Sel       => s_ALU_Sel,
            FP_Op_Sel     => s_FP_Op_Sel,
            WriteBack_Sel => s_WriteBack_Sel
        );

    -- Instância do seu 'register_file'
    u_Int_Reg_File: register_file
        port map (
            Clock     => Clk,
            RegWrite  => s_RegWrite,
            ReadReg1  => s_Instruction(25 downto 21), -- rs
            ReadReg2  => s_Instruction(20 downto 16), -- rt
            ReadData1 => s_Int_Read_Data_1,
            ReadData2 => s_Int_Read_Data_2,
            WriteReg  => s_Int_Write_Addr,
            WriteData => s_Write_Back_Data
        );
        
    u_FP_Reg_File: FP_Register_File
        port map (
            Clk          => Clk,
            Rst          => Rst,
            Write_Enable => s_FP_RegWrite,
            Read_Addr_1  => s_Instruction(25 downto 21), -- fs
            Read_Addr_2  => s_Instruction(20 downto 16), -- ft
            Data_Out_1   => s_FP_Read_Data_1,
            Data_Out_2   => s_FP_Read_Data_2,
            Write_Addr   => s_FP_Write_Addr,
            Data_In      => s_Write_Back_Data
        );

    -- --- Estágio 3: EX (Execute) ---
    
    u_Int_ALU: Integer_ALU
        port map (
            A       => s_Int_Read_Data_1,
            B       => s_ALU_Input_B,
            ALU_Sel => s_ALU_Sel,
            R       => s_Int_ALU_Result,
            Zero    => s_Int_ALU_Zero
        );

    u_FP_ALU: FP_ALU_Wrapper
        port map (
            X_in    => s_FP_Read_Data_1,
            Y_in    => s_FP_Read_Data_2,
            Op_sel  => s_FP_Op_Sel,
            R_out   => s_FP_ALU_Result
        );

    -- --- Estágio 4: MEM (Memory Access) ---
    
    u_DMem: Data_Memory
        port map (
            Clk         => Clk,
            MemWrite    => s_MemWrite,
            MemRead     => s_MemRead,
            Address     => s_Int_ALU_Result,
            DataIn      => s_Int_Read_Data_2,
            DataOut     => s_Memory_Read_Data
        );

    -- --- Estágio 5: WB (Write Back) ---
    -- (A lógica de Write Back está na Seção 3 e na conexão Data_In)

end architecture Structural;