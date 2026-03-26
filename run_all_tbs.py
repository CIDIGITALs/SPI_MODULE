import os
import subprocess
from pathlib import Path

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    modules_dir = project_root / "modules"

    print("Iniciando a bateria de testes...\n")

    # Itera sobre cada pasta dentro de modules/
    for module_path in modules_dir.iterdir():
        if not module_path.is_dir():
            continue

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

        # Pega todos os arquivos .v do módulo (RTL e TB)
        verilog_files = list(rtl_dir.glob("*.v")) + list(tb_dir.glob("*.v"))
        if not verilog_files:
            print(f"[{module_name}] Nenhum arquivo .v encontrado. Pulando.\n")
            continue

        file_paths = [str(f) for f in verilog_files]
        output_vvp = res_dir / "sim.vvp"
        log_file = res_dir / "sim.log"

        # 1. Compilação
        compile_cmd = ["iverilog", "-o", str(output_vvp)] + file_paths
        try:
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
                subprocess.run(["vvp", "sim.vvp"], cwd=res_dir, stdout=f_out, check=True)
            print(f"[{module_name}] Simulação concluída. Log salvo em: {log_file.relative_to(project_root)}")
        except subprocess.CalledProcessError as e:
            print(f"[{module_name}] ERRO NA SIMULAÇÃO.\n")
            continue
        
        print("-" * 40)

if __name__ == "__main__":
    main()