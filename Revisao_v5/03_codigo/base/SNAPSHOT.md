# Instantâneo congelado de `avionics-crem`

* **Origem:** repositório `https://github.com/0ph1s/avionics-crem` (cópia local `GitHub/avionics-crem`, fora do repositório IC).
* **Commit:** `9689ce8` ("Desenvolve o README: máquina, camadas, simulador, validação e limites").
  A etiqueta `v0.2.0-pic-parcial` é o commit anterior, `ab02fea`, citado no relatório v4; `9689ce8` só acrescenta o README.
* **Como foi obtido:** `git archive 9689ce8 | tar -x` (sem `.git`). **Nenhum arquivo foi alterado.**
  `MANIFEST.sha256` lista o hash de cada arquivo; confira com `cd avionics-crem && sha256sum -c ../MANIFEST.sha256`.
* **Por que não `Projects/avionics-crem` do repositório IC:** aquela cópia está no commit `c97981a` (anterior), sem a
  especificação, a matriz de rejeição, os testes de cadeia e de políticas e a comparação com C/C++ que o relatório v4 cita
  (`spec/domain_rules.txt`, `scripts/negative_matrix.sh`, `test/SpecChain.hs`, `test/SpecPolicy.hs`, `compare-c/`).
* **Uso:** só como dependência de `../validation` (pacote `avionics-validation`). O pacote base mantém as suítes originais
  (`avionics-spec-tests`, `avionics-sim-tests`, `avionics-chain-tests`, `avionics-policy-tests`), reproduzidas por
  `08_reprodutibilidade/run_all.sh`.
