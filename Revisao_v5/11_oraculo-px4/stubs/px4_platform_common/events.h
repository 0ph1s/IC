// STUB (nosso): no build EMSCRIPTEN_BUILD do PX4 (o simulador de failsafe do proprio PX4) as chamadas a events::send
// sao compiladas fora; so os tipos dos enums sao necessarios.
#pragma once
#include <stdint.h>
namespace events { namespace px4 { namespace enums {
enum class failsafe_action_t : uint8_t { _max = 9 };
enum class failsafe_cause_t : uint8_t { _max = 6 };
} } }
