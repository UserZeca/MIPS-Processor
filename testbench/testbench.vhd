library ieee;
use ieee.std_logic_1164.all;

entity tb_MIPS_Pipeline is
end entity tb_MIPS_Pipeline;

architecture test of tb_MIPS_Pipeline is

    component MIPS_Pipeline_Processor
        port (
            Clk : in  std_logic;
            Rst : in  std_logic
        );
    end component;

    signal s_Clk : std_logic := '0';
    signal s_Rst : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;

begin

    u_Pipeline: MIPS_Pipeline_Processor
        port map ( Clk => s_Clk, Rst => s_Rst );

    -- Gerador de Clock
    clk_proc: process
    begin
        while true loop
            s_Clk <= '0'; wait for CLK_PERIOD / 2;
            s_Clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- =========================================================================
    -- PROCESSO DE "NARRAÇÃO" DO TESTE
    -- =========================================================================
    stim_proc: process
    begin
        -- 1. Reset
        report "--- [0 ns] RESET ---" severity note;
        s_Rst <= '1';
        wait for CLK_PERIOD * 2;
        s_Rst <= '0';
        
        -- O Pipeline começa a encher aqui.
        -- A instrução 1 (LUI $t0) entra no ciclo 1.
        -- Ela levará 5 ciclos para chegar ao WB.
        
        -- =========================================================
        -- Evento 1: Gravação do $t0 (Float 1.0 em Hex)
        -- Instrução: 3c083f80 (lui $t0, 0x3F80)
        -- =========================================================
        -- Esperamos 4 ciclos (1 inst + 3 NOPs) para a instrução atravessar
        wait for CLK_PERIOD * 4; 
        
        report "--- [CHECKPOINT 1] WB: Gravando $t0 ---" severity note;
        -- OLHAR NO WAVEFORM AGORA:
        -- Sinal: u_Pipeline/s_WB_RegWrite deve ser '1'
        -- Sinal: u_Pipeline/s_WB_WriteReg_Addr deve ser 8 ($t0)
        -- Sinal: u_Pipeline/s_WB_WriteData_Final deve ser 3F800000
        wait for CLK_PERIOD; -- Ciclo de escrita efetiva

        -- =========================================================
        -- Evento 2: Gravação do $t1 (Float 2.0 em Hex)
        -- Instrução: 3c094000 (lui $t1, 0x4000)
        -- =========================================================
        -- Mais 4 ciclos (1 inst + 3 NOPs)
        wait for CLK_PERIOD * 3; 
        
        report "--- [CHECKPOINT 2] WB: Gravando $t1 ---" severity note;
        -- OLHAR NO WAVEFORM AGORA:
        -- Sinal: u_Pipeline/s_WB_WriteReg_Addr deve ser 9 ($t1)
        -- Sinal: u_Pipeline/s_WB_WriteData_Final deve ser 40000000
        wait for CLK_PERIOD;

        -- =========================================================
        -- Evento 3: Gravação do Endereço Base $a0
        -- Instrução: 20040014 (addi $a0, $zero, 20)
        -- =========================================================
        wait for CLK_PERIOD * 3;
        
        report "--- [CHECKPOINT 3] WB: Gravando $a0 ---" severity note;
        -- OLHAR NO WAVEFORM AGORA:
        -- Sinal: u_Pipeline/s_WB_WriteReg_Addr deve ser 4 ($a0)
        -- Sinal: u_Pipeline/s_WB_WriteData_Final deve ser 00000014 (20 decimal)
        wait for CLK_PERIOD;

        -- =========================================================
        -- Evento 4: Armazenamento na Memória (SW)
        -- Instruções: ac880000 e ac890004
        -- =========================================================
        -- Aqui não precisamos de tantos NOPs entre eles pois SW não escreve em Reg
        report "--- [CHECKPOINT 4] MEM: Salvando na RAM (SW) ---" severity note;
        -- OLHAR NO WAVEFORM (Estágio MEM):
        -- Sinal: u_Pipeline/s_MEM_MemWrite deve ir para '1' duas vezes seguidas
        -- Sinal: u_Pipeline/s_MEM_WriteData_Mem deve mostrar 3F800000 depois 40000000
        wait for CLK_PERIOD * 2;

        -- =========================================================
        -- Evento 5: Carregamento para FPU (L.S)
        -- Instruções: c4840000 e c4850004
        -- =========================================================
        -- Esperamos passar os loads e seus NOPs
        wait for CLK_PERIOD * 4;
        wait for CLK_PERIOD * 4;

        report "--- [CHECKPOINT 5] WB: FPU Carregada ($f4 e $f5) ---" severity note;
        -- OLHAR NO WAVEFORM (Estágio WB):
        -- Sinal: u_Pipeline/s_WB_FP_RegWrite deve ser '1'
        -- Sinal: u_Pipeline/s_WB_WriteData_Final deve mostrar 3F800000 e 40000000
        
        -- =========================================================
        -- Evento FINAL: Soma de Ponto Flutuante
        -- Instrução: 46052100 (add.s $f4, $f4, $f5)
        -- =========================================================
        -- Esperamos os NOPs finais
        wait for CLK_PERIOD * 4;
        
        report "--- [CHECKPOINT FINAL] Resultado da Soma! ---" severity note;
        -- OLHAR NO WAVEFORM (Estágio EX ou WB):
        -- Sinal: u_Pipeline/s_EX_FP_Result deve ser 40400000 (3.0)
        -- Sinal: u_Pipeline/s_WB_WriteData_Final deve ser 40400000
        
        wait for CLK_PERIOD * 5;
        report "Simulacao da Fase 1 Concluida." severity failure;
        wait;
    end process;

end architecture test;