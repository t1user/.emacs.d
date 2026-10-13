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

Emacs activates installed packages automatically before loading `init.el`.
There is no additional `package-initialize` call in the configuration.

Built-in libraries and extensions supplied by another package use `:ensure nil`.
External programs, including language servers and Python formatters, must still
be installed separately.

Eat and Vterm load on demand. Ef loads during startup to select `ef-elea-dark`.
Yasnippet loads after one second of idle time, followed by its snippet collection.
Use `M-x yas-insert-snippet` to load and use snippets immediately if needed.

Recent-file tracking is enabled at startup; list cleanup runs after 10 seconds
of idle time.

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

Pyright retains PET's project interpreter configuration. The existing Eglot
file-watch allowance is preserved; it does not raise operating-system inotify
limits.

Line numbers are enabled in programming buffers through `prog-mode-hook`.
Text, terminal, compilation, and pytest output buffers keep them disabled.

## Frames and themes

Ef and Modus are configured. `ef-elea-dark` is selected at
startup for both graphical and terminal sessions, including daemon clients.
Use `M-x modus-themes-select` to choose from both collections, or
`M-x ef-themes-select` to choose only Ef themes. Themes are shared by all frames
in the session.

Graphical frames use DejaVu Sans Mono at 11.3 points through the standard
`default` face setting. Terminal fonts are selected by the terminal emulator.

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
