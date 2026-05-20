from __future__ import annotations

import csv
from collections import defaultdict
from pathlib import Path


WORKSPACE = Path(r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files")
REGISTRY_CSV = WORKSPACE / "dssat_crop_registry.csv"
TRACE_CSV = WORKSPACE / "dssat_example_trace.csv"
OUT_CSV = WORKSPACE / "omniwrapper_family_coverage.csv"
OUT_MD = WORKSPACE / "OMNIWRAPPER_FAMILY_COVERAGE.md"


TESTED_CASES = [
    {
        "family": "ALOHA",
        "crop_code": "PI",
        "crop_name": "Pineapple",
        "example_file": "UHKN8901.PIX",
        "example_path": r"C:\DSSAT48\PineApple\UHKN8901.PIX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with CWAD output.",
    },
    {
        "family": "AROIDS",
        "crop_code": "TR",
        "crop_name": "Taro",
        "example_file": "IBHK8901.TRX",
        "example_path": r"C:\DSSAT48\Taro\IBHK8901.TRX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with CWAD output using fallback PlantGro parser.",
    },
    {
        "family": "CANEGRO",
        "crop_code": "SC",
        "crop_name": "Sugarcane",
        "example_file": "ESAL1401.SCX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Sugarcane\ESAL1401.SCX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with SCCAN048 and LAIGD output.",
    },
    {
        "family": "CSYCA",
        "crop_code": "CS",
        "crop_name": "Cassava",
        "example_file": "CCPA7801.CSX",
        "example_path": r"C:\DSSAT48\Cassava\CCPA7801.CSX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with CWAD output.",
    },
    {
        "family": "CASUPRO",
        "crop_code": "SC",
        "crop_name": "Sugarcane",
        "example_file": "ESAL1401.SCX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Sugarcane\ESAL1401.SCX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with SCCSP048 and LAIGD output.",
    },
    {
        "family": "CERES-IXIM",
        "crop_code": "MZ",
        "crop_name": "Maize",
        "example_file": "UFGA8201.MZX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Maize\UFGA8201.MZX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with MZIXM048 and CWAD output.",
    },
    {
        "family": "CROPSIM",
        "crop_code": "BA",
        "crop_name": "Barley",
        "example_file": "IEBR8201.BAX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Barley\IEBR8201.BAX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with CSCRP048 and GSTD output.",
    },
    {
        "family": "NWHEAT",
        "crop_code": "TF",
        "crop_name": "Teff",
        "example_file": "ETGA0201.TFX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Teff\ETGA0201.TFX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with TFAPS048 and CWAD output.",
    },
    {
        "family": "NWHEAT",
        "crop_code": "WH",
        "crop_name": "Wheat",
        "example_file": "KSAS8101.WHX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Wheat\KSAS8101.WHX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with WHAPS048 and GSTD output.",
    },
    {
        "family": "OILCROP",
        "crop_code": "SU",
        "crop_name": "Sunflower",
        "example_file": "AUTA8101.SUX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Sunflower\AUTA8101.SUX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with SUOIL048 and CWAD output.",
    },
    {
        "family": "SAMUCA",
        "crop_code": "SC",
        "crop_name": "Sugarcane",
        "example_file": "SAPO8601.SCX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Sugarcane\SAPO8601.SCX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with SCSAM048 and LAIGD output.",
    },
    {
        "family": "CERES",
        "crop_code": "WH",
        "crop_name": "Wheat",
        "example_file": "KSAS8101.WHX",
        "example_path": r"C:\DSSAT48\Wheat\KSAS8101.WHX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with GSTD output.",
    },
    {
        "family": "SUBSTOR",
        "crop_code": "PT",
        "crop_name": "Potato",
        "example_file": "AUCB7001.PTX",
        "example_path": r"C:\DSSAT48\Potato\AUCB7001.PTX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with TWAD output.",
    },
    {
        "family": "CROPGRO",
        "crop_code": "SB",
        "crop_name": "Soybean",
        "example_file": "CLMO8501.SBX",
        "example_path": r"C:\DSSAT48\Soybean\CLMO8501.SBX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with CWAD output.",
    },
    {
        "family": "CROPGRO",
        "crop_code": "HM",
        "crop_name": "Hemp",
        "example_file": "UFDSS0301.HMX",
        "example_path": r"C:\DSSAT48\Hemp\UFDSS0301.HMX",
        "status": "tested",
        "notes": "Validated through DSSAT_omniwrapper with CWAD output.",
    },
]

BLOCKED_CASES = {
    "CSCAS": {
        "status": "blocked_model_data",
        "example_file": "CCPA7801.CSX",
        "example_path": r"C:\Users\chich\Downloads\DSSAT Files\DSSAT Files\dssat-csm-data\Cassava\CCPA7801.CSX",
        "notes": "Wrapper launch reaches CSCAS048, but the model exits with 'Missing ecotype coefficients. Fix ecotype input file. Error key: IPECO'.",
    }
}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def unique_sorted(values: list[str]) -> str:
    cleaned = sorted({value for value in values if value})
    return ", ".join(cleaned)


def main() -> None:
    registry_rows = read_csv(REGISTRY_CSV)
    trace_rows = read_csv(TRACE_CSV)

    tested_by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    for case in TESTED_CASES:
        tested_by_family[case["family"]].append(case)

    trace_rows_by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    trace_success_by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in trace_rows:
        family = ""
        model_used = row.get("model_used", "")
        if model_used.endswith("048"):
            model_used = model_used[:-3]
        for registry_row in registry_rows:
            if registry_row["model_code"] == model_used:
                family = registry_row["model_family"]
                break
        if family:
            trace_rows_by_family[family].append(row)
            if row.get("returncode") == "0":
                trace_success_by_family[family].append(row)

    family_rows: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in registry_rows:
        family_rows[row["model_family"]].append(row)

    coverage_rows: list[dict[str, str]] = []
    for family in sorted(family_rows):
        rows = family_rows[family]
        crop_codes = [row["crop_code"] for row in rows]
        crop_names = [row["crop_name"] for row in rows]
        modules = [row["model_code"] for row in rows]
        install_dirs = [row["install_crop_dir"] for row in rows]
        no_eco = sorted({row["crop_code"] for row in rows if str(row.get("has_ecotype_file", "")).lower() == "false"})
        tested = tested_by_family.get(family, [])
        traced = trace_rows_by_family.get(family, [])
        trace_success = trace_success_by_family.get(family, [])
        trace_fail = [row for row in traced if row.get("returncode") != "0"]
        blocked_case = BLOCKED_CASES.get(family)

        if tested:
            status = "tested"
        elif blocked_case:
            status = blocked_case["status"]
        elif trace_success:
            status = "trace_only"
        elif trace_fail:
            status = "trace_failures"
        else:
            status = "recognized_only"

        representative_example = ""
        representative_path = ""
        notes = []
        if tested:
            representative_example = unique_sorted([case["example_file"] for case in tested])
            representative_path = unique_sorted([case["example_path"] for case in tested])
            notes.extend(case["notes"] for case in tested)
        elif trace_success:
            representative_example = unique_sorted([row["filex"] for row in trace_success[:3]])
            representative_path = unique_sorted([str(Path(row["trace_dir"]) / row["filex"]) for row in trace_success[:3]])
            notes.append("Installed DSSAT example(s) ran successfully in batch trace, but not yet validated through DSSAT_omniwrapper.")
        elif trace_fail:
            representative_example = unique_sorted([row["filex"] for row in trace_fail[:3]])
            representative_path = unique_sorted([str(Path(row["trace_dir"]) / row["filex"]) for row in trace_fail[:3]])
            notes.append("Installed DSSAT examples were traced but currently fail before omniwrapper validation.")
        elif blocked_case:
            representative_example = blocked_case["example_file"]
            representative_path = blocked_case["example_path"]
            notes.append(blocked_case["notes"])
        else:
            notes.append("Present in DSSAT registry, but not yet traced or validated through DSSAT_omniwrapper.")

        if no_eco:
            notes.append(f"Includes crop code(s) without .ECO files: {', '.join(no_eco)}.")
        if family == "FORAGE":
            notes.append("Current installed example failures are concentrated here and are linked to extra mowing inputs such as .MOW files.")

        coverage_rows.append(
            {
                "family": family,
                "status": status,
                "crop_codes": unique_sorted(crop_codes),
                "crop_names": unique_sorted(crop_names),
                "model_codes": unique_sorted(modules),
                "install_dirs": unique_sorted(install_dirs),
                "tested_case_count": str(len(tested)),
                "trace_attempt_count": str(len(traced)),
                "trace_success_count": str(len(trace_success)),
                "trace_failure_count": str(len(trace_fail)),
                "representative_example": representative_example,
                "representative_example_path": representative_path,
                "notes": " ".join(notes),
            }
        )

    with OUT_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "family",
                "status",
                "crop_codes",
                "crop_names",
                "model_codes",
                "install_dirs",
                "tested_case_count",
                "trace_attempt_count",
                "trace_success_count",
                "trace_failure_count",
                "representative_example",
                "representative_example_path",
                "notes",
            ],
        )
        writer.writeheader()
        writer.writerows(coverage_rows)

    lines = [
        "# Omniwrapper Family Coverage",
        "",
        "Status meanings:",
        "- `tested`: validated end-to-end through `DSSAT_omniwrapper.R`.",
        "- `trace_only`: installed DSSAT examples ran successfully in the executable trace, but not yet through the omniwrapper.",
        "- `trace_failures`: installed DSSAT examples were traced, but current runs fail and need family-specific fixes.",
        "- `blocked_model_data`: the omniwrapper reaches the target model, but the current local data/model setup still stops inside DSSAT.",
        "- `recognized_only`: present in the DSSAT registry and family map, but not yet validated by trace or wrapper test.",
        "",
        "| Family | Status | Crop Codes | Model Codes | Tested | Trace Attempts | Trace Success | Trace Failures | Representative Example | Notes |",
        "|---|---|---|---|---:|---:|---:|---:|---|---|",
    ]

    for row in coverage_rows:
        lines.append(
            f"| {row['family']} | {row['status']} | {row['crop_codes']} | {row['model_codes']} | "
            f"{row['tested_case_count']} | {row['trace_attempt_count']} | {row['trace_success_count']} | {row['trace_failure_count']} | "
            f"{row['representative_example']} | {row['notes']} |"
        )

    lines.extend(
        [
            "",
            "Key current result:",
            "- The prototype is now proven across `ALOHA`, `AROIDS`, `CANEGRO`, `CASUPRO`, `CERES`, `CERES-IXIM`, `CROPGRO`, `CROPSIM`, `CSYCA`, `NWHEAT`, `OILCROP`, `SAMUCA`, and `SUBSTOR`.",
            "- `CSCAS` is no longer a wrapper-design unknown; it is specifically blocked by a DSSAT-side ecotype error in the current local setup.",
            "- The next highest-value unresolved family is `FORAGE`, where installed examples still fail around extra mowing inputs such as `.MOW` files.",
        ]
    )

    OUT_MD.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
