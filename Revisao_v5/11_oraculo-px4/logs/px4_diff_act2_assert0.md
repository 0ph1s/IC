Parametro COM_LOW_BAT_ACT = 2; tracos usados: 1020 (aresta e aleatorios); finais de tick comparados: 16099.

| Classe | Finais de tick | Exemplo (tipo, traco, tick) |
|---|---|---|
| concordam | 15409 | ('aresta', 1, 1) |
| trava: nossa segue em EmergencyLanding com bateria Charged; PX4 liberou (acao None) | 275 | ('aresta', 49, 2) |
| trava: nossa segue em EmergencyLanding com bateria Low; PX4 liberou (acao Warn) | 210 | ('aresta', 50, 2) |
| PX4 pousa; nossa fica InFlight com bateria Critical (cegueira) | 201 | ('aresta', 26, 2) |
| PX4 so avisa: a bateria ja estava Critical ao armar (framework.cpp/failsafe.cpp, COM_LOW_BAT_ACT) | 4 | ('aresta', 269, 4) |
