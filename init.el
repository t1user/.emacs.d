;;; init.el --- Emacs configuration  -*- lexical-binding: t -*-

;; ========================================
;; PACKAGE MANAGEMENT
;; ========================================

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(eval-when-compile
  (require 'use-package))

;; Install missing packages before configuring them, including deferred packages.
;; Built-in libraries and bundled extensions opt out with :ensure nil.
(setq use-package-always-ensure t)

;; ========================================
;; CORE BEHAVIOR
;; ========================================

;; Enable Vertico first so better-defaults does not activate Ido.
(use-package vertico
  :config (vertico-mode)
  :custom (vertico-cycle t))

(use-package better-defaults)

(setq inhibit-startup-message t
      initial-scratch-message ""
      use-short-answers t
      calendar-week-start-day 1
      x-select-enable-clipboard t)

(global-display-line-numbers-mode -1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(electric-pair-mode 1)
(add-hook 'text-mode-hook #'visual-line-mode)

(use-package recentf
  :ensure nil
  :custom
  (recentf-auto-cleanup 10)
  (recentf-max-menu-items 25)
  (recentf-max-saved-items 25)
  :config (recentf-mode 1))

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

;; Recognize Python projects, including projects outside version control.
(add-to-list 'project-vc-extra-root-markers "pyproject.toml")
(add-to-list 'project-vc-extra-root-markers ".venv")

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

(use-package ef-themes
  :config
  (ef-themes-load-theme 'ef-elea-dark))

(use-package modus-themes
  :after ef-themes
  :config
  (modus-themes-include-derivatives-mode 1))

;; ========================================
;; FONTS & FRAME
;; ========================================

(add-to-list 'default-frame-alist '(fullscreen . maximized))
(set-face-attribute 'default nil :family "DejaVu Sans Mono" :height 113)

;; ========================================
;; MINIBUFFER COMPLETION — VERTICO
;; ========================================

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
  :config (marginalia-mode))

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
  :config (global-corfu-mode))

;; Emacs 31 supports terminal child frames; corfu-terminal is unnecessary.

;; ========================================
;; SYNTAX CHECKING — FLYCHECK
;; ========================================

;; Use Flycheck's native Eglot bridge, not the separate flycheck-eglot package.
(use-package flycheck
  :config
  (global-flycheck-mode 1)
  (global-flycheck-eglot-mode 1))

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
(use-package lua-mode)

;; ========================================
;; PYTHON
;; ========================================

(use-package python
  :ensure nil
  :custom
  (python-shell-interpreter "python3")
  (python-shell-interpreter-args "-i"))

;; Docstrings
(use-package python-docstring
  :hook (python-base-mode . python-docstring-mode)
  :config
  (setq python-docstring-sentence-end-double-space nil))

;; Load formatter definitions before PET assigns buffer-local executable paths.
(use-package apheleia
  :demand t
  :hook (python-base-mode . apheleia-mode)
  :config
  (setf (alist-get 'python-mode apheleia-mode-alist) '(isort black)
        (alist-get 'python-ts-mode apheleia-mode-alist) '(isort black)))

;; PET owns environment discovery and tool paths. Run it before Eglot and
;; formatting modes so they see the selected project's executables.
(use-package pet
  :commands pet-mode
  :init
  (add-hook 'python-base-mode-hook #'pet-mode -10))

;; C-c t opens the test dispatch menu in both Python modes.
(use-package python-pytest
  :bind (:map python-base-mode-map ("C-c t" . python-pytest-dispatch)))

;; ========================================
;; SNIPPETS & DOCSTRINGS
;; ========================================

(use-package yasnippet
  :defer 5
  :config (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

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
