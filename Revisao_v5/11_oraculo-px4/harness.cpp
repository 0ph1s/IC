// Harness (nosso) que liga o failsafe REAL do PX4 (failsafe.cpp, framework.cpp) a uma interface de texto.
// Stubs nossos: parametros (mapa), tempo (hrt_abstime), eventos (desligados, como no build EMSCRIPTEN_BUILD do PX4).
//
// Entrada (stdin), uma diretiva por linha; '#' inicia comentario:
//   PARAM <NOME> <valor>              define um parametro; vale para as instancias criadas depois
//   NEW                               cria uma instancia nova de Failsafe (estado zerado, parametros atuais)
//   STEP <t_ms> chave=valor ...       um update(); chaves: armed mode bat rft gnss mc gcs nav unh stick vtype
//   VERBOSE <0|1>                     com 1, cada STEP imprime tambem o estado interno (ver abaixo)
// Saida: uma linha por STEP:  <t_ms> <acao> <takeover> <modo_pretendido>
//   com VERBOSE 1, acrescenta:  <atraso_us> <atraso_inicial_us> <acoes ativas>
//   onde <acoes ativas> = lista ordenada de "acao/limpeza/falha" das entradas validas de _actions (ou "-").
// Os cabecalhos da biblioteca padrao entram ANTES do truque abaixo. O truque (private/protected -> public) vale so
// nesta unidade de traducao e serve para LER, sem alterar o codigo do PX4, o estado interno do Failsafe (atrasos e
// lista de acoes) na diretiva VERBOSE; o layout das classes nao muda.
#include <algorithm>
#include <cfloat>
#include <climits>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <new>
#include <sstream>
#include <string>
#include <type_traits>
#include <utility>
#include <vector>
#define private public
#define protected public
#include "failsafe.h"
#undef private
#undef protected
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
	bool verbose = false;

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

		} else if (cmd == "VERBOSE") {
			int v; is >> v; verbose = v != 0;

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
				else if (k == "gf") { flags.geofence_breached = v; }
				else if (k == "wind") { flags.wind_limit_exceeded = v; }
				else if (k == "ftl") { flags.flight_time_limit_exceeded = v; }
				else if (k == "mf") { flags.mission_failure = v; }
				else if (k == "posl") { flags.position_accuracy_low = v; }
				else if (k == "stick") { stick = v; }
				else if (k == "vtype") { st.vehicle_type = (uint8_t)v; }
				else { std::fprintf(stderr, "chave desconhecida: %s\n", k.c_str()); return 2; }
			}

			(void)first_step_of_instance;
			uint8_t m = fs->update((hrt_abstime)t_ms * 1000ULL, st, false, stick, flags);
			std::printf("%ld %d %d %d", t_ms, (int)fs->selectedAction(), (int)fs->userTakeoverActive(), (int)m);

			if (verbose) {
				std::vector<std::string> acts;

				for (int a = 0; a < fs->max_num_actions; ++a) {
					const auto &x = fs->_actions[a];

					if (x.valid()) {
						acts.push_back(std::to_string((int)x.action) + "/" + std::to_string((int)x.clear_condition) + "/"
							       + std::to_string((int)x.state_failure));
					}
				}

				std::sort(acts.begin(), acts.end());
				std::string joined;

				for (auto &a : acts) { joined += (joined.empty() ? "" : ",") + a; }

				std::printf(" %llu %llu %s", (unsigned long long)fs->_current_delay,
					    (unsigned long long)fs->_current_start_delay, joined.empty() ? "-" : joined.c_str());
				// resto do estado privado que pode influir nas decisoes seguintes (ordem fixa; ver px4_sd.py)
				std::printf(" %d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", (int)fs->_last_armed, (int)fs->_user_takeover_active,
					    (int)fs->_last_user_intended_mode, (int)fs->_last_status_flags.battery_warning,
					    (int)fs->_last_status_flags.battery_low_remaining_time, (int)fs->_last_state_battery_warning_low,
					    (int)fs->_last_state_battery_warning_critical, (int)fs->_last_state_battery_warning_emergency,
					    (int)fs->_battery_warning_at_arming, (int)fs->_was_armed, (int)(fs->_armed_time != 0));
				// outras causas: ultimas flags vistas e bits privados de Failsafe (acrescentados ao fim)
				const auto &lf = fs->_last_status_flags;
				std::printf(",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", (int)fs->_manual_control_lost_at_arming,
					    (int)fs->_last_state_mode_fallback, (int)lf.manual_control_signal_lost, (int)lf.gcs_connection_lost,
					    (int)lf.gnss_lost, (int)lf.geofence_breached, (int)lf.wind_limit_exceeded,
					    (int)lf.flight_time_limit_exceeded, (int)lf.navigator_failure, (int)lf.mission_failure,
					    (int)lf.position_accuracy_low);
			}

			std::printf("\n");
			first_step_of_instance = false;

		} else {
			std::fprintf(stderr, "diretiva desconhecida: %s\n", cmd.c_str());
			return 2;
		}
	}

	return 0;
}
