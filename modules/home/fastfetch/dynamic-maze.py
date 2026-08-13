#!/usr/bin/env python3
"""Generate a solvable Nixodus pipe maze."""

import argparse
import random
import sys
from pathlib import Path
from typing import TypeAlias

Cell: TypeAlias = tuple[int, int]
Seed: TypeAlias = int | str
Walls: TypeAlias = list[list[list[bool]]]
Edges: TypeAlias = list[list[bool]]

DIRECTIONS: tuple[Cell, ...] = ((-1, 0), (0, 1), (1, 0), (0, -1))
PIPES: dict[int, str] = {
    1: "║",
    2: "═",
    3: "╚",
    4: "║",
    5: "║",
    6: "╔",
    7: "╠",
    8: "═",
    9: "╝",
    10: "═",
    11: "╩",
    12: "╗",
    13: "╣",
    14: "╦",
    15: "╬",
}


class Args(argparse.Namespace):
    cell_rows: int = 10
    cell_columns: int = 11
    passage_width: int = 1
    character_aspect: float = 3.0
    seed: str = "legion"
    start_row: int = 0
    start_column: int = 0
    entrance_row: int | None = None
    exit_row: int | None = None
    output: str = "assets/nixodus-logo.txt"


def parse_args() -> Args:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument("--cell-rows", type=int, default=10, help="maze cell rows")
    _ = parser.add_argument("--cell-columns", type=int, default=11, help="maze cell columns")
    _ = parser.add_argument(
        "--passage-width",
        type=int,
        default=1,
        help="visual passage width; vertical character count",
    )
    _ = parser.add_argument(
        "--character-aspect",
        type=float,
        default=3.0,
        help="terminal character height divided by width",
    )
    _ = parser.add_argument(
        "--seed",
        default="legion",
        help="alphanumeric or hyphenated random layout seed",
    )
    _ = parser.add_argument("--start-row", type=int, default=0, help="generation start row")
    _ = parser.add_argument("--start-column", type=int, default=0, help="generation start column")
    _ = parser.add_argument(
        "--entrance-row",
        type=int,
        help="left-side entrance cell row; omitted for a closed maze",
    )
    _ = parser.add_argument(
        "--exit-row",
        type=int,
        help="right-side exit cell row; omitted for a closed maze",
    )
    _ = parser.add_argument(
        "--output",
        default="assets/nixodus-logo.txt",
        help="output path, or - for stdout",
    )
    return parser.parse_args(namespace=Args())


def validate_args(args: Args) -> None:
    if args.cell_rows < 2 or args.cell_columns < 2:
        raise ValueError("cell rows and columns must be at least 2")
    if args.passage_width < 1:
        raise ValueError("passage width must be at least 1")
    if args.character_aspect <= 0:
        raise ValueError("character aspect must be greater than 0")
    if not args.seed.replace("-", "").isalnum():
        raise ValueError("seed must contain only letters, numbers, and hyphens")
    if not 0 <= args.start_row < args.cell_rows:
        raise ValueError("start row is outside maze")
    if not 0 <= args.start_column < args.cell_columns:
        raise ValueError("start column is outside maze")
    if args.entrance_row is not None and not 0 <= args.entrance_row < args.cell_rows:
        raise ValueError("entrance row is outside maze")
    if args.exit_row is not None and not 0 <= args.exit_row < args.cell_rows:
        raise ValueError("exit row is outside maze")


def carve_maze(rows: int, columns: int, seed: Seed, start: Cell) -> Walls:
    rng = random.Random(seed)
    walls: Walls = [[[True] * 4 for _ in range(columns)] for _ in range(rows)]
    visited: set[Cell] = {start}
    stack: list[Cell] = [start]

    while stack:
        row, column = stack[-1]
        choices: list[tuple[int, Cell]] = []

        for direction, (row_delta, column_delta) in enumerate(DIRECTIONS):
            next_row = row + row_delta
            next_column = column + column_delta
            next_cell = (next_row, next_column)
            if (
                0 <= next_row < rows
                and 0 <= next_column < columns
                and next_cell not in visited
            ):
                choices.append((direction, next_cell))

        if not choices:
            _ = stack.pop()
            continue

        direction, (next_row, next_column) = rng.choice(choices)
        walls[row][column][direction] = False
        walls[next_row][next_column][(direction + 2) % 4] = False
        visited.add((next_row, next_column))
        stack.append((next_row, next_column))

    return walls


def build_edges(walls: Walls, entrance_row: int | None, exit_row: int | None) -> tuple[Edges, Edges]:
    rows = len(walls)
    columns = len(walls[0])
    if entrance_row is not None:
        walls[entrance_row][0][3] = False
    if exit_row is not None:
        walls[exit_row][columns - 1][1] = False

    horizontal: Edges = [[False] * columns for _ in range(rows + 1)]
    vertical: Edges = [[False] * (columns + 1) for _ in range(rows)]

    for row in range(rows):
        for column in range(columns):
            horizontal[row][column] |= walls[row][column][0]
            horizontal[row + 1][column] |= walls[row][column][2]
            vertical[row][column] |= walls[row][column][3]
            vertical[row][column + 1] |= walls[row][column][1]

    return horizontal, vertical


def junction_mask(horizontal: Edges, vertical: Edges, row: int, column: int) -> int:
    rows = len(vertical)
    columns = len(horizontal[0])
    return (
        (1 if row > 0 and vertical[row - 1][column] else 0)
        | (2 if column < columns and horizontal[row][column] else 0)
        | (4 if row < rows and vertical[row][column] else 0)
        | (8 if column > 0 and horizontal[row][column - 1] else 0)
    )


def render_maze(horizontal: Edges, vertical: Edges, passage_width: int, character_aspect: float) -> str:
    rows = len(vertical)
    columns = len(horizontal[0])
    horizontal_width = max(1, round(passage_width * character_aspect))
    lines: list[str] = []

    for row in range(rows + 1):
        wall_line = ""
        for column in range(columns + 1):
            wall_line += PIPES[junction_mask(horizontal, vertical, row, column)]
            if column < columns:
                fill = "═" if horizontal[row][column] else " "
                wall_line += fill * horizontal_width
        lines.append(wall_line)

        if row < rows:
            passage_line = ""
            for column in range(columns + 1):
                passage_line += "║" if vertical[row][column] else " "
                if column < columns:
                    passage_line += " " * horizontal_width
            lines.extend([passage_line] * passage_width)

    return "\n".join(lines) + "\n"


def main() -> None:
    args = parse_args()
    try:
        validate_args(args)
    except ValueError as error:
        raise SystemExit(str(error)) from error

    seed = int(args.seed) if args.seed.isdigit() else args.seed
    walls = carve_maze(
        args.cell_rows,
        args.cell_columns,
        seed,
        (args.start_row, args.start_column),
    )
    horizontal, vertical = build_edges(walls, args.entrance_row, args.exit_row)
    maze = render_maze(
        horizontal,
        vertical,
        args.passage_width,
        args.character_aspect,
    )

    horizontal_width = max(1, round(args.passage_width * args.character_aspect))
    character_rows = args.cell_rows * (args.passage_width + 1) + 1
    character_columns = args.cell_columns * (horizontal_width + 1) + 1
    if args.output == "-":
        _ = sys.stdout.write(maze)
        return

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    _ = output_path.write_text(maze)
    print(
        f"Wrote {output_path} ({character_rows}x{character_columns} characters)",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
