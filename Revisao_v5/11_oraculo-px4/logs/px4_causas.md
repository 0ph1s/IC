# Outras causas de failsafe no PX4 real

## 1. A acao trava ou libera quando a condicao some?

`COM_FAIL_ACT_T = 0`, armado, AUTO_MISSION, um passo por segundo. Colunas: acao com a causa ativa; 1 s depois de a causa sumir; depois de uma troca de modo para Loiter; depois de desarmar e armar de novo (causa ja desligada).

| Causa | Parametro = valor | ativa | causa some | troca de modo | desarma e arma | Leitura |
|---|---|---|---|---|---|---|
| perda de manual/RC | NAV_RCL_ACT = 0 | None | None | None | None | sem acao |
| perda de manual/RC | NAV_RCL_ACT = 1 | Hold | Hold | None | None | trava ate troca de modo ou desarmar |
| perda de manual/RC | NAV_RCL_ACT = 2 | RTL | RTL | None | None | trava ate troca de modo ou desarmar |
| perda de manual/RC | NAV_RCL_ACT = 3 | Land | Land | None | None | trava ate troca de modo ou desarmar |
| perda de manual/RC | NAV_RCL_ACT = 5 | Term | Term | Term | Term | nunca libera |
| perda de manual/RC | NAV_RCL_ACT = 6 | Disarm | None | None | None | libera |
| perda de manual/RC | NAV_RCL_ACT = 7 | None | None | None | None | sem acao |
| perda do GCS | NAV_DLL_ACT = 0 | None | None | None | None | sem acao |
| perda do GCS | NAV_DLL_ACT = 1 | Hold | Hold | None | None | trava ate troca de modo ou desarmar |
| perda do GCS | NAV_DLL_ACT = 2 | RTL | RTL | None | None | trava ate troca de modo ou desarmar |
| perda do GCS | NAV_DLL_ACT = 3 | Land | Land | None | None | trava ate troca de modo ou desarmar |
| perda do GCS | NAV_DLL_ACT = 5 | Term | Term | Term | Term | nunca libera |
| perda do GCS | NAV_DLL_ACT = 6 | Disarm | None | None | None | libera |
| perda do GCS | NAV_DLL_ACT = 7 | None | None | None | None | sem acao |
| perda de GNSS | COM_GNSSLOSS_ACT = 0 | Warn | None | None | None | so avisa ou nada |
| perda de GNSS | COM_GNSSLOSS_ACT = 1 | RTL | RTL | None | None | trava ate troca de modo ou desarmar |
| perda de GNSS | COM_GNSSLOSS_ACT = 2 | Land | Land | None | None | trava ate troca de modo ou desarmar |
| perda de GNSS | COM_GNSSLOSS_ACT = 3 | Term | Term | Term | Term | nunca libera |
| perda de GNSS | COM_GNSSLOSS_ACT = 4 | Warn | None | None | None | so avisa ou nada |
| geofence | GF_ACTION = 0 | None | None | None | None | sem acao |
| geofence | GF_ACTION = 1 | Warn | None | None | None | so avisa ou nada |
| geofence | GF_ACTION = 2 | Hold | Hold | None | None | trava ate troca de modo ou desarmar |
| geofence | GF_ACTION = 3 | RTL | RTL | None | None | trava ate troca de modo ou desarmar |
| geofence | GF_ACTION = 4 | Term | Term | Term | Term | nunca libera |
| geofence | GF_ACTION = 5 | Land | Land | None | None | trava ate troca de modo ou desarmar |
| vento acima do limite | COM_WIND_MAX_ACT = 0 | None | None | None | None | sem acao |
| vento acima do limite | COM_WIND_MAX_ACT = 1 | Warn | None | None | None | so avisa ou nada |
| vento acima do limite | COM_WIND_MAX_ACT = 2 | Hold | Hold | None | None | trava ate troca de modo ou desarmar |
| vento acima do limite | COM_WIND_MAX_ACT = 3 | RTL | RTL | None | None | trava ate troca de modo ou desarmar |
| vento acima do limite | COM_WIND_MAX_ACT = 4 | Term | Term | Term | Term | nunca libera |
| vento acima do limite | COM_WIND_MAX_ACT = 5 | Land | Land | None | None | trava ate troca de modo ou desarmar |
| tempo de voo excedido | (fixo) | RTL | None | None | None | libera |
| falha de missao | (fixo) | RTL | None | None | None | libera |
| falha do navegador | (fixo) | Hold | Hold | None | None | trava ate troca de modo ou desarmar |
| bateria Critical | COM_LOW_BAT_ACT = 0 | Warn | None | None | None | so avisa ou nada |
| bateria Critical | COM_LOW_BAT_ACT = 1 | RTL | None | None | None | libera |
| bateria Critical | COM_LOW_BAT_ACT = 2 | Land | None | None | None | libera |
| bateria Critical | COM_LOW_BAT_ACT = 3 | RTL | None | None | None | libera |
| bateria Critical | COM_LOW_BAT_ACT = 4 | RTL | None | None | None | libera |
| bateria Critical | COM_LOW_BAT_ACT = 5 | RTL | None | None | None | libera |
| bateria Critical | COM_LOW_BAT_ACT = 6 | RTL | None | None | None | libera |
| bateria Emergency | COM_LOW_BAT_ACT = 0 | Warn | None | None | None | so avisa ou nada |
| bateria Emergency | COM_LOW_BAT_ACT = 1 | RTL | None | None | None | libera |
| bateria Emergency | COM_LOW_BAT_ACT = 2 | Land | None | None | None | libera |
| bateria Emergency | COM_LOW_BAT_ACT = 3 | Land | None | None | None | libera |
| bateria Emergency | COM_LOW_BAT_ACT = 4 | Term | Term | Term | Term | nunca libera |
| bateria Emergency | COM_LOW_BAT_ACT = 5 | Land | None | None | None | libera |
| bateria Emergency | COM_LOW_BAT_ACT = 6 | Term | Term | Term | Term | nunca libera |

Resumo por causa (quantos valores do parametro caem em cada comportamento):

* bateria Critical: libera: 6; sem acao: 1
* bateria Emergency: libera: 4; nunca libera: 2; sem acao: 1
* falha de missao: libera: 1
* falha do navegador: trava ate modo/desarmar: 1
* geofence: nunca libera: 1; sem acao: 2; trava ate modo/desarmar: 3
* perda de GNSS: nunca libera: 1; sem acao: 2; trava ate modo/desarmar: 2
* perda de manual/RC: libera: 1; nunca libera: 1; sem acao: 2; trava ate modo/desarmar: 3
* perda do GCS: libera: 1; nunca libera: 1; sem acao: 2; trava ate modo/desarmar: 3
* tempo de voo excedido: libera: 1
* vento acima do limite: nunca libera: 1; sem acao: 2; trava ate modo/desarmar: 3

## 2. Com varias causas ao mesmo tempo, vale a mais severa?

300 configuracoes sorteadas de parametros (semente 20261119), todos os 502 subconjuntos de 2 ou mais das 9 causas (perda de manual/RC, perda do GCS, perda de GNSS, geofence, vento acima do limite, tempo de voo excedido, falha de missao, falha do navegador, bateria Critical) ligados ao mesmo tempo no passo 1. Lei: acao escolhida = maximo das acoes de cada causa sozinha (mesma configuracao).

| `COM_FAIL_ACT_T` | casos | violacoes | escolhida / esperada (o maximo) |
|---|---|---|---|
| 0 | 150600 | 0 | - |
| 5 | 150600 | 0 | - |


## 3. O resultado depende da ordem em que as causas aparecem?

Mesmas configuracoes. Para cada subconjunto de 2 ou 3 causas, todas as ordens de chegada, uma causa nova por passo (1 s) e as anteriores continuam ligadas; depois, passos de espera ate o fim. Conferem-se (a) acao final igual para todas as ordens e (b) igual ao maximo das acoes de cada causa sozinha.

| `COM_FAIL_ACT_T` | casos (subconjunto, configuracao) | ordens distintas dao acao final diferente | acao final diferente do maximo |
|---|---|---|---|
| 0 | 36000 | 0 | 0 |
| 5 | 36000 | 0 | 0 |
