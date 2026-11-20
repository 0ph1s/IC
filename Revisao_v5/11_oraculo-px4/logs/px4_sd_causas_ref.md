PX4 (failsafe real), COM_LOW_BAT_ACT = 3, NAV_RCL_ACT=2, COM_GNSSLOSS_ACT=2, GF_ACTION=2, armado, entrada (bateria:manche:modo, ou flags nomeadas) em {0:0:3,2:0:3} a cada segundo.
Todas as 128 palavras de comprimento 7; classes futuras: historias de comprimento 3, continuacoes de comprimento 4.

| COM_FAIL_ACT_T (s) | estados alfa | conflitos alfa | estados alfa' | conflitos alfa' | estados beta | conflitos beta | classes futuras |
|---|---|---|---|---|---|---|---|
| 0 | 3 | 1 | 3 | 1 | 5 | 0 | 2 |
| 2 | 4 | 2 | 4 | 2 | 26 | 0 | 5 |
