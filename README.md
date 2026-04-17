# Controlador SPI Mestre Multi-Escravo (IP Core)

Projeto de um módulo SPI Mestre (IP Core) em Verilog-2001, desenvolvido com foco em robustez, modularidade e integração agnóstica de barramento. O design é altamente parametrizável, com suporte a múltiplos escravos.
Desenvolvidos como projeto CI DIGITAL

![Cidigital](images\Logo_Site_CIDigital.png)

## 🚀 Características Principais

* **Comunicação Full-Duplex:** Transmissão simultânea via MOSI e recepção via MISO.
* **Topologias Suportadas:** Implementação nativa e roteamento físico para configuração **Multiponto** (vários CS independentes) e **Daisy Chain** (cascata de dados contínua entre dispositivos).
* **Configuração Dinâmica:** Suporte a variação de CPOL, CPHA e divisor de clock (`clk_div`) em tempo de execução para cada nova transação.
* **Arquitetura Agnóstica (Blindagem de Barramento):** Utilização de um registrador estrutural (PIPO) no Top-Level para realizar o *latch* das configurações. O host pode alterar os dados no barramento externo durante uma transação sem corromper o Datapath ou o Gerador de Clock.
* **Separação de Responsabilidades:** A Máquina de Estados (FSM) gerencia o fluxo temporal (`IDLE`, `TRANSFER`, `DEASSERT_CS`, etc.), enquanto um módulo contador dedicado (`spi_counter`) gerencia os bits enviados e recebidos
* **Interface de Handshake:** Comunicação assíncrona com o processador host baseada nos sinais `cmd_valid`, `cmd_ready`, `rsp_valid` e `rsp_ready`, facilitando futura integração com barramentos de sistema como AXI-Lite ou APB.
* **Verificação Automatizada:** Testbench Top-Level com arquitetura *Self-Checking* e scripts Python para automação de build e simulação.

![Arquitetura SPI](images\FSM.png)


## 📂 Arquitetura do Repositório

Este projeto utiliza uma abordagem *IP-centric*. Cada submódulo possui seu próprio diretório isolado contendo seu código fonte (RTL), seu respectivo Testbench (TB) e uma pasta dedicada para os logs e formas de onda (`.vcd`):

* `modules/spi_master_system/`: Módulo *top-level* que integra o sistema e gerencia a interface física.
* `modules/spi_fsm/`: Máquina de estados para controle temporal das transações.
* `modules/spi_clk_gen/`: Gerador de clock da SPI com divisores configuráveis e gerador de bordas (Lead/Trail/Sample/Shift).
* `modules/spi_shift_register/`: Registrador universal PISO/SIPO para serialização de dados.
* `modules/spi_counter/`: Contador regressivo para controle exato de bits transmitidos.
* `modules/spi_decoder/`: Roteador combinatório avançado para gerenciamento dos pinos de Chip Select e caminhos MISO baseados na topologia.
* `modules/spi_config_register/`: Registrador de blindagem para guardar CPOL CPHA e CLK_DIV vindos da barramento principal.
* `scripts/`: Ferramentas de automação em Python.
* `docs/`: Relatório contendo motivação, diagrama de blocos e documentação das interfaces.

### Estrutura de Diretórios
```text
spi-master-project/
├── docs/
│   └── relatorio_projeto_spi.pdf
├── modules/
│   ├── spi_clk/
│   ├── spi_counter/
│   ├── spi_decoder/
│   ├── spi_fsm/
│   ├── spi_master_system/
│   └── spi_shift_register/
│       ├── resultados/       # Logs (.log) e Ondas (.vcd) gerados automaticamente
│       ├── rtl/              # Código fonte Verilog (.v)
│       └── tb/               # Testbenches (.v)
├── scripts/
│   ├── run_all_tbs.py
│   └── create_module.py
├── .gitignore
└── README.md

## 🛠️ Como Compilar e Simular

O projeto conta com um script automatizado que varre a estrutura de diretórios, compila os módulos Verilog e executa a simulação principal.

## Scripts

run_all_tbs.py 
uso : python scripts/run_all_tbs.py 
Testa todos os modulos de uma vez e gera os arquivos de log e vcd na respectiva pasta de results

create_new_module.py
uso: python scripts/create_module.py <nome_do_modulo>
Gera a estrutura de pastas de um modulo novo no repositorio com um esqueleto de testbench e module


1. Clone o repositório:
   ```bash
   git clone https://github.com/CIDIGITALs/SPI_MODULE