# Controlador SPI Mestre Multi-Escravo

Projeto de um módulo SPI mestre em Verilog-2001, desenvolvido com suporte a múltiplos escravos, parametrizável e com controle de *chip select*. O design é modular e projetado para suportar transações complexas, desenvolvido como parte das atividades de Circuitos Digitais na FEEC/Unicamp.

## 🚀 Características Principais

* **Comunicação Full-Duplex:** Transmissão simultânea via MOSI e recepção via MISO.
* **Topologias Suportadas:** Implementação compatível com configuração multiponto (vários CS independentes) e *Daisy Chain* (cascata de dados entre dispositivos).
* **Shift Registers:** Transmissão implementada obrigatoriamente utilizando registradores de deslocamento, sem atribuições diretas paralelas.
* **Máquina de Estados de Controle:** Controle sequencial da transação implementando os estados: `IDLE`, `FETCH_CMD`, `CONFIG`, `ASSERT_CS`, `TRANSFER`, `DEASSERT_CS` e `DONE`.
* **Interface de Handshake:** Comunicação assíncrona com o sistema baseada nos sinais `cmd_valid`, `cmd_ready`, `rsp_valid` e `rsp_ready`.

# Controlador SPI Mestre Multi-Escravo

Projeto de um módulo SPI mestre em Verilog-2001, desenvolvido com suporte a múltiplos escravos, parametrizável e com controle de *chip select*. O design é modular e projetado para suportar transações complexas, desenvolvido como parte das atividades de prova do curso CI DIGITAL.

## 🚀 Características Principais

* **Comunicação Full-Duplex:** Transmissão simultânea via MOSI e recepção via MISO.
* **Topologias Suportadas:** Implementação compatível com configuração multiponto (vários CS independentes) e *Daisy Chain* (cascata de dados entre dispositivos).
* **Shift Registers:** Transmissão implementada obrigatoriamente utilizando registradores de deslocamento, sem atribuições diretas paralelas.
* **Máquina de Estados de Controle:** Controle sequencial da transação implementando os estados: `IDLE`, `FETCH_CMD`, `CONFIG`, `ASSERT_CS`, `TRANSFER`, `DEASSERT_CS` e `DONE`.
* **Interface de Handshake:** Comunicação assíncrona com o sistema baseada nos sinais `cmd_valid`, `cmd_ready`, `rsp_valid` e `rsp_ready`.

## 📂 Arquitetura do Repositório

Este projeto utiliza uma abordagem *IP-centric*. Cada submódulo possui seu próprio diretório isolado contendo seu código fonte (RTL), seu respectivo Testbench (TB) e uma pasta dedicada para os logs e formas de onda gerados na simulação:

* `modules/spi_master_system/`: Módulo *top-level* que integra o sistema e gerencia a interface física do protocolo SPI (`sclk`, `mosi`, `miso`, `cs`).
* `modules/spi_fsm/`: Lógica sequencial e máquina de estados para controle temporal das transações.
* `modules/spi_shift_register/`: Instanciação dos registradores para manipulação e deslocamento dos bits de dados.
* `scripts/`: Ferramentas de automação em Python para compilação, testes e geração de boilerplate.
* `docs/`: Relatório do projeto contendo a motivação, descrição da arquitetura, diagrama de blocos e documentação das interfaces.

```text
spi-master-project/
├── docs/
│   └── relatorio_projeto_spi.pdf
├── modules/
│   ├── spi_fsm/
│   │   ├── resultados/       
│   │   ├── rtl/
│   │   │   └── spi_fsm.v
│   │   └── tb/
│   │       └── spi_fsm_tb.v
│   ├── spi_master_system/
│   │   ├── resultados/
│   │   ├── rtl/
│   │   │   └── spi_master_system.v
│   │   └── tb/
│   │       └── spi_master_system_tb.v
│   └── spi_shift_register/
│       ├── resultados/
│       ├── rtl/
│       │   └── spi_shift_register.v
│       └── tb/
│           └── spi_shift_register_tb.v
├── scripts/
│   ├── run_all_tbs.py
│   └── create_new_module.py
├── .gitignore
└── README.md

## 🛠️ Como Compilar e Simular

O projeto conta com um script automatizado que varre a estrutura de diretórios, compila os módulos Verilog e executa a simulação principal.

## Scripts

run_all_tbs.py 
uso : python run_all_tbs.py 
Testa todos os modulos de uma vez e gera os arquivos de log e vcd na respectiva pasta de results

create_new_module.py
uso: python scripts/create_module.py <nome_do_modulo>
Gera a estrutura de pastas de um modulo novo no repositorio com um esqueleto de testbench e module


1. Clone o repositório:
   ```bash
   git clone https://github.com/CIDIGITALs/SPI_MODULE