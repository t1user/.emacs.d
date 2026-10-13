;;; init-tests.el --- Configuration regression tests -*- lexical-binding: t -*-

(require 'ert)
(require 'cl-lib)
(require 'package)

(defconst my/test-config-directory
  (file-name-directory (directory-file-name (file-name-directory load-file-name))))

;; Load the full configuration, but keep histories and caches in /tmp.
(setq native-comp-jit-compilation nil
      user-emacs-directory (make-temp-file "emacs-init-tests-" t)
      package-user-dir (or (getenv "EMACS_TEST_PACKAGE_DIR")
                           (expand-file-name "elpa" my/test-config-directory))
      treesit-extra-load-path (list (expand-file-name "tree-sitter" my/test-config-directory)))
(setenv "EMACS_EXEC_PATH_INITIALIZED" "1")
(cl-letf (((symbol-function 'package-refresh-contents)
           (lambda (&rest _) (error "Unexpected archive refresh during startup")))
          ((symbol-function 'package-install)
           (lambda (&rest _) (error "Unexpected package installation during startup"))))
  (load (expand-file-name "init.el" my/test-config-directory) nil nil t))

(require 'eglot)
(require 'pet)
(require 'apheleia)
(require 'python-pytest)
(require 'typescript-mode)
(require 'typescript-ts-mode)
(require 'js)
(setq treesit-auto-install nil
      treesit-auto-install-grammar nil)

(defun my/test-executable (directory name)
  "Create a harmless executable called NAME in DIRECTORY."
  (make-directory directory t)
  (let ((file (expand-file-name name directory)))
    (write-region "#!/bin/sh\nexit 0\n" nil file nil 'silent)
    (set-file-modes file #o755)
    file))

(defun my/test-python-project (root &optional git)
  "Create a Python project at ROOT, optionally initialized with GIT."
  (make-directory root t)
  (write-region "[project]\nname = \"fixture\"\nversion = \"0.1.0\"\n"
                nil (expand-file-name "pyproject.toml" root) nil 'silent)
  (when git
    (should (eq 0 (process-file "git" nil nil nil "init" "--quiet" root))))
  (expand-file-name ".venv/bin" root))

(defmacro my/test-with-directory (&rest body)
  "Run BODY in a temporary directory and remove its fixtures afterward."
  (declare (indent 0) (debug t))
  `(let* ((test-root (make-temp-file "emacs-python-test-" t))
          (default-directory (file-name-as-directory test-root))
          (process-environment (copy-sequence process-environment))
          ;; Do not inherit unrelated VC markers from the temporary parent.
          (vc-ignore-dir-regexp
           (concat "\\`" (regexp-quote (file-name-directory test-root)) "\\'")))
     (setenv "VIRTUAL_ENV" nil)
     (unwind-protect (progn ,@body)
       (delete-directory test-root t))))

(ert-deftest my/project-preserves-real-git-repository ()
  (my/test-with-directory
    (my/test-python-project test-root t)
    (let ((project (project-current nil)))
      (should (equal (seq-take project 2) '(vc Git)))
      (should (file-equal-p (project-root project) test-root)))))

(ert-deftest my/project-preserves-gitfile-repository ()
  (my/test-with-directory
    (let ((root (expand-file-name "worktree" test-root))
          (gitdir (expand-file-name "metadata" test-root)))
      (should (eq 0 (process-file "git" nil nil nil "init" "--quiet"
                                 (concat "--separate-git-dir=" gitdir) root)))
      (let ((project (project-current nil root)))
        (should (equal (seq-take project 2) '(vc Git)))
        (should (file-equal-p (project-root project) root))))))

(ert-deftest my/project-recognizes-non-git-python-root ()
  (my/test-with-directory
    (my/test-python-project test-root)
    (let ((project (project-current nil)))
      (should (eq (car project) 'vc))
      (should (file-equal-p (project-root project) test-root)))))

(ert-deftest my/python-discovers-venv-without-git-or-pyproject ()
  (my/test-with-directory
    (let* ((bin (expand-file-name ".venv/bin" test-root))
           (python (my/test-executable bin "python"))
           (subdir (expand-file-name "src" test-root)))
      (make-directory subdir)
      (let ((default-directory (file-name-as-directory subdir)))
        (should (eq (car (project-current nil)) 'vc))
        (should (equal (pet-executable-find "python") python))))))

(ert-deftest my/python-uses-global-python3-when-python-is-absent ()
  (my/test-with-directory
    (let* ((bin (expand-file-name "global/bin" test-root))
           (python (my/test-executable bin "python3"))
           (exec-path (list bin)))
      (should (equal (pet-executable-find "python") python)))))

(ert-deftest my/python-prefers-project-tools-in-git-and-non-git-projects ()
  (dolist (git '(nil t))
    (my/test-with-directory
      (let* ((bin (my/test-python-project test-root git))
             (local (my/test-executable bin "black"))
             (global-bin (expand-file-name "global/bin" test-root))
             (exec-path (cons global-bin exec-path)))
        (my/test-executable global-bin "black")
        (should (equal (pet-executable-find "black") local))
        (should (equal (pet-virtualenv-root)
                       (file-name-as-directory (file-name-directory bin))))))))

(ert-deftest my/python-honors-inherited-virtualenv ()
  (my/test-with-directory
    (let* ((bin (my/test-python-project test-root))
           (inherited (expand-file-name "inherited" test-root))
           (black (my/test-executable (expand-file-name "bin" inherited) "black")))
      (my/test-executable bin "black")
      (setenv "VIRTUAL_ENV" inherited)
      (should (file-equal-p (pet-virtualenv-root) inherited))
      (should (equal (pet-executable-find "black") black)))))

(ert-deftest my/python-falls-back-for-missing-local-tool ()
  (my/test-with-directory
    (let* ((bin (my/test-python-project test-root))
           (global-bin (expand-file-name "global/bin" test-root))
           (global (my/test-executable global-bin "black"))
           (exec-path (cons global-bin exec-path)))
      (make-directory bin t)
      ;; A directory or a broken symlink must not count as an executable.
      (make-directory (expand-file-name "black" bin))
      (should (equal (pet-executable-find "black") global))
      (delete-directory (expand-file-name "black" bin))
      (make-symbolic-link "/nonexistent/emacs-test-tool" (expand-file-name "black" bin))
      (should (equal (pet-executable-find "black") global)))))

(ert-deftest my/python-global-fallback-without-project-or-venv ()
  (dolist (project '(nil t))
    (my/test-with-directory
      (when project (my/test-python-project test-root))
      (let* ((global-bin (expand-file-name "global/bin" test-root))
             (global (my/test-executable global-bin "black"))
             (exec-path (cons global-bin exec-path)))
        (should-not (pet-virtualenv-root))
        (should (equal (pet-executable-find "black") global))
        (should-not (pet-executable-find "emacs-test-unavailable-tool"))))))

(ert-deftest my/python-discovers-nested-project-environment ()
  (my/test-with-directory
    (my/test-python-project test-root t)
    (let* ((inner (expand-file-name "inner" test-root))
           (bin (my/test-python-project inner))
           (local (my/test-executable bin "black"))
           (default-directory (file-name-as-directory inner)))
      (should (equal (pet-executable-find "black") local)))))

(ert-deftest my/python-tools-are-buffer-local-through-pet ()
  (my/test-with-directory
    (let* ((root (expand-file-name "project with spaces" test-root))
           (bin (my/test-python-project root))
           (pytest (my/test-executable bin "pytest"))
           (black (my/test-executable bin "black"))
           (isort (my/test-executable bin "isort"))
           (original-formatters (copy-tree apheleia-formatters))
           (original-path (getenv "PATH")))
      (with-temp-buffer
        (setq default-directory (file-name-as-directory root))
        (pet-buffer-local-vars-setup)
        (should (equal python-pytest-executable pytest))
        (should (equal (car (alist-get 'black apheleia-formatters)) black))
        (should (equal (car (alist-get 'isort apheleia-formatters)) isort))
        (should (local-variable-p 'apheleia-formatters))
        (should (equal (getenv "PATH") original-path)))
      (should (equal apheleia-formatters original-formatters)))))

(ert-deftest my/python-and-js-mode-hooks-start-eglot ()
  (my/test-with-directory
    (let (calls)
      (cl-letf (((symbol-function 'eglot-ensure)
                 (lambda () (push major-mode calls)))
                ((symbol-function 'flyspell-prog-mode) #'ignore)
                ((symbol-function 'treesit-ensure-installed) (lambda (&rest _) nil))
                ((symbol-function 'treesit-ready-p) (lambda (&rest _) nil)))
        (dolist (mode '(python-mode python-ts-mode js-mode js-ts-mode
                                   typescript-mode typescript-ts-mode tsx-ts-mode))
          (with-temp-buffer
            (funcall mode)
            (should (memq mode calls))
            (when (derived-mode-p 'python-base-mode)
              (should pet-mode)
              (should (eq (key-binding (kbd "C-c t")) #'python-pytest-dispatch))
              (should apheleia-mode)
              (should (memq #'apheleia-format-after-save after-save-hook))
              (should (equal (alist-get major-mode apheleia-mode-alist)
                             '(isort black))))))))))

(ert-deftest my/apheleia-chains-project-isort-and-black ()
  (my/test-with-directory
    (let* ((root (expand-file-name "project with spaces" test-root))
           (bin (my/test-python-project root))
           (isort (my/test-executable bin "isort"))
           (black (my/test-executable bin "black")))
      ;; Each fixture consumes its input and produces the next stage's text.
      (write-region "#!/bin/sh\ncat >/dev/null\nprintf 'import a\\nimport z\\nx=1\\n'\n"
                    nil isort nil 'silent)
      (write-region "#!/bin/sh\ninput=$(cat)\ncase \"$input\" in 'import a'*) printf 'import a\\nimport z\\n\\nx = 1\\n';; *) exit 1;; esac\n"
                    nil black nil 'silent)
      (with-temp-buffer
        (setq default-directory (file-name-as-directory root)
              buffer-file-name (expand-file-name "example.py" root))
        (insert "import z\nimport a\nx=1\n")
        (pet-buffer-local-vars-setup)
        (let ((finished nil) result
              (deadline (+ (float-time) 10)))
          (apheleia-format-buffer
           '(isort black) nil
           :callback (lambda (&rest args)
                       (setq result (plist-get args :error)
                             finished t)))
          (while (and (not finished) (< (float-time) deadline))
            (accept-process-output nil 0.05))
          (should finished)
          (should-not result)
          (should (equal (buffer-string) "import a\nimport z\n\nx = 1\n")))))))

(ert-deftest my/pyright-contact-keeps-project-python ()
  (my/test-with-directory
    (let* ((bin (my/test-python-project test-root))
           (python (my/test-executable bin "python"))
           (global-bin (expand-file-name "global/bin" test-root))
           (server (my/test-executable global-bin "pyright-langserver"))
           (exec-path (cons global-bin exec-path)))
      (should (equal (pet-executable-find "pyright-langserver") server))
      (should (equal (plist-get (plist-get
                                (pet-lookup-eglot-server-initialization-options
                                 '("pyright-langserver" "--stdio"))
                                :python)
                               :pythonPath)
                     python)))))

(ert-deftest my/pyright-settings-preserve-pet-interpreter ()
  (let* ((pet-config '(:python (:pythonPath "/project/.venv/bin/python")))
         (merged (pet-merge-eglot-initialization-options
                  eglot-workspace-configuration pet-config)))
    (should-not (default-value 'eglot-workspace-configuration))
    (should (equal (plist-get (plist-get merged :python) :pythonPath)
                   "/project/.venv/bin/python"))))

(ert-deftest my/eglot-contact-resolution-does-not-recurse ()
  (my/test-with-directory
    (let* ((bin (my/test-python-project test-root t))
           (python (my/test-executable bin "python"))
           (global-bin (expand-file-name "global/bin" test-root))
           (server (my/test-executable global-bin "pyright-langserver"))
           (exec-path (cons global-bin exec-path)))
      (with-temp-buffer
        (setq major-mode 'python-mode
              buffer-file-name (expand-file-name "example.py" test-root))
        (pet-eglot-setup)
        (let* ((contact (nth 3 (eglot--guess-contact)))
               (options (plist-get (nthcdr 2 contact) :initializationOptions)))
          (should (equal (car contact) server))
          (should (equal (plist-get (plist-get options :python) :pythonPath)
                         python)))))))

(ert-deftest my/flycheck-uses-native-eglot-integration ()
  (should (bound-and-true-p global-flycheck-mode))
  (should (bound-and-true-p global-flycheck-eglot-mode))
  (should (featurep 'flycheck))
  (should-not (featurep 'flycheck-eglot))
  (should (memq #'flycheck-eglot--managed-mode-update eglot-managed-mode-hook))
  (should-not (memq #'flymake-mode prog-mode-hook))
  (with-temp-buffer
    (emacs-lisp-mode)
    (should-not flymake-mode)))

;;; init-tests.el ends here
