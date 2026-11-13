/* A mesma FSM de aviônica em C++17 "moderno": estados e eventos são TIPOS distintos
 * (std::variant) e a topologia está no nível dos tipos, em um traço `Allowed`, de modo que
 * uma transição fora da topologia falha em `static_assert`. É o análogo, em C++, do par
 * `AllowedTransition` / `pureResult` do CREM, e existe para NÃO generalizar a conclusão de que
 * "só o Haskell detecta a transição proibida na compilação".
 *
 * Custo: ~25 linhas de gabarito (templates) além da função de transição, e mensagens de erro de
 * template. Não é uma recomendação de estilo; é uma verificação da fronteira da afirmação.
 *
 * Imprime os 16 pares (estado, evento, destino) para ser conferido contra a tabela
 * 03_codigo/validation/spec/transition_table.csv por scripts/audit.sh.
 * Cada `step` fica em UMA linha, para as mutações do script (sed) mexerem em linhas inteiras. */
#include <cstdio>
#include <type_traits>
#include <variant>

struct Grounded {};
struct InFlight {};
struct EmergencyLanding {};
struct Shutdown {};
struct TakeoffSignal {};
struct CriticalBattery {};
struct LandedSignal {};
struct SystemCutoff {};

using State = std::variant<Grounded, InFlight, EmergencyLanding, Shutdown>;
using Event = std::variant<TakeoffSignal, CriticalBattery, LandedSignal, SystemCutoff>;

/* Topologia no nível dos tipos. A aresta identidade é sempre permitida (como no CREM). */
template <class From, class To> struct Allowed : std::is_same<From, To> {};
template <> struct Allowed<Grounded, InFlight> : std::true_type {};
template <> struct Allowed<InFlight, EmergencyLanding> : std::true_type {};
template <> struct Allowed<EmergencyLanding, Grounded> : std::true_type {};
template <> struct Allowed<Grounded, Shutdown> : std::true_type {};

template <class To, class From> State go(From)
{
    static_assert(Allowed<From, To>::value, "transicao fora da topologia");
    return To{};
}

State step(Grounded s, TakeoffSignal)   { return go<InFlight>(s); }
State step(Grounded s, CriticalBattery) { return go<Grounded>(s); }
State step(Grounded s, LandedSignal)    { return go<Grounded>(s); }
State step(Grounded s, SystemCutoff)    { return go<Shutdown>(s); }
State step(InFlight s, TakeoffSignal)   { return go<InFlight>(s); }
State step(InFlight s, CriticalBattery) { return go<EmergencyLanding>(s); }
State step(InFlight s, LandedSignal)    { return go<InFlight>(s); }
State step(InFlight s, SystemCutoff)    { return go<InFlight>(s); }
State step(EmergencyLanding s, TakeoffSignal)   { return go<EmergencyLanding>(s); }
State step(EmergencyLanding s, CriticalBattery) { return go<EmergencyLanding>(s); }
State step(EmergencyLanding s, LandedSignal)    { return go<Grounded>(s); }
State step(EmergencyLanding s, SystemCutoff)    { return go<EmergencyLanding>(s); }
State step(Shutdown s, TakeoffSignal)   { return go<Shutdown>(s); }
State step(Shutdown s, CriticalBattery) { return go<Shutdown>(s); }
State step(Shutdown s, LandedSignal)    { return go<Shutdown>(s); }
State step(Shutdown s, SystemCutoff)    { return go<Shutdown>(s); }

/* std::visit exige uma `step` para CADA combinação: par omitido = erro de compilação. */
State transition(State s, Event e)
{
    return std::visit([](auto st, auto ev) { return step(st, ev); }, s, e);
}

static const char *STATE_NAME[] = {"Grounded", "InFlight", "EmergencyLanding", "Shutdown"};
static const char *EVENT_NAME[] = {"TakeoffSignal", "CriticalBattery", "LandedSignal", "SystemCutoff"};

int main()
{
    const State states[] = {Grounded{}, InFlight{}, EmergencyLanding{}, Shutdown{}};
    const Event events[] = {TakeoffSignal{}, CriticalBattery{}, LandedSignal{}, SystemCutoff{}};
    for (const State &s : states)
        for (const Event &e : events)
            std::printf("%s %s %s\n", STATE_NAME[s.index()], EVENT_NAME[e.index()],
                        STATE_NAME[transition(s, e).index()]);
    return 0;
}
