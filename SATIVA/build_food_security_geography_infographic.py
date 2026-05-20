from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable
from urllib.request import urlretrieve

import geopandas as gpd
import matplotlib.patheffects as pe
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Circle, FancyArrowPatch, FancyBboxPatch


PROJECT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = PROJECT_DIR / "infographic_outputs"
DATA_DIR = PROJECT_DIR / "infographic_data"
WORLD_ZIP_URL = (
    "https://naturalearth.s3.amazonaws.com/110m_cultural/"
    "ne_110m_admin_0_countries.zip"
)
WORLD_ZIP_PATH = DATA_DIR / "ne_110m_admin_0_countries.zip"


@dataclass(frozen=True)
class RegionSpec:
    key: str
    label: str
    share: int
    color: str
    bubble_xy: tuple[float, float]
    label_xy: tuple[float, float]
    radius: float


PALETTE = {
    "navy": "#183968",
    "navy_dark": "#0E2746",
    "navy_mid": "#234C84",
    "aqua": "#91CFDA",
    "teal": "#3B9AA9",
    "green": "#98C45D",
    "green_dark": "#4F8D33",
    "orange": "#F08C3A",
    "orange_dark": "#D76913",
    "grey": "#BDBDBD",
    "grey_dark": "#6B6E73",
    "paper": "#F8F5EF",
    "ink": "#1F2940",
}


REGIONS = [
    RegionSpec(
        key="Asia",
        label="Asia",
        share=43,
        color="#2E5B98",
        bubble_xy=(111, 38),
        label_xy=(111, 38),
        radius=18,
    ),
    RegionSpec(
        key="Africa",
        label="Africa",
        share=19,
        color="#9BC65A",
        bubble_xy=(21, -3),
        label_xy=(21, -3),
        radius=14,
    ),
    RegionSpec(
        key="North America",
        label="North America",
        share=15,
        color="#90CFDB",
        bubble_xy=(-100, 29),
        label_xy=(-100, 29),
        radius=15,
    ),
    RegionSpec(
        key="Europe",
        label="Europe",
        share=11,
        color="#F29A4B",
        bubble_xy=(11, 46),
        label_xy=(11, 46),
        radius=13,
    ),
    RegionSpec(
        key="Oceania",
        label="Oceania",
        share=2,
        color="#B9B9BB",
        bubble_xy=(170, -29),
        label_xy=(170, -29),
        radius=11,
    ),
]


ASIA_OVERRIDES = {
    "Russia",
    "Turkey",
    "Kazakhstan",
    "Georgia",
    "Armenia",
    "Azerbaijan",
}

EUROPE_OVERRIDES = {
    "Cyprus",
    "Iceland",
}


def ensure_world_data() -> Path:
    DATA_DIR.mkdir(exist_ok=True)
    if not WORLD_ZIP_PATH.exists():
        urlretrieve(WORLD_ZIP_URL, WORLD_ZIP_PATH)
    return WORLD_ZIP_PATH


def load_world() -> gpd.GeoDataFrame:
    world_path = ensure_world_data()
    world = gpd.read_file(world_path)
    world = world[world["NAME"] != "Antarctica"].copy()
    world["region_key"] = world.apply(assign_region, axis=1)
    return world


def assign_region(row) -> str:
    name = row["NAME"]
    continent = row["CONTINENT"]

    if name in ASIA_OVERRIDES:
        return "Asia"
    if name in EUROPE_OVERRIDES:
        return "Europe"

    if continent == "Asia":
        return "Asia"
    if continent == "Africa":
        return "Africa"
    if continent == "North America":
        return "North America"
    if continent == "Europe":
        return "Europe"
    if continent == "Oceania":
        return "Oceania"
    return "Other"


def setup_figure():
    fig = plt.figure(figsize=(16, 9), dpi=240)
    fig.patch.set_facecolor(PALETTE["paper"])
    ax = fig.add_axes([0.13, 0.08, 0.84, 0.78])
    ax.set_facecolor(PALETTE["paper"])
    ax.set_xlim(-178, 182)
    ax.set_ylim(-58, 88)
    ax.axis("off")
    return fig, ax


def draw_background_glow(ax) -> None:
    x = np.linspace(-178, 182, 600)
    y = np.linspace(-58, 88, 360)
    xx, yy = np.meshgrid(x, y)
    glow = (
        np.exp(-(((xx + 25) / 110) ** 2 + ((yy - 15) / 75) ** 2))
        + 0.7 * np.exp(-(((xx - 40) / 130) ** 2 + ((yy - 30) / 65) ** 2))
    )
    ax.imshow(
        glow,
        extent=[-178, 182, -58, 88],
        origin="lower",
        cmap="Blues",
        alpha=0.09,
        zorder=0,
    )


def draw_header(fig) -> None:
    fig.text(
        0.5,
        0.94,
        "Global Trends in Food Security Literature",
        ha="center",
        va="center",
        fontsize=28,
        color=PALETTE["navy_dark"],
        fontfamily="DejaVu Serif",
        weight="bold",
    )
    fig.text(
        0.5,
        0.90,
        "A synthesis of global research patterns, thematic foci, and adaptive responses",
        ha="center",
        va="center",
        fontsize=12.5,
        color=PALETTE["navy_dark"],
        fontfamily="DejaVu Sans",
    )
    fig.add_artist(
        plt.Line2D(
            [0.03, 0.97],
            [0.875, 0.875],
            transform=fig.transFigure,
            color=PALETTE["navy_mid"],
            linewidth=1.4,
        )
    )


def draw_section_title(fig) -> None:
    badge = FancyBboxPatch(
        (0.045, 0.805),
        0.028,
        0.038,
        boxstyle="round,pad=0.002,rounding_size=0.004",
        transform=fig.transFigure,
        linewidth=0,
        facecolor=PALETTE["navy_mid"],
        zorder=20,
    )
    fig.add_artist(badge)
    fig.text(
        0.059,
        0.824,
        "1",
        ha="center",
        va="center",
        fontsize=15,
        color="white",
        weight="bold",
    )
    fig.text(
        0.08,
        0.828,
        "GEOGRAPHIC DISTRIBUTION OF STUDIES",
        ha="left",
        va="center",
        fontsize=14,
        color=PALETTE["navy_dark"],
        weight="bold",
        fontfamily="DejaVu Sans",
    )
    fig.text(
        0.08,
        0.793,
        "Share of publications by\nregion (2010-2023)",
        ha="left",
        va="top",
        fontsize=11,
        color=PALETTE["ink"],
        fontfamily="DejaVu Sans",
        linespacing=1.4,
    )


def draw_map(ax, world: gpd.GeoDataFrame) -> None:
    draw_background_glow(ax)
    world.plot(
        ax=ax,
        color="#E5E4E1",
        edgecolor="white",
        linewidth=0.55,
        zorder=1,
    )

    for spec in REGIONS:
        region = world[world["region_key"] == spec.key]
        if region.empty:
            continue
        region.plot(
            ax=ax,
            color=spec.color,
            edgecolor="white",
            linewidth=0.8,
            zorder=3,
        )

    coastline = world.dissolve()
    coastline.boundary.plot(
        ax=ax,
        color="white",
        linewidth=0.8,
        alpha=0.85,
        zorder=4,
    )


def draw_legend(fig, specs: Iterable[RegionSpec]) -> None:
    y0 = 0.72
    dy = 0.048
    for idx, spec in enumerate(specs):
        y = y0 - idx * dy
        bullet = Circle(
            (0.086, y),
            0.0063,
            transform=fig.transFigure,
            facecolor=spec.color,
            edgecolor=darken(spec.color, 0.85),
            linewidth=0.6,
        )
        fig.add_artist(bullet)
        fig.text(
            0.103,
            y,
            spec.label,
            transform=fig.transFigure,
            ha="left",
            va="center",
            fontsize=11.5,
            color=PALETTE["ink"],
        )
        fig.text(
            0.205,
            y,
            f"{spec.share}%",
            transform=fig.transFigure,
            ha="left",
            va="center",
            fontsize=12,
            color=PALETTE["navy_dark"],
            weight="bold",
        )


def draw_bubbles(ax, specs: Iterable[RegionSpec]) -> None:
    for spec in specs:
        cx, cy = spec.bubble_xy
        anchor_x = cx - spec.radius * 1.15 if cx > 0 else cx + spec.radius * 1.1
        anchor_y = cy - spec.radius * 0.55
        leader = FancyArrowPatch(
            posA=(anchor_x, anchor_y),
            posB=(cx, cy),
            arrowstyle="-",
            linewidth=1.0,
            color=darken(spec.color, 0.82),
            alpha=0.5,
            zorder=5,
            connectionstyle="arc3,rad=0.15",
        )
        shadow = Circle(
            (cx + 1.2, cy - 1.2),
            radius=spec.radius,
            facecolor="black",
            edgecolor="none",
            alpha=0.06,
            zorder=5,
        )
        bubble = Circle(
            (cx, cy),
            radius=spec.radius,
            facecolor=(1, 1, 1, 0.94),
            edgecolor=darken(spec.color, 0.82),
            linewidth=1.2,
            zorder=6,
        )
        ax.add_patch(leader)
        ax.add_patch(shadow)
        ax.add_patch(bubble)

        label = spec.label
        if label == "North America":
            label = "North\nAmerica"

        ax.text(
            cx,
            cy + spec.radius * 0.12,
            f"{spec.share}%",
            ha="center",
            va="center",
            fontsize=16,
            color=darken(spec.color, 0.65),
            weight="bold",
            zorder=7,
        )
        ax.text(
            cx,
            cy - spec.radius * 0.30,
            label,
            ha="center",
            va="center",
            fontsize=10.5,
            color=PALETTE["ink"],
            zorder=7,
        )


def draw_summary_box(fig) -> None:
    box = FancyBboxPatch(
        (0.055, 0.34),
        0.63,
        0.072,
        boxstyle="round,pad=0.004,rounding_size=0.01",
        transform=fig.transFigure,
        linewidth=0.8,
        edgecolor="#AAB2BD",
        facecolor=(1, 1, 1, 0.65),
        zorder=12,
    )
    fig.add_artist(box)
    draw_globe_icon(fig, center=(0.078, 0.376), radius=0.016)
    fig.text(
        0.108,
        0.376,
        "Asia leads food security research output (43%), followed by Africa (19%), North America (15%),\n"
        "and Europe (11%). Oceania accounts for 2%.",
        ha="left",
        va="center",
        fontsize=10.6,
        color=PALETTE["ink"],
        linespacing=1.4,
        zorder=13,
    )


def draw_globe_icon(fig, center: tuple[float, float], radius: float) -> None:
    outer = Circle(
        center,
        radius,
        transform=fig.transFigure,
        facecolor=(1, 1, 1, 0),
        edgecolor=PALETTE["navy_mid"],
        linewidth=1.2,
        zorder=13,
    )
    fig.add_artist(outer)

    cx, cy = center
    for scale in (0.45, 0.78):
        fig.add_artist(
            Circle(
                center,
                radius * scale,
                transform=fig.transFigure,
                facecolor="none",
                edgecolor=PALETTE["navy_mid"],
                linewidth=0.8,
                alpha=0.9,
                zorder=13,
            )
        )

    for dx in (-0.55, 0.0, 0.55):
        fig.add_artist(
            plt.Line2D(
                [cx + radius * dx, cx + radius * dx],
                [cy - radius * 0.9, cy + radius * 0.9],
                transform=fig.transFigure,
                color=PALETTE["navy_mid"],
                linewidth=0.8,
                alpha=0.9,
                zorder=13,
            )
        )

    fig.add_artist(
        plt.Line2D(
            [cx - radius * 0.92, cx + radius * 0.92],
            [cy, cy],
            transform=fig.transFigure,
            color=PALETTE["navy_mid"],
            linewidth=0.8,
            alpha=0.9,
            zorder=13,
        )
    )


def draw_optional_icon_slots(ax) -> None:
    slot_style = dict(
        bbox=dict(
            boxstyle="round,pad=0.15,rounding_size=0.15",
            fc=(1, 1, 1, 0.72),
            ec="#D4D8DD",
            lw=0.7,
        ),
        fontsize=7.5,
        color=PALETTE["grey_dark"],
        ha="center",
        va="center",
        zorder=10,
    )
    ax.text(-130, 62, "ICON\nSLOT", **slot_style)
    ax.text(150, 60, "ICON\nSLOT", **slot_style)


def darken(hex_color: str, factor: float) -> tuple[float, float, float]:
    hex_color = hex_color.lstrip("#")
    rgb = np.array([int(hex_color[i : i + 2], 16) for i in (0, 2, 4)]) / 255.0
    return tuple(np.clip(rgb * factor, 0, 1))


def apply_text_effects(fig) -> None:
    for text in fig.findobj(match=plt.Text):
        if text.get_fontsize() >= 20:
            text.set_path_effects(
                [pe.withStroke(linewidth=2.5, foreground=(1, 1, 1, 0.25))]
            )


def build_infographic(
    output_name: str = "food_security_geographic_distribution.png",
    show_icon_slots: bool = False,
) -> Path:
    world = load_world()
    fig, ax = setup_figure()
    draw_header(fig)
    draw_section_title(fig)
    draw_map(ax, world)
    draw_legend(fig, REGIONS)
    draw_bubbles(ax, REGIONS)
    draw_summary_box(fig)
    if show_icon_slots:
        draw_optional_icon_slots(ax)
    apply_text_effects(fig)

    OUTPUT_DIR.mkdir(exist_ok=True)
    output_path = OUTPUT_DIR / output_name
    fig.savefig(output_path, dpi=300, facecolor=fig.get_facecolor(), bbox_inches="tight")
    plt.close(fig)
    return output_path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Build the geographic distribution food-security infographic."
    )
    parser.add_argument(
        "--output",
        default="food_security_geographic_distribution.png",
        help="Name of the output file inside infographic_outputs.",
    )
    parser.add_argument(
        "--show-icon-slots",
        action="store_true",
        help="Render placeholder boxes where custom icons could be inserted later.",
    )
    args = parser.parse_args()
    output_path = build_infographic(
        output_name=args.output,
        show_icon_slots=args.show_icon_slots,
    )
    print(f"Saved infographic to: {output_path}")
