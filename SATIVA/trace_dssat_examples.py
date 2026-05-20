from __future__ import annotations

import csv
import json
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path


INSTALL_DIR = Path(r"C:\DSSAT48")
WORKSPACE = Path(__file__).resolve().parent
TRACE_ROOT = WORKSPACE / "example_traces"
JSON_OUT = WORKSPACE / "dssat_example_trace.json"
CSV_OUT = WORKSPACE / "dssat_example_trace.csv"
MD_OUT = WORKSPACE / "DSSAT_EXAMPLE_TRACE.md"
DSCSM = INSTALL_DIR / "DSCSM048.EXE"


@dataclass
class ExampleEntry:
    crop_folder: str
    rank: int
    base_name: str
    ext: str
    title: str

    @property
    def filex(self) -> str:
        return f"{self.base_name}.{self.ext}"

    @property
    def filea(self) -> str:
        return f"{self.base_name}.{self.ext[:2]}A"

    @property
    def filet(self) -> str:
        return f"{self.base_name}.{self.ext[:2]}T"


def crop_folders_with_explist() -> list[Path]:
    return sorted(
        [
            path
            for path in INSTALL_DIR.iterdir()
            if path.is_dir() and (path / "EXP.LST").exists()
        ],
        key=lambda p: p.name.lower(),
    )


def parse_exp_list(path: Path) -> list[ExampleEntry]:
    entries: list[ExampleEntry] = []
    crop_folder = path.parent.name
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        if not line.strip() or line.startswith("*") or line.startswith("@"):
            continue
        match = re.match(r"^\s*(\d+)\s+([A-Z0-9]{8})\s+([A-Z0-9]{3})\s+(.*)$", line)
        if not match:
            continue
        entries.append(
            ExampleEntry(
                crop_folder=crop_folder,
                rank=int(match.group(1)),
                base_name=match.group(2),
                ext=match.group(3),
                title=match.group(4).strip(),
            )
        )
    return entries


def parse_treatment_numbers(filex_path: Path) -> list[int]:
    treatments: list[int] = []
    in_treatments = False
    for raw in filex_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.rstrip("\x1a").rstrip()
        if line.startswith("*TREATMENTS"):
            in_treatments = True
            continue
        if in_treatments and line.startswith("*") and not line.startswith("*TREATMENTS"):
            break
        if not in_treatments or not line.strip() or line.lstrip().startswith("@"):
            continue
        match = re.match(r"^\s*(\d+)", line)
        if match:
            treatments.append(int(match.group(1)))
    return treatments


def parse_experiment_hints(filex_path: Path) -> dict:
    data: dict[str, object] = {
        "weather_station": None,
        "soil_id": None,
        "cultivars": [],
    }
    section = None
    cultivars: list[str] = []
    for raw in filex_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.rstrip("\x1a").rstrip()
        if line.startswith("*"):
            section = line.split(":", 1)[0].strip()
            continue
        if not line.strip() or line.lstrip().startswith("@"):
            continue
        if section == "*FIELDS" and data["weather_station"] is None:
            parts = line.split()
            if len(parts) >= 3:
                data["weather_station"] = parts[2]
            if len(parts) >= 10:
                data["soil_id"] = parts[9]
        elif section == "*CULTIVARS":
            cultivars.append(line.strip())
    data["cultivars"] = cultivars[:10]
    return data


def write_batch_file(run_dir: Path, filex_name: str, treatment: int) -> None:
    filex_field = filex_name + (" " * max(0, 92 - len(filex_name)))
    content = (
        "$BATCH\n"
        "@FILEX                                                                                        TRTNO     RP     SQ     OP     CO\n"
        f"{filex_field}{treatment:>7}      1      0      0      0\n"
    )
    (run_dir / "DSSBatch.V48").write_text(content, encoding="utf-8")


def parse_used_files(path: Path) -> dict[str, dict[str, str]]:
    used: dict[str, dict[str, str]] = {}
    if not path.exists():
        return used
    lines = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    in_files = False
    model = None
    for line in lines:
        if line.startswith("MODEL") and "FILES" not in line:
            parts = line.split()
            if len(parts) >= 2:
                model = parts[-1]
        if line.startswith("*FILES"):
            in_files = True
            continue
        if in_files and line.startswith("*") and not line.startswith("*FILES"):
            break
        if not in_files:
            continue
        if line.startswith("@") or not line.strip():
            continue
        parts = line.split()
        if len(parts) >= 3:
            label = parts[0]
            used[label] = {
                "file": parts[1],
                "dir": parts[2] if len(parts) >= 3 else "",
            }
    if model:
        used["MODEL"] = {"file": model, "dir": ""}
    return used


def generated_outputs(run_dir: Path) -> list[str]:
    keep = []
    for path in sorted(run_dir.iterdir()):
        if not path.is_file():
            continue
        if path.name in {"DSSBatch.V48"}:
            continue
        if path.suffix.upper() in {".WHX", ".WHA", ".WHT", ".HMX", ".HMA", ".HMT", ".PTX", ".PTA", ".PTT"}:
            continue
        keep.append(path.name)
    return keep


def reduce_run_dir(run_dir: Path) -> None:
    keep = {
        "DSSAT48.INH",
        "DSSAT48.INP",
        "Summary.OUT",
        "Overview.OUT",
        "OVERVIEW.OUT",
        "WARNING.OUT",
        "RunList.OUT",
        "OUTPUT.LST",
    }
    for path in run_dir.iterdir():
        if path.is_file() and path.name not in keep and path.name != "DSSBatch.V48":
            if path.suffix.upper() not in {".WHX", ".WHA", ".WHT", ".HMX", ".HMA", ".HMT", ".PTX", ".PTA", ".PTT"}:
                path.unlink(missing_ok=True)


def run_example(entry: ExampleEntry) -> dict:
    crop_dir = INSTALL_DIR / entry.crop_folder
    filex_path = crop_dir / entry.filex
    filea_path = crop_dir / entry.filea
    filet_path = crop_dir / entry.filet
    treatments = parse_treatment_numbers(filex_path)
    hints = parse_experiment_hints(filex_path)

    run_dir = TRACE_ROOT / entry.crop_folder / entry.base_name
    if run_dir.exists():
        shutil.rmtree(run_dir)
    run_dir.mkdir(parents=True, exist_ok=True)

    shutil.copy2(filex_path, run_dir / entry.filex)
    if filea_path.exists():
        shutil.copy2(filea_path, run_dir / entry.filea)
    if filet_path.exists():
        shutil.copy2(filet_path, run_dir / entry.filet)

    first_treatment = treatments[0] if treatments else 1
    write_batch_file(run_dir, entry.filex, first_treatment)

    proc = subprocess.run(
        [str(DSCSM), "B", "DSSBatch.V48"],
        cwd=run_dir,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=180,
    )

    used_files = parse_used_files(run_dir / "DSSAT48.INP")
    if not used_files:
        used_files = parse_used_files(run_dir / "DSSAT48.INH")
    outputs = generated_outputs(run_dir)
    reduce_run_dir(run_dir)

    summary_line = ""
    runlist = run_dir / "RunList.OUT"
    if runlist.exists():
        lines = [line.strip() for line in runlist.read_text(encoding="utf-8", errors="ignore").splitlines() if line.strip()]
        if lines:
            summary_line = lines[-1]

    return {
        "crop_folder": entry.crop_folder,
        "rank": entry.rank,
        "base_name": entry.base_name,
        "filex": entry.filex,
        "title": entry.title,
        "filea_exists": filea_path.exists(),
        "filet_exists": filet_path.exists(),
        "treatment_count": len(treatments),
        "first_treatment": first_treatment,
        "weather_station_hint": hints["weather_station"],
        "soil_id_hint": hints["soil_id"],
        "cultivars_hint": hints["cultivars"],
        "returncode": proc.returncode,
        "summary_line": summary_line,
        "used_files": used_files,
        "generated_outputs": outputs,
        "trace_dir": str(run_dir),
    }


def write_outputs(rows: list[dict]) -> None:
    JSON_OUT.write_text(json.dumps(rows, indent=2), encoding="utf-8")

    fieldnames = [
        "crop_folder",
        "rank",
        "base_name",
        "filex",
        "title",
        "filea_exists",
        "filet_exists",
        "treatment_count",
        "first_treatment",
        "weather_station_hint",
        "soil_id_hint",
        "returncode",
        "summary_line",
        "trace_dir",
        "model_used",
        "species_file",
        "ecotype_file",
        "cultivar_file",
        "soil_file",
        "weather_file",
    ]
    with CSV_OUT.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            used = row.get("used_files", {})
            writer.writerow(
                {
                    "crop_folder": row["crop_folder"],
                    "rank": row["rank"],
                    "base_name": row["base_name"],
                    "filex": row["filex"],
                    "title": row["title"],
                    "filea_exists": row["filea_exists"],
                    "filet_exists": row["filet_exists"],
                    "treatment_count": row["treatment_count"],
                    "first_treatment": row["first_treatment"],
                    "weather_station_hint": row["weather_station_hint"],
                    "soil_id_hint": row["soil_id_hint"],
                    "returncode": row["returncode"],
                    "summary_line": row["summary_line"],
                    "trace_dir": row["trace_dir"],
                    "model_used": used.get("MODEL", {}).get("file"),
                    "species_file": used.get("SPECIES", {}).get("file"),
                    "ecotype_file": used.get("ECOTYPE", {}).get("file"),
                    "cultivar_file": used.get("CULTIVAR", {}).get("file"),
                    "soil_file": used.get("SOILS", {}).get("file"),
                    "weather_file": used.get("WEATHERW", {}).get("file"),
                }
            )

    lines = [
        "# DSSAT Example Trace",
        "",
        f"- Crop folders with `EXP.LST`: {len({r['crop_folder'] for r in rows})}",
        f"- Example files traced: {len(rows)}",
        "",
        "## Per Crop",
        "",
    ]
    by_crop: dict[str, list[dict]] = {}
    for row in rows:
        by_crop.setdefault(row["crop_folder"], []).append(row)
    for crop in sorted(by_crop):
        lines.append(f"### {crop}")
        for row in by_crop[crop]:
            used = row.get("used_files", {})
            lines.append(
                f"- `{row['filex']}`: model `{used.get('MODEL', {}).get('file', 'UNKNOWN')}`, "
                f"species `{used.get('SPECIES', {}).get('file', '')}`, "
                f"eco `{used.get('ECOTYPE', {}).get('file', '')}`, "
                f"cul `{used.get('CULTIVAR', {}).get('file', '')}`, "
                f"soil `{used.get('SOILS', {}).get('file', '')}`, "
                f"weather `{used.get('WEATHERW', {}).get('file', '')}`, "
                f"rc={row['returncode']}"
            )
        lines.append("")
    MD_OUT.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    entries: list[ExampleEntry] = []
    for crop_dir in crop_folders_with_explist():
        entries.extend(parse_exp_list(crop_dir / "EXP.LST"))

    TRACE_ROOT.mkdir(exist_ok=True)
    rows = []
    for idx, entry in enumerate(entries, start=1):
        print(f"[{idx}/{len(entries)}] {entry.crop_folder} {entry.filex}")
        try:
            rows.append(run_example(entry))
        except Exception as exc:  # noqa: BLE001
            rows.append(
                {
                    "crop_folder": entry.crop_folder,
                    "rank": entry.rank,
                    "base_name": entry.base_name,
                    "filex": entry.filex,
                    "title": entry.title,
                    "filea_exists": (INSTALL_DIR / entry.crop_folder / entry.filea).exists(),
                    "filet_exists": (INSTALL_DIR / entry.crop_folder / entry.filet).exists(),
                    "treatment_count": 0,
                    "first_treatment": 1,
                    "weather_station_hint": None,
                    "soil_id_hint": None,
                    "cultivars_hint": [],
                    "returncode": -1,
                    "summary_line": str(exc),
                    "used_files": {},
                    "generated_outputs": [],
                    "trace_dir": str(TRACE_ROOT / entry.crop_folder / entry.base_name),
                }
            )

    write_outputs(rows)
    print(f"Wrote {JSON_OUT}")
    print(f"Wrote {CSV_OUT}")
    print(f"Wrote {MD_OUT}")


if __name__ == "__main__":
    main()
