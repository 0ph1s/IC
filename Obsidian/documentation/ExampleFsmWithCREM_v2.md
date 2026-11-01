# Deterministic Finite State Machine (FSM) in Haskell — revised version (v2)

> Revision of `ExampleFsmWithCREM.md` (kept unchanged as history). What changed:
> the claim that `turnstileAction SLocked Push = pureResult "..." SUnlocked` is
> rejected by GHC was **false** and was removed (section 3.2). The turnstile
> cannot show a rejected transition; the rejection test lives in the avionics
> example (section 5), with the real GHC message.

This document presents two implementations of a classic turnstile FSM in
Haskell: a simple pedagogical one and one using the **CREM** library
(*Composable Representable Executable Machines*). It then explains why the
turnstile is not enough to demonstrate compile-time rejection, and points to
the avionics example that is.

---

## 1. The Turnstile FSM

| Current State | Input | Next State   | Output                         |
|---------------|-------|--------------|--------------------------------|
| Locked        | Coin  | Unlocked     | "insert coin — now unlocked"   |
| Locked        | Push  | Locked       | "push denied — still locked"   |
| Unlocked      | Coin  | Unlocked     | "already open"                 |
| Unlocked      | Push  | Locked       | "passed through — now locked"  |

---

## 2. Simple Haskell Implementation

**File:** `Code/stateMachine.hs`

```haskell
data State = Locked | Unlocked deriving (Show, Eq)
data Input = Coin | Push deriving (Show, Eq)

transition :: State -> Input -> State
transition Locked   Coin  = Unlocked
transition Locked   Push  = Locked
transition Unlocked Coin  = Unlocked
transition Unlocked Push  = Locked

run :: State -> [Input] -> State
run = foldl transition
```

Output for `[Coin,Push,Push,Coin,Coin,Push]` from `Locked`: final state `Locked`.

**What the compiler checks.** With `-Wall`, GHC *warns* (`-Wincomplete-patterns`)
if a `(State, Input)` pair has no equation; it becomes an error only with
`-Werror` (or `-Werror=incomplete-patterns`). A wildcard equation (`_`) hides
omissions. It does **not** check that the table is the *intended* one:
`transition Locked Push = Unlocked` compiles without complaint.
Real GHC output for the warning/error: `aviso_exaustividade.txt`.

---

## 3. Formalized FSM with CREM

**Location:** `others/crem-example/app/Main.hs`

### 3.1 What CREM is

CREM models Mealy machines with a **topology** that lists, for each vertex,
the vertices it may move to.

- The topology is a value of type `Topology vertex`, promoted to the type level
  with the `singletons` library (Template Haskell).
- `ActionResult` carries a constraint
  `AllowedTransition topology initialVertex finalVertex` (a type **class**; its
  evidence is the GADT `AllowTransition`). GHC resolves it by searching the
  topology's edge list.
- Staying in the same vertex is **always** allowed: the class has an
  identity instance (`AllowedTransition topology a a`, Perone and Karachalias
  2023, Fig. 4), so self-loops need not be listed.
- Machines are leaves (`Basic`) of a tree composed with `Sequential`,
  `Parallel`, `Alternative`, `Feedback` and `Kleisli`.

### 3.2 Turnstile formalization — and its limit

```haskell
$(singletons [d|
  data TurnstileVertex = Locked | Unlocked
    deriving (Show, Eq)

  turnstileTopology :: Topology TurnstileVertex
  turnstileTopology = Topology
    [ (Locked,   [Unlocked])
    , (Unlocked, [Locked])
    ]
  |])

turnstileAction :: Applicative m
  => STurnstileVertex initialVertex -> Input
  -> ActionResult m TurnstileTopology STurnstileVertex initialVertex Output
turnstileAction SLocked Coin   = pureResult "Unlocked (insert coin)"  SUnlocked
turnstileAction SLocked Push   = pureResult "Locked (push denied)"    SLocked
turnstileAction SUnlocked Coin = pureResult "Unlocked (already open)" SUnlocked
turnstileAction SUnlocked Push = pureResult "Locked (passed through)" SLocked
```

**Correction.** The previous version said that
`turnstileAction SLocked Push = pureResult "..." SUnlocked` would be rejected
by GHC. It is not: it compiles. Reason:

1. The topology has the edges `Locked -> Unlocked` and `Unlocked -> Locked`.
2. The identity edges `Locked -> Locked` and `Unlocked -> Unlocked` are always
   allowed.
3. With only two vertices, those four edges are *every* ordered pair. The
   topology is a complete graph (with self-loops), so `AllowedTransition` can
   always be resolved and no equation of `turnstileAction` can be rejected.

Also, the input (`Coin`/`Push`) is not part of the vertex type, so the topology
constrains only which vertex can follow which, not which *event* causes it.
"A `Push` must not unlock a locked turnstile" is a rule about events; the
types here do not express it. This is the limitation that Perone and
Karachalias (2023, section 6) list as future work: no connection between
allowed transitions and the inputs that trigger them.

For compile-time rejection we need a topology that is **not** complete, such
as the avionics one below.

### 3.3 Build and run

```bash
cd others/crem-example
cabal run
```

---

## 4. Key Differences

| Aspect               | Simple FSM                       | CREM formalization                                   |
|----------------------|----------------------------------|------------------------------------------------------|
| Transition table     | Plain function                   | `Topology` + `ActionResult` with `AllowedTransition` |
| Edge not in topology | Not detected (any table compiles)| Compile-time error (`Could not deduce ...`)          |
| Wrong event→edge map | Not detected                     | Not detected (inputs are not in the topology)        |
| Missing (state,event)| Warning (error with `-Werror`)   | Same, on the `SVertex`/event patterns                |
| Composition          | Manual                           | `Sequential`, `Parallel`, `Alternative`, ...         |
| Diagrams             | Not available                    | `Crem.Render.*` (Mermaid)                            |
| Dependencies         | `base` only                      | `crem`, `singletons-base`                            |

---

## 5. Where rejection really happens: the avionics example

Project: `others/avionics-crem/` (cabal). Topology:

```
Grounded         -> InFlight, Shutdown
InFlight         -> EmergencyLanding
EmergencyLanding -> Grounded
```

There is no `InFlight -> Shutdown` edge. The test module
`invalid/InvalidInFlightShutdown.hs` writes
`pureResult MsgShutdown SShutdown` while in `SInFlight`, and it is built
outside the main build:

```bash
cd others/avionics-crem
cabal build invalid-inflight-shutdown --enable-tests
```

Real GHC 9.6.7 message (full text in `erro_invalidez_inflight_shutdown.txt`):

```
invalid\InvalidInFlightShutdown.hs:23:39: error: [GHC-39999]
    * Could not deduce `Crem.Topology.AllowedTransition
                          (Crem.Topology.Topology '[]) InFlight Shutdown'
        arising from a use of `pureResult'
```

The residual `Topology '[]` shows how the search ends: the class instances
discard the edges one by one, and when the list is empty without a match,
GHC has no evidence and stops.

Scope of the guarantee: it covers a **single** transition. The path
`InFlight -> EmergencyLanding -> Grounded -> Shutdown` exists in the topology,
so "never shut down in flight" holds for the direct edge, not for every
sequence of events.

Diagrams generated by the CREM `Render` module: `avionics_topology.mmd`,
`power_topology.mmd`, `coupled_flow.mmd` (this folder).

---

## 6. References

- Perone, M.; Karachalias, G. *Crème de la Crem: Composable Representable
  Executable Machines*. 2023 (arXiv:2307.09090).
- CREM library: <https://github.com/tweag/crem>, Hackage package `crem` 0.1.0.0.
- `singletons-base`: <https://hackage.haskell.org/package/singletons-base>
