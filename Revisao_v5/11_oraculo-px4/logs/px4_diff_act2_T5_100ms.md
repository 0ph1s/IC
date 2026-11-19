Parametro COM_LOW_BAT_ACT = 2, COM_FAIL_ACT_T = 5 s, 100 ms por passo; tracos usados: 1020 (aresta e aleatorios); finais de tick comparados: 16099.

| Classe | Finais de tick | Exemplo (tipo, traco, tick) |
|---|---|---|
| concordam | 15332 | ('aresta', 1, 1) |
| ATRASO: o PX4 esta em Hold esperando COM_FAIL_ACT_T; a nossa esta em EmergencyLanding | 517 | ('aresta', 49, 2) |
| ATRASO: o PX4 esta em Hold esperando COM_FAIL_ACT_T; a nossa esta em InFlight | 201 | ('aresta', 26, 2) |
| trava: nossa segue em EmergencyLanding com bateria Low; PX4 liberou (acao Warn) | 41 | ('aresta', 143, 3) |
| PX4 so avisa: a bateria ja estava Critical ao armar (framework.cpp/failsafe.cpp, COM_LOW_BAT_ACT) | 8 | ('aresta', 269, 4) |
