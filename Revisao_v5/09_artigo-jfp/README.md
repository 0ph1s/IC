# 09_artigo-jfp — manuscrito formatado para o Journal of Functional Programming

| Arquivo | Conteúdo |
|---|---|
| `artigo/main.pdf` | o manuscrito compilado (12 páginas; `jfp-epi` v1.2, modo `review`: linhas numeradas, "DRAFT PAPER UNDER REVIEW", CC-BY) |
| `artigo/main.tex`, `refs.bib` | fontes (inglês; títulos em *sentence case*; bibliografia `ACM-Reference-Format`) |
| `artigo/jfp-epi.cls`, `jfp-cup2epi.sty` | a classe oficial, copiada de `class/` |
| `class/` | `jfp_epi_1.2.zip` baixado do site da revista, e o conteúdo extraído (guia da classe, modelo) |
| `GUIA_JFP.md` | o que se estudou do padrão do JFP, por que JFP e não SCP, divergências do guia |
| `CHECKLIST_SUBMISSAO.md` | o que falta antes de enviar (ORCID, e-mail, repositório/DOI, revisão da orientação, busca de literatura...) |

**Título:** *Limits of type-level transition guarantees in composable state machines: a closed-loop case study in Haskell*
(artigo 2 de `06_artigos/`, enquadrado como artigo de pesquisa do JFP). Os resultados do artigo 1 (comparação com C/C++) **não** foram
reutilizados, para respeitar a recomendação de não duplicar resultados entre artigos.

Compilar (na pasta `artigo/`): `pdflatex main && bibtex main && pdflatex main && pdflatex main`.
A primeira compilação demora: o MiKTeX gera as fontes da classe.
