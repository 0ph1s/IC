# Checklist de submissão ao SCP — o que falta antes de enviar

O manuscrito (`artigo/main.tex`, classe `elsarticle`, 21 páginas em modo de revisão) está **formatado**, mas **não pronto para enviar**.

## Bloqueantes (ação do autor)

| # | Item | Observação |
|---|---|---|
| 1 | **E-mail do autor correspondente** e **endereço postal completo** da Fatec BS | o guia diz que o e-mail é publicado; deixados como marcadores por privacidade |
| 2 | **Coautoria da orientação?** | decisão das pessoas; o guia diz que mudanças de autoria **depois** do envio exigem formulário e aprovação do editor |
| 3 | **CRediT**, **conflito de interesses** e **fomento** | marcadores no texto; o conflito é preenchido também na ferramenta de declarações |
| 4 | **Repositório público + DOI** (Zenodo, por exemplo) | "Opção B" de dados de pesquisa: depositar e citar; o repositório era privado |
| 5 | **Declaração de IA**: o autor confirma a frase "reviewed and edited the content… takes full responsibility" e a extensão da revisão | exigência da Elsevier; sem a confirmação, não pode ser enviada como está |
| 6 | **Sobreposição com o manuscrito do JFP** | ver abaixo |
| 7 | **Revisão externa do código C/C++** | o artigo declara essa revisão como pendente (`05_c-cpp/REVISAO_EXTERNA_CHECKLIST.md`) |

## Sobreposição com o artigo do JFP (decidir antes de enviar qualquer um dos dois)

Os dois manuscritos compartilham **(a)** a matriz de 16 pares do `crem` (JFP Tabela 2; SCP Tabela 4), **(b)** a tabela da função de transição
(JFP Tabela 1; SCP Tabela 1) e **(c)** a mutação da implementação em `crem` (JFP Tabela 3, 8 mutantes; SCP Seção 4.3, 9 mutantes, resumida
sem a tabela). O SCP exige que o trabalho "não esteja em avaliação em outro lugar" e o JFP exige declarar trabalhos relacionados.
Opções: (i) enviar um primeiro e só depois o outro, citando-o; (ii) reduzir a Seção 4 do JFP a um resumo que cite o SCP; (iii) declarar a
sobreposição na carta ao editor de cada um. Qualquer que seja a escolha, **declarar na carta**.

## Recomendados

| # | Item |
|---|---|
| 8 | Executar a **busca de literatura** (`07_estado-da-arte/PROTOCOLO_REVISAO.md`); a seção "Related work" diz que não é sistemática |
| 9 | Outras máquinas, outros compiladores (GCC, MSVC), outros analisadores (`clang-tidy` indisponível), tempo de compilação |
| 10 | Revisão de inglês por falante fluente |
| 11 | Ler no site a página de **acesso aberto e APC** do SCP (não lida) |
| 12 | Conferir a edição da norma ISO/IEC 14882:2017 e as entradas de *software* (datas e identificadores) |
| 13 | Converter `highlights.txt` para `.docx` se o sistema pedir Word |

## Conferências já feitas

| Verificação | Resultado |
|---|---|
| compila (pdflatex + bibtex + 2 passadas) | sim, 21 páginas, sem referência indefinida |
| resumo ≤ 250 palavras | 229 |
| palavras-chave 1 a 7 | 7 |
| *highlights* 3 a 5, ≤ 85 caracteres | 5 itens, 62 a 74 caracteres |
| figuras em arquivos separados | `Figure_1.pdf`, `Figure_2.pdf` |
| tabelas sem linhas verticais | sim |
| números do artigo × logs de `08_reprodutibilidade/` | sim (`05_c_cpp_matrix.md`, `15_typed_matrix.md`, `16_haskell_defects.md`, `02_negative_matrix.md`, `06_mutation_*.md`, `05_c-cpp/AUDITORIA.md`) |
| marcadores `[...]` em negrito | no texto: e-mail, endereço, CRediT, conflito de interesses, fomento, URL/DOI e confirmação da IA; nada foi inventado |

## O que o artigo **não** afirma

Que o Haskell seja pior ou melhor que C ou C++; que o resultado valha para máquinas maiores; que a legibilidade dos diagnósticos seja medida
(só o tamanho foi); nenhuma alegação de ineditismo; nada sobre aviônica real.
