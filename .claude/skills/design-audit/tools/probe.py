#!/usr/bin/env python3
"""Render probes for the design-audit skill.

Every claim the skill makes about layout, contrast, focus, targets or layout
shift is measured here in real headless Chromium, never inferred from the
cascade. Output is JSON on stdout so a report can quote before-and-after pairs.

Fixtures are the generated pages in samples/. They are read, never written.

  python3 probe.py sweep      --fixtures samples/dark.html ... --out sweep.json
  python3 probe.py components --fixtures samples/dark-charts.html --out comp.json
  python3 probe.py a11y       --fixtures samples/dark.html --out a11y.json
  python3 probe.py perf       --fixtures samples/light-charts.html --out perf.json

Run from anywhere. Paths are resolved from the repo root. Set $CHROME to the
browser binary; Microsoft Edge is the expected fallback on a Mac with no Chrome.
"""
import argparse
import json
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from cdp import Browser

ROOT = pathlib.Path(__file__).resolve().parents[4]

SWEEP_JS = r"""
(() => {
  const de = document.documentElement;
  const hatches = Array.from(document.querySelectorAll('pre, .table-scroll, math, .math, pre.mermaid'))
    .filter(el => {
      const cs = getComputedStyle(el);
      return cs.overflowX !== 'visible' || el.scrollWidth > el.clientWidth + 1;
    });
  const overflow = [];
  for (const el of document.body.querySelectorAll('*')) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) continue;
    if (r.right > de.clientWidth + 1 || r.left < -1) {
      let inHatch = false;
      for (const h of hatches) if (h.contains(el)) { inHatch = true; break; }
      overflow.push({tag: el.tagName.toLowerCase(), cls: (el.className || '').toString().slice(0, 60),
        left: +r.left.toFixed(1), right: +r.right.toFixed(1), inHatch});
    }
  }
  const targets = [];
  for (const el of document.querySelectorAll('a[href], button, input, summary, [tabindex]:not([tabindex="-1"])')) {
    const r = el.getBoundingClientRect();
    if (!r.width && !r.height) continue;
    targets.push({tag: el.tagName.toLowerCase(), id: el.id || null,
      name: (el.getAttribute('aria-label') || el.textContent || '').trim().slice(0, 48),
      w: +r.width.toFixed(1), h: +r.height.toFixed(1)});
  }
  return JSON.stringify({
    viewport: {w: innerWidth, h: innerHeight},
    scrollWidth: de.scrollWidth, clientWidth: de.clientWidth, bodyScrollWidth: document.body.scrollWidth,
    overflow, targets, season: de.getAttribute('data-season'),
    scripts: document.querySelectorAll('script').length,
    title: document.title, lang: de.getAttribute('lang')
  });
})()
"""

COMPONENTS_JS = r"""
(() => {
  const q = (s) => document.querySelector(s);
  const cs = (s, p) => { const el = q(s); return el ? getComputedStyle(el, p || null) : null; };
  const box = (s) => { const el = q(s); if (!el) return null; const r = el.getBoundingClientRect();
    return {left: +r.left.toFixed(1), width: +r.width.toFixed(1), right: +r.right.toFixed(1), height: +r.height.toFixed(1)}; };
  const out = {dir: document.documentElement.dir || 'ltr', title: document.title,
    season: document.documentElement.getAttribute('data-season'),
    snippet: !!Array.from(document.querySelectorAll('script:not([type])')).find(s => s.textContent.includes('data-season')),
    scripts: document.querySelectorAll('script').length,
    moduleScripts: document.querySelectorAll('script[type=module]').length,
    type: {}, meters: [], dots: []};
  for (const s of ['body', 'article p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'th', 'code',
                   'dl.meter dt', 'dl.meter .v', 'dl.meter .s', '.chart-takeaway']) {
    const c = cs(s);
    if (c) out.type[s] = {size: c.fontSize, weight: c.fontWeight, style: c.fontStyle, lineHeight: c.lineHeight, color: c.color};
  }
  const m = q('dl.meter');
  if (m) {
    const after = getComputedStyle(m, '::after');
    out.meters.push({bar: m.style.getPropertyValue('--bar'),
      after: {size: after.backgroundSize, position: after.backgroundPosition,
              image: after.backgroundImage.slice(0, 120), border: after.borderTopWidth + ' ' + after.borderTopStyle},
      grid: getComputedStyle(m).gridTemplateColumns,
      dl: box('dl.meter'), value: box('dl.meter .v'), gloss: box('dl.meter .s')});
    const second = document.querySelectorAll('dl.meter')[1];
    if (second) out.meters.push({secondValueRight: +second.querySelector('dd.v').getBoundingClientRect().right.toFixed(1)});
  }
  for (const d of document.querySelectorAll('td.dot')) {
    const c = getComputedStyle(d);
    out.dots.push({bar: d.style.getPropertyValue('--bar'), size: c.backgroundSize,
      position: c.backgroundPosition, image: c.backgroundImage.slice(0, 160),
      width: +d.getBoundingClientRect().width.toFixed(1), textLength: d.textContent.length});
  }
  const t = q('table.bar-chart td.dot');
  if (t) out.dotRow = Array.from(t.closest('tr').children).map(c => ({tag: c.tagName,
    cls: c.className, text: (c.textContent || '').trim(), width: +c.getBoundingClientRect().width.toFixed(1)}));
  return JSON.stringify(out);
})()
"""

PRINT_JS = r"""
(() => {
  const m = document.querySelector('dl.meter');
  const after = m ? getComputedStyle(m, '::after') : null;
  const t = document.querySelector('table.bar-chart');
  const d = document.querySelector('td.dot');
  return JSON.stringify({
    meterFill: after ? after.backgroundImage.slice(0, 80) : null,
    meterPrintAdjust: after ? after.printColorAdjust : null,
    meterBreak: m ? getComputedStyle(m).breakInside : null,
    tableBackground: t ? getComputedStyle(t).backgroundColor : null,
    dotPrintAdjust: d ? getComputedStyle(d).printColorAdjust : null
  });
})()
"""

FOCUS_JS = r"""
(() => {
  const a = document.activeElement;
  if (!a || a === document.body) return JSON.stringify({tag: 'BODY'});
  const cs = getComputedStyle(a);
  const r = a.getBoundingClientRect();
  return JSON.stringify({tag: a.tagName, id: a.id || null,
    name: (a.getAttribute('aria-label') || a.textContent || '').trim().slice(0, 40),
    outline: cs.outline, boxShadow: cs.boxShadow, visible: r.width > 0 && r.height > 0});
})()
"""

TARGETS_JS = r"""
(() => {
  const rows = [];
  for (const el of document.querySelectorAll('a[href], button, input, summary, [tabindex]:not([tabindex="-1"])')) {
    const r = el.getBoundingClientRect();
    if (!r.width || !r.height) continue;
    const cs = getComputedStyle(el);
    const parent = el.parentElement;
    const inlineText = cs.display === 'inline' && parent &&
      /^(P|LI|TD|DD|SPAN|BLOCKQUOTE|H[1-6])$/.test(parent.tagName);
    rows.push({tag: el.tagName, type: el.type || null, w: +r.width.toFixed(1), h: +r.height.toFixed(1),
      x: +r.left.toFixed(1), y: +r.top.toFixed(1), display: cs.display,
      inlineText, text: (el.textContent || '').trim().slice(0, 30)});
  }
  const small = rows.filter(r => r.w < 24 || r.h < 24);
  const candidates = small.filter(r => !r.inlineText && r.tag !== 'INPUT' && r.tag !== 'SELECT');
  const overlaps = [];
  for (let i = 0; i < candidates.length; i++) {
    for (let j = i + 1; j < candidates.length; j++) {
      const a = candidates[i], b = candidates[j];
      const dx = (a.x + a.w / 2) - (b.x + b.w / 2);
      const dy = (a.y + a.h / 2) - (b.y + b.h / 2);
      const d = Math.hypot(dx, dy);
      if (d < 24) overlaps.push({a: a.text || a.tag, b: b.text || b.tag, distance: +d.toFixed(1)});
    }
  }
  return JSON.stringify({total: rows.length, small: small.length,
    under44: rows.filter(r => r.w < 44 || r.h < 44).length,
    inputs: rows.filter(r => r.tag === 'INPUT'),
    spacingCandidates: candidates, circleOverlaps: overlaps});
})()
"""

CLS_JS = r"""
if (!window.__shifts) {
  window.__shifts = [];
  window.__lcp = null;
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) if (!entry.hadRecentInput) {
      window.__shifts.push({value: entry.value, time: Math.round(entry.startTime),
        sources: (entry.sources || []).map((s) => s.node ? s.node.nodeName : null)});
    }
  }).observe({type: 'layout-shift', buffered: true});
  new PerformanceObserver((list) => {
    const entries = list.getEntries();
    if (entries.length) window.__lcp = Math.round(entries[entries.length - 1].startTime);
  }).observe({type: 'largest-contentful-paint', buffered: true});
}
"""


def fixture_url(name):
    path = pathlib.Path(name)
    if not path.is_absolute():
        path = ROOT / path
    return path.as_uri()


def dedupe(rows):
    seen, out = set(), []
    for row in rows:
        key = (row.get("tag"), row.get("cls"), row.get("left"), row.get("right"))
        if key not in seen:
            seen.add(key)
            out.append(row)
    return out


def sweep(page, fixtures, widths, heights):
    results = []
    for fixture in fixtures:
        for width in widths:
            for height in heights:
                page.load(fixture_url(fixture), width=width, height=height)
                data = page.json(SWEEP_JS)
                data.update({"fixture": fixture, "requested": [width, height]})
                data["overflowNonHatch"] = dedupe([o for o in data["overflow"] if not o["inHatch"]])
                results.append(data)
    return results


def components(page, fixtures):
    out = {}
    for fixture in fixtures:
        page.load(fixture_url(fixture), 1280, 900)
        out[fixture] = {"desktop": page.json(COMPONENTS_JS)}
        out[fixture]["rtl"] = None
        page.evaluate("document.documentElement.setAttribute('dir', 'rtl')")
        time.sleep(0.3)
        out[fixture]["rtl"] = page.json(COMPONENTS_JS)
        page.load(fixture_url(fixture), 320, 568)
        out[fixture]["narrow"] = page.json(COMPONENTS_JS)
        page.load(fixture_url(fixture), 1280, 900, media="print")
        out[fixture]["print"] = page.json(PRINT_JS)
    return out


def tab_order(page, limit=250):
    rows = []
    page.evaluate("document.activeElement && document.activeElement.blur()")
    for _ in range(limit):
        page.call("Input.dispatchKeyEvent", type="keyDown", key="Tab", code="Tab", windowsVirtualKeyCode=9)
        page.call("Input.dispatchKeyEvent", type="keyUp", key="Tab", code="Tab", windowsVirtualKeyCode=9)
        info = json.loads(page.evaluate(FOCUS_JS))
        rows.append(info)
        if info.get("tag") == "BODY":
            break
    return rows


def press_escape(page):
    page.call("Input.dispatchKeyEvent", type="rawKeyDown", key="Escape", code="Escape",
              windowsVirtualKeyCode=27, nativeVirtualKeyCode=53)
    page.call("Input.dispatchKeyEvent", type="keyUp", key="Escape", code="Escape",
              windowsVirtualKeyCode=27, nativeVirtualKeyCode=53)
    time.sleep(0.4)


def a11y(page, fixtures):
    out = {}
    for fixture in fixtures:
        data = {}
        page.load(fixture_url(fixture), 1280, 900)
        rows = tab_order(page)
        data["tab"] = {
            "count": len(rows),
            "stops": rows,
            "noVisibleFocus": [r for r in rows if r.get("tag") not in (None, "BODY")
                               and (r.get("outline", "none").startswith("none") or r.get("outline") == "")
                               and r.get("boxShadow") == "none"],
        }
        data["targets"] = page.json(TARGETS_JS)

        data["filter"] = page.json(r"""
        (() => {
          const input = document.querySelector('.filter-box');
          if (!input) return JSON.stringify({present: false});
          const label = document.querySelector('.filter-label') || document.querySelector('label[for="' + input.id + '"]');
          const status = document.querySelector('[role=status]');
          const before = status ? status.textContent : null;
          input.focus();
          input.value = 'zzz';
          input.dispatchEvent(new Event('input', {bubbles: true}));
          const after = status ? status.textContent : null;
          input.value = '';
          input.dispatchEvent(new Event('input', {bubbles: true}));
          return JSON.stringify({present: true, labelFor: label && label.getAttribute('for'),
            inputId: input.id, statusRole: status && status.getAttribute('role'),
            before, after});
        })()
        """)

        page.load(fixture_url(fixture), 1280, 900, settle=3.0)
        data["zoom"] = page.json(r"""
        (() => {
          const button = document.querySelector('.mermaid-zoom');
          if (!button) return JSON.stringify({present: false});
          button.focus();
          button.click();
          const dialog = document.getElementById('mermaid-zoom');
          return JSON.stringify({present: true, open: dialog && dialog.open,
            modal: dialog && dialog.matches(':modal'),
            label: dialog && dialog.getAttribute('aria-label'),
            buttonText: button.textContent.trim(), buttonLabel: button.getAttribute('aria-label'),
            active: document.activeElement.tagName + '.' + (document.activeElement.className || '')});
        })()
        """)
        press_escape(page)
        data["zoomAfterEscape"] = page.json(r"""
        (() => {
          const dialog = document.getElementById('mermaid-zoom');
          return JSON.stringify({open: dialog && dialog.open, htmlLength: dialog && dialog.innerHTML.length,
            active: document.activeElement.tagName + '.' + (document.activeElement.className || '')});
        })()
        """)

        page.load(fixture_url(fixture), 1280, 900,
                  features=[{"name": "forced-colors", "value": "active"}])
        data["forcedColors"] = page.json(r"""
        (() => {
          const meter = document.querySelector('dl.meter');
          const dot = document.querySelector('td.dot');
          const after = meter && getComputedStyle(meter, '::after');
          return JSON.stringify({matches: matchMedia('(forced-colors: active)').matches,
            meterTrack: after && after.borderTopStyle + ' ' + after.borderTopWidth,
            meterFill: after && after.backgroundImage,
            dotFill: dot && getComputedStyle(dot).backgroundImage});
        })()
        """)

        page.load(fixture_url(fixture), 1280, 900,
                  features=[{"name": "prefers-reduced-motion", "value": "reduce"}])
        data["reducedMotion"] = page.json(r"""
        (() => {
          const html = getComputedStyle(document.documentElement);
          const button = document.querySelector('.mermaid-zoom');
          return JSON.stringify({matches: matchMedia('(prefers-reduced-motion: reduce)').matches,
            htmlTransition: html.transitionDuration,
            buttonTransition: button ? getComputedStyle(button).transitionDuration : null});
        })()
        """)

        page.load(fixture_url(fixture), 1280, 900)
        data["textSpacing"] = page.json(r"""
        (() => {
          const style = document.createElement('style');
          style.textContent = '* { line-height: 1.5 !important; letter-spacing: 0.12em !important; word-spacing: 0.16em !important; } p { margin-bottom: 2em !important; }';
          document.head.appendChild(style);
          return new Promise(r => setTimeout(() => {
            const de = document.documentElement;
            r(JSON.stringify({clientWidth: de.clientWidth, scrollWidth: de.scrollWidth}));
          }, 200));
        })()
        """, await_promise=True)

        page.load(fixture_url(fixture), 1280, 900)
        data["textZoom200"] = page.json(r"""
        (() => {
          document.documentElement.style.fontSize = '32px';
          return new Promise(r => setTimeout(() => {
            const de = document.documentElement;
            r(JSON.stringify({clientWidth: de.clientWidth, scrollWidth: de.scrollWidth}));
          }, 200));
        })()
        """, await_promise=True)

        page.load(fixture_url(fixture), 320, 568)
        data["textZoom200At320"] = page.json(r"""
        (() => {
          document.documentElement.style.fontSize = '32px';
          return new Promise(r => setTimeout(() => {
            const de = document.documentElement;
            r(JSON.stringify({clientWidth: de.clientWidth, scrollWidth: de.scrollWidth}));
          }, 200));
        })()
        """, await_promise=True)

        out[fixture] = data
    return out


def measure_cls(page, fixture, block=None, cpu=4, settle=8):
    page.call("Emulation.setCPUThrottlingRate", rate=cpu)
    page.call("Network.setBlockedURLs", urls=block or [])
    page.call("Page.navigate", url="about:blank")
    page.wait_event("Page.loadEventFired")
    if getattr(page, "observer_script", None):
        page.call("Page.removeScriptToEvaluateOnNewDocument", identifier=page.observer_script)
    added = page.call("Page.addScriptToEvaluateOnNewDocument", source=CLS_JS)
    page.observer_script = added["identifier"]
    page.load(fixture_url(fixture), 1280, 900, wait_fonts=False, settle=settle, scroll_top=False)
    value = page.json("JSON.stringify({cls: +window.__shifts.reduce((a, b) => a + b.value, 0).toFixed(4), lcp: window.__lcp, shifts: window.__shifts})")
    page.call("Network.setBlockedURLs", urls=[])
    page.call("Emulation.setCPUThrottlingRate", rate=1)
    return value


def perf(page, fixtures):
    out = {}
    page.call("DOM.enable")
    page.call("CSS.enable")
    page.call("Network.setCacheDisabled", cacheDisabled=True)
    for fixture in fixtures:
        data = {}
        page.call("CSS.startRuleUsageTracking")
        page.load(fixture_url(fixture), 1280, 900, settle=4)
        usage = page.call("CSS.stopRuleUsageTracking")["ruleUsage"]
        used = sum(1 for rule in usage if rule["used"])
        data["coverage"] = {"rules": len(usage), "used": used, "unused": len(usage) - used}

        data["timing"] = page.json(r"""
        (() => {
          const nav = performance.getEntriesByType('navigation')[0] || {};
          const paints = Object.fromEntries(performance.getEntriesByType('paint').map(p => [p.name, Math.round(p.startTime)]));
          const lcpEntries = performance.getEntriesByType('largest-contentful-paint');
          const lcp = lcpEntries.length ? Math.round(lcpEntries[lcpEntries.length - 1].startTime) : null;
          const resources = performance.getEntriesByType('resource');
          return JSON.stringify({domContentLoaded: Math.round(nav.domContentLoadedEventEnd || 0),
            load: Math.round(nav.loadEventEnd || 0), paints, lcp,
            resourceCount: resources.length,
            transferBytes: resources.reduce((a, r) => a + (r.transferSize || 0), 0),
            thirdParty: [...new Set(resources.map(r => { try { return new URL(r.name).host; } catch { return 'data'; } }))]});
        })()
        """)

        data["clsAll"] = measure_cls(page, fixture)
        data["clsFontsBlocked"] = measure_cls(page, fixture, block=["*source-serif-4*", "*jetbrains-mono*"])
        data["clsMermaidBlocked"] = measure_cls(page, fixture, block=["*mermaid*"])
        out[fixture] = data
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("command", choices=["sweep", "components", "a11y", "perf"])
    parser.add_argument("--fixtures", nargs="+", required=True)
    parser.add_argument("--widths", nargs="+", type=int, default=[320, 375, 768, 1024, 1280])
    parser.add_argument("--heights", nargs="+", type=int, default=[568, 768, 900])
    parser.add_argument("--out", help="write JSON here as well as printing a summary")
    parser.add_argument("--port", type=int, default=9222)
    args = parser.parse_args()

    with Browser(port=args.port) as browser:
        page = browser.page()
        if args.command == "sweep":
            result = sweep(page, args.fixtures, args.widths, args.heights)
        elif args.command == "components":
            result = components(page, args.fixtures)
        elif args.command == "a11y":
            result = a11y(page, args.fixtures)
        else:
            result = perf(page, args.fixtures)

    payload = json.dumps(result, indent=1)
    if args.out:
        pathlib.Path(args.out).write_text(payload)
    if args.command == "sweep":
        for row in result:
            print(f"{row['fixture']:34s} {row['requested'][0]}x{row['requested'][1]}: "
                  f"scrollWidth={row['scrollWidth']} clientWidth={row['clientWidth']} "
                  f"nonHatchOverflow={len(row['overflowNonHatch'])}")
    else:
        print(payload)


if __name__ == "__main__":
    main()
