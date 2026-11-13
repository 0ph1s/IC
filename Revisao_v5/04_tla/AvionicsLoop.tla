-------------------------------- MODULE AvionicsLoop --------------------------------
(***************************************************************************)
(* Especificação do laço fechado  aviônica || energia -> ambiente,         *)
(* escrita a partir de 03_codigo/validation/spec/*.csv e POLITICAS.md,     *)
(* e NÃO do código Haskell (parecer de 03/11/2026, nível 2).               *)
(*                                                                         *)
(* STATUS: executada no TLC 2.19 (TLA+ Tools 1.7.4) em 13/11/2026; ver     *)
(* 04_tla/README.md e 08_reprodutibilidade/logs/14_tlc_*.txt. OneSlot viola *)
(* NoPermanentBlindness (esperado); Level satisfaz todas as propriedades.   *)
(* As mesmas propriedades foram verificadas, no mesmo modelo finito, por    *)
(* 03_codigo/validation (validation-reach-tests).                           *)
(*                                                                         *)
(* Modelagem: cada SINAL processado é um passo atômico (Step). Os sinais   *)
(* de um tick ficam numa fila; o que o ambiente libera é colocado NA FRENTE *)
(* da fila (profundidade primeiro, como o Feedback do CREM). Um novo tick  *)
(* (Tick) só começa com a fila vazia.                                      *)
(***************************************************************************)
EXTENDS Naturals, Sequences

CONSTANT Policy                       \* "OneSlot" ou "Level"
ASSUME Policy \in {"OneSlot", "Level"}

AvStates == {"Grounded", "InFlight", "EmergencyLanding", "Shutdown"}
PwStates == {"Charged", "Low", "Critical"}
Slots    == {"Standby", "CriticalHeld", "TouchdownHeld", "CutoffHeld"}

AvEvents == {"TakeoffSignal", "CriticalBattery", "LandedSignal", "SystemCutoff"}
PwEvents == {"Drain", "Recharge", "ShedLoad"}

\* Um sinal é um registro [kind |-> "Beat" | "Av" | "Pw", ev |-> nome do evento].
BeatSig == [kind |-> "Beat", ev |-> "-"]
AvSig(e) == [kind |-> "Av", ev |-> e]
PwSig(e) == [kind |-> "Pw", ev |-> e]
Signals == {BeatSig} \cup {AvSig(e) : e \in AvEvents} \cup {PwSig(e) : e \in PwEvents}

VARIABLES av, pw, slot, queue
vars == <<av, pw, slot, queue>>

(***************************************************************************)
(* Tabela da aviônica (transition_table.csv). Pares sem regra: o estado    *)
(* não muda e a saída é MsgIgnored (convenção CONV do projeto).            *)
(***************************************************************************)
AvNext(q, e) ==
  CASE q = "Grounded"         /\ e = "TakeoffSignal"   -> "InFlight"
    [] q = "Grounded"         /\ e = "SystemCutoff"    -> "Shutdown"
    [] q = "InFlight"         /\ e = "CriticalBattery" -> "EmergencyLanding"
    [] q = "EmergencyLanding" /\ e = "LandedSignal"    -> "Grounded"
    [] OTHER                                           -> q

AvOut(q, e) ==
  CASE q = "Grounded"         /\ e = "TakeoffSignal"   -> "MsgTakeoff"
    [] q = "Grounded"         /\ e = "SystemCutoff"    -> "MsgShutdown"
    [] q = "InFlight"         /\ e = "CriticalBattery" -> "MsgEmergency"
    [] q = "EmergencyLanding" /\ e = "LandedSignal"    -> "MsgLanded"
    [] OTHER                                           -> "MsgIgnored"

\* Tabela da energia (power_table.csv). ShedLoad só alivia Critical -> Low.
PwNext(p, e) ==
  CASE e = "Drain"    /\ p = "Charged"  -> "Low"
    [] e = "Drain"    /\ p = "Low"      -> "Critical"
    [] e = "Drain"    /\ p = "Critical" -> "Critical"
    [] e = "Recharge" /\ p = "Charged"  -> "Charged"
    [] e = "Recharge" /\ p = "Low"      -> "Charged"
    [] e = "Recharge" /\ p = "Critical" -> "Low"
    [] e = "ShedLoad" /\ p = "Critical" -> "Low"
    [] OTHER                            -> p

\* O que cada retenção libera no Beat (POLITICAS.md, seção 2).
ReleaseSeq(s) ==
  CASE s = "CriticalHeld"  -> <<AvSig("CriticalBattery")>>
    [] s = "TouchdownHeld" -> <<PwSig("ShedLoad"), AvSig("LandedSignal")>>
    [] s = "CutoffHeld"    -> <<AvSig("SystemCutoff")>>
    [] OTHER               -> <<>>

(***************************************************************************)
(* Processamento de UM sinal s (a cabeça da fila).                         *)
(***************************************************************************)
Process(s) ==
  LET newAv == IF s.kind = "Av" THEN AvNext(av, s.ev) ELSE av
      newPw == IF s.kind = "Pw" THEN PwNext(pw, s.ev) ELSE pw
      out   == IF s.kind = "Av" THEN AvOut(av, s.ev) ELSE "MsgIgnored"
      cue   == IF s.kind = "Beat" THEN "Beat"
               ELSE IF s.kind = "Av"
                    THEN (IF out = "MsgEmergency" THEN "Emergency"
                          ELSE IF out = "MsgLanded" THEN "Landed"
                          ELSE "Quiet")
                    ELSE (IF newPw = "Critical" THEN "Crit" ELSE "Quiet")
      \* Level: com o slot livre, bateria Critical e aviônica em voo, reage ao NÍVEL.
      levelSig == IF Policy = "Level" /\ cue = "Beat" /\ slot = "Standby"
                                      /\ pw = "Critical" /\ av = "InFlight"
                  THEN <<AvSig("CriticalBattery")>>
                  ELSE <<>>
      newSlot == IF cue = "Beat" THEN "Standby"
                 ELSE IF slot # "Standby" THEN slot          \* ocupado: descarta (um slot)
                 ELSE IF cue = "Crit"      THEN "CriticalHeld"
                 ELSE IF cue = "Emergency" THEN "TouchdownHeld"
                 ELSE IF cue = "Landed"    THEN "CutoffHeld"
                 ELSE slot
      emitted == IF cue = "Beat" THEN ReleaseSeq(slot) \o levelSig ELSE <<>>
  IN /\ av' = newAv
     /\ pw' = newPw
     /\ slot' = newSlot
     /\ queue' = emitted \o Tail(queue)

Step == /\ queue # <<>>
        /\ Process(Head(queue))

\* Início de um tick: Beat, depois o comando (opcional), depois a energia (opcional).
Tick == /\ queue = <<>>
        /\ \E c \in AvEvents \cup {"none"}, p \in PwEvents \cup {"none"} :
              queue' = <<BeatSig>>
                       \o (IF c = "none" THEN <<>> ELSE <<AvSig(c)>>)
                       \o (IF p = "none" THEN <<>> ELSE <<PwSig(p)>>)
        /\ UNCHANGED <<av, pw, slot>>

Init == /\ av = "Grounded"
        /\ pw = "Charged"
        /\ slot = "Standby"
        /\ queue = <<>>

Next == Step \/ Tick

\* Justiça fraca: um tick em curso termina, e ticks novos continuam a ocorrer.
Spec == Init /\ [][Next]_vars /\ WF_vars(Step) /\ WF_vars(Tick)

(***************************************************************************)
(* Propriedades                                                            *)
(***************************************************************************)
TypeOK == /\ av \in AvStates
          /\ pw \in PwStates
          /\ slot \in Slots
          /\ queue \in Seq(Signals)

\* Terminação do Feedback dentro de um tick: a fila não cresce sem limite.
\* (No modelo do Haskell, no máximo 5 passos por tick; a fila tem no máximo 4 sinais.)
QueueBounded == Len(queue) <= 4

\* Segurança da topologia (a regra dos requisitos): nunca InFlight -> Shutdown, em nenhum passo.
NoDirectInFlightShutdown == [][~(av = "InFlight" /\ av' = "Shutdown")]_vars

\* Propriedades de sequência do relatório v4 (seção 5.11).
ShutdownOnlyFromGrounded == [][av' = "Shutdown" => av \in {"Grounded", "Shutdown"}]_vars
EmergencyOnlyFromFlight  == [][av' = "EmergencyLanding" => av \in {"InFlight", "EmergencyLanding"}]_vars

\* Evento e destino (a lacuna que o tipo não cobre): TakeoffSignal em Grounded leva a InFlight.
EventDestination ==
  [][(queue # <<>> /\ Head(queue) = AvSig("TakeoffSignal") /\ av = "Grounded") => av' = "InFlight"]_vars

\* A realimentação termina: a fila esvazia infinitas vezes (cada tick acaba).
LoopTerminates == []<>(queue = <<>>)

\* Política da bateria. "Cega" = aviônica em voo com a bateria Critical. A propriedade diz que o
\* sistema NÃO fica cego para sempre. Esperado: VIOLADA com Policy = "OneSlot" (contraexemplo:
\* Drain, Drain, TakeoffSignal e depois só ticks ociosos), VÁLIDA com Policy = "Level".
NoPermanentBlindness == []<>(~(av = "InFlight" /\ pw = "Critical"))
=============================================================================
