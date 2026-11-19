PX4 (failsafe real), COM_LOW_BAT_ACT = 3, armado, entrada = nivel de bateria em {0,2} a cada segundo.
Todas as 65536 palavras de comprimento 16; classes futuras: historias de comprimento 8, continuacoes de comprimento 8.

| COM_FAIL_ACT_T (s) | estados alfa | conflitos alfa | estados alfa' | conflitos alfa' | estados beta | conflitos beta | classes futuras |
|---|---|---|---|---|---|---|---|
| 0 | 3 | 1 | 3 | 1 | 5 | 0 | 2 |
| 1 | 4 | 1 | 4 | 1 | 15 | 0 | 3 |
| 2 | 4 | 2 | 4 | 2 | 31 | 0 | 15 |
| 3 | 4 | 2 | 4 | 2 | 55 | 0 | 29 |
| 5 | 4 | 2 | 4 | 2 | 127 | 0 | 38 |
| 8 | 4 | 2 | 4 | 2 | 269 | 0 | 23 |
