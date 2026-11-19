PX4 (failsafe real), COM_LOW_BAT_ACT = 3, NAV_RCL_ACT=2, COM_GNSSLOSS_ACT=2, GF_ACTION=2, armado, entrada (bateria:manche:modo, ou flags nomeadas) em {0:0:3,2:0:3,gnss1,mc1,gf1} a cada segundo.
Todas as 15625 palavras de comprimento 6; classes futuras: historias de comprimento 3, continuacoes de comprimento 3.

| COM_FAIL_ACT_T (s) | estados alfa | conflitos alfa | estados alfa' | conflitos alfa' | estados beta | conflitos beta | classes futuras |
|---|---|---|---|---|---|---|---|
| 0 | 5 | 5 | 15 | 5 | 77 | 0 | 7 |
| 2 | 5 | 9 | 17 | 28 | 540 | 0 | 15 |
