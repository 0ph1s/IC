Parametro COM_LOW_BAT_ACT = 2, COM_FAIL_ACT_T = 0 s, 100 ms por passo; tracos usados: 1023 (aresta e aleatorios); finais de tick comparados: 16738.

| Classe | Finais de tick | Exemplo (tipo, traco, tick) |
|---|---|---|
| concordam | 16472 | ('aresta', 1, 1) |
| PX4 pousa; nossa fica InFlight com bateria Critical (cegueira) | 204 | ('aresta', 26, 2) |
| trava: nossa segue em EmergencyLanding com bateria Low; PX4 liberou (acao Warn) | 48 | ('aresta', 143, 3) |
| PX4 so avisa: a bateria ja estava Critical ao armar (framework.cpp/failsafe.cpp, COM_LOW_BAT_ACT) | 14 | ('aresta', 261, 4) |

Persistencia da cegueira (ticks consecutivos terminando em (InFlight, Critical), do lado nosso):
sequencias: 225; maior sequencia: 2 ticks; sequencias com mais de 1 tick: 10.
Tracos que terminam cegos, por tipo (total do tipo): aleatorio30: 0 de 500; aresta: 25 de 520; ocioso: 0 de 3
