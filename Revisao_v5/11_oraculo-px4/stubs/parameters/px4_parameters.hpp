// STUB (nosso): no PX4 este arquivo e gerado a partir dos metadados de parametros. Aqui so os parametros que
// failsafe.h e framework.h declaram; os valores ficam em stubs.cpp (param_get/param_set sobre um mapa).
#pragma once
#include <stdint.h>

typedef uint16_t param_t;
#define PARAM_INVALID ((param_t)0xffff)

namespace px4
{
enum class params : uint16_t {
	COM_FAIL_ACT_T, COM_POS_FS_ACT,
	NAV_DLL_ACT, NAV_RCL_ACT, COM_RCL_EXCEPT, COM_DLL_EXCEPT, COM_RC_IN_MODE, GF_ACTION, COM_SPOOLUP_TIME,
	CBRK_FLIGHTTERM, COM_ACT_FAIL_ACT, COM_LOW_BAT_ACT, COM_OBL_RC_ACT, COM_QC_ACT, COM_WIND_MAX_ACT,
	COM_POS_LOW_ACT, COM_ARM_ODID, COM_PARACHUTE, COM_TRAFF_AVOID, COM_GNSSLOSS_ACT, Count
};

// tipos: o param.h real confere por static_assert que ParamFloat/ParamInt batem com esta tabela
enum { PARAM_TYPE_INT32 = 1, PARAM_TYPE_FLOAT = 2 };
constexpr uint8_t parameters_type[] = {
	PARAM_TYPE_FLOAT /*COM_FAIL_ACT_T*/, PARAM_TYPE_INT32 /*COM_POS_FS_ACT*/,
	PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32,
	PARAM_TYPE_FLOAT /*COM_SPOOLUP_TIME*/,
	PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32,
	PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32, PARAM_TYPE_INT32
};
}
using px4::PARAM_TYPE_INT32;
using px4::PARAM_TYPE_FLOAT;

int param_get(param_t param, void *val);
int param_set(param_t param, const void *val);
int param_set_no_notification(param_t param, const void *val);
void param_get_mark_used(param_t param, void *val);
