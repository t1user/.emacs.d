; init.el --- Emacs configuration

;; INSTALL PACKAGES
;; --------------------------------------

;(setq debug-on-error t)

(require 'package)

(add-to-list 'package-archives
       '("melpa" . "http://melpa.org/packages/") t)

(package-initialize)

;; If there are no archived package contents, refresh them
(when (not package-archive-contents)
  (package-refresh-contents))

(defvar myPackages
  '(
    ein
    flycheck
    magit
    elpy
    material-theme
    py-autopep8
    ))


;; Scans the list in myPackages
;; If the package listed is not already installed, install it
(mapc #'(lambda (package)
    (unless (package-installed-p package)
      (package-install package)))
      myPackages)


;;;========================================
;;;       verify this shit
;;;========================================

;; This is from different source, has to be eventually reconciled with the previous
;; Initialize the packages, avoiding a re-initialization.

(unless (bound-and-true-p package--initialized)
  (package-initialize))

;; Make sure `use-package' is available.

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Configure `use-package' prior to loading it.

(eval-and-compile
  (setq use-package-always-ensure nil)
  (setq use-package-always-defer nil)
  (setq use-package-always-demand nil)
  (setq use-package-expand-minimally nil)
  (setq use-package-enable-imenu-support t)
  (setq use-package-compute-statistics nil)
  ;; The following is VERY IMPORTANT.  Write hooks using their real name
  ;; instead of a shorter version: after-init ==> `after-init-hook'.
  ;;
  ;; This is to empower help commands with their contextual awareness,
  ;; such as `describe-symbol'.
  (setq use-package-hook-name-suffix nil))

(eval-when-compile
  (require 'use-package))

;; ========================================
;;       BASIC CUSTOMIZATION
;; ========================================


(setq inhibit-startup-message t) ;; hide the startup message
;; (load-theme 'material t) ;; load material theme

;; ======================================================================
;; This is supposed to prevent terminal from screwing up graphical frames

;; Function to load the material theme only for graphical frames
(defun load-material-theme (frame)
  "Load the material theme for graphical frames only."
  (select-frame frame)
  (when (display-graphic-p frame)  ; Check if the frame is graphical
    (load-theme 'material t)))

;; Load theme immediately if not in daemon mode
(unless (daemonp)
  (if (display-graphic-p)  ; Check if initial frame is graphical
      (load-theme 'material t)))

;; Hook for daemon mode to apply theme to new graphical frames
(when (daemonp)
  (add-hook 'after-make-frame-functions #'load-material-theme))

;; ======================================================================

(use-package better-defaults
  :ensure t
  :config
  (save-place-mode 1))

(use-package csv-mode
  :ensure t
  )

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown"))


(use-package yaml-mode
  :ensure t
  :custom (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
  )

(add-hook 'yaml-mode-hook
      #'(lambda ()
        (define-key yaml-mode-map "\C-m" 'newline-and-indent)))


;; keep list of recent files
;; accessible by C-x C-r
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)


;; (global-linum-mode t) ;; enable line numbers globally
(global-display-line-numbers-mode 1)
;; (setq make-backup-files nil) ;; don't create backup~ files
;; (menu-bar-mode -1) ;; Switch off menu
;; (toggle-scroll-bar -1) ;; Switch off scroll bar
;; (tool-bar-mode -1) ;; Switch off tool bar
;; show buffer list in the current window (rather than the other window)
;; (global-set-key "\C-x\C-b" 'buffer-menu)

(setq initial-scratch-message "") ;; initial scratch message blank
(setq use-short-answers t) ;; y and n instead of yes and no
(add-hook 'text-mode-hook 'visual-line-mode) ;; Sensible line breaking for text modes
(setq calendar-week-start-day 1) ;; calendar week starts on Monday
;;(delete-selection-mode t) ;; Start writing straight after deletion
;; (put 'narrow-to-region 'disabled nil) ; Allows narrowing bound to C-x n n (region) and C-x n w (widen)

;; auto-close parens and quotes
(electric-pair-mode 1)

;; use S-<arrow> to move to window ('meta replaces shift)
;; (windmove-default-keybindings 'meta)

(global-set-key (kbd "M-o") 'other-window) ;; use M-o to move window
;; (global-set-key (kbd "M-o") 'ace-window) ;; use M-o to move window
;; (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)) ;; ace-window will use letters instead of numbers
(global-set-key (kbd "C-;") 'comment-line) ;; this should be standard but somehow isn't
(setq x-select-enable-clipboard t) ;; use clipboard to copy between apps

;; Enable richer annotations using the Marginalia package

(use-package marginalia
  :pin melpa
  :ensure t
  :defer 3
  :custom (marginalia-annotators '(marginalia-annotators-light))
  :config
  (marginalia-mode))


(use-package cython-mode
  :ensure t)

;; ========================================
;;       ORG-MODE CONFIGURATION
;; ========================================


(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)

(setq org-todo-keywords
      '((sequence "TODO"  "IN PROGRESS" "|" "DONE")))

(setq org-log-done 'time)

(setq org-hide-emphasis-markers t)

(setq org-directory "~/Documents/org/")
(setq org-agenda-files (list "inbox.org"))

;; (org-babel-do-load-languages
;;  'org-babel-load-languages
;;  '((python . t)))

(use-package ox-twbs
  :ensure t)

;; ========================================
;;       ORG-ROAM CONFIGURATION
;; ========================================

;; (use-package org-roam
;;   :ensure t
;;   :custom
;;   (org-roam-directory (file-truename "/path/to/org-files/"))
;;   :bind (("C-c n l" . org-roam-buffer-toggle)
;;          ("C-c n f" . org-roam-node-find)
;;          ("C-c n g" . org-roam-graph)
;;          ("C-c n i" . org-roam-node-insert)
;;          ("C-c n c" . org-roam-capture)
;;          ;; Dailies
;;          ("C-c n j" . org-roam-dailies-capture-today))
;;   :config
;;   ;; If you're using a vertical completion framework, you might want
;;   ;; a more informative completion interface
;;   (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
;;   (org-roam-db-autosync-mode)
;;   ;; If using org-roam-protocol
;;   (require 'org-roam-protocol))

;; ========================================
;;     IDO MODE CONFIGURATION
;; ========================================

(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)
(setq ido-use-filename-at-point 'guess)
(setq ido-create-new-buffer 'always)
(setq ido-file-extensions-order '(".py" ".org" ".txt" ".el" ".cfg" ".toml" ".yaml"))
(setq ido-auto-merge-work-directories-length -1)
(defun ido-my-keys ()
  (define-key ido-completion-map (kbd "<up>")   'ido-prev-match)
  (define-key ido-completion-map (kbd "<down>") 'ido-next-match))

(add-hook 'ido-setup-hook 'ido-my-keys)
;; use ido in M-x
(global-set-key "\M-x"
                (lambda ()
                  (interactive)
                  (call-interactively
                   (intern
                    (ido-completing-read
                     "M-x "
                     (all-completions "" obarray 'commandp))))))



;; ========================================
;;     PYTHON CONFIGURATION
;; ========================================


;; all elpy code would have to be include in use-package -> TODO
;; (use-package elpy
;;   :ensure t
;;   :defer t
;;   :init
;;   (advice-add 'python-mode :before 'elpy-enable))

(use-package py-isort
  :ensure t)

(elpy-enable)
;; elpy to use standard interpreter
(setq python-shell-interpreter "python3"
     python-shell-interpreter-args "-i")

;; elpy to use jupyter console
;; (setq python-shell-interpreter "jupyter"
;;      python-shell-interpreter-args "console --simple-prompt"
;;      python-shell-prompt-detect-failure-warning nil)
;; (add-to-list 'python-shell-completion-native-disabled-interpreters
;; 	     "jupyter")

;; elpy to use ipython
;; (setq python-shell-interpreter "ipython"
;;       python-shell-interpreter-args "-i --simple-prompt")
      
(setq elpy-rpc-virtualenv-path 'default)
(setq elpy-rpc-python-command "python")
(setq elpy-rpc-backend "jedi")


;; use flycheck not flymake with elpy
(when (require 'flycheck nil t)
  (setq elpy-modules (delq 'elpy-module-flymake elpy-modules))
  (add-hook 'elpy-mode-hook 'flycheck-mode))


; This configures flycheck to display window always on the bottom of the screen
;; (add-to-list 'display-buffer-alist
;;              `(,(rx bos "*Flycheck errors*" eos)
;;               (display-buffer-reuse-window
;;                display-buffer-in-side-window)
;;               (side            . bottom)
;;               (reusable-frames . visible)
;;               (window-height   . 0.2)))

;; enable autopep8 formatting on save
;; (require 'py-autopep8)
;; (add-hook 'elpy-mode-hook 'py-autopep8-enable-on-save)

;; elpy autoformat code by yapf
;; (add-hook 'elpy-mode-hook (lambda ()
;;                            (add-hook 'before-save-hook
;;                                      'elpy-format-code nil t)))

; ---------------------
; This was added to have black check code only if black enabled in pyproject.toml
;; (defun elpy-black-fix-code (&optional only-if-config)
;;   "Automatically formats Python code with black.

;; if ONLY-IF-CONFIG is non-nil, only fix the code when a '[black]'
;; section in the project 'pyproject.toml' is found."
;;   (interactive)
;;   (when (or (not only-if-config)
;;             (let ((pyproject (concat (file-name-as-directory
;;                                       (elpy-project-root))
;;                                      "pyproject.toml")))
;;               (and (file-exists-p pyproject)
;;                    (with-temp-buffer
;;                      (insert-file-contents pyproject)
;;                      (search-forward "[black]" nil t)))))
;;     (elpy--fix-code-with-formatter "fix_code_with_black")))
;--------------------

;; elpy autoformat code by black
(add-hook 'elpy-mode-hook (lambda ()
                            (add-hook 'before-save-hook
                                      'elpy-black-fix-code nil t)))

(add-hook 'before-save-hook 'py-isort-before-save)

;; set default test runner as pytest
(setq elpy-test-runner 'elpy-test-pytest-runner)

;; alias for 'workon'
(defalias 'workon 'pyvenv-workon)


;; work-around for bug with python-shell-interpreter
;; source: https://emacs.stackexchange.com/questions/30082/your-python-shell-interpreter-doesn-t-seem-to-support-readline
(setq python-shell-completion-native-enable nil)


;; ensure jupyter images are displayed
(setq ein:output-area-inlined-images t)


(use-package python-docstring
  :ensure t)

(add-hook 'python-mode-hook 'python-docstring-mode)

(setq python-fill-docstring-style 'symetric)

;; numpy docstring for python
;; (use-package numpydoc
;;   :ensure t
;;   :defer t
;;   :after python
;;   :custom
;;   (numpydoc-insert-examples-block nil)
;;   (numpydoc-insertion-style nil)
;;   (numpydoc-template-long nil)
;;   :bind (:map elpy-mode-map
;;               ("C-c C-n" . numpydoc-generate)))


;; (add-hook 'python-mode-hook (lambda ()
;;                                   (require 'sphinx-doc)
;;                                   (sphinx-doc-mode t)))

;; (setq sphinx-doc-include-types t)

;; ========================================
;;     End Python Config
;; ========================================



(add-to-list 'default-frame-alist '(fullscreen  . maximized))

;; (add-to-list 'default-frame-alist '(font . "Monospace-12"))

;; Set default font
(set-face-attribute 'default nil
                    :family "DejaVu Sans Mono"
                    :height 113
                    :weight 'normal
                    :width 'normal)

;; (defun my-python-noindent-docstring (&optional _previous)
;;   (if (eq (car (python-indent-context)) :inside-docstring)
;;       'noindent))

;; (advice-add 'python-indent-line :before-until #'my-python-noindent-docstring)



;; pandoc
(use-package pandoc-mode
  :ensure t
  :hook (markdown-mode . pandoc-mode)
  :config
  (define-key pandoc-mode-map (kbd "C-c p p") 'pandoc-run-pandoc)
  (define-key pandoc-mode-map (kbd "C-c p f") 'pandoc-set-output-format))


(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode)
  :init
  (setq markdown-command "pandoc"))


(add-to-list 'load-path "~/.emacs.d/site-lisp/")
(require 'kivy-mode)
(add-to-list 'auto-mode-alist '("\\.kv$" . kivy-mode))

(add-hook 'kivy-mode-hook
          #'(lambda ()
             (electric-indent-local-mode t)))

(use-package vterm
  :ensure t)

(use-package auto-virtualenv
  :load-path "~/.emacs.d/site-lisp/auto-virtualenv/"
  :config
  (setq auto-virtualenv-verbose t)
  (auto-virtualenv-setup))

(projectile-mode +1)
;; Recommended keymap prefix on Windows/Linux
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
