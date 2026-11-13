# 10_artigo-scp — manuscrito formatado para o Science of Computer Programming

| Arquivo | Conteúdo |
|---|---|
| `artigo/main.pdf` | manuscrito compilado (21 páginas, `elsarticle`, modo `review`) |
| `artigo/main.tex`, `refs.bib` | fontes (inglês; referências numeradas) |
| `artigo/highlights.txt` | *highlights* (arquivo separado, como o guia exige) |
| `artigo/figures/` | `Figure_1.pdf`, `Figure_2.pdf` e os `.tex` que os geram |
| `GUIA_SCP.md` | o que se estudou do padrão do SCP e a conferência item a item |
| `CHECKLIST_SUBMISSAO.md` | o que falta antes de enviar, e a sobreposição com o artigo do JFP |

**Título:** *Compile-time transition safety versus exhaustive testing in composable finite-state machines: an experimental comparison in
Haskell, C and C++* (artigo 1 de `06_artigos/`). Experimentos novos que o sustentam: `05_c-cpp/scripts/typed_matrix.sh` (matriz de 16 pares
em C++17 tipado), `05_c-cpp/scripts/haskell_defects.sh` (defeitos na FSM em Haskell) e o mutante H9 (`08_reprodutibilidade/logs/06_mutation_h9.md`).

Compilar (na pasta `artigo/`): `pdflatex main && bibtex main && pdflatex main && pdflatex main`. As figuras são compiladas à parte em `figures/`.
