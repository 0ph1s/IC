# Diagramas gerados pelo módulo Render do CREM

Gerados por `cabal run` em `others/avionics-crem` (`Avionics.Diagram`). Texto Mermaid conferido; não foi renderizado por ferramenta Mermaid nesta máquina.

## Aviônica (topologia)

```mermaid
stateDiagram-v2

Grounded
InFlight
EmergencyLanding
Shutdown
Grounded --> InFlight
Grounded --> Shutdown
InFlight --> EmergencyLanding
EmergencyLanding --> Grounded
```

Não há aresta `InFlight --> Shutdown`. As auto-transições não aparecem porque a aresta identidade é implícita.

## Energia (topologia)

```mermaid
stateDiagram-v2

Charged
Low
Critical
Charged --> Low
Low --> Charged
Low --> Critical
Critical --> Low
```

## Composição acoplada (energia -> tradução -> aviônica), via renderFlow

```mermaid
stateDiagram-v2
state Power {
Power_Charged
Power_Low
Power_Critical
Power_Charged --> Power_Low
Power_Low --> Power_Charged
Power_Low --> Power_Critical
Power_Critical --> Power_Low
}
state Translate {
Translate_()
}
state Avionics {
Avionics_Grounded
Avionics_InFlight
Avionics_EmergencyLanding
Avionics_Shutdown
Avionics_Grounded --> Avionics_InFlight
Avionics_Grounded --> Avionics_Shutdown
Avionics_InFlight --> Avionics_EmergencyLanding
Avionics_EmergencyLanding --> Avionics_Grounded
}
state PassThrough {
PassThrough_()
}
state fork_choice_AvionicsPassThrough <<choice>>
state join_choice_AvionicsPassThrough <<choice>>
fork_choice_AvionicsPassThrough --> Avionics
fork_choice_AvionicsPassThrough --> PassThrough
Avionics --> join_choice_AvionicsPassThrough
PassThrough --> join_choice_AvionicsPassThrough
Translate --> fork_choice_AvionicsPassThrough
Power --> Translate
```
