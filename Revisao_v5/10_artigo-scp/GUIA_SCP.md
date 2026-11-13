# Padrão de publicação do Science of Computer Programming (SCP) — o que foi estudado

Estudo feito em 13/11/2026. A página do guia (ScienceDirect) devolveu 403 ao leitor automático, mas **carregou no navegador
embutido do app** e foi lida por inteiro; também se leu a página "LaTeX instructions" da Elsevier. Nada abaixo vem de memória.

Fontes: `sciencedirect.com/journal/science-of-computer-programming/publish/guide-for-authors` e
`elsevier.com/researcher/author/policies-and-guidelines/latex-instructions`.

## Trilha e tipo de artigo

SCP tem duas trilhas: **Research papers** e **Software** (*Original Software Publications*, 3 a 6 páginas). O artigo 1 é da primeira,
na linha **Experimental software technology** ("expositions on implementations of and experiments with novel programming languages,
systems and methods"). Revisão **simples-anônima** (os revisores veem o autor), no mínimo dois revisores.

## O que o guia exige e como o manuscrito atende

| Item (guia) | Regra | Atendido? |
|---|---|---|
| Arquivo | LaTeX: enviar `.tex`; **PDF não é arquivo-fonte aceitável**; usar o modelo da Elsevier (`elsarticle`) | **sim** (`artigo/main.tex`, `elsarticle`, modo `review`) |
| Resumo | conciso, factual, **≤ 250 palavras**, autônomo, sem referências | **sim**: 229 palavras |
| Palavras-chave | **1 a 7**, em inglês, evitar com "and"/"of" | **sim**: 7 |
| *Highlights* | **obrigatórios**; arquivo editável **separado** com "highlights" no nome; **3 a 5** itens, **≤ 85 caracteres** cada | **sim**: `artigo/highlights.txt` (5 itens, 62 a 74 caracteres). Converter para `.docx` se o sistema exigir Word |
| Página de rosto | título conciso; nomes; afiliações com **endereço postal completo e país**; autor correspondente com **e-mail** (publicado) | **parcial**: faltam o endereço da rua e o e-mail |
| Seções | numeradas (1, 1.1, 1.1.1); resumo sem número | **sim** |
| Tabelas | texto editável; citadas no texto; legendas; **sem linhas verticais nem sombreado**; usar com parcimônia | **sim** (`booktabs`, sem verticais) |
| Figuras | arquivos **separados** (`Figure_1`, `Figure_2`...), vetoriais (EPS/PDF) com fonte embutida; legenda com título breve | **sim**: `artigo/figures/Figure_1.pdf`, `Figure_2.pdf` (e seus `.tex`) |
| Referências | numeradas por ordem de aparição, entre colchetes; qualquer estilo consistente; **cada referência deve ser uma fonte real** (referências geradas por IA podem estar erradas); DOIs quando houver; *software* citado com criador, título, venue, data (ou "n.d."), identificador, versão | **sim** (`elsarticle-num`); as 13 foram conferidas (ver abaixo) |
| CRediT | o autor correspondente deve declarar os papéis (CRediT) | **pendente** (marcador no texto) |
| Conflito de interesses | declaração obrigatória (ferramenta de declarações do sistema) | **pendente** |
| Fomento | declarar; se não houve, a frase padrão da Elsevier | **pendente** |
| Dados de pesquisa | **Opção B**: incentivado depositar em repositório e citar; senão, explicar por que não | **parcial**: URL e DOI pendentes |
| **IA generativa** | declaração **obrigatória** no envio, em **nova seção antes das referências**, com o título "Declaration of generative AI and AI-assisted technologies in the manuscript preparation process" e o texto-modelo da Elsevier; IA **não** pode ser autora; o autor responde pelo conteúdo | **sim** (seção presente; o autor tem de confirmar a revisão) |
| Agradecimentos | seção própria, antes das referências | n/a (nenhum) |
| Originalidade | trabalho não publicado nem em avaliação em outro lugar | **atenção**: ver a sobreposição com o artigo do JFP, no checklist |
| Linguagem inclusiva | obrigatória | sim |
| Preprints | permitidos (SSRN gratuito no próprio envio) | opcional |
| Acesso aberto | opções e APC na página de acesso aberto; **não lida** | pendente de leitura |

## Referências conferidas (existência e dados)

Perone e Karachalias (arXiv 2307.09090, título completo "… (Architectural Pearl)", FUNARCH/ICFP 2023); Hutton (2016, ISBN
9781316626221); Eisenberg e Weirich (Haskell '12, pp. 117–130); Strom e Yemini (IEEE TSE SE-12(1), 157–171, DOI
10.1109/TSE.1986.6312929); Atkey (JFP 19(3–4), 335–376, DOI 10.1017/S095679680900728X); Brady (JFP 23(5), 552–593, DOI
10.1017/S095679681300018X); DeMillo, Lipton e Sayward (IEEE Computer 11(4), 34–41, DOI 10.1109/C-M.1978.218136); Jia e Harman
(IEEE TSE 37(5), 649–678, DOI 10.1109/TSE.2010.62). **Sem verificação independente:** ISO/IEC 14882:2017 (norma, edição),
Malakhovski e Shalyto (fonte em russo, lida só com apoio de IA, sem falante nativo; citada apenas para uma observação geral),
as entradas de *software* (Clang, analisador, GHC), sem data. O DOI de Eisenberg e Weirich tinha valores divergentes nas fontes e
**foi omitido**.

## Modelo LaTeX

A Elsevier recomenda a classe `elsarticle`, "contained in most TeX distributions" (instalada no MiKTeX). Não se baixou nada para esta
revista. No envio: PDF + arquivo único com **todos** os fontes (`.tex`, `.bib`/`.bbl`, figuras, classes que não estejam no TeX Live);
não enviar os `.tex` como material suplementar.
