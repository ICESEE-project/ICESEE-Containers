#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
from pathlib import Path
import tomllib

PIP_EXCLUDE = {
    "h5py",
    "setuptools",
    "wheel",
    "pip",
    "python",
    "jax",
    "jaxlib",
    "mpi4py",
    "petsc4py",
}

def norm(name: str) -> str:
    return re.split(r"[<>=!~ \[]", name.strip(), maxsplit=1)[0].lower().replace("_", "-")

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pyproject", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--extras", default="", help="Comma-separated extras, e.g. mpi,viz,dev")
    args = ap.parse_args()

    data = tomllib.loads(args.pyproject.read_text(encoding="utf-8"))
    proj = data.get("project", {})

    deps: list[str] = list(proj.get("dependencies", []))
    extras = [e.strip() for e in args.extras.split(",") if e.strip()]
    opt = proj.get("optional-dependencies", {}) or {}

    for e in extras:
        deps.extend(opt.get(e, []))

    seen = set()
    kept: list[str] = []
    for d in deps:
        key = norm(d)
        if key in PIP_EXCLUDE:
            continue
        if key not in seen:
            seen.add(key)
            kept.append(d)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(kept) + ("\n" if kept else ""), encoding="utf-8")

    print(f"[gen_pip_reqs] wrote {len(kept)} deps to {args.out}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())