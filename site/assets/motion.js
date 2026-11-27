/* Skyward site motion — a port of ReClash's runtime
   (shared/motion/core.ts + app/motion/{browser,scope}.js).

   One shared rAF loop drives every spring; springs drive the magnetic plates,
   the loader and the pointer effects, while CSS transitions handle the rest.
   Everything is progressive: without this file the page is complete. */
(function () {
  'use strict';

  const root = document.documentElement;
  const mq = matchMedia('(prefers-reduced-motion: reduce)');
  let reduced = mq.matches;
  root.classList.toggle('rm', reduced);

  const presets = {
    gentle: { stiffness: 120, damping: 22 },
    smooth: { stiffness: 230, damping: 30 },
    snappy: { stiffness: 440, damping: 38 },
    bouncy: { stiffness: 320, damping: 17 },
    jelly: { stiffness: 240, damping: 11 },
    scroll: { stiffness: 280, damping: 38 },
  };

  const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);

  /* ---------- one frame loop for every spring ---------- */
  const jobs = new Set();
  let frameId = 0;
  let last = 0;
  function request() {
    if (!frameId && jobs.size) frameId = requestAnimationFrame(frame);
  }
  function frame(time) {
    frameId = 0;
    let dt = (time - last) / 1000;
    last = time;
    if (!(dt > 0) || dt > 0.1) dt = 1 / 60;
    for (const job of [...jobs]) {
      if (jobs.has(job) && job(dt, time) === false) jobs.delete(job);
    }
    request();
  }
  function tick(job) {
    if (!jobs.size) last = 0;
    jobs.add(job);
    request();
    return () => {
      jobs.delete(job);
      if (!jobs.size && frameId) {
        cancelAnimationFrame(frameId);
        frameId = 0;
      }
    };
  }

  /* ---------- spring ---------- */
  class Spring {
    constructor(value, options = {}) {
      this.x = this.target = value;
      this.v = 0;
      this.k = 230;
      this.c = 30;
      this.m = 1;
      this.eps = 0.01;
      this.onUpdate = null;
      this.running = false;
      this.stop = null;
      this.config(options);
    }
    config(options = {}) {
      const p = options.preset ? presets[options.preset] : options;
      this.k = p.stiffness ?? this.k;
      this.c = p.damping ?? this.c;
      this.m = options.mass ?? this.m;
      this.eps = options.precision ?? this.eps;
      return this;
    }
    to(target, options) {
      if (options) this.config(options);
      this.target = target;
      if (reduced) return this.set(target);
      if (!this.running && Math.abs(this.x - target) < this.eps && Math.abs(this.v) < this.eps) return this;
      this.run();
      return this;
    }
    set(value) {
      if (this.stop) this.stop();
      this.stop = null;
      this.running = false;
      this.x = this.target = value;
      this.v = 0;
      if (this.onUpdate) this.onUpdate(value, 0);
      return this;
    }
    kick(dv) {
      if (!reduced) {
        this.v += dv;
        this.run();
      }
      return this;
    }
    run() {
      if (this.running) return;
      this.running = true;
      this.stop = tick((dt) => this.step(dt));
    }
    step(dt) {
      if (reduced) {
        this.set(this.target);
        return false;
      }
      const n = Math.ceil(dt * 240);
      const h = dt / n;
      for (let i = 0; i < n; i++) {
        this.v += ((-this.k * (this.x - this.target) - this.c * this.v) / this.m) * h;
        this.x += this.v * h;
      }
      const done = Math.abs(this.v) < this.eps && Math.abs(this.x - this.target) < this.eps;
      if (done) {
        this.x = this.target;
        this.v = 0;
      }
      if (this.onUpdate) this.onUpdate(this.x, this.v);
      if (done) {
        this.running = false;
        this.stop = null;
        return false;
      }
    }
  }

  function spring(value = 0, options = {}) {
    return new Spring(value, options);
  }

  /* ---------- batched style writes ---------- */
  const writes = new Map();
  let queued = false;
  function write(key, fn) {
    writes.set(key, fn);
    if (queued) return;
    queued = true;
    queueMicrotask(() => {
      queued = false;
      const list = [...writes.values()];
      writes.clear();
      for (const run of list) run();
    });
  }

  /* ---------- tiny scope: listeners and observers ---------- */
  const cleanups = [];
  function listen(target, type, fn, options) {
    target.addEventListener(type, fn, options);
    cleanups.push(() => target.removeEventListener(type, fn, options));
  }
  function observe(fn, options) {
    const io = new IntersectionObserver(fn, options);
    cleanups.push(() => io.disconnect());
    return io;
  }
  function frameJob(fn) {
    return tick(() => {
      fn();
      return false;
    });
  }
  function animate(el, frames, options) {
    return el.animate(frames, options);
  }

  /* ---------- magnetic plate ----------
     One plate per group, each edge on its own spring, so it stays glued to the
     hovered item: the leading edge arrives first and the plate never leans. */
  let uid = 0;
  function magnetGroup(group, options = {}) {
    const { items = '[data-mg]', contentPull = 0.08, className = 'mg-ind', sticky = false } = options;
    const key = `mg${++uid}`;
    const ind = document.createElement('span');
    ind.className = className;
    ind.setAttribute('aria-hidden', 'true');
    group.prepend(ind);

    const edge = () => spring(0, { stiffness: 260, damping: 20, precision: 0.05 });
    const E = { l: edge(), r: edge(), t: edge(), b: edge() };
    const O = spring(0, { preset: 'snappy', precision: 0.003 });

    const render = () => {
      ind.style.width = `${Math.max(0, E.r.x - E.l.x)}px`;
      ind.style.height = `${Math.max(0, E.b.x - E.t.x)}px`;
      ind.style.transform = `translate3d(${E.l.x}px, ${E.t.x}px, 0)`;
      ind.style.opacity = O.x;
    };
    for (const s of [...Object.values(E), O]) s.onUpdate = () => write(key, render);

    let active = null;
    let selected = null;
    let hovered = false;

    function rect(el) {
      const g = group.getBoundingClientRect();
      const r = el.getBoundingClientRect();
      return {
        l: r.left - g.left - group.clientLeft + group.scrollLeft,
        r: r.left - g.left + r.width - group.clientLeft + group.scrollLeft,
        t: r.top - g.top - group.clientTop + group.scrollTop,
        b: r.top - g.top + r.height - group.clientTop + group.scrollTop,
      };
    }
    function travel(a, b, from, to) {
      const forward = to > from;
      const lead = { stiffness: 420, damping: 2 * Math.sqrt(420) * 0.72 };
      const tail = { stiffness: 170, damping: 2 * Math.sqrt(170) * 0.72 };
      a.config(forward ? tail : lead);
      b.config(forward ? lead : tail);
    }
    function go(el, e, instant = false) {
      const r = rect(el);
      const hidden = O.x < 0.04 && O.target === 0;
      if (hidden || instant) {
        for (const k in E) E[k].set(r[k]);
      } else {
        travel(E.l, E.r, E.l.target, r.l);
        travel(E.t, E.b, E.t.target, r.t);
        for (const k in E) E[k].to(r[k]);
      }
      O.to(1);
      if (active !== el) {
        if (active) {
          active.classList.remove('is-mg');
          active.style.removeProperty('--mx');
          active.style.removeProperty('--my');
        }
        el.classList.add('is-mg');
        active = el;
      }
      if (e && contentPull && !reduced) {
        const box = el.getBoundingClientRect();
        el.style.setProperty('--mx', `${(e.clientX - box.left - box.width / 2) * contentPull}px`);
        el.style.setProperty('--my', `${(e.clientY - box.top - box.height / 2) * contentPull}px`);
      }
    }
    function leave() {
      hovered = false;
      if (active) {
        active.classList.remove('is-mg');
        active.style.removeProperty('--mx');
        active.style.removeProperty('--my');
        active = null;
      }
      if (sticky && selected && selected.isConnected) return go(selected);
      O.to(0);
    }
    function pick(e) {
      const it = e.target.closest ? e.target.closest(items) : null;
      return it && group.contains(it) ? it : null;
    }
    listen(group, 'pointermove', (e) => {
      if (e.pointerType === 'touch') return;
      const it = pick(e);
      if (it) {
        hovered = true;
        go(it, e);
      } else if (active && !sticky) {
        leave();
      }
    });
    listen(group, 'pointerleave', leave);
    listen(group, 'focusin', (e) => {
      const it = pick(e);
      if (it) {
        hovered = true;
        go(it);
      }
    });
    listen(group, 'focusout', (e) => {
      if (!group.contains(e.relatedTarget)) leave();
    });
    // Fonts, wrapping and async content move the items: snap the plate back.
    const snap = () => {
      const el = active || selected;
      if (el && el.isConnected && O.target) go(el, null, true);
    };
    listen(window, 'resize', snap);
    if ('ResizeObserver' in window) new ResizeObserver(snap).observe(group);

    return {
      el: ind,
      select(el) {
        selected = el;
        if (hovered) return;
        if (el) go(el);
        else leave();
      },
      refresh: snap,
    };
  }

  /* ---------- path morph between two same-layout paths ---------- */
  const NUM = /-?\d*\.?\d+(?:e-?\d+)?/gi;
  function morph(pathEl, preset = 'bouncy') {
    let from = null;
    let to = null;
    let tpl = null;
    const s = spring(1, { preset, precision: 0.001 });
    s.onUpdate = (t) => {
      if (!to) return;
      let i = 0;
      pathEl.setAttribute('d', tpl.replace(NUM, () => {
        const value = from[i] + (to[i] - from[i]) * t;
        i++;
        return value.toFixed(2);
      }));
    };
    return {
      to(d) {
        const next = d.match(NUM).map(Number);
        const cur = (pathEl.getAttribute('d') || d).match(NUM).map(Number);
        if (cur.length !== next.length) {
          pathEl.setAttribute('d', d);
          return;
        }
        from = cur;
        to = next;
        tpl = d;
        s.set(0);
        s.to(1);
      },
    };
  }

  /* ---------- text: split into words, each on its own delay ---------- */
  function splitWords(el) {
    if (el.dataset.split) return el;
    el.dataset.split = '1';
    let i = 0;
    const walk = (node) => {
      for (const child of [...node.childNodes]) {
        if (child.nodeType === 3) {
          const parts = child.textContent.split(/(\s+)/);
          const frag = document.createDocumentFragment();
          for (const part of parts) {
            if (!part) continue;
            if (/^\s+$/.test(part)) {
              frag.append(' ');
              continue;
            }
            const outer = document.createElement('span');
            outer.className = 'w';
            const inner = document.createElement('span');
            inner.className = 'wi';
            inner.style.setProperty('--i', i++);
            inner.textContent = part;
            outer.append(inner);
            frag.append(outer);
          }
          child.replaceWith(frag);
        } else if (child.nodeType === 1 && !child.matches('br')) {
          walk(child);
        }
      }
    };
    walk(el);
    return el;
  }

  /* ---------- once-only reveal ---------- */
  function reveal(list, fn = (el) => el.classList.add('is-in'), opts = {}) {
    if (!('IntersectionObserver' in window)) {
      list.forEach(fn);
      return;
    }
    const io = observe(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          io.unobserve(e.target);
          fn(e.target);
        }
      },
      { threshold: opts.threshold ?? 0.2, rootMargin: opts.rootMargin ?? '0px 0px -8% 0px' },
    );
    list.forEach((el) => io.observe(el));
  }

  /* ---------- coalesced scroll hook ---------- */
  function onScroll(fn) {
    let queued = false;
    const run = () => {
      queued = false;
      fn(scrollY);
    };
    const req = () => {
      if (queued) return;
      queued = true;
      frameJob(run);
    };
    listen(window, 'scroll', req, { passive: true });
    listen(window, 'resize', req);
    req();
  }

  /* ---------- closed smooth blob path (hero ring, decorative shapes) ---------- */
  function blobPath(cx, cy, radii, rot = -Math.PI / 2) {
    const n = radii.length;
    const px = [];
    const py = [];
    for (let i = 0; i < n; i++) {
      const a = rot + (i / n) * Math.PI * 2;
      px.push(cx + Math.cos(a) * radii[i]);
      py.push(cy + Math.sin(a) * radii[i]);
    }
    const f = (v) => v.toFixed(1);
    let d = `M${f(px[0])} ${f(py[0])}`;
    for (let i = 0; i < n; i++) {
      const i0 = (i - 1 + n) % n;
      const i2 = (i + 1) % n;
      const i3 = (i + 2) % n;
      d += `C${f(px[i] + (px[i2] - px[i0]) / 6)} ${f(py[i] + (py[i2] - py[i0]) / 6)} ${f(px[i2] - (px[i3] - px[i]) / 6)} ${f(py[i2] - (py[i3] - py[i]) / 6)} ${f(px[i2])} ${f(py[i2])}`;
    }
    return `${d}Z`;
  }

  /* ---------- turn the CSS easing tokens into spring-shaped curves ----------
     The stylesheet's transitions then settle like the springs do. */
  function cssEase(preset, samples = 56) {
    const p = typeof preset === 'string' ? presets[preset] : preset;
    const h = 1 / 1200;
    const out = [[0, 0]];
    let x = 0;
    let v = 0;
    let t = 0;
    while (t < 3) {
      for (let i = 0; i < 10; i++) {
        v += (-p.stiffness * (x - 1) - p.damping * v) * h;
        x += v * h;
        t += h;
      }
      out.push([t, x]);
      if (Math.abs(x - 1) < 0.0015 && Math.abs(v) < 0.02) break;
    }
    const stride = Math.max(1, Math.round(out.length / samples));
    const points = [];
    for (let i = 0; i < out.length; i += stride) points.push(out[i]);
    points.push([t, 1]);
    return {
      easing: `linear(${points.map(([tt, xx]) => `${+xx.toFixed(4)} ${+((tt / t) * 100).toFixed(2)}%`).join(', ')})`,
      duration: Math.round(t * 1000),
    };
  }
  function installEasings(names = Object.keys(presets)) {
    if (!CSS.supports('transition-timing-function', 'linear(0, 1)')) return;
    for (const name of names) {
      const ease = cssEase(name);
      root.style.setProperty(`--ease-${name}`, ease.easing);
      root.style.setProperty(`--dur-${name}`, `${ease.duration}ms`);
    }
  }

  listen(mq, 'change', (e) => {
    reduced = e.matches;
    root.classList.toggle('rm', e.matches);
    if (e.matches) {
      root.getAnimations({ subtree: true }).forEach((a) => a.cancel());
    }
  });

  globalThis.SkywardMotion = {
    clamp,
    spring,
    tick,
    write,
    listen,
    observe,
    frame: frameJob,
    animate,
    magnetGroup,
    morph,
    splitWords,
    reveal,
    onScroll,
    blobPath,
    cssEase,
    installEasings,
    get reduced() {
      return reduced;
    },
  };
})();
