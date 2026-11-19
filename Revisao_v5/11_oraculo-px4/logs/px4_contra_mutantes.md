# O4 (PX4) contra os mutantes de destino aceitos pelo compilador

COM_LOW_BAT_ACT = 2. Linha de base (implementacao sem mutacao), todos os tracos: concordam 16450, cegueira 201, trava 41, so avisa 8.
So os 500 aleatorios (mesmos cenarios para toda implementacao): concordam 14861, cegueira 100, trava 35, so avisa 4.

| Id | Defeito | Resultado | Classes novas | Contagens que mudam nos aleatorios (base -> mutante) |
|---|---|---|---|---|
| D01 | Grounded + TakeoffSignal: InFlight -> Grounded | **morto (aleatorios diferem)** | - | cegueira 100 -> 0; concordam 14861 -> 15000; so avisa 4 -> 0; trava 35 -> 0 |
| D03 | Grounded + TakeoffSignal: InFlight -> Shutdown | **morto (aleatorios diferem)** | - | cegueira 100 -> 0; concordam 14861 -> 15000; so avisa 4 -> 0; trava 35 -> 0 |
| D04 | Grounded + CriticalBattery: Grounded -> InFlight | **morto (aleatorios diferem)** | - | cegueira 100 -> 96; concordam 14861 -> 14598; so avisa 4 -> 243; trava 35 -> 63 |
| D06 | Grounded + CriticalBattery: Grounded -> Shutdown | **morto (aleatorios diferem)** | - | cegueira 100 -> 63; concordam 14861 -> 14915; so avisa 4 -> 0; trava 35 -> 22 |
| D07 | Grounded + LandedSignal: Grounded -> InFlight | **morto (aleatorios diferem)** | - | cegueira 100 -> 219; concordam 14861 -> 14706; so avisa 4 -> 15; trava 35 -> 60 |
| D09 | Grounded + LandedSignal: Grounded -> Shutdown | **morto (aleatorios diferem)** | - | cegueira 100 -> 65; concordam 14861 -> 14911; so avisa 4 -> 0; trava 35 -> 24 |
| D10 | Grounded + SystemCutoff: Shutdown -> Grounded | **morto (aleatorios diferem)** | - | cegueira 100 -> 557; concordam 14861 -> 14091; so avisa 4 -> 161; trava 35 -> 191 |
| D11 | Grounded + SystemCutoff: Shutdown -> InFlight | **morto (aleatorios diferem)** | - | cegueira 100 -> 1007; concordam 14861 -> 13235; so avisa 4 -> 495; trava 35 -> 263 |
| D14 | InFlight + TakeoffSignal: InFlight -> EmergencyLanding | **morto (aleatorios diferem)** | - | cegueira 100 -> 54; concordam 14861 -> 14519; so avisa 4 -> 3; trava 35 -> 424 |
| D17 | InFlight + CriticalBattery: EmergencyLanding -> InFlight | **morto (classe nova)** | PX4 pousa; nossa (InFlight, Charged) nao, PX4 pousa; nossa (InFlight, Low) nao | PX4 pousa; nossa (InFlight, Charged) nao 0 -> 592; PX4 pousa; nossa (InFlight, Low) nao 0 -> 490; cegueira 100 -> 1061; concordam 14861 -> 12857; so avisa 4 -> 0; trava 35 -> 0 |
| D20 | InFlight + LandedSignal: InFlight -> EmergencyLanding | **morto (aleatorios diferem)** | - | cegueira 100 -> 48; concordam 14861 -> 14502; so avisa 4 -> 5; trava 35 -> 445 |
| D23 | InFlight + SystemCutoff: InFlight -> EmergencyLanding | **morto (aleatorios diferem)** | - | cegueira 100 -> 39; concordam 14861 -> 14502; so avisa 4 -> 9; trava 35 -> 450 |
| D25 | EmergencyLanding + TakeoffSignal: EmergencyLanding -> Grounded | **morto (aleatorios diferem)** | - | cegueira 100 -> 101; concordam 14861 -> 14867; trava 35 -> 28 |
| D28 | EmergencyLanding + CriticalBattery: EmergencyLanding -> Grounded | **morto (aleatorios diferem)** | - | cegueira 100 -> 104; concordam 14861 -> 14855; trava 35 -> 37 |
| D32 | EmergencyLanding + LandedSignal: Grounded -> EmergencyLanding | **morto (aleatorios diferem)** | - | cegueira 100 -> 80; concordam 14861 -> 11154; so avisa 4 -> 58; trava 35 -> 3708 |
| D34 | EmergencyLanding + SystemCutoff: EmergencyLanding -> Grounded | **morto (aleatorios diferem)** | - | cegueira 100 -> 104; concordam 14861 -> 14864; so avisa 4 -> 6; trava 35 -> 26 |

Mutantes avaliados: 16; mortos por classe nova: 1; mortos por contagens nos aleatorios: 15; mortos so pelos tracos de aresta: 0; vivos: 0; sem resultado: 0.

Os tracos de aresta de um mutante sao os da exploracao da propria implementacao mutada; por isso as contagens variam de um mutante para outro.
