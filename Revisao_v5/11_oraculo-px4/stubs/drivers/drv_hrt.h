// STUB (nosso): so o necessario do drv_hrt.h do PX4 para compilar o failsafe fora do firmware.
#pragma once
#include <stdint.h>

typedef uint64_t hrt_abstime;

namespace time_literals
{
constexpr hrt_abstime operator "" _s(unsigned long long seconds) { return hrt_abstime(seconds * 1000000ULL); }
constexpr hrt_abstime operator "" _ms(unsigned long long ms) { return hrt_abstime(ms * 1000ULL); }
constexpr hrt_abstime operator "" _us(unsigned long long us) { return hrt_abstime(us); }
}
