### No momento já esta comunicando, recebendo requisições, mas ainda não esta tratando. Projeto em desenvolvimento, a idéia é finalizar até primeiro semestre de 2026.

# 🧠 SocketBareMetal

Escopo e objetivos do projeto.

Servidor HTTP minimalista e de alto desempenho, desenvolvido em **Delphi** com foco em **baixo nível**, **multiplataforma (Windows/Linux)** e **controle total sobre threads e conexões**.

---

## 🚀 Visão Geral

O `SocketBareMetal` é um servidor HTTP construído do zero, sem dependência de frameworks externos, utilizando diretamente APIs de socket e gerenciamento de threads. Ideal para aplicações que exigem:

- Alta performance
- Baixo consumo de recursos
- Controle fino sobre conexões e paralelismo

---

## 🧩 Principais Funcionalidades

- 🔌 Gerenciador de conexões TCP com abstração multiplataforma
- 🧵 ThreadPool escalável com monitoramento automático
- 📦 Parser HTTP com validação de headers e payloads
- 🛡️ Segurança básica contra requisições malformadas e ataques simples
- 🧭 Compatível com **Windows (WinSock)** e **Linux (POSIX sockets)**

---

## 🧱 Arquitetura Modular

Organizado em módulos com prefixo `SBM`:

| Módulo         | Responsabilidade Principal                     |
|----------------|------------------------------------------------|
| Listener       | Escutar conexões TCP                          |
| Connection     | Gerenciar conexões ativas                     |
| ThreadPool     | Processamento paralelo                        |
| Parser         | Interpretação de requisições HTTP             |
| Response       | Montagem e envio de respostas                 |
| Security       | Validação de headers e proteção básica        |
| Config         | Definições globais do projeto                 |

---


