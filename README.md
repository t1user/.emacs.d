# Emacs configuration

This configuration targets Emacs 31.1. `init.el` contains the active setup;
`better-defaults` loads `custom.el` and enables history, saved places, and backups.
Generated state, installed packages, and caches remain outside version control.

## Packages and startup

`use-package` installs missing Emacs packages before configuring them, including
packages whose loading is deferred. The first startup on a clean machine needs
network access to GNU ELPA, NonGNU ELPA, and MELPA and can take longer while
packages are downloaded and compiled. Subsequent startups reuse installed
packages; they do not automatically upgrade them.

Built-in libraries and extensions supplied by another package use `:ensure nil`.
External programs, including language servers and Python formatters, must still
be installed separately.

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

PET handles Python environment discovery and sets buffer-local executable paths
for Eglot, Flycheck, pytest, and Apheleia. Its standard discovery considers a
cached or inherited `VIRTUAL_ENV`, supported environment managers, and local
`.venv`, `venv`, or `env` directories. Tool discovery also considers configured
pre-commit environments, then the selected virtualenv, pyenv, and global
`exec-path`. The configuration does not override PET's discovery functions or
activate environments globally with pyvenv.

Emacs's built-in `project-vc-extra-root-markers` recognizes `pyproject.toml` and
`.venv`, including projects outside version control. PET uses the standard
project backend. Unlike the previous custom finder, PET's default virtualenv
search can find an environment above a nested project, and an inherited
`VIRTUAL_ENV` can take precedence over a local `.venv`.

Apheleia runs isort followed by Black asynchronously after saving, then saves
the formatted result. PET supplies the formatter executable paths before
formatting modes are enabled. Both tools must be available; a missing or failing
formatter stops the chain. Configure isort's Black-compatible profile in the
project's configuration when needed; this setup does not change project
formatting options. The old Blacken and py-isort save hooks are no longer used.

`C-c t` opens python-pytest's dispatch menu in both Python modes. It uses PET's
selected pytest executable and the package's standard project and unsaved-buffer
behavior. The previous special handling for files outside projects and quoting
pytest executable paths containing spaces has been removed; these cases follow
the installed python-pytest package's behavior.

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
`M-x my/switch-theme` to switch explicitly. The explicit DejaVu Sans Mono font
setup is commented out so graphical frames use Emacs's default font selection.
Terminal fonts are selected by the terminal emulator.

## Validation

With the configured packages already installed, run from this directory:

```sh
emacs -Q --batch -l tests/init-tests.el -f ert-run-tests-batch-and-exit
```

Tests load the configuration with network package operations forbidden and
histories/caches redirected to temporary storage. They cover Git and non-Git
project markers, PET's inherited-environment precedence and tool paths,
Apheleia's formatter chain, mode hooks, and Eglot contact configuration. They
suppress language-server startup and grammar installation. Missing packages
must be installed before running this offline regression suite.

Set `EMACS_TEST_PACKAGE_DIR` to test a separate package installation.

Restart Emacs, including any daemon, to activate configuration changes in an
existing session.
