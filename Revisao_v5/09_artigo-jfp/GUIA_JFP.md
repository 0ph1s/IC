# Padrão de publicação do Journal of Functional Programming (JFP) — o que foi estudado

Estudo feito em 13/11/2026. **Revista escolhida: JFP**, entre as recomendadas no documento de 07/11/2026 (JFP e SCP são
"os melhores journals"; JFP com aderência "muito alta" e enquadramento "Tools and Applications ou experiência e limites de
garantias estáticas; exige contribuição reutilizável").

## Por que JFP e não SCP

| Critério | JFP | SCP |
|---|---|---|
| Guia de autores lido? | **sim**: páginas do Episciences e o guia da própria classe (`jfp-epi-guide.pdf`, v1.2, 27/05/2026) | **não**: a página do ScienceDirect devolveu HTTP 403; só se leu a página-vitrine (escopo) |
| Tema | Haskell, tipos, garantias estáticas, experiência | engenharia de software e métodos formais; trilha de pesquisa e trilha de software |
| Modelo de LaTeX | `jfp-epi` (baixado do site da revista) | `elsarticle` (instalado no MiKTeX), mas as regras não foram lidas |

Escolher a revista cujo guia **não se conseguiu ler** seria formatar às cegas. O SCP continua uma opção válida para o artigo 1
(`ARTIGO_1_*.md`), depois de alguém ler o guia no navegador.

## O que o JFP exige (fontes: `jfp.episciences.org/for-authors`, `/about`, `jfp-epi-guide.pdf`)

| Item | Regra | Atendido no manuscrito? |
|---|---|---|
| Classe | `jfp-epi` (v1.2), fina camada sobre `acmart`; `\documentclass[review]{jfp-epi}` para o artigo em revisão | **sim** (`artigo/main.tex`) |
| Linhas numeradas | **obrigatórias** em revisão (a opção `review` as insere, em vermelho, e escreve "DRAFT PAPER UNDER REVIEW") | **sim** |
| Tipo de artigo | `research` (padrão); `pearl`, `theory`, `education` são os especiais | **sim** (`research`) |
| Caixa dos títulos | **sentence case** no título, em todas as seções/subseções/parágrafos e nas legendas | **sim** (conferir à mão; nomes próprios em maiúscula) |
| Autores | `\author`, `\affiliation` com `\authoremail` **dentro** do bloco; **ORCID obrigatório para todos os autores** (guia da classe) | **parcial**: falta ORCID e e-mail |
| Palavras-chave e classificação ACM | **não usar** ("delete any ACM category classifications, as well as keywords") | **sim** (não há) |
| Bibliografia | estilo `ACM-Reference-Format` (instalado no MiKTeX); citação numérica (padrão) ou autor-ano (`\citestyle{acmauthoryear}`) | **sim** (numérica) |
| Licença | CC-BY 4.0 (padrão da classe; `\setcopyright{none}` só para rascunho) | **sim** (padrão) |
| Seções finais sem número | Agradecimentos, declaração de disponibilidade de dados, link para material suplementar, via `\section*` | **sim** (disponibilidade de dados; declaração de IA; fomento) |
| Originalidade | trabalho original, **não** em revisão em outro periódico ou conferência | a confirmar pelo autor |
| Extensão | sem limite rígido; artigos regulares costumam ter 20 a 50 páginas, mais curtos são aceitos | ver o número de páginas do PDF |
| Revisão | simples-anônima (os revisores conhecem o autor); três revisores; primeira decisão em ~3 meses | n/a |
| Fluxo de submissão | enviar antes o artigo a um repositório aberto (**arXiv, HAL ou Zenodo**) e criar a submissão no Episciences com o ID e a versão; arXiv não aceita linhas numeradas: gerar duas versões (sem `review` para o arXiv; com `review` no campo "Cover Letter") | **pendente** (ação do autor) |
| Após aceite | PDF **e** diretório com todo o código-fonte LaTeX | `artigo/` já está no formato |
| Acesso | *Diamond Open Access*; nenhuma taxa citada nas páginas lidas | n/a |
| Material suplementar | incentivado, em repositório aberto; a revista não o hospeda | **parcial**: URL e DOI pendentes |

## Divergências e lacunas do próprio guia (a conferir no site antes de submeter)

* **ORCID:** a página do Episciences diz "encorajado, não obrigatório" para submissão e obrigatório só no aceite; o guia da classe diz
  "required for all authors on JFP submissions". Seguiu-se o mais rígido.
* **Resumo, extensão do resumo e política sobre IA generativa:** **não constam** nas páginas lidas. Incluiu-se uma declaração de uso de IA
  por honestidade (o texto foi escrito com assistência de IA), mas a política da revista não foi encontrada.
* **Páginas da Cambridge** (autor-instruções antigas): HTTP 429 em duas tentativas; **não lidas**. A página do Episciences afirma
  que o JFP deixou a Cambridge no fim de 2025, então são provavelmente legadas.
* **Fluxo de submissão** descrito por uma página; o guia de submissão do Episciences não foi lido por completo.

## Origem da classe

`jfp_epi_1.2.zip` (292 091 bytes, sha256 `6255daa991d5836bfbd8313c1a31a7f5f1936a668791ad5db8ba130aa9ad4203`) foi baixado de
`https://jfp.episciences.org/jfp/resources/jfp_epi_1.2.zip`, o endereço que a revista indica aos autores, para a pasta
`class/` (descompactada em `class/extraido/`). O `.cls` (3 995 linhas) foi inspecionado: não há comandos de shell; a abertura
de arquivos é só dos auxiliares `\jobname.*`. Os dois arquivos usados foram copiados para `artigo/`.
