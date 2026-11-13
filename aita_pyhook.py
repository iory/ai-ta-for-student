"""ai-ta: record uncaught Python exceptions so `ta fix` can include them.

Loaded at interpreter start by ``aita-pyhook.pth`` in the user site-packages
(installed by ``install.sh``; remove both files to uninstall). It chains to
the existing ``sys.excepthook`` / ``threading.excepthook``, so tracebacks
still print exactly as before. It only writes a small file under
``~/.cache/ai-ta/py_errors``; nothing is sent anywhere until the student
runs ``ta fix`` / ``ta call``. Any failure inside the hook is ignored so it
can never change how a program behaves.
"""

import os
import sys
import threading

_DIR = os.path.join(
    os.environ.get("AITA_CACHE_DIR") or os.path.join(os.path.expanduser("~"), ".cache", "ai-ta"),
    "py_errors",
)
_KEEP = 20
_SKIP = (KeyboardInterrupt, SystemExit)


def _record(exc_type, exc_value, exc_tb, thread_name=None):
    """Write one traceback to ``py_errors/<time>-<pid>.txt`` and ``latest.txt``."""
    try:
        if exc_type is None or issubclass(exc_type, _SKIP):
            return
        import time
        import traceback

        os.makedirs(_DIR, exist_ok=True)
        stamp = time.strftime("%Y%m%d-%H%M%S")
        header = [
            f"time: {time.strftime('%F %T')}",
            f"argv: {' '.join(sys.argv)}",
            f"cwd: {os.getcwd()}",
            f"python: {sys.executable} {sys.version.split()[0]}",
        ]
        if thread_name:
            header.append(f"thread: {thread_name}")
        body = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
        text = "\n".join(header) + "\n\n" + body
        path = os.path.join(_DIR, f"{stamp}-{os.getpid()}.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)
        latest = os.path.join(_DIR, "latest.txt")
        tmp = latest + f".{os.getpid()}"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(text)
        os.replace(tmp, latest)
        old = sorted(n for n in os.listdir(_DIR) if n[:1].isdigit())
        for name in old[:-_KEEP]:
            os.remove(os.path.join(_DIR, name))
    except Exception:
        pass


def _install():
    prev_sys = sys.excepthook

    def sys_hook(exc_type, exc_value, exc_tb):
        _record(exc_type, exc_value, exc_tb)
        prev_sys(exc_type, exc_value, exc_tb)

    sys.excepthook = sys_hook

    prev_thread = threading.excepthook

    def thread_hook(args):
        name = args.thread.name if args.thread is not None else None
        _record(args.exc_type, args.exc_value, args.exc_traceback, name)
        prev_thread(args)

    threading.excepthook = thread_hook


def _install_after_sitecustomize():
    """Install once ``sitecustomize`` has run.

    ``.pth`` files are processed before ``sitecustomize``, and Ubuntu's
    sitecustomize installs apport's ``sys.excepthook`` -- which would replace
    ours. So when called from a ``.pth`` during ``site.main()``, wrap
    ``site.execsitecustomize`` and install right after it (chaining to
    apport's hook). Otherwise install immediately.
    """
    import site

    orig = getattr(site, "execsitecustomize", None)
    if orig is None or "sitecustomize" in sys.modules:
        _install()
        return

    def wrapped():
        try:
            orig()
        finally:
            site.execsitecustomize = orig
            _install()

    site.execsitecustomize = wrapped


if os.environ.get("AITA_PYHOOK", "1") != "0" and not getattr(sys, "_aita_pyhook", False):
    sys._aita_pyhook = True
    _install_after_sitecustomize()
