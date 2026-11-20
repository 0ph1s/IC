------------------------------ MODULE TraceCheck ------------------------------
(***************************************************************************)
(* O3 (plano v2, tarefa T12): VALIDAÇÃO DE TRAÇOS da implementação (CREM)   *)
(* contra a especificação AvionicsLoop.tla, sem alterar esta.              *)
(*                                                                         *)
(* Cada elemento de Traces (módulo TraceData, gerado por                    *)
(* validation-export) é um traço da IMPLEMENTAÇÃO: uma lista de ticks, e    *)
(* em cada tick o comando, o evento de energia e, para CADA SINAL           *)
(* processado, o terno (aviônica, bateria, ambiente) observado depois dele. *)
(* O traço é ACEITO se a especificação tem um comportamento com as mesmas   *)
(* entradas cujos passos reproduzem, um a um, os ternos observados e cuja   *)
(* fila esvazia no fim de cada tick (ou seja, o número de sinais também     *)
(* coincide). Em Done, o traço inteiro foi reproduzido.                     *)
(*                                                                         *)
(* O modelo escolhe um traço qualquer na partida (id) e o segue; o TLC      *)
(* explora todos de uma vez. Rodar com -deadlock (todo traço termina).      *)
(***************************************************************************)
EXTENDS AvionicsLoop, TraceData

VARIABLES id, t, k
tvars == <<av, pw, slot, queue, id, t, k>>

AvList   == <<"Grounded", "InFlight", "EmergencyLanding", "Shutdown">>
PwList   == <<"Charged", "Low", "Critical">>
SlotList == <<"Standby", "CriticalHeld", "TouchdownHeld", "CutoffHeld">>
CmdList  == <<"TakeoffSignal", "CriticalBattery", "LandedSignal", "SystemCutoff">>
PwEvList == <<"Drain", "Recharge", "ShedLoad">>

Tr == Traces[id]

\* o estado depois do passo é o que o traço registra
StepMatches(code) ==
  /\ av'   = AvList[(code \div 100) + 1]
  /\ pw'   = PwList[((code \div 10) % 10) + 1]
  /\ slot' = SlotList[(code % 10) + 1]

TInit == /\ Init
         /\ id \in 1..Len(Traces)
         /\ t = 0
         /\ k = 0

\* começa o tick t+1 (com os MESMOS comando e energia do traço) quando o anterior terminou
TTick == /\ queue = <<>>
         /\ t < Len(Tr)
         /\ IF t = 0 THEN TRUE ELSE k = Len(Tr[t][3])
         /\ LET c == Tr[t + 1][1]
                p == Tr[t + 1][2]
            IN queue' = <<BeatSig>>
                        \o (IF c = 0 THEN <<>> ELSE <<AvSig(CmdList[c])>>)
                        \o (IF p = 0 THEN <<>> ELSE <<PwSig(PwEvList[p])>>)
         /\ t' = t + 1
         /\ k' = 0
         /\ UNCHANGED <<av, pw, slot, id>>

\* processa um sinal; o resultado tem de ser o próximo passo registrado
TStep == /\ queue # <<>>
         /\ t >= 1
         /\ k < Len(Tr[t][3])
         /\ Process(Head(queue))
         /\ StepMatches(Tr[t][3][k + 1])
         /\ k' = k + 1
         /\ UNCHANGED <<t, id>>

TNext == TTick \/ TStep
TSpec == TInit /\ [][TNext]_tvars

Done == /\ t >= 1
        /\ t = Len(Tr)
        /\ k = Len(Tr[t][3])
        /\ queue = <<>>

\* Para o relatório: o TLC é rodado só para enumerar os estados (-dump); ver run_trace_validation.sh.
TypeOKTrace == /\ id \in 1..Len(Traces) /\ t \in Nat /\ k \in Nat
=============================================================================
