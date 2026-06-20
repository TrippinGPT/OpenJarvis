"""Startup banner -- Trippin AI Relay wordmark + tagline."""

from __future__ import annotations

_WORDMARK = (
    "==================================================",
    "              TRIPPIN AI RELAY                    ",
    "        Local switchboard powered by Core          ",
    "        Signal In -> Relay Routes -> Work Out      ",
    "==================================================",
)

_TAGLINE = "OpenClaw Core online. Relay ready."


def print_banner(quiet: bool = False) -> None:
    """Print the Trippin AI Relay startup banner. No-op when quiet."""
    if quiet:
        return
    try:
        from rich.console import Console

        console = Console()
        for line in _WORDMARK:
            console.print(line, style="bold magenta", highlight=False, markup=False)
        console.print(f"      {_TAGLINE}", style="cyan", highlight=False, markup=False)
        console.print()
    except ImportError:
        for line in _WORDMARK:
            print(line)
        print(f"      {_TAGLINE}")
        print()
