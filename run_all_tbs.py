import os
import subprocess
from pathlib import Path

def main():
    script_dir = Path(__file__).parent
    project_root = Path(__file__).parent
    modules_dir = project_root / "modules"

    print("Iniciando a bateria de testes...\n")

    # Faz uma varredura (rglob) e coleta TODOS os arquivos .v presentes 
    # dentro de QUALQUER pasta 'rtl' do projeto inteiro.
    global_rtl_files = list(modules_dir.rglob("rtl/*.v"))
    
    if not global_rtl_files:
        print("[AVISO] Nenhum arquivo RTL encontrado no projeto.")

    # Itera sobre cada pasta dentro de modules/
    # Descobre cada módulo presente na pasta
    for module_path in modules_dir.iterdir():
        if not module_path.is_dir():
            continue

        # Extrai o nome do módulo e define os caminhos para rtl, tb e resultados
        module_name = module_path.name
        rtl_dir = module_path / "rtl"
        tb_dir = module_path / "tb"
        res_dir = module_path / "resultados"

        # Pula se não tiver as pastas rtl e tb
        if not rtl_dir.exists() or not tb_dir.exists():
            continue

        print(f"[{module_name}] Preparando simulação...")
        
        # Cria a pasta resultados se não existir
        res_dir.mkdir(exist_ok=True)

        # Pega APENAS os arquivos .v do Testbench (TB) Deste módulo específico
        tb_files = list(tb_dir.glob("*.v"))
        if not tb_files:
            print(f"[{module_name}] Nenhum arquivo Testbench (.v) encontrado. Pulando.\n")
            continue

        # Combina TODOS os RTLs do projeto com o TB específico deste módulo
        files_to_compile = global_rtl_files + tb_files

        # Converte os caminhos dos arquivos para strings e define os caminhos de saída
        file_paths = [str(f) for f in files_to_compile]
        # O arquivo de saída do compilador e o log da simulação serão salvos dentro da pasta resultados/
        output_vvp = res_dir / "sim.vvp"
        log_file = res_dir / "sim.log"

        #Compilação
        compile_cmd = ["iverilog", "-o", str(output_vvp)] + file_paths
        
        # Compila TODOS os modulos RTL e o testbench atual e cospe o resultado em sim.vvp dentro da pasta resultados/ do módulo. O comando é algo como:
        # EX: iverilog -o modules/VrDlatch/resultados/sim.vvp modules/VrDlatch/rtl/*.v modules/spi_fsm/rtl/*.v modules/VrDlatch/tb/*.v
        try:
            # compila de fato
            subprocess.run(compile_cmd, check=True, capture_output=True, text=True)
            print(f"[{module_name}] Compilado com sucesso.")
        except subprocess.CalledProcessError as e:
            print(f"[{module_name}] ERRO DE COMPILAÇÃO:\n{e.stderr}\n")
            continue

        # 2. Execução (mudando o diretório de trabalho para 'resultados')
        try:
            # Ao rodar com cwd=res_dir, qualquer arquivo gerado pelo TB (como .vcd)
            # será salvo automaticamente dentro da pasta resultados/
            with open(log_file, "w") as f_out:
                # Executa a simulação usando o vvp, redirecionando a saída para o log_file.
                # O codigo do TB deve conter as chamadas para gerar os arquivos de saída (como .vcd).
                # Como a execução do codigo compilado (sim.vvp) é feita com o diretório de trabalho sendo 'resultados', 
                # os arquivos gerados pelo TB serão salvos diretamente dentro da pasta resultados/ do módulo.
                subprocess.run(["vvp", "sim.vvp"], cwd=res_dir, stdout=f_out, check=True)
            print(f"[{module_name}] Simulação concluída. Log salvo em: {log_file.relative_to(project_root)}")
        except subprocess.CalledProcessError as e:
            print(f"[{module_name}] ERRO NA SIMULAÇÃO.\n")
            continue
        
        print("-" * 40)

if __name__ == "__main__":
    main()