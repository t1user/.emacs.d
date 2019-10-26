;; init.el --- Emacs configuration

;; INSTALL PACKAGES
;; --------------------------------------

(require 'package)

(add-to-list 'package-archives
       '("melpa" . "http://melpa.org/packages/") t)

(package-initialize)
(when (not package-archive-contents)
  (package-refresh-contents))

(defvar myPackages
  '(better-defaults
    ein
    elpy
    flycheck
    material-theme
    py-autopep8
    ))

(mapc #'(lambda (package)
    (unless (package-installed-p package)
      (package-install package)))
      myPackages)


;; BASIC CUSTOMIZATION
;; --------------------------------------

(setq inhibit-startup-message t) ;; hide the startup message
(load-theme 'material-light t) ;; load material theme (TM: changed to material-light)
(global-linum-mode t) ;; enable line numbers globally
(setq make-backup-files nil) ;; don't create backup~ files
(menu-bar-mode -1) ;; Switch off menu
(toggle-scroll-bar -1)
(tool-bar-mode -1)
(global-set-key "\C-x\C-b" 'buffer-menu) ;; rebind of buffer listing keys


;; PYTHON CONFIGURATION
;; --------------------------------------

(elpy-enable)

;; elpy to use standard interpreter
(setq python-shell-interpreter "python3"
      python-shell-interpreter-args "-i")

;; elpy to use jupyter console
;;(setq python-shell-interpreter "jupyter"
;;      python-shell-interpreter-args "console --simple-prompt"
;;      python-shell-prompt-detect-failure-warning nil)
;;(add-to-list 'python-shell-completion-native-disabled-interpreters
;;	     "jupyter")

;; elpy to use ipython
;;(setq python-shell-interpreter "ipython"
;;      python-shell-interpreter-args "-i --simple-prompt"
      
;; deprecated statement from real python website
;;(elpy-use-ipython)

(setq elpy-rpc-python-command "python")


;; use flycheck not flymake with elpy
(when (require 'flycheck nil t)
  (setq elpy-modules (delq 'elpy-module-flymake elpy-modules))
  (add-hook 'elpy-mode-hook 'flycheck-mode))

;; enable autopep8 formatting on save
(require 'py-autopep8)
(add-hook 'elpy-mode-hook 'py-autopep8-enable-on-save)


;; change font
(set-default-font "Monospace 12")


;; work-around for bug with python-shell-interpreter
;; source: https://emacs.stackexchange.com/questions/30082/your-python-shell-interpreter-doesn-t-seem-to-support-readline
(setq python-shell-completion-native-enable nil)



;; init.el ends here


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(elpy-syntax-check-command "flake8")
 '(pyvenv-workon "elpy-rpc-venv"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
