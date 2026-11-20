# Takeover do piloto (PX4 real): cenarios e sonda nos estados de EmergencyLanding

Sequencias de acoes, um passo por segundo, armado, modo AUTO_MISSION; bateria Critical a partir do passo 1; `*` = userTakeoverActive.

```
COM_FAIL_ACT_T=0 COM_LOW_BAT_ACT=2
  sem takeover        : None Land Land Land Land Land Land Land Land Land Land Land Land Land
  manche no passo 8   : None Land Land Land Land Land Land Land Land Land Land Land Land Land
  troca de modo, 8    : None Land Land Land Land Land Land Land Warn* Warn* Warn* Warn* Warn* Warn*
  manche no passo 8, bateria Emergency no 11: None Land Land Land Land Land Land Land Land Land Land Land Land Land
  manche no passo 8, bateria recupera no 10 e cai de novo no 12: None Land Land Land Land Land Land Land Land Land None Land Land Land
COM_FAIL_ACT_T=0 COM_LOW_BAT_ACT=3
  sem takeover        : None RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL
  manche no passo 8   : None RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL
  troca de modo, 8    : None RTL RTL RTL RTL RTL RTL RTL Warn* Warn* Warn* Warn* Warn* Warn*
  manche no passo 8, bateria Emergency no 11: None RTL RTL RTL RTL RTL RTL RTL RTL RTL RTL Land RTL RTL
  manche no passo 8, bateria recupera no 10 e cai de novo no 12: None RTL RTL RTL RTL RTL RTL RTL RTL RTL None RTL RTL RTL
COM_FAIL_ACT_T=5 COM_LOW_BAT_ACT=2
  sem takeover        : None Hold Hold Hold Hold Hold Land Land Land Land Land Land Land Land
  manche no passo 8   : None Hold Hold Hold Hold Hold Land Land Warn* Warn* Warn* Warn* Warn* Warn*
  troca de modo, 8    : None Hold Hold Hold Hold Hold Land Land Warn* Warn* Warn* Warn* Warn* Warn*
  manche no passo 8, bateria Emergency no 11: None Hold Hold Hold Hold Hold Land Land Warn* Warn* Warn* Hold Hold Land
  manche no passo 8, bateria recupera no 10 e cai de novo no 12: None Hold Hold Hold Hold Hold Land Land Warn* Warn* None Hold Hold Land
COM_FAIL_ACT_T=5 COM_LOW_BAT_ACT=3
  sem takeover        : None Hold Hold Hold Hold Hold RTL RTL RTL RTL RTL RTL RTL RTL
  manche no passo 8   : None Hold Hold Hold Hold Hold RTL RTL Warn* Warn* Warn* Warn* Warn* Warn*
  troca de modo, 8    : None Hold Hold Hold Hold Hold RTL RTL Warn* Warn* Warn* Warn* Warn* Warn*
  manche no passo 8, bateria Emergency no 11: None Hold Hold Hold Hold Hold RTL RTL Warn* Warn* Warn* Hold Hold RTL
  manche no passo 8, bateria recupera no 10 e cai de novo no 12: None Hold Hold Hold Hold Hold RTL RTL Warn* Warn* None Hold Hold RTL
```

## Sonda nos estados de EmergencyLanding dos nossos tracos

Cada linha: de um fim de tick em que a NOSSA aviônica esta em EmergencyLanding, o que o PX4 faz com um manche (ou uma troca de modo para Loiter) no passo seguinte (`depois`), e o que faz no passo seguinte a esse sem novo gesto (`mantem`). `antes` = a acao do PX4 naquele fim de tick.

### COM_FAIL_ACT_T = 0 s, COM_LOW_BAT_ACT = 2, 100 ms por passo

| gesto | antes | depois | mantem | fins de tick |
|---|---|---|---|---|
| manche | Land | Land | Land | 517 |
| manche | Warn | Warn | Warn | 49 |
| modo | Land | Warn | Warn | 517 |
| modo | Warn | Warn | Warn | 49 |

### COM_FAIL_ACT_T = 5 s, COM_LOW_BAT_ACT = 2, 100 ms por passo

| gesto | antes | depois | mantem | fins de tick |
|---|---|---|---|---|
| manche | Hold | Hold | Hold | 517 |
| manche | Warn | Warn | Warn | 49 |
| modo | Hold | Warn | Warn | 517 |
| modo | Warn | Warn | Warn | 49 |

### COM_FAIL_ACT_T = 5 s, COM_LOW_BAT_ACT = 2, 1000 ms por passo

| gesto | antes | depois | mantem | fins de tick |
|---|---|---|---|---|
| manche | Hold | Hold | Hold | 458 |
| manche | Warn | Warn | Warn | 49 |
| manche | Hold | Warn | Warn | 29 |
| manche | Hold | Hold | Land | 22 |
| manche | Land | Warn | Warn | 8 |
| modo | Hold | Warn | Warn | 509 |
| modo | Warn | Warn | Warn | 49 |
| modo | Land | Warn | Warn | 8 |

