// O2 (plano v2, T13): valida, no SCION (scxml 4.3.1), os traços da implementação em CREM exportados por
// validation-export (TraceData.tla + tracos.csv). Para cada traço, o SCXML (avionics_loop.scxml) recebe os
// mesmos eventos externos de cada tick (Beat, comando, energia) e o observador registra o terno
// (aviônica, bateria, ambiente) depois de CADA SINAL (um passo por evento "de sinal"; os eventos cue_* que o
// SCXML usa internamente não contam como passo). O traço é ACEITO se os ternos coincidem passo a passo e o
// número de passos por tick é o mesmo.
//
// Uso:  SCXML_DIR=<pasta onde `npm install scxml@4.3.1 --ignore-scripts` foi feito> \
//       node scion_oracle.js <TraceData.tla> <tracos.csv> [avionics_loop.scxml]
// Saída: contagem por tipo de traço; código de saída 0 se todos os de aresta e aleatórios forem aceitos e
// todos os corrompidos recusados.
'use strict';
const fs = require('fs');
const path = require('path');
const scxml = require(path.join(process.env.SCXML_DIR || '.', 'node_modules', 'scxml'));

const [traceFile, csvFile, scxmlFile = path.join(__dirname, 'avionics_loop.scxml')] = process.argv.slice(2);
const AV = ['Grounded', 'InFlight', 'EmergencyLanding', 'Shutdown'];
const PW = ['Charged', 'Low', 'Critical'];
const MS = ['Standby', 'CriticalHeld', 'TouchdownHeld', 'CutoffHeld'];
const CMD = [null, 'TakeoffSignal', 'CriticalBattery', 'LandedSignal', 'SystemCutoff'];
const PWE = [null, 'Drain', 'Recharge', 'ShedLoad'];
const SIGNALS = new Set(['Beat', 'TakeoffSignal', 'CriticalBattery', 'LandedSignal', 'SystemCutoff', 'Drain', 'Recharge', 'ShedLoad']);

// --- traços: um por linha de nível superior de TraceData.tla
const text = fs.readFileSync(traceFile, 'utf8').split('\r\n').join('\n');
const body = text.slice(text.indexOf('Traces == <<') + 'Traces == <<'.length, text.lastIndexOf('>>\n===='));
const traces = body.split(/,\n  (?=<<)/).map(b => {
  const ticks = [];
  const re = /<<(\d+),(\d+), <<([\d,]*)>>>>/g;
  let m;
  while ((m = re.exec(b)) !== null) ticks.push({ c: +m[1], p: +m[2], steps: m[3] === '' ? [] : m[3].split(',').map(Number) });
  return ticks;
});
const rows = fs.readFileSync(csvFile, 'utf8').trim().split(/\r?\n/).slice(1).map(l => l.split(','));
if (rows.length !== traces.length) { console.error('número de traços difere do CSV', rows.length, traces.length); process.exit(2); }

scxml.pathToModel(scxmlFile, (err, model) => {
  if (err) { console.error(err); process.exit(2); }
  model.prepare((err2, fnModel) => {
    if (err2) { console.error(err2); process.exit(2); }

    function triple(sc) {
      const conf = sc.getConfiguration();
      const pick = names => names.findIndex(n => conf.includes(n));
      return 100 * pick(AV) + 10 * pick(PW) + pick(MS);
    }

    function runTrace(ticks) {
      const sc = new scxml.scion.Statechart(fnModel);
      let cur = null;           // passo em curso: ainda não fechado
      let tickSteps = [];
      const close = () => { if (cur !== null) { tickSteps.push(triple(sc)); cur = null; } };
      sc.on('onSmallStepBegin', ev => { if (ev && SIGNALS.has(ev.name)) { close(); cur = ev.name; } });
      sc.on('onBigStepEnd', () => close());
      sc.start();
      const got = [];
      for (const t of ticks) {
        tickSteps = [];
        sc.gen({ name: 'Beat' });
        if (CMD[t.c]) sc.gen({ name: CMD[t.c] });
        if (PWE[t.p]) sc.gen({ name: PWE[t.p] });
        got.push(tickSteps);
      }
      return got;
    }

    const accepted = [];
    const count = {};
    const bad = [];
    traces.forEach((ticks, i) => {
      const kind = rows[i][2];
      const got = runTrace(ticks);
      const ok = ticks.every((t, k) => got[k].length === t.steps.length && got[k].every((v, j) => v === t.steps[j]));
      count[kind] = count[kind] || { n: 0, ok: 0 };
      count[kind].n++;
      if (ok) { count[kind].ok++; accepted.push(rows[i][1]); }
      if ((kind !== 'corrompido') !== ok && bad.length < 10) bad.push(rows[i][1]);
    });
    if (process.env.ACCEPT_LIST) fs.writeFileSync(process.env.ACCEPT_LIST, accepted.join('\n') + '\n');
    for (const k of Object.keys(count)) console.log(`${k.padEnd(12)} traços: ${String(count[k].n).padStart(4)}  aceitos: ${String(count[k].ok).padStart(4)}  recusados: ${String(count[k].n - count[k].ok).padStart(4)}`);
    const good = ['aresta', 'aleatorio30'].every(k => count[k] && count[k].ok === count[k].n) && count['corrompido'] && count['corrompido'].ok === 0;
    console.log('ESPERADO (todos os traços da implementação aceitos pelo SCION; todos os corrompidos recusados):', good ? 'CONFERE' : 'NAO CONFERE');
    if (!good) console.log('traços divergentes (primeiros 10):', bad.join(' '));
    process.exit(good ? 0 : 1);
  });
});
