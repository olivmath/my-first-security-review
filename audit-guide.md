# Guia de Auditoria de Smart Contract — Primeira Auditoria

> Este guia te conduz pelo processo sem fazer o trabalho por você.
> Cada seção tem: o que é, por que importa, como fazer, e o que anotar.

---

## Mentalidade Antes de Começar

Auditoria não é "rodar ferramentas e ver o que aparece". É **entender o sistema melhor do que o desenvolvedor que o escreveu** — e então tentar quebrá-lo.

Duas perguntas que devem estar sempre na sua cabeça:

1. **"O que este código tenta fazer?"** (intenção)
2. **"O que este código realmente faz?"** (realidade)

A vulnerabilidade vive no gap entre as duas.

---

## Passo 1 — Onboarding

**O que é:** Coletar todas as informações sobre o protocolo antes de ver uma linha de código.

**Por que importa:** Você precisa saber o que o contrato *deveria* fazer para identificar quando ele faz algo diferente.

**Como fazer:**
- Preencha o `onboarding.md` completamente
- Identifique: qual o problema de negócio que o contrato resolve?
- Liste todos os **actors** (quem interage com o contrato) e seus **poderes**
- Anote os **Known Issues** — vulnerabilidades que o time já sabe e aceita

**O que anotar:**
```
- Qual é o fluxo principal de dinheiro? (de quem → para quem → quando)
- Quais são as precondições para cada função?
- O owner tem poderes demais? (centralização)
```

**Sinal de que terminou:** Você consegue explicar o protocolo em 3 frases sem olhar o código.

---

## Passo 2 — Scoping Stats

**O que é:** Medir o tamanho e complexidade do código antes de entrar nele.

**Por que importa:** Define quanto tempo você vai precisar. Auditores experientes usam métricas para precificar e planejar.

**Como fazer:**
```bash
# Instalar solidity-metrics (se não tiver)
npm install -g solidity-code-metrics

# Rodar
solidity-code-metrics src/**/*.sol

# Alternativa simples
cloc src/
```

**O que anotar:**
- **nSLOC** (non-comment lines of code) — indica tamanho real
- **Complexity Score** — funções com score alto são onde bugs se escondem
- **Número de contratos externos chamados** — superfície de ataque externa

**Regra prática:**
- < 200 nSLOC → 1-2 dias de revisão
- 200-500 nSLOC → 3-5 dias
- 500+ nSLOC → semana+

---

## Passo 3 — Reconnaissance

Esta fase tem **três partes** que devem ser feitas nesta ordem.

### 3a. Leitura e Mapeamento Manual

**O que é:** Ler o código como documentação, sem procurar bugs ainda.

**Por que importa:** Se você pular para "achar bugs" antes de entender, você vai encontrar bugs superficiais e perder os profundos.

**Como fazer:**
1. Leia cada contrato de cima para baixo, uma vez, sem parar
2. Para cada função, anote em comentário: *o que ela faz*
3. Desenhe o fluxo de estado (quais variáveis mudam em cada função)
4. Mapeie o fluxo de ETH/tokens (entra onde, sai onde)

**Perguntas para cada função:**
```
- Quem pode chamar esta função? (access control)
- Quais são os inputs? Podem ser manipulados?
- O que muda no estado do contrato?
- O que é enviado para fora? (ETH, tokens, calls externas)
- Em que ordem as coisas acontecem?
```

### 3b. Cobertura de Testes

**O que é:** Ver quais linhas de código os testes existentes não cobrem.

**Por que importa:** Linhas sem cobertura = casos que o dev não pensou = onde bugs vivem.

**Como fazer:**
```bash
forge test -vv          # ver se todos os testes passam
forge coverage          # ver % de cobertura por contrato
```

**O que anotar:**
- Quais funções têm 0% de cobertura?
- Quais branches (if/else) não são testados?
- Os testes testam casos de erro (reverts)?

### 3c. Análise Estática Automatizada

**O que é:** Ferramentas que analisam o código sem executá-lo e reportam padrões conhecidos.

**Por que importa:** Pega 20-30% das vulnerabilidades comuns em segundos. Libera seu tempo mental para os bugs complexos.

**Slither:**
```bash
# Instalar
pip install slither-analyzer

# Rodar
slither src/

# Focar em severidade alta
slither src/ --filter-paths "lib/" --exclude-informational
```

**Aderyn:**
```bash
# Instalar
cargo install aderyn

# Rodar
aderyn src/
```

**Como interpretar:**
- Leia cada finding — não aceite cegamente
- Classifique: real vulnerability ou false positive?
- Anote os false positives com justificativa (vira parte do report)

---

## Passo 4 — Vulnerability Identification

**O que é:** A revisão manual linha por linha com olhos de atacante.

**Por que importa:** Ferramentas não entendem lógica de negócio. O bug mais caro quase sempre está na lógica, não na sintaxe.

### Checklist das Vulnerabilidades Mais Comuns

Vá função por função e pergunte cada item desta lista:

**Controle de Acesso**
- [ ] Funções privilegiadas têm o modifier correto?
- [ ] Existe função que deveria ter `onlyOwner` mas não tem?
- [ ] O `owner` pode fazer coisas que não deveria? (rug pull)

**Reentrancy**
- [ ] O padrão CEI (Checks-Effects-Interactions) é seguido?
  - Checks: validações primeiro
  - Effects: mudanças de estado no meio
  - Interactions: chamadas externas por último
- [ ] Existe algum `call{value}()` antes de atualizar o estado?

**Arithmetic**
- [ ] Existe divisão que pode resultar em 0 inesperadamente?
- [ ] Existe overflow possível? (Solidity 0.8+ protege, mas `unchecked` não)
- [ ] Operações com tokens de 6 decimais (USDC) vs 18 decimais?

**Lógica de Negócio**
- [ ] O cálculo de preço/quantidade está correto?
- [ ] Existe alguma condição de corrida (front-running)?
- [ ] Um usuário pode manipular uma variável para benefício próprio?
- [ ] Existe alguma função que pode ser chamada na ordem errada?

**Estado**
- [ ] Todas as variáveis são inicializadas corretamente?
- [ ] Existe estado que pode ficar "preso" (stuck)?
- [ ] O contrato pode ficar sem ETH mas com dívidas?

**Calls Externas**
- [ ] O retorno de calls externas é verificado?
- [ ] O contrato assume que outra chamada vai ter sucesso?

### Como Anotar os Findings

Durante a revisão, use este formato para cada suspeita:

```
[TITULO]
Localização: arquivo.sol:linha
Tipo: Reentrancy / Access Control / Logic / ...
Descrição: O que está errado
Impacto: O que um atacante consegue fazer
Severidade (suspeita): Critical / High / Medium / Low / Info
```

Não descarte nada ainda. Confirma com PoC depois.

---

## Passo 5 — Fuzzing e Invariant Testing

**O que é:** Testar o contrato com entradas aleatórias e verificar propriedades que *sempre* devem ser verdadeiras.

**Por que importa:** Encontra bugs que revisão manual não vê — especialmente em interações complexas entre funções.

### Invariantes: o que definir

Um **invariante** é uma propriedade que nunca deve ser violada, independente do que aconteça.

Exemplos para um TokenSale:
```
- O contrato nunca deve dever mais ETH do que tem em balance
- Total de tokens emitidos nunca deve exceder o supply máximo
- Um usuário sem whitelist nunca deve conseguir tokens
```

### Como escrever em Foundry

```solidity
// test/invariant/TokenSaleInvariant.t.sol
contract TokenSaleInvariant is Test {
    TokenSale sale;

    function setUp() public {
        sale = new TokenSale(...);
        targetContract(address(sale));
    }

    // Esta função é chamada após cada sequência de chamadas aleatórias
    function invariant_solvency() public {
        // O contrato deve sempre ter ETH suficiente para cobrir reembolsos
        uint256 ethOwed = sale.totalTokens() * sale.tokenPrice();
        assertGe(address(sale).balance, ethOwed);
    }
}
```

```bash
forge test --match-contract Invariant -vv
```

---

## Passo 6 — Proof of Concepts

**O que é:** Escrever um teste em Foundry que *demonstra* a vulnerabilidade sendo explorada.

**Por que importa:**
1. Confirma que o finding é real (não falso positivo)
2. Quantifica o impacto exato
3. É obrigatório em qualquer report sério

### Como escrever um PoC

```solidity
function test_poc_reentrancy() public {
    // 1. Setup: estado inicial que permite o ataque
    // 2. Attack: executar o exploit
    // 3. Assert: mostrar o dano causado

    // Exemplo:
    uint256 balanceBefore = address(attacker).balance;
    attacker.attack{value: 1 ether}();
    uint256 balanceAfter = address(attacker).balance;

    assertGt(balanceAfter, balanceBefore, "Attacker drained the contract");
}
```

### Classificação de Severidade

| Severidade | Critério |
|------------|----------|
| **Critical** | Perda direta de fundos, qualquer usuário, sem restrição |
| **High** | Perda de fundos com alguma condição, ou quebra total do protocolo |
| **Medium** | Comportamento incorreto, sem perda de fundos mas com impacto significativo |
| **Low** | Impacto pequeno, edge cases improváveis |
| **Informational** | Código ruim mas sem risco de segurança imediato |
| **Gas** | Otimizações de gas |

**Fatores que aumentam severidade:**
- Funds at risk
- Sem precondições especiais (qualquer atacante)
- Sem interação prévia necessária

**Fatores que diminuem severidade:**
- Requer permissão especial para explorar
- Impacto limitado a um único usuário
- Já listado como Known Issue

---

## Passo 7 — Report

**O que é:** Documento formal entregue ao protocolo.

**Estrutura padrão:**

```markdown
# Security Review Report — [Nome do Protocolo]

## Executive Summary
[2-3 parágrafos: o que foi auditado, resumo dos findings, recomendação geral]

## Scope
- Commit: [hash]
- Contracts: [lista]
- Período: [datas]

## Summary of Findings

| ID | Título | Severidade | Status |
|----|--------|------------|--------|
| C-01 | Reentrancy em refund() | Critical | Open |
| H-01 | ... | High | Open |

## Detailed Findings

### [C-01] Título da Vulnerabilidade

**Severity:** Critical
**Location:** `src/Contract.sol:L42`

**Description:**
[Explicação clara do problema]

**Impact:**
[O que um atacante consegue fazer, com números se possível]

**Proof of Concept:**
[Cole o teste Foundry aqui]

**Recommendation:**
[Como corrigir]

---

## Known Issues Acknowledged
[Lista o que foi reportado pelo time e não será corrigido]
```

---

## Dicas de Processo

**Sobre o tempo:**
- Divida sua sessão em blocos de 90 min com pausa de 15 min
- Nos primeiros 90 min: só leitura, sem anotar bugs
- A partir daí: análise ativa com anotações

**Sobre o mindset:**
- Pense como um atacante, não como um desenvolvedor
- "Isso *pode* dar errado?" é mais útil que "Isso está *errado*?"
- Se uma função parece estranha, investigue — instinto importa

**Sobre ferramentas:**
- Ferramentas são seu primeiro filtro, não sua conclusão
- Um finding de ferramenta sem PoC não é um finding

**Sobre o report:**
- Escreva para alguém que não conhece o código
- Cada finding deve ser compreensível isoladamente
- Seja específico: "linha 42" é melhor que "no contrato"

**Red flags clássicos no código:**
```solidity
call{value: x}()          // call ETH sem verificar retorno
tx.origin                 // nunca use para auth
block.timestamp           // manipulável em ~15 segundos
delegatecall              // extremamente perigoso
assembly                  // requer atenção redobrada
selfdestruct              // pode destruir o contrato
```

---

## Recursos

- [Solidity Docs — Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [SWC Registry](https://swcregistry.io/) — catálogo de vulnerabilidades
- [Cyfrin Updraft](https://updraft.cyfrin.io/) — curso gratuito de auditoria
- [Solodit](https://solodit.xyz/) — banco de findings reais de auditorias
- [Code4rena Reports](https://code4rena.com/reports) — reports públicos para estudar
