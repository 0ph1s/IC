# Ameaças à validade

Atende à melhoria 4 do documento de 07/11/2026 ("tratar ameaças à validade") e à seção 8 do parecer
("questão de pesquisa, evidências, limites e ameaças à validade"). A lista é específica deste trabalho; cada item
diz o que **foi** feito e o que **não** foi para mitigá-lo.

## Validade de construto (medimos o que dizemos medir?)

| Ameaça | Mitigação feita | Resta |
|---|---|---|
| "Segurança de tipos" é tratada como **rejeição antecipada de arestas fora da topologia**, não como segurança comportamental | definição explícita nas hipóteses; o evento–destino e o temporal são tratados à parte | o termo pode ser lido de forma mais ampla por leitores; manter a definição no resumo |
| O "domínio de aviônica" é um exemplo escolhido, sem requisitos reais | escopo declarado em todo documento; nenhuma alegação sobre segurança de voo | os achados valem para o **modelo**; não generalizar para UAVs |
| Esforço e legibilidade medidos só por proxies (tamanho de diagnóstico, linhas) | proxies medidos e rotulados como tal | sem estudo de manutenção, sem leitura por terceiros |

## Validade interna (o experimento prova o que parece provar?)

| Ameaça | Mitigação feita | Resta |
|---|---|---|
| **Autor único** escreveu código, tabelas, oráculo, TLA+ e as três implementações C/C++: um erro de interpretação pode estar em todos | tabela revisável com origem `REQ` (4 linhas) × `CONV` (12) × `MODEL` (9); oráculo guiado pela tabela; especificação em TLA+ (executada no TLC) | **revisão pela orientação pendente**; **não existe oráculo de terceiros**; revisor externo de C/C++ pendente |
| A hipótese da abstração (o futuro depende só do terno de vértices) sustenta a alcançabilidade "para qualquer comprimento" | vale por construção de `closedLoop`; conferida em 8 421 cenários (`faithful`) | não provada formalmente; vale para esta implementação |
| Mutantes são escolhidos por quem escreve os testes | classes escolhidas pelo parecer (aresta ilegal, destino errado, eventos trocados) mais omissão, saída, ambiente e energia | sem mutação sistemática (por exemplo, operador a operador) |
| O shrinking do Hedgehog dá mínimo local | mínimo global obtido por busca em largura e registrado (4 ticks); com a semente fixa do log, o shrinking chegou a ele, mas em geral só garante mínimo local | — |
| O TLA+ é do mesmo autor e o TLC verifica o modelo, não a implementação | executado no TLC 2.19; mesmos 26 ternos que o Haskell; conclusões iguais | erro de interpretação comum às três representações; revisão da orientação |
| A implementação em CREM foi observada por um `Observe` que reconstrói a prova `AllowedTransition` | a suíte confere que observar não muda o comportamento (planta == `uavSystem`) | confiança na própria camada de observação |

## Validade externa (generaliza?)

| Ameaça | Mitigação feita | Resta |
|---|---|---|
| **Uma** topologia, 4 vértices, 4 eventos; ambiente de um slot | declarado | outras topologias e escalas (melhoria 3 do documento de adequação): **não feito** |
| Um compilador por linguagem (clang 14.0.6; GHC 9.6.7), um sistema (Windows 11), uma versão do CREM (0.1.0.0) | versões registradas | GCC, MSVC, outras versões do GHC e do `crem` |
| A implementação C++ tipada é a escolha do autor | descrita no código | revisor de C++ |
| A literatura não foi levantada sistematicamente | protocolo escrito | **busca não executada**: sem ela não se pode alegar ineditismo |

## Validade de conclusão (as conclusões decorrem dos dados?)

| Ameaça | Mitigação feita | Resta |
|---|---|---|
| Testes exaustivos em domínio finito não provam sequências arbitrárias | a alcançabilidade fecha o grafo de estados (modelo finito) | prova relativa à hipótese da abstração |
| "Achado" confundido com defeito do CREM | rotulado como propriedade do modelo do ambiente | manter no título e no resumo do artigo 2 |
| Números dependem do alfabeto de entrada | o relatório v4 usou alfabeto reduzido e N = 8; aqui, alfabeto completo (20 ticks) e fechamento | explicitar o alfabeto em toda tabela |
| Tempos e contagens vêm de uma máquina e de uma execução | ordem de grandeza | repetir em outra máquina |

## Ameaças de procedência e de integridade

* **Uso de IA:** código, scripts e textos desta revisão foram produzidos com assistência de IA (ver `DECLARACAO_USO_IA.md`).
  O risco é de erro confiante: por isso há suítes que **conseguem falhar** (mutantes, traços corrompidos) e logs completos.
  A revisão humana do que foi gerado é **pendente**.
* **Fonte em russo** (Malakhovski e Shalyto, 2009) lida com apoio de IA, sem revisão por falante nativo.
* **Reutilização de resultados entre artigos:** dividir só se cada artigo tiver contribuição distinta; ver os dois esqueletos.
