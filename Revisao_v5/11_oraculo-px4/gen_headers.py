#!/usr/bin/env python3
"""Gera, a partir dos .msg REAIS do PX4, os cabecalhos uORB minimos de que o failsafe precisa.
Uso: python gen_headers.py <repo PX4> <pasta stubs>
Gera uORB/topics/failsafe_flags.h, vehicle_status.h e battery_status.h (so constantes e campos)."""
import os
import re
import sys

repo, out = sys.argv[1], sys.argv[2]
top = os.path.join(out, "uORB", "topics")
os.makedirs(top, exist_ok=True)
TYPES = {"bool": "bool", "uint8": "uint8_t", "uint16": "uint16_t", "uint32": "uint32_t", "uint64": "uint64_t",
         "int8": "int8_t", "int16": "int16_t", "int32": "int32_t", "int64": "int64_t", "float32": "float", "float64": "double"}


def parse(path):
    consts, fields = [], []
    for raw in open(path, encoding="utf8"):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        m = re.match(r"^(\w+)\s+(\w+)\s*=\s*([-\w.]+)$", line)
        if m:
            consts.append((TYPES[m.group(1)], m.group(2), m.group(3)))
            continue
        m = re.match(r"^(\w+)(\[\d+\])?\s+(\w+)$", line)
        if m and m.group(1) in TYPES:
            fields.append((TYPES[m.group(1)], m.group(3), m.group(2) or ""))
    return consts, fields


def emit(name, struct, src, extra=""):
    consts, fields = parse(src)
    with open(os.path.join(top, name + ".h"), "w", encoding="utf8", newline="\n") as f:
        f.write("// GERADO por gen_headers.py a partir de %s (PX4); so constantes e campos.\n#pragma once\n#include <stdint.h>\n" % os.path.relpath(src, repo).replace("\\", "/"))
        f.write(extra)
        f.write("struct %s {\n" % struct)
        for t, n, v in consts:
            f.write("\tstatic constexpr %s %s = %s;\n" % (t, n, v))
        for t, n, a in fields:
            f.write("\t%s %s%s{};\n" % (t, n, a) if not a else "\t%s %s%s{};\n" % (t, n, a))
        f.write("};\n")


emit("failsafe_flags", "failsafe_flags_s", os.path.join(repo, "msg", "FailsafeFlags.msg"), "typedef void *orb_advert_t;\n")
emit("vehicle_status", "vehicle_status_s", os.path.join(repo, "msg", "versioned", "VehicleStatus.msg"))
emit("battery_status", "battery_status_s", os.path.join(repo, "msg", "versioned", "BatteryStatus.msg"))
print("ok")
