Parametro COM_LOW_BAT_ACT = 2, COM_FAIL_ACT_T = 5 s, 1000 ms por passo; tracos usados: 1020 (aresta e aleatorios); finais de tick comparados: 16700.

| Classe | Finais de tick | Exemplo (tipo, traco, tick) |
|---|---|---|
| concordam | 15941 | ('aresta', 1, 1) |
| ATRASO: o PX4 esta em Hold esperando COM_FAIL_ACT_T; a nossa esta em EmergencyLanding | 509 | ('aresta', 49, 2) |
| ATRASO: o PX4 esta em Hold esperando COM_FAIL_ACT_T; a nossa esta em InFlight | 197 | ('aresta', 26, 2) |
| trava: nossa segue em EmergencyLanding com bateria Low; PX4 liberou (acao Warn) | 41 | ('aresta', 143, 3) |
| PX4 so avisa: a bateria ja estava Critical ao armar (framework.cpp/failsafe.cpp, COM_LOW_BAT_ACT) | 8 | ('aresta', 269, 4) |
| PX4 pousa; nossa fica InFlight com bateria Critical (cegueira) | 4 | ('aresta', 486, 4) |

Persistencia da cegueira (ticks consecutivos terminando em (InFlight, Critical), do lado nosso):
sequencias: 223; maior sequencia: 2 ticks; sequencias com mais de 1 tick: 18.
Tracos que terminam cegos, por tipo (total do tipo): aleatorio30: 0 de 500; aresta: 33 de 520
