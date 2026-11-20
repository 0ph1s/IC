------------------------- MODULE AvionicsLoopFairness -------------------------
(***************************************************************************)
(* T15 (plano v2): a conclusão "OneSlot viola NoPermanentBlindness" depende *)
(* de uma hipótese sobre o ambiente externo. Em AvionicsLoop.tla, a justiça *)
(* fraca de Tick só exige que ticks continuem a ocorrer; o mundo pode      *)
(* mandar ticks ociosos para sempre. Aqui, a mesma especificação (sem       *)
(* alterar AvionicsLoop.tla) é combinada com hipóteses MAIS FORTES sobre o  *)
(* que o mundo acaba enviando, em justiça forte (SF), porque o tick só é    *)
(* habilitado com a fila vazia, e isso se repete a cada tick.               *)
(*                                                                         *)
(* TickWith(c, p): um tick cujo comando é c e cuja energia é p ("none" =   *)
(* ausente). Cada hipótese diz: se o tick com aquela entrada fica         *)
(* habilitado infinitas vezes, ele ocorre infinitas vezes.                  *)
(***************************************************************************)
EXTENDS AvionicsLoop

TickWith(c, p) ==
  /\ queue = <<>>
  /\ queue' = <<BeatSig>>
               \o (IF c = "none" THEN <<>> ELSE <<AvSig(c)>>)
               \o (IF p = "none" THEN <<>> ELSE <<PwSig(p)>>)
  /\ UNCHANGED <<av, pw, slot>>

Base == Init /\ [][Next]_vars /\ WF_vars(Step) /\ WF_vars(Tick)

\* H0: a especificação original (o mundo pode ficar ocioso para sempre).
SpecH0 == Base

\* Entradas com energia fixa, comando qualquer.
SpecDrain    == Base /\ SF_vars(\E c \in AvEvents \cup {"none"} : TickWith(c, "Drain"))
SpecRecharge == Base /\ SF_vars(\E c \in AvEvents \cup {"none"} : TickWith(c, "Recharge"))
SpecShedLoad == Base /\ SF_vars(\E c \in AvEvents \cup {"none"} : TickWith(c, "ShedLoad"))

\* Entradas com comando fixo, energia qualquer.
SpecCritCmd    == Base /\ SF_vars(\E p \in PwEvents \cup {"none"} : TickWith("CriticalBattery", p))
SpecLandedCmd  == Base /\ SF_vars(\E p \in PwEvents \cup {"none"} : TickWith("LandedSignal", p))
SpecCutoffCmd  == Base /\ SF_vars(\E p \in PwEvents \cup {"none"} : TickWith("SystemCutoff", p))
SpecTakeoffCmd == Base /\ SF_vars(\E p \in PwEvents \cup {"none"} : TickWith("TakeoffSignal", p))

\* H*: toda entrada possível ocorre infinitas vezes (o mundo "sorteia" os 20 ticks).
SpecAll == Base /\ \A c \in AvEvents \cup {"none"} : \A p \in PwEvents \cup {"none"} :
                      SF_vars(TickWith(c, p))
=============================================================================
