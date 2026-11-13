# Ferramentas do parecer: o que foi adotado, o que não foi e por quê

O parecer de 03/11/2026 (seção 3) lista recursos públicos com "propósitos diferentes" e pede que versão,
licença e compatibilidade sejam confirmadas antes da adoção. Esta tabela registra o que **de fato** foi
feito nesta revisão. Onde nada foi testado, está escrito.

| Recurso | Papel no parecer | Adotado? | O que foi feito / por que não |
|---|---|---|---|
| CREM | exemplos e testes da biblioteca original; regressão | já era a base | `crem` 0.1.0.0 (já no projeto). Não foram lidos nem reproduzidos os testes do diretório de testes do repositório do CREM: **pendente**. Não é oráculo independente da biblioteca. |
| Motor | biblioteca alternativa de FSMs tipadas | **não** | Não instalado nem testado; só consta como candidato em `PROTOCOLO_REVISAO.md`. Comparar uma topologia equivalente fica para a revisão da literatura. |
| QuickCheck State Machine | geração de comandos e testes por modelo | **não** | Não testado. Exigiria um modelo com referências simbólicas que esta FSM pura não precisa; dependências e compatibilidade com GHC 9.6.7 não foram verificadas. |
| Hedgehog | testes por propriedades, geradores, shrinking | **sim** | `hedgehog` 1.7 resolveu com GHC 9.6.7 e foi compilado (cerca de 30 pacotes baixados do Hackage pelo cabal). Usado **sem** a API de máquinas de estado do Hedgehog: a propriedade é "para toda lista de ticks, o traço do CREM coincide com o do oráculo". |
| TLA+ / TLC | invariantes e propriedades temporais do modelo finito | **sim** | Especificação escrita e **executada** (`04_tla/`): TLA+ Tools v1.7.4 (release estável, TLC 2.19, Java 8, jar de 2 274 532 bytes, sha256 `936a2620...0e88`, baixado de github.com/tlaplus/tlaplus; a prerelease v1.8.0 não foi usada). O equivalente em Haskell (`Validation.Reach`) coincide. O TLC verifica o modelo, não a implementação. |
| PX4 Autopilot | segundo caso de estudo com requisitos reais | **não** | Não houve extração de requisitos. O parecer avisa que não é oráculo direto da FSM simplificada. |

## Por que Hedgehog e não QuickCheck State Machine

1. **Dependências:** a árvore do Hedgehog resolveu e compilou sem intervenção. Para o QSM isso não foi tentado.
2. **Natureza do sistema:** a FSM é uma máquina de Mealy pura. O valor do QSM (comandos com referências
   simbólicas e pós-condições sobre estado opaco) é pequeno aqui; a propriedade por lista de eventos basta.
3. **Reprodutibilidade:** cada falha do Hedgehog imprime a semente (`recheckAt (Seed ...) ...`); os relatórios
   de falha dos mutantes estão em `08_reprodutibilidade/logs/03_model_hedgehog.txt`.
4. **Limite aceito:** o shrinking do Hedgehog encontra um mínimo **local**. No mutante de política (CREM contra
   `Level`) reduziu a 7 ticks; o mínimo global, obtido por busca em largura, tem 4
   (`DRAIN, DRAIN, TAKEOFF, IDLE`). Registrar essa diferença evita atribuir ao shrinking o que ele não garante.

## O que o parecer chama de "oráculo independente" e o que aqui se tem

| Artefato | Independente de quê | Escrito por | Revisado por |
|---|---|---|---|
| `spec/transition_table.csv` e `power_table.csv` | do código Haskell (derivado do texto dos requisitos) | o mesmo pesquisador | **ninguém ainda** (pendente da orientação) |
| `Validation.RefModel` | do CREM e da FSM ingênua (lê as tabelas) | o mesmo pesquisador | idem |
| `04_tla/AvionicsLoop.tla` | do código Haskell | o mesmo pesquisador | idem |
| oráculo de terceiros | — | — | **não existe** |

A independência obtida é de **código**, não de **autoria**: um erro de interpretação dos requisitos pode estar
nas três representações ao mesmo tempo. Só a revisão da orientação (ou de uma segunda pessoa) fecha essa lacuna.
