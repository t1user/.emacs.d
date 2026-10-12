# Emacs configuration

This configuration targets Emacs 31.1. `init.el` contains the active setup;
`better-defaults` loads `custom.el` and enables history, saved places, and backups.
Generated state, installed packages, and caches remain outside version control.

## Packages and startup

Startup does not refresh archives or install packages. When setting up a new
installation, run `M-x package-refresh-contents`, then use `M-x package-install`
for missing packages named in the `use-package` declarations.

Eat, Vterm, and theme libraries load on demand. The initially selected theme
still loads immediately; unused theme libraries wait until a theme is selected.

`exec-path-from-shell` imports the shell PATH, including executables installed
through `uv tool`. Global Python tools can be installed explicitly with:

```sh
uv tool install pyright
uv tool install black
uv tool install isort
```

No global pytest or mypy installation is required when those tools are present
in a project's `.venv/bin` directory.

## Python environments

Local Python buffers use the nearest project's `.venv/bin` executable first,
then the executable on Emacs's global PATH. Missing `python` falls back to
`python3`. Discovery stops at a Python project (`pyproject.toml` or `.venv`) or
VC boundary, so a nested project without its own environment does not borrow
an outer project's environment.

Git projects retain the VC backend. Non-Git Python projects use the built-in
transient project backend. Git detection uses Emacs's normal VC project finder;
there is no additional Git subprocess for validating each lookup.

PET supplies the existing Eglot, interpreter, and formatter integration.
For local buffers its environment/tool discovery follows the policy above,
instead of selecting pre-commit, Conda, Poetry, pyenv, or an inherited
`VIRTUAL_ENV`. Remote buffers retain PET's original discovery.

Saving Python files sorts imports with isort before running Black. The legacy
isort wrapper is adapted to current command arguments and the discovered
executable. Import sorting is skipped if isort is absent. Black still needs to
be installed locally or globally. Configure isort's Black-compatible profile
in the project's configuration when needed; this Emacs setup does not change
project formatting options.

`C-c t` opens the pytest dispatch menu in both Python modes. Outside projects,
pytest runs from the current directory and asks about saving the current buffer.
Project tool paths, PATH, and environment changes remain buffer-local.

To inspect resolution, use `M-:` in the relevant Python buffer:

```elisp
(project-current nil)
(pet-virtualenv-root)
(pet-executable-find "python")
(pet-executable-find "black")
(pet-executable-find "isort")
(pet-executable-find "pytest")
```

Flycheck is enabled globally, with its native Eglot bridge displaying
language-server diagnostics in managed buffers and disabling Flymake there.
Use `M-x flycheck-next-error` or `M-x flycheck-list-errors` to inspect diagnostics.
The obsolete separate `flycheck-eglot` package is not used.

The Flymake alternative remains commented out in `init.el`. To switch back,
comment out the Flycheck block, uncomment the Flymake block and its Lisp setup,
and restart Emacs.

Pyright retains PET's project interpreter configuration. The existing Eglot
file-watch allowance is preserved; it does not raise operating-system inotify
limits.

Line numbers are enabled in programming buffers through `prog-mode-hook`.
Text, terminal, compilation, and pytest output buffers keep them disabled.

## Frames and themes

GUI startup and graphical `emacsclient` frames automatically select `material`.
The client hook selects the new GUI frame while reloading Material, because
Material calculates its palette from the selected display at load time.
Terminal startup and the daemon's initial frame use `ef-elea-dark`. Themes are
shared by the session: opening a GUI client selects Material for existing frames
as well, and opening a terminal client does not switch it back. Use
`M-x my/switch-theme` to switch explicitly. Fonts are applied to new graphical
frames, including frames created by a non-daemon session.

## Validation

With the configured packages already installed, run from this directory:

```sh
emacs -Q --batch -l tests/init-tests.el -f ert-run-tests-batch-and-exit
```

Tests load the configuration with network package operations forbidden and
histories/caches redirected to temporary storage. They cover Git and non-Git
projects, executable fallback, environment isolation,
formatter arguments and ordering, mode hooks, and Eglot contact configuration.
They suppress language-server startup and grammar installation.

Restart Emacs, including any daemon, to activate configuration changes in an
existing session.
