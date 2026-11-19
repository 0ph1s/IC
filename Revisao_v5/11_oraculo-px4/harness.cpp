// Harness (nosso) que liga o failsafe REAL do PX4 (failsafe.cpp, framework.cpp) a uma interface de texto.
// Stubs nossos: parametros (mapa), tempo (hrt_abstime), eventos (desligados, como no build EMSCRIPTEN_BUILD do PX4).
//
// Entrada (stdin), uma diretiva por linha; '#' inicia comentario:
//   PARAM <NOME> <valor>              define um parametro; vale para as instancias criadas depois
//   NEW                               cria uma instancia nova de Failsafe (estado zerado, parametros atuais)
//   STEP <t_ms> chave=valor ...       um update(); chaves: armed mode bat rft gnss mc gcs nav unh stick vtype
// Saida: uma linha por STEP:  <t_ms> <acao> <takeover> <modo_pretendido>
#include "failsafe.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <uORB/topics/battery_status.h>
#include <uORB/topics/vehicle_status.h>

// ---- parametros (stub) ----
static double g_param[(int)px4::params::Count];
static const char *g_name[] = {"COM_FAIL_ACT_T", "COM_POS_FS_ACT", "NAV_DLL_ACT", "NAV_RCL_ACT", "COM_RCL_EXCEPT",
			       "COM_DLL_EXCEPT", "COM_RC_IN_MODE", "GF_ACTION", "COM_SPOOLUP_TIME", "CBRK_FLIGHTTERM",
			       "COM_ACT_FAIL_ACT", "COM_LOW_BAT_ACT", "COM_OBL_RC_ACT", "COM_QC_ACT", "COM_WIND_MAX_ACT",
			       "COM_POS_LOW_ACT", "COM_ARM_ODID", "COM_PARACHUTE", "COM_TRAFF_AVOID", "COM_GNSSLOSS_ACT"};
static bool g_float[(int)px4::params::Count];

static void defaults()
{
	for (auto &v : g_param) { v = 0; }

	g_param[(int)px4::params::COM_FAIL_ACT_T] = 5.0;
	g_param[(int)px4::params::NAV_RCL_ACT] = 2;
	g_param[(int)px4::params::COM_RC_IN_MODE] = 3;
	g_param[(int)px4::params::COM_SPOOLUP_TIME] = 1.0;
	g_param[(int)px4::params::CBRK_FLIGHTTERM] = 121212;
	g_param[(int)px4::params::COM_LOW_BAT_ACT] = 3;
	g_param[(int)px4::params::COM_POS_LOW_ACT] = 1;
	g_param[(int)px4::params::COM_TRAFF_AVOID] = 1;
	g_float[(int)px4::params::COM_FAIL_ACT_T] = true;
	g_float[(int)px4::params::COM_SPOOLUP_TIME] = true;
}

int param_get(param_t p, void *val)
{
	if (p >= (param_t)px4::params::Count) { return -1; }

	if (g_float[p]) { *(float *)val = (float)g_param[p]; } else { *(int32_t *)val = (int32_t)g_param[p]; }

	return 0;
}
int param_set(param_t, const void *) { return 0; }
int param_set_no_notification(param_t, const void *) { return 0; }
void param_get_mark_used(param_t p, void *val) { param_get(p, val); }

// ---- circuit breaker (o cabecalho real declara; aqui a definicao) ----
extern "C" bool circuit_breaker_enabled(const char *, int32_t) { return false; }

static int paramIndex(const std::string &n)
{
	for (int i = 0; i < (int)px4::params::Count; ++i) { if (n == g_name[i]) { return i; } }

	return -1;
}

int main()
{
	defaults();
	std::unique_ptr<Failsafe> fs;
	failsafe_flags_s flags{};
	std::string line;
	bool first_step_of_instance = true;

	while (std::getline(std::cin, line)) {
		auto hash = line.find('#');

		if (hash != std::string::npos) { line.erase(hash); }

		std::istringstream is(line);
		std::string cmd;

		if (!(is >> cmd)) { continue; }

		if (cmd == "PARAM") {
			std::string n; double v; is >> n >> v;
			int i = paramIndex(n);

			if (i < 0) { std::fprintf(stderr, "parametro desconhecido: %s\n", n.c_str()); return 2; }

			g_param[i] = v;

		} else if (cmd == "NEW") {
			fs.reset(new Failsafe(nullptr));
			flags = failsafe_flags_s{};
			first_step_of_instance = true;

		} else if (cmd == "STEP") {
			if (!fs) { std::fprintf(stderr, "STEP antes de NEW\n"); return 2; }

			long t_ms; is >> t_ms;
			FailsafeBase::State st{};
			st.vehicle_type = vehicle_status_s::VEHICLE_TYPE_ROTARY_WING;
			st.user_intended_mode = vehicle_status_s::NAVIGATION_STATE_AUTO_MISSION;
			bool stick = false;
			std::string kv;

			while (is >> kv) {
				auto eq = kv.find('=');
				std::string k = kv.substr(0, eq);
				int v = std::atoi(kv.c_str() + eq + 1);

				if (k == "armed") { st.armed = v; }
				else if (k == "mode") { st.user_intended_mode = (uint8_t)v; }
				else if (k == "bat") { flags.battery_warning = (uint8_t)v; }
				else if (k == "rft") { flags.battery_low_remaining_time = v; }
				else if (k == "gnss") { flags.gnss_lost = v; }
				else if (k == "mc") { flags.manual_control_signal_lost = v; }
				else if (k == "gcs") { flags.gcs_connection_lost = v; }
				else if (k == "nav") { flags.navigator_failure = v; }
				else if (k == "unh") { flags.battery_unhealthy = v; }
				else if (k == "stick") { stick = v; }
				else if (k == "vtype") { st.vehicle_type = (uint8_t)v; }
				else { std::fprintf(stderr, "chave desconhecida: %s\n", k.c_str()); return 2; }
			}

			(void)first_step_of_instance;
			uint8_t m = fs->update((hrt_abstime)t_ms * 1000ULL, st, false, stick, flags);
			std::printf("%ld %d %d %d\n", t_ms, (int)fs->selectedAction(), (int)fs->userTakeoverActive(), (int)m);
			first_step_of_instance = false;

		} else {
			std::fprintf(stderr, "diretiva desconhecida: %s\n", cmd.c_str());
			return 2;
		}
	}

	return 0;
}
