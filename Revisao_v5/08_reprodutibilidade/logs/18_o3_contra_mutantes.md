# O3 (validação de traços no TLC) contra os mutantes de destino aceitos pelo compilador

| Id | Defeito | TLC: aresta aceitos | TLC: aleatórios aceitos | TLC: corrompidos aceitos | Resultado O3 | SCION: aresta aceitos | SCION: aleatórios aceitos | Resultado O2 (SCION) | SCION aceita o mesmo conjunto que o TLC |
|---|---|---|---|---|---|---|---|---|---|
| D01 | Grounded + TakeoffSignal: InFlight -> Grounded | 144/160 | 259/500 | 3/100 | **morto pelo O3** | 144/160 | 259/500 | **morto pelo SCION** | sim |
| D03 | Grounded + TakeoffSignal: InFlight -> Shutdown | 64/160 | 259/500 | 0/100 | **morto pelo O3** | 64/160 | 259/500 | **morto pelo SCION** | sim |
| D04 | Grounded + CriticalBattery: Grounded -> InFlight | 432/500 | 281/500 | 0/100 | **morto pelo O3** | 432/500 | 281/500 | **morto pelo SCION** | sim |
| D06 | Grounded + CriticalBattery: Grounded -> Shutdown | 312/500 | 281/500 | 2/100 | **morto pelo O3** | 312/500 | 281/500 | **morto pelo SCION** | sim |
| D07 | Grounded + LandedSignal: Grounded -> InFlight | 452/520 | 279/500 | 0/100 | **morto pelo O3** | 452/520 | 279/500 | **morto pelo SCION** | sim |
| D09 | Grounded + LandedSignal: Grounded -> Shutdown | 312/520 | 279/500 | 2/100 | **morto pelo O3** | 312/520 | 279/500 | **morto pelo SCION** | sim |
| D10 | Grounded + SystemCutoff: Shutdown -> Grounded | 284/380 | 0/500 | 0/100 | **morto pelo O3** | 284/380 | 0/500 | **morto pelo SCION** | sim |
| D11 | Grounded + SystemCutoff: Shutdown -> InFlight | 284/380 | 0/500 | 0/100 | **morto pelo O3** | 284/380 | 0/500 | **morto pelo SCION** | sim |
| D14 | InFlight + TakeoffSignal: InFlight -> EmergencyLanding | 436/600 | 388/500 | 0/100 | **morto pelo O3** | 436/600 | 388/500 | **morto pelo SCION** | sim |
| D17 | InFlight + CriticalBattery: EmergencyLanding -> InFlight | 208/300 | 259/500 | 2/100 | **morto pelo O3** | 208/300 | 259/500 | **morto pelo SCION** | sim |
| D20 | InFlight + LandedSignal: InFlight -> EmergencyLanding | 496/600 | 382/500 | 0/100 | **morto pelo O3** | 496/600 | 382/500 | **morto pelo SCION** | sim |
| D23 | InFlight + SystemCutoff: InFlight -> EmergencyLanding | 448/600 | 365/500 | 0/100 | **morto pelo O3** | 448/600 | 365/500 | **morto pelo SCION** | sim |
| D25 | EmergencyLanding + TakeoffSignal: EmergencyLanding -> Grounded | 476/520 | 486/500 | 0/100 | **morto pelo O3** | 476/520 | 486/500 | **morto pelo SCION** | sim |
| D28 | EmergencyLanding + CriticalBattery: EmergencyLanding -> Grounded | 476/520 | 478/500 | 0/100 | **morto pelo O3** | 476/520 | 478/500 | **morto pelo SCION** | sim |
| D32 | EmergencyLanding + LandedSignal: Grounded -> EmergencyLanding | 236/440 | 259/500 | 0/100 | **morto pelo O3** | 236/440 | 259/500 | **morto pelo SCION** | sim |
| D34 | EmergencyLanding + SystemCutoff: EmergencyLanding -> Grounded | 516/520 | 480/500 | 0/100 | **morto pelo O3** | 516/520 | 480/500 | **morto pelo SCION** | sim |

Mutantes avaliados: 16; mortos pelo O3: 16; vivos no O3: 0.
SCION: mortos 16; vivos 0; conjuntos de traços aceitos idênticos aos do TLC em 16 de 16.

Os traços de aresta de um mutante são os da exploração da própria implementação mutada, por isso o total varia de um mutante para outro.
