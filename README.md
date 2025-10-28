# 🧠 SocketBareMetal

Escopo e objetivos do projeto.

Servidor HTTP minimalista e de alto desempenho, desenvolvido em **Delphi** com foco em **baixo nível**, **multiplataforma (Windows/Linux)** e **controle total sobre threads e conexões**.

---

## 🧑‍💻 Situação do Desenvolvimento
- Recebendo requisições e tratando
- Ainda o retorno esta fixo sempre código 200 independente do tratamento
- Camada mínima de segurança
- Sistema de rotas básico
- Compativel somente VCL Windows
> ⚠️ **Atenção:** Projeto em desenvolvimento, a idéia é finalizar até primeiro semestre de 2026.

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

| Módulo                    | Responsabilidade Principal                    |
|---------------------------|-----------------------------------------------|
| Connection                | Gerenciar conexões ativas                     |
| Exception                 | Centralizar exceções HTTP                     |
| Listener                  | Escutar conexões TCP                          |
| Routes                    | Permite a criação de rotas                    |
| Security.RequestValidator | Validação de headers e proteção básica        |
| ThreadPool                | Processamento paralelo                        |
| ThreadPoolManager         | Gerenciar a fila e trabalhadores              |

---

## 📁 Estrutura do Projeto

- `src/`: Contém os arquivos fontes do componente.
- `testes/WindowsVCL`: Aplicação exemplo funcionando com o que já foi desenvolvido.

> ⚠️ **Atenção:** Compativel somente com versões do Delphi superior ou igual a 10.1. Apesar de não estar usando componentes de terceiros, o uso de TObjectList, TDictionary e TTaks impossibilita uso em versões antigas, a não ser que fosse adaptado com soluções lá presentes. 

---

