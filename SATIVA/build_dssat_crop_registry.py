from __future__ import annotations

import csv
import json
import re
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parent
INSTALL_DIR = Path(r"C:\DSSAT48")
SOURCE_DIR = ROOT / "dssat-csm-os"
OUTPUT_JSON = ROOT / "dssat_crop_registry.json"
OUTPUT_CSV = ROOT / "dssat_crop_registry.csv"
OUTPUT_MD = ROOT / "DSSAT_CROP_REGISTRY.md"


FAMILY_MAP = {
    "BSCER": ("CERES", "Plant/CERES-Sugarbeet"),
    "CSCER": ("CERES", "Plant/CERES-Wheat_Barley"),
    "CRGRO": ("CROPGRO", "Plant/CROPGRO"),
    "CSCRP": ("CROPSIM", "Plant/CROPSIM"),
    "CSCAS": ("CSCAS", "Plant/CSCAS"),
    "CSYCA": ("CSYCA", "Plant/CSYCA-Cassava"),
    "MLCER": ("CERES", "Plant/CERES-Millet"),
    "MZCER": ("CERES", "Plant/CERES-Maize"),
    "MZIXM": ("CERES-IXIM", "Plant/CERES-IXIM-Maize"),
    "PTSUB": ("SUBSTOR", "Plant/SUBSTOR-Potato"),
    "RICER": ("CERES", "Plant/CERES-Rice"),
    "SCCAN": ("CANEGRO", "Plant/CANEGRO-Sugarcane"),
    "SCCSP": ("CASUPRO", "Plant/CASUPRO-Sugarcane"),
    "SCSAM": ("SAMUCA", "Plant/SAMUCA-Sugarcane"),
    "SGCER": ("CERES", "Plant/CERES-Sorghum"),
    "SWCER": ("CERES", "Plant/CERES-SweetCorn"),
    "PIALO": ("ALOHA", "Plant/ALOHA-Pineapple"),
    "TRARO": ("AROIDS", "Plant/AROIDS"),
    "TNARO": ("AROIDS", "Plant/AROIDS"),
    "TFAPS": ("NWHEAT", "Plant/NWHEAT"),
    "TFCER": ("CERES", "Plant/CERES-TEFF"),
    "WHAPS": ("NWHEAT", "Plant/NWHEAT"),
    "PRFRM": ("FORAGE", "Plant/FORAGE"),
    "SUOIL": ("OILCROP", "Plant/OilCrop-Sunflower"),
}


GENERIC_OUTPUTS = ["PlantGro.OUT", "Summary.OUT", "Evaluate.OUT"]
FAMILY_EXTRA_OUTPUTS = {
    "CERES": [],
    "CERES-IXIM": [],
    "CROPGRO": [],
    "SUBSTOR": [],
    "FORAGE": [],
    "NWHEAT": ["PlantGr2.OUT"],
    "CROPSIM": [],
    "CSCAS": [],
    "CSYCA": [],
    "CANEGRO": [],
    "CASUPRO": [],
    "SAMUCA": [],
    "ALOHA": [],
    "AROIDS": [],
    "OILCROP": [],
}


def parse_simulation_models(path: Path) -> list[dict]:
    rows = []
    in_models = False
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.rstrip()
        if line.startswith("*Simulation/Crop Models"):
            in_models = True
            continue
        if not in_models or not line or line.startswith("@") or line.startswith("!"):
            continue
        if line.startswith("*"):
            break
        parts = line.split()
        if len(parts) < 3:
            continue
        model_code, crop_code = parts[0], parts[1]
        description = " ".join(parts[2:])
        family, source_dir = FAMILY_MAP.get(model_code, ("UNKNOWN", None))
        rows.append(
            {
                "model_code": model_code,
                "crop_code": crop_code,
                "description": description,
                "model_family": family,
                "source_plant_dir": source_dir,
            }
        )
    return rows


def parse_dssat_profile(path: Path) -> tuple[dict[str, str], dict[str, str]]:
    crop_dirs: dict[str, str] = {}
    default_modules: dict[str, str] = {}
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("*"):
            continue
        dir_match = re.match(r"^([A-Z0-9]{2})D\s+C:\s+\\DSSAT48\\(.+)$", line, re.IGNORECASE)
        if dir_match:
            crop_code = dir_match.group(1).upper()
            crop_dirs[crop_code] = dir_match.group(2).strip()
            continue
        mod_match = re.match(
            r"^M([A-Z0-9]{2})\s+C:\s+\\DSSAT48\s+DSCSM048\.EXE\s+([A-Z0-9]{8})$",
            line,
            re.IGNORECASE,
        )
        if mod_match:
            crop_code = mod_match.group(1).upper()
            default_modules[crop_code] = mod_match.group(2).upper()
    return crop_dirs, default_modules


def parse_genotype_inventory(path: Path) -> dict[str, dict]:
    inventory: dict[str, dict] = {}
    stems: dict[str, set[str]] = defaultdict(set)
    for file in path.iterdir():
        if not file.is_file():
            continue
        suffix = file.suffix.upper().lstrip(".")
        if suffix not in {"CUL", "ECO", "SPE"}:
            continue
        stems[file.stem.upper()].add(suffix)
    for stem, exts in stems.items():
        inventory[stem] = {
            "genotype_stem": stem,
            "genotype_extensions": sorted(exts),
            "has_eco": "ECO" in exts,
        }
    return inventory


def build_registry() -> list[dict]:
    simulation_rows = parse_simulation_models(SOURCE_DIR / "Data" / "SIMULATION.CDE")
    crop_dirs, default_modules = parse_dssat_profile(SOURCE_DIR / "Data" / "DSSATPRO.v48")
    genotype_inventory = parse_genotype_inventory(INSTALL_DIR / "Genotype")

    registry = []
    for row in simulation_rows:
        module_048 = f"{row['model_code']}048"
        crop_code = row["crop_code"]
        genotype_stem = f"{crop_code}{row['model_code'][2:]}048"
        genotype = genotype_inventory.get(genotype_stem, {})
        install_crop_dir = crop_dirs.get(crop_code)
        family = row["model_family"]

        wrapper_adapter = family
        if family in {"CERES", "CERES-IXIM"}:
            wrapper_adapter = "CERES"
        elif family in {"CANEGRO", "CASUPRO", "SAMUCA"}:
            wrapper_adapter = "SUGARCANE"

        supports_ecotype = genotype.get("has_eco", False)
        cultivar_id_strategy = "unknown"
        if wrapper_adapter == "SUBSTOR":
            cultivar_id_strategy = "VAR# (observed in local SUBSTOR wrapper)"
        elif wrapper_adapter in {
            "CERES",
            "CROPGRO",
            "FORAGE",
            "NWHEAT",
            "CSCAS",
            "CSYCA",
            "SUGARCANE",
            "ALOHA",
            "AROIDS",
            "OILCROP",
            "CROPSIM",
        }:
            cultivar_id_strategy = "needs source-aware adapter; current generic wrapper assumes VAR-NAME"

        phenology_strategy = "custom"
        if wrapper_adapter in {"CERES", "NWHEAT", "SUBSTOR"}:
            phenology_strategy = "can use GSTD-like staging with crop-specific care"
        elif wrapper_adapter == "CROPGRO":
            phenology_strategy = "must map CROPGRO stage variables, not blindly Zadok"

        registry.append(
            {
                "crop_code": crop_code,
                "crop_name": row["description"].split("-", 1)[-1],
                "model_code": row["model_code"],
                "module_code_048": module_048,
                "model_description": row["description"],
                "model_family": family,
                "wrapper_adapter": wrapper_adapter,
                "source_plant_dir": row["source_plant_dir"],
                "install_crop_dir": install_crop_dir,
                "genotype_stem": genotype.get("genotype_stem", genotype_stem),
                "genotype_extensions": genotype.get("genotype_extensions", []),
                "has_ecotype_file": supports_ecotype,
                "default_profile_module": default_modules.get(crop_code),
                "is_default_profile_module": default_modules.get(crop_code) == module_048,
                "default_outputs": GENERIC_OUTPUTS + FAMILY_EXTRA_OUTPUTS.get(family, []),
                "cultivar_id_strategy": cultivar_id_strategy,
                "phenology_strategy": phenology_strategy,
                "omniwrapper_readiness": classify_readiness(wrapper_adapter, supports_ecotype),
            }
        )
    return registry


def classify_readiness(wrapper_adapter: str, has_eco: bool) -> str:
    if wrapper_adapter in {"CERES", "CROPGRO", "SUBSTOR"} and has_eco:
        return "good_v1_target"
    if wrapper_adapter in {"NWHEAT", "FORAGE", "SUGARCANE"}:
        return "needs_family_adapter"
    if not has_eco:
        return "special_case_no_eco"
    return "advanced_adapter_needed"


def write_outputs(registry: list[dict]) -> None:
    OUTPUT_JSON.write_text(json.dumps(registry, indent=2), encoding="utf-8")

    fieldnames = [
        "crop_code",
        "crop_name",
        "model_code",
        "module_code_048",
        "model_family",
        "wrapper_adapter",
        "source_plant_dir",
        "install_crop_dir",
        "genotype_stem",
        "genotype_extensions",
        "has_ecotype_file",
        "default_profile_module",
        "is_default_profile_module",
        "default_outputs",
        "cultivar_id_strategy",
        "phenology_strategy",
        "omniwrapper_readiness",
    ]
    with OUTPUT_CSV.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for row in registry:
            row = row.copy()
            row["genotype_extensions"] = ",".join(row["genotype_extensions"])
            row["default_outputs"] = ",".join(row["default_outputs"])
            writer.writerow({k: row.get(k) for k in fieldnames})

    md = build_markdown_summary(registry)
    OUTPUT_MD.write_text(md, encoding="utf-8")


def build_markdown_summary(registry: list[dict]) -> str:
    by_adapter: dict[str, list[dict]] = defaultdict(list)
    for row in registry:
        by_adapter[row["wrapper_adapter"]].append(row)

    lines = [
        "# DSSAT Crop Registry",
        "",
        "Generated from:",
        "",
        "- `C:\\DSSAT48` install",
        "- `dssat-csm-os\\Data\\SIMULATION.CDE`",
        "- `dssat-csm-os\\Data\\DSSATPRO.v48`",
        "- `dssat-csm-os\\Plant\\...` source families",
        "",
        "## Summary",
        "",
        f"- Total model/crop combinations: {len(registry)}",
        f"- Unique crop codes: {len({r['crop_code'] for r in registry})}",
        f"- Unique wrapper adapters proposed: {len(by_adapter)}",
        "",
        "## Adapter Groups",
        "",
    ]
    for adapter in sorted(by_adapter):
        rows = sorted(by_adapter[adapter], key=lambda r: (r["crop_code"], r["model_code"]))
        crop_list = ", ".join(f"{r['crop_code']}:{r['model_code']}" for r in rows)
        lines.append(f"- `{adapter}`: {crop_list}")

    lines.extend(
        [
            "",
            "## Profile vs Source Notes",
            "",
            "- `default_profile_module` is what DSSATPRO points to by default for a crop code.",
            "- `is_default_profile_module = false` means the source exposes an alternate model variant that is not the default profile target.",
            "- These cases matter for an omniwrapper because crop code alone is not always enough.",
            "",
            "## Special Cases",
            "",
        ]
    )

    special = [r for r in registry if not r["has_ecotype_file"] or not r["is_default_profile_module"]]
    for row in sorted(special, key=lambda r: (r["crop_code"], r["model_code"])):
        notes = []
        if not row["has_ecotype_file"]:
            notes.append("no .ECO file")
        if not row["is_default_profile_module"]:
            notes.append(f"default profile points to {row['default_profile_module']}")
        lines.append(
            f"- `{row['crop_code']}` / `{row['model_code']}` / `{row['module_code_048']}`: "
            + "; ".join(notes)
        )

    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    registry = build_registry()
    write_outputs(registry)
    print(f"Wrote {OUTPUT_JSON}")
    print(f"Wrote {OUTPUT_CSV}")
    print(f"Wrote {OUTPUT_MD}")
