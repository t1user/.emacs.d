;;; init.el --- Emacs configuration  -*- lexical-binding: t -*-

;; ========================================
;; PACKAGE MANAGEMENT
;; ========================================

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(when (not package-archive-contents)
  (package-refresh-contents))

(eval-when-compile
  (require 'use-package))

;; All packages auto-installed unless :ensure nil (built-ins)
(setq use-package-always-ensure t)

;; ========================================
;; CORE BEHAVIOR
;; ========================================

(use-package better-defaults
  :config
  (save-place-mode 1)
  (ido-mode -1)) ; we use vertico instead

(setq inhibit-startup-message t
      initial-scratch-message ""
      use-short-answers t
      calendar-week-start-day 1
      x-select-enable-clipboard t)

(global-display-line-numbers-mode 1)
(electric-pair-mode 1)
(add-hook 'text-mode-hook #'visual-line-mode)

(recentf-mode 1)
(setq recentf-max-menu-items 25
      recentf-max-saved-items 25)

(global-set-key (kbd "C-x C-r") #'recentf-open-files)
(global-set-key (kbd "M-o")     #'other-window)
(global-set-key (kbd "C-;")     #'comment-line)

;; ========================================
;; ENVIRONMENT DETECTION
;; ========================================

(defun my/wsl-p ()
  "Return non-nil if running inside WSL."
  (and (eq system-type 'gnu/linux)
       (getenv "WSL_DISTRO_NAME")))

;; ========================================
;; THEME
;; ========================================

;; ef-themes works correctly in both GUI and terminal.
;; To browse available themes: M-x ef-themes-select

(use-package ef-themes
  :config
  (defun my/apply-theme (&optional frame)
    (when frame
      (select-frame frame))
    (load-theme 'ef-dark t))

  (if (daemonp)
      (add-hook 'after-make-frame-functions #'my/apply-theme)
    (my/apply-theme)))

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

(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/set-font)
  (my/set-font))

;; ========================================
;; MINIBUFFER COMPLETION — VERTICO
;; ========================================

(use-package vertico
  :init (vertico-mode)
  :custom (vertico-cycle t))

;; Persist minibuffer history; vertico surfaces recent items first
(use-package savehist
  :ensure nil
  :init (savehist-mode))

;; Flexible space-separated matching (e.g. "py test" matches "python-pytest")
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; ── IDO (alternative — to switch: comment out the three use-packages above,
;;         uncomment this block, and remove (ido-mode -1) from better-defaults) ──
;;
;; (setq ido-enable-flex-matching t
;;       ido-everywhere t
;;       ido-use-filename-at-point 'guess
;;       ido-create-new-buffer 'always
;;       ido-file-extensions-order '(".py" ".org" ".txt" ".el" ".cfg" ".toml" ".yaml")
;;       ido-auto-merge-work-directories-length -1)
;; (ido-mode 1)
;; (defun ido-my-keys ()
;;   (define-key ido-completion-map (kbd "<up>")   'ido-prev-match)
;;   (define-key ido-completion-map (kbd "<down>") 'ido-next-match))
;; (add-hook 'ido-setup-hook 'ido-my-keys)
;; (global-set-key "\M-x"
;;                 (lambda ()
;;                   (interactive)
;;                   (call-interactively
;;                    (intern (ido-completing-read
;;                             "M-x " (all-completions "" obarray 'commandp))))))

;; ========================================
;; MARGINALIA
;; ========================================

;; Adds annotations to minibuffer candidates (docstrings for M-x,
;; file sizes for find-file, modes for buffer switching, etc.)
(use-package marginalia
  :init (marginalia-mode)
  :custom (marginalia-annotators
           '(marginalia-annotators-heavy marginalia-annotators-light nil)))

;; ========================================
;; WHICH-KEY
;; ========================================

(use-package which-key
  :config (which-key-mode))

;; ========================================
;; MAGIT
;; ========================================

(use-package magit
  :bind ("C-x g" . magit-status))

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

;; Corfu uses child frames which don't work in terminal — this fixes that
(use-package corfu-terminal
  :after corfu
  :config (corfu-terminal-mode 1))

;; ========================================
;; SYNTAX CHECKING — FLYCHECK
;; ========================================

(use-package flycheck
  :init (global-flycheck-mode))

;; Bridge between eglot (uses flymake by default) and flycheck
(use-package flycheck-eglot
  :after (flycheck eglot)
  :config (global-flycheck-eglot-mode 1))

;; ========================================
;; LSP — EGLOT
;; ========================================

;; Prerequisites — install outside Emacs:
;;   Python:        pip install pyright
;;   TypeScript/JS: npm install -g typescript-language-server typescript

(use-package eglot
  :ensure nil
  :hook ((python-ts-mode . eglot-ensure)
         (typescript-mode . eglot-ensure)
         (js-mode         . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '((python-ts-mode python-mode) . ("pyright-langserver" "--stdio"))))

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
  (defalias 'workon #'pyvenv-workon))

;; Auto-detect virtualenv per project (.venv, poetry, pipenv, pyenv)
;; and activate it via pyvenv
(use-package pet
  :config
  (add-hook 'python-base-mode-hook #'pet-mode -10)
  (add-hook 'python-base-mode-hook
            (lambda ()
              (when-let ((venv (and (fboundp 'pet-virtualenv-root)
                                   (pet-virtualenv-root))))
                (pyvenv-activate venv)))))

;; Black formatter on save
(use-package blacken
  :hook ((python-ts-mode python-mode) . blacken-mode))

;; Import sorting on save (buffer-local hook, python buffers only)
(use-package py-isort
  :hook ((python-ts-mode python-mode) .
         (lambda ()
           (add-hook 'before-save-hook #'py-isort-before-save nil t))))

;; Test runner — C-c t opens dispatch menu
(use-package python-pytest
  :bind ((:map python-ts-mode-map ("C-c t" . python-pytest-dispatch))
         (:map python-mode-map    ("C-c t" . python-pytest-dispatch))))

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
  :hook (yaml-mode . (lambda ()
                       (define-key yaml-mode-map
                         "\C-m" #'newline-and-indent))))

(use-package csv-mode)

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"        . markdown-mode))
  :init (setq markdown-command "multimarkdown"))

(use-package cython-mode)

(use-package kivy-mode
  :mode "\\.kv\\'"
  :hook (kivy-mode . (lambda ()
                       (electric-indent-local-mode t))))

;; ========================================
;; TERMINAL — VTERM
;; ========================================

(use-package vterm)

;; ========================================
;; ORG-MODE
;; ========================================

(use-package org
  :ensure nil
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c c" . org-capture))
  :custom
  (org-todo-keywords      '((sequence "TODO" "IN PROGRESS" "|" "DONE")))
  (org-log-done           'time)
  (org-hide-emphasis-markers t)
  (org-directory          "~/Documents/org/")
  (org-agenda-files       (list "~/Documents/org/inbox.org")))
