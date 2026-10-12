;;; init.el --- Emacs configuration  -*- lexical-binding: t -*-

;; ========================================
;; PACKAGE MANAGEMENT
;; ========================================

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(eval-when-compile
  (require 'use-package))

;; Install missing packages explicitly with M-x package-install.
;; Startup must not refresh archives or install packages over the network.
(setq use-package-always-ensure nil)

;; ========================================
;; CORE BEHAVIOR
;; ========================================

(use-package better-defaults
  :config
  (ido-mode -1))

(setq inhibit-startup-message t
      initial-scratch-message ""
      use-short-answers t
      calendar-week-start-day 1
      x-select-enable-clipboard t)

(global-display-line-numbers-mode -1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(electric-pair-mode 1)
(add-hook 'text-mode-hook #'visual-line-mode)

(recentf-mode 1)
(setq recentf-max-menu-items 25
      recentf-max-saved-items 25)

(global-set-key (kbd "C-x C-r") #'recentf-open-files)
(global-set-key (kbd "M-o")     #'other-window)
(global-set-key (kbd "C-;")     #'comment-line)
(with-eval-after-load 'flyspell
  (define-key flyspell-mode-map (kbd "C-;") nil))

;; Move text with Alt + arrow keys.
(use-package drag-stuff
  :config
  (drag-stuff-global-mode 1)
  (drag-stuff-define-keys))

;; ========================================
;; PROJECT DETECTION
;; ========================================

(require 'project)

(defun my/project-find-python (directory)
  "Find a non-VC Python project containing DIRECTORY."
  (when-let* ((root (locate-dominating-file
                    directory
                    (lambda (dir)
                      (or (file-regular-p (expand-file-name "pyproject.toml" dir))
                          (file-directory-p (expand-file-name ".venv" dir)))))))
    (cons 'transient root)))

;; Keep real VC projects first; support uv projects without a repository.
(add-hook 'project-find-functions #'my/project-find-python 90)

;; ========================================
;; EXEC PATH FROM SHELL
;; ========================================

;; Import PATH for GUI/daemon launches, including uv tool and Node executables.
(use-package exec-path-from-shell
  :config
  (when (not (getenv "EMACS_EXEC_PATH_INITIALIZED"))
    (exec-path-from-shell-initialize)
    (setenv "EMACS_EXEC_PATH_INITIALIZED" "1")))

;; ========================================
;; THEME
;; ========================================

(use-package material-theme
  :defer t)
(use-package ef-themes
  :defer t)
(use-package doom-themes
  :defer t)

(defun my/switch-theme (theme)
  "Disable all active themes then load THEME."
  (interactive (list (intern (completing-read
                             "Theme: "
                             (mapcar #'symbol-name (custom-available-themes))
                             nil t))))
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme theme t))

(defun my/apply-frame-theme (frame)
  "Select Material when graphical FRAME opens, including daemon clients."
  (when (display-graphic-p frame)
    ;; Material computes its palette from the selected display at load time.
    ;; Reload even if enabled: it may have been loaded from a terminal frame.
    (with-selected-frame frame
      (my/switch-theme 'material))))

;; Themes are session-wide: GUI clients select Material for the session,
;; while new terminal clients leave the chosen theme alone.
(add-hook 'after-make-frame-functions #'my/apply-frame-theme)
(my/switch-theme (if (display-graphic-p) 'material 'ef-elea-dark))

;; ========================================
;; FONTS & FRAME
;; ========================================

(add-to-list 'default-frame-alist '(fullscreen . maximized))

(defun my/set-font (&optional frame)
  "Set font for FRAME, or current frame if nil."
  (when (display-graphic-p (or frame (selected-frame)))
    (set-face-attribute 'default (or frame nil)
                        :family "DejaVu Sans Mono"
                        :height 113
                        :weight 'normal
                        :width 'normal)))

(add-hook 'after-make-frame-functions #'my/set-font)
(my/set-font)

;; ========================================
;; MINIBUFFER COMPLETION — VERTICO
;; ========================================

(use-package vertico
  :init (vertico-mode)
  :custom (vertico-cycle t))

;; Configure directory extension.
(use-package vertico-directory
  :after vertico
  :ensure nil
  ;; More convenient directory navigation commands
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  ;; Tidy shadowed file names
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;; better-defaults enables savehist-mode for minibuffer history.

;; Flexible space-separated matching (e.g. "py test" matches "python-pytest")
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; ========================================
;; MARGINALIA
;; ========================================

;; Adds annotations to minibuffer candidates (docstrings for M-x,
;; file sizes for find-file, modes for buffer switching, etc.)
(use-package marginalia
  :init (marginalia-mode))

;; ========================================
;; WHICH-KEY
;; ========================================

(use-package which-key
  :ensure nil
  :config (which-key-mode))

;; ========================================
;; MAGIT
;; ========================================

(use-package magit
  :bind ("C-x g" . magit-status)
  :hook (magit-mode . visual-line-mode))

;; ========================================
;; TREE-SITTER
;; ========================================

;; Auto-installs grammars and maps modes. Falls back gracefully
;; if a grammar isn't available (e.g. on older WSL install).
(use-package treesit-auto
  :custom (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; ========================================
;; IN-BUFFER COMPLETION — CORFU
;; ========================================

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  :init (global-corfu-mode))

;; Emacs 31 supports terminal child frames; corfu-terminal is unnecessary.

;; ========================================
;; SYNTAX CHECKING — FLYCHECK
;; ========================================

;; Use Flycheck's native Eglot bridge, not the separate flycheck-eglot package.
(use-package flycheck
  :init (global-flycheck-mode 1)
  :config (global-flycheck-eglot-mode 1))

;; Alternative: comment out Flycheck above, uncomment the following, and restart.
;; (use-package flymake
;;   :ensure nil
;;   :hook (prog-mode . flymake-mode))
;;
;; (defun my/elisp-flymake-setup ()
;;   "Use only non-compiling Lisp diagnostics in untrusted buffers."
;;   (unless (trusted-content-p)
;;     (remove-hook 'flymake-diagnostic-functions
;;                  #'elisp-flymake-byte-compile t)))
;;
;; ;; Lisp registers its backends after prog-mode-hook has run.
;; (add-hook 'emacs-lisp-mode-hook #'my/elisp-flymake-setup)

;; ========================================
;; LSP — EGLOT
;; ========================================

;; Prerequisites — install outside Emacs:
;;   Python:        uv tool install pyright
;;   TypeScript/JS: npm install -g typescript-language-server typescript

(use-package eglot
  :ensure nil
  :hook ((python-base-mode . eglot-ensure)
         (python-base-mode . superword-mode)
         (python-base-mode . flyspell-prog-mode)
         (typescript-mode . eglot-ensure)
         (typescript-ts-base-mode . eglot-ensure)
         (js-base-mode . eglot-ensure))
  ;; Preserve the existing allowance for large workspaces.  This does not
  ;; change the operating system's inotify limits.
  :custom (eglot-max-file-watches 524288)
  :bind (:map eglot-mode-map
              ("C-c C-e" . eglot-rename)
              ("C-c C-f" . eglot-format-buffer)
              ("C-c C-d" . eldoc))
  :config
  (add-to-list 'eglot-server-programs
               '((python-ts-mode python-mode) . ("pyright-langserver" "--stdio"))))
(use-package lua-mode :ensure nil)

;; ========================================
;; PYTHON
;; ========================================

(use-package python
  :ensure nil
  :custom
  (python-shell-interpreter "python3")
  (python-shell-interpreter-args "-i")
  ;; Workaround for readline completion warning
  (python-shell-completion-native-enable nil))

;; Virtual environment management
(use-package pyvenv
  :config
  (defalias 'workon #'pyvenv-workon)
  (pyvenv-mode t))

;; Docstrings
(use-package python-docstring
  :hook (python-base-mode . python-docstring-mode)
  :config
  (setq python-docstring-sentence-end-double-space nil))

(defun my/python-virtualenv-root ()
  "Find the nearest .venv, stopping at a Python or VC project boundary."
  (let* ((project (project-current nil))
         (project-root (and project (expand-file-name (project-root project))))
         (root (locate-dominating-file
                default-directory
                (lambda (dir)
                  (or (equal (expand-file-name dir) project-root)
                      (file-regular-p (expand-file-name "pyproject.toml" dir))
                      (file-directory-p (expand-file-name ".venv" dir))))))
         (venv (and root (expand-file-name ".venv" root))))
    (when (and venv (file-directory-p venv))
      (file-name-as-directory venv))))

(defun my/pet-virtualenv-root (original)
  "Use the local project's .venv; preserve ORIGINAL for remote buffers."
  (if (file-remote-p default-directory)
      (funcall original)
    (my/python-virtualenv-root)))

(defun my/pet-executable-find (original executable &optional search-globally)
  "Find EXECUTABLE in .venv, then global PATH; use ORIGINAL remotely."
  (if (file-remote-p default-directory)
      (funcall original executable search-globally)
    (let* ((venv (my/python-virtualenv-root))
           (local (and venv (expand-file-name executable
                                             (expand-file-name "bin" venv))))
           (exec-path (default-value 'exec-path)))
      (or (and local (file-executable-p local) (not (file-directory-p local))
               local)
          (when (or search-globally pet-search-globally)
            ;; Eglot temporarily redirects executable-find through PET.
            ;; Use PET's saved original finder to avoid recursive lookup.
            (or (pet--executable-find executable)
                (and (equal executable "python")
                     (pet--executable-find "python3"))))))))

(defun my/python-tools-setup ()
  "Set usable formatter commands and pytest context after PET discovery."
  (unless (file-remote-p default-directory)
    (let ((venv (my/python-virtualenv-root)))
      (setq-local exec-path
                  (append (and venv (list (expand-file-name "bin" venv)))
                          (default-value 'exec-path)))
      (setq-local process-environment
                  (copy-sequence (default-value 'process-environment)))
      (when venv
        (setenv "VIRTUAL_ENV" (directory-file-name venv))
        (setenv "PATH" (concat (expand-file-name "bin" venv)
                               path-separator (or (getenv "PATH") ""))))))
  (setq-local blacken-executable (or (pet-executable-find "black") "black"))
  ;; python-pytest builds a shell command without quoting the executable.
  (setq-local python-pytest-executable
              (shell-quote-argument (or (pet-executable-find "pytest") "pytest")))
  (unless (project-current nil)
    (setq-local python-pytest-project-root-override default-directory)
    (setq-local python-pytest-project-name-override
                (file-name-nondirectory (directory-file-name default-directory)))
    (setq-local python-pytest-unsaved-buffers-behavior 'ask-current)))

;; Retain PET's Eglot, REPL, and formatter integration, while
;; using .venv -> global PATH rather than pre-commit or inherited environments.
(use-package pet
  :custom
  ;; uv configuration belongs at the root or above the current file, not
  ;; inside an unrelated subtree or the virtualenv's installed packages.
  (pet-find-file-functions '(pet-find-file-from-project-root
                             pet-locate-dominating-file))
  :config
  (advice-add 'pet-virtualenv-root :around #'my/pet-virtualenv-root)
  (advice-add 'pet-executable-find :around #'my/pet-executable-find)
  (add-hook 'pet-after-buffer-local-vars-setup #'my/python-tools-setup)
  (add-hook 'python-base-mode-hook #'pet-mode -10))

;; Black formatter on save.
(use-package blacken
  :hook (python-base-mode . blacken-mode))

(defun my/py-isort-call-executable (errbuf file)
  "Sort FILE using the project's isort; send diagnostics to ERRBUF."
  (let ((executable (or (pet-executable-find "isort") "isort"))
        (default-directory (py-isort--find-settings-path)))
    (zerop (apply #'call-process executable
                  nil errbuf nil file
                  (concat "--settings-path=" default-directory)
                  py-isort-options))))

(defun my/python-isort-before-save ()
  "Sort Python imports before Black, skipping unavailable isort."
  (when (derived-mode-p 'python-base-mode)
    (if (pet-executable-find "isort")
        (py-isort-buffer)
      (message "Skipping import sorting: isort is not installed"))))

(defun my/python-enable-isort ()
  "Enable import sorting for the current Python buffer."
  (add-hook 'before-save-hook #'my/python-isort-before-save -10 t))

;; Adapt the installed legacy wrapper to current isort arguments and paths.
(use-package py-isort
  :hook (python-base-mode . my/python-enable-isort)
  :config
  (advice-add 'py-isort--call-executable :override #'my/py-isort-call-executable))

;; C-c t opens the test dispatch menu in both Python modes.
(use-package python-pytest
  :bind (:map python-base-mode-map ("C-c t" . python-pytest-dispatch)))

;; ========================================
;; SNIPPETS & DOCSTRINGS
;; ========================================

(use-package yasnippet
  :config (yas-global-mode 1))

(use-package yasnippet-snippets)

;; Google-style Python docstring
;; Usage: type 'gdoc' then TAB inside a Python function body
(with-eval-after-load 'yasnippet
  (yas-define-snippets
   'python-ts-mode
   '(("gdoc"
      "\"\"\"${1:Summary line.}\n\nArgs:\n    ${2:param}: ${3:Description.}\n\nReturns:\n    ${4:Description.}\n\"\"\"\n$0"
      "Google-style docstring")))
  ;; Also available in plain python-mode
  (yas-define-snippets
   'python-mode
   '(("gdoc"
      "\"\"\"${1:Summary line.}\n\nArgs:\n    ${2:param}: ${3:Description.}\n\nReturns:\n    ${4:Description.}\n\"\"\"\n$0"
      "Google-style docstring"))))

;; ========================================
;; WEB / JS / TS
;; ========================================

;; Handles HTML templates, Jinja, Django templates, mixed files
(use-package web-mode
  :mode (("\\.html?\\'"  . web-mode)
         ("\\.jinja2?\\'" . web-mode)
         ("\\.djhtml\\'" . web-mode)))

(use-package typescript-mode
  :mode "\\.ts\\'")

;; js-mode is built-in; treesit-auto maps it to js-ts-mode automatically

;; ========================================
;; OTHER MODES
;; ========================================

(use-package yaml-mode
  :mode "\\.ya?ml\\'"
  :bind (:map yaml-mode-map ("RET" . newline-and-indent)))

(use-package csv-mode)

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"        . markdown-mode))
  :init (setq markdown-command "pandoc"))

(use-package cython-mode)

(use-package kivy-mode
  :mode "\\.kv\\'"
  :hook (kivy-mode . (lambda ()
                       (electric-indent-local-mode t))))

;; ========================================
;; TERMINAL — VTERM (and EAT)
;; ========================================

(use-package vterm
  :commands (vterm vterm-other-window))

(use-package eat
  :commands (eat eat-other-window eat-project eat-project-other-window))
