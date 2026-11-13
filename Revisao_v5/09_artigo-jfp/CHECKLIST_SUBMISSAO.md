# Checklist de submissão ao JFP — o que falta antes de enviar

O manuscrito (`artigo/main.tex`, 12 páginas na classe `jfp-epi` v1.2, modo `review`) está **formatado**, mas **não está pronto
para submissão**: faltam itens que só o autor ou a orientação podem resolver. Cada linha abaixo é bloqueante, salvo onde dito.

## Bloqueantes (ação do autor)

| # | Item | Por quê | Onde no manuscrito |
|---|---|---|---|
| 1 | **ORCID** de todos os autores | o guia da classe diz "required for all authors on JFP submissions" | `main.tex`, bloco `\author` (comentário `TODO`) |
| 2 | **E-mail** (`\authoremail`) | exigido pela classe; deixado como "[e-mail to be added]" por privacidade | `\affiliation` |
| 3 | **Decidir a coautoria** da orientação (Prof. Felipe Canarozzo Lourenço) | o v4 só diz "Orientação"; coautoria é decisão das pessoas | `\author` |
| 4 | **Revisão da tabela e das políticas pela orientação** | o artigo declara que isso está pendente; sem a revisão, o oráculo é do mesmo autor do código | Sect. 5.1, 7.3 |
| 5 | **Repositório público + DOI** (Zenodo, por exemplo) | o JFP incentiva material suplementar aberto e pede o artigo em arXiv/HAL/Zenodo; o repositório era privado | "Data availability statement" |
| 6 | **Declaração de IA**: o autor preenche o grau de revisão e confere a política da revista e da Fatec | o texto foi escrito com IA; a política do JFP **não foi encontrada** nas páginas lidas | "Declaration of generative AI use" |
| 7 | **Fomento e conflito de interesses** | placeholders | "Funding and competing interests" |
| 8 | **Relatar na carta ao editor** que o trabalho não está em revisão em outro lugar e declarar trabalhos relacionados | exigência de originalidade; o artigo 1 (C/C++) é um trabalho relacionado do mesmo projeto | carta de apresentação |

## Sobreposição com o manuscrito do SCP (`10_artigo-scp/`)

Os dois manuscritos compartilham a matriz de 16 pares do `crem`, a tabela da função de transição e a mutação da implementação em `crem`
(os mesmos 9 mutantes aqui e no SCP, onde vem resumida). Decidir **antes de enviar qualquer um**: enviar um primeiro e citá-lo, reduzir a Seção 4 deste
manuscrito, ou declarar a sobreposição na carta ao editor de cada um. Ver `10_artigo-scp/CHECKLIST_SUBMISSAO.md`.

## Fortemente recomendados (afetam a aceitação)

| # | Item | Situação |
|---|---|---|
| 9 | **Busca de literatura executada** (`07_estado-da-arte/PROTOCOLO_REVISAO.md`) e a seção "Related work" reescrita | hoje a seção diz, com franqueza, que **não** é uma revisão sistemática |
| 10 | **Outras topologias e escalas** | uma só topologia de 4 vértices; o artigo declara o limite |
| 11 | **Segundo revisor** da especificação (ou da tabela) | independência de autoria não existe |
| 12 | Conferir os dados bibliográficos de `refs.bib` (Strom e Yemini; Claessen e Hughes; Atkey; Brady; Eisenberg e Weirich) nas fontes | citados de memória; as entradas de software (Hedgehog, Motor, TLA+) não têm data |
| 13 | Revisão de linguagem (inglês) por falante fluente | texto escrito com IA, sem revisão de língua |
| 14 | Ler no site a **política de IA, de resumo e de ética** do Episciences/JFP | não constam nas páginas lidas |

## Passos de submissão (segundo o guia do JFP)

1. Compilar **sem** `review` (`\documentclass{jfp-epi}`) e publicar o PDF no **arXiv, HAL ou Zenodo**; anotar o ID e a versão.
   (O arXiv não aceita linhas numeradas.)
2. Compilar **com** `review` (versão com linhas numeradas, já é o `main.pdf`).
3. Criar a submissão no Episciences/JFP com o ID e a versão; anexar o PDF com linhas numeradas no campo "Cover Letter"
   (junto da carta, em um só PDF, se houver).
4. Após o aceite: enviar o PDF **e** o diretório `artigo/` com todos os fontes (`main.tex`, `refs.bib`, `jfp-epi.cls`, `.bbl` e figuras).

## Conferências automáticas já feitas

| Verificação | Resultado |
|---|---|
| compila (pdflatex + bibtex + 2 passadas) | **sim**, 12 páginas, sem referência indefinida e sem *overfull box* |
| classe `jfp-epi` v1.2 com `[review]` | **sim** (linhas numeradas, "DRAFT PAPER UNDER REVIEW", CC-BY 4.0) |
| títulos em *sentence case* | **sim** (conferido nas 29 seções e subseções) |
| sem palavras-chave e sem classificação ACM | **sim** |
| estilo de bibliografia `ACM-Reference-Format` | **sim** |
| números do artigo conferidos com os logs de `08_reprodutibilidade/` | **sim** (26/48 ternos; 520 arestas; 9 mutantes; 1 143 estados no TLC; etc.) |
| marcadores `[...]` em negrito no texto | **4 lugares** (e-mail, URL/DOI, declaração de IA, fomento) e 1 comentário `TODO` no fonte (ORCID); nada foi inventado |

## O que o artigo **não** afirma

Novo sistema de tipos, nova semântica formal, prova geral da composição, ineditismo, segurança de voo real, ou que o defeito
da bateria seja do `crem` ou do GHC.
