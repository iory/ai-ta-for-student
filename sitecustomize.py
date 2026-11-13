"""ai-ta: load the exception hook (aita_pyhook) where the user site is skipped.

``aita-pyhook.pth`` in the user site-packages does not run when
``PYTHONNOUSERSITE`` is set, and the course's ``ros2 run <pkg> python`` wrappers
set it (they keep ``~/.local`` out of their virtual environments). Python still
imports ``sitecustomize`` from ``PYTHONPATH``, and those wrappers keep
``PYTHONPATH``, so ``ta-hook.bash`` puts this file's directory on it.

This file shadows any other ``sitecustomize`` (Ubuntu's installs apport's
exception hook), so that one is run first, then ``aita_pyhook`` chains to
whatever hook it installed. Any failure here is ignored so it can never change
how a program behaves.
"""

import os
import sys


def _run_next_sitecustomize():
    """Run the ``sitecustomize`` that this one shadows, if there is one."""
    try:
        import importlib.machinery
        import importlib.util

        here = os.path.dirname(os.path.abspath(__file__))
        rest = [p for p in sys.path if os.path.abspath(p or os.curdir) != here]
        spec = importlib.machinery.PathFinder.find_spec("sitecustomize", rest)
        if spec is None or spec.loader is None:
            return
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    except Exception:
        pass


_run_next_sitecustomize()
try:
    import aita_pyhook  # noqa: E402,F401  (installs the hooks on import)
except Exception:
    pass
