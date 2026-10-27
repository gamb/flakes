;;; config.el -- My emacs configuration -*- lexical-binding: t  -*-

(require 'package)

(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(use-package exec-path-from-shell
  :demand t
  :config
  (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO" "LANG" "LC_CTYPE" "NIX_SSL_CERT_FILE" "NIX_PATH"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

;; Raycast launches the daemon with LC_ALL set to a Swift BCP-47 tag
;; ("en-GB-u-ca-gregory-..."), which setlocale rejects, and with no LANG to fall
;; back on -- so the daemon defaults to iso-latin-1 and prompts for a coding
;; system every time a buffer picks up an em dash.
(setenv "LC_ALL" "en_GB.UTF-8")
(setenv "LANG" "en_GB.UTF-8")
(set-locale-environment "en_GB.UTF-8")
(prefer-coding-system 'utf-8-unix)

(use-package emacs
  :custom
  (tool-bar-mode nil)
  (ring-bell-function 'ignore)
  (line-spacing 3)
  (cursor-type 'bar)
  (scroll-bar-mode nil)
  (frame-inhibit-implied-resize t)
  :config
  (global-set-key (kbd "M-`")
                  (if (fboundp 'ns-next-frame)
                      #'ns-next-frame
                    #'other-frame))
  ;; Configure modifiers for the compiled graphical backend.
  (cond
   ((featurep 'ns)
    (setq ns-alternate-modifier 'none
          ns-command-modifier 'meta))
   ((or (featurep 'pgtk) (featurep 'x))
    (setq x-super-keysym 'meta
          x-meta-keysym 'super)))
  (when (featurep 'ns)
    ;; Due to eldoc/ emoji line-height issues, thanks https://www.reddit.com/r/emacs/comments/1lbo5jy/comment/noely1y/
    (set-fontset-font "fontset-default" 'emoji "Noto Color Emoji")
    ;; (add-to-list 'default-frame-alist '(alpha . 96))
    ;; (dolist (frame (frame-list))
    ;;   (set-frame-parameter frame 'alpha 96))
    )

  ;; FUTURE: support multi-step font sizes and use repeat-mode to cycle values
  (defun font-size-toggle ()
    "Alternate the `default' face height between `font-size-toggle-heights'.

     Any other height goes to the first of the two."
    (interactive)
    (pcase-let ((`(,small . ,large) font-size-toggle-heights))
      (set-face-attribute 'default nil
                          :height (if (equal (face-attribute 'default :height) small)
                                      large
                                    small))))
  :custom-face
  (mode-line ((t (:weight light :background "grey90" :box nil))))
  (mode-line-inactive ((t (:weight light :background "grey95" :box nil))))
  (fringe ((t (:background nil)))))

(use-package ef-themes
  :demand t
  :custom
  (modus-themes-to-toggle '(ef-arbutus ef-autumn))
  :bind
  ("C-c t" . ef-themes-toggle)
  :config
  (load-theme 'ef-arbutus t))

(use-package ns-auto-titlebar
  :if (featurep 'ns)
  :demand t
  :config
  (ns-auto-titlebar-mode))

(use-package minibuffer
  :custom
  (completion-styles '(orderless basic)))

(use-package goto-addr
  :custom
  (global-goto-address-mode t))

(use-package simple
  :custom
  (indent-tabs-mode nil))

(use-package files
  :custom
  (make-backup-files nil)
  (require-final-newline t)
  ;; macos issue: https://github.com/d12frosted/homebrew-emacs-plus/issues/383#issuecomment-899157143
  ;; use e.g. `nix profile install nixpkgs#coreutils-prefixed` to get the "gls" binary
  (insert-directory-program (or (executable-find "gls") "ls")))

(use-package consult-imenu
  :after (consult))

(use-package consult
  :demand t
  :custom
  (consult-mode t)
  (consult-narrow-key ">")
  (consult-preview-key nil)
  :config

  (defcustom consult-preferred-grep-function #'consult-ripgrep
    "The consult grep function to use in `consult-grep-at-point'."
    :type 'function
    :group 'consult)

  (defun consult-grep-at-point (&optional dir initial)
    "Invokes the configured grep function using symbol at point as the initial search term.

     If called with a prefix argument, grep inside the `default-directory'
     instead of project-wide."
    (interactive (list (and current-prefix-arg default-directory)
                       (when-let ((s (symbol-at-point)))
			 (symbol-name s))))
    (funcall consult-preferred-grep-function dir initial))
  :bind
  (("C-x ," . consult-imenu)
   ("C-x b" . consult-buffer)
   ("M-?" . consult-grep-at-point)))

(use-package emacs-lisp-mode
  :hook
  (emacs-lisp-mode . paredit-mode)
  :bind
  (:map emacs-lisp-mode-map
	("M-?")
	("C-c C-c" . eval-buffer)))

(use-package xref
  :bind
  ("M-j" . xref-find-references))

(use-package orderless)

(use-package vertico
  ;; :custom
  ;; (vertico-group-format nil)
  :hook
  (after-init . vertico-mode)
  :bind
  (:map vertico-map
	("M-." . embark-export))
  ;;(define-key vertico-map (kbd "C-w") 'backward-kill-word)
  :config
  (setq vertico-sort-function #'vertico-sort-history-length-alpha))

(use-package which-key
  :config
  (which-key-mode 1))

(use-package embark
  :bind
  (("C-," . embark-act)
   (:map minibuffer-mode-map
         ("M-," . embark-become))))

(use-package embark-consult)

(use-package project
  :custom
  (project-vc-extra-root-markers '("package.json" "deps.edn"))
  (project-switch-commands 'magit-project-status)
  :bind
  (("M-P" . project-find-file)))

(use-package ibuffer-project
  :demand t
  :after ibuffer
  :config
  (add-hook 'ibuffer-hook
            (lambda ()
              (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))
              (unless (eq ibuffer-sorting-mode 'project-file-relative)
                (ibuffer-do-sort-by-project-file-relative)))))

(use-package ibuffer
  :bind ("C-x C-b" . ibuffer)

  :custom
  (ibuffer-formats '((mark modified read-only locked
                           " " (name 18 18 :left :elide)
			   " " (size 9 -1 :right)
			   " " (mode 16 16 :left :elide) " " project-file-relative)
		     ;;(mark " " (name 16 -1) " " project-file-relative)
                     )))

;; (use-package mode-line
;;   :custom-face
;;   )

(use-package dired
  :config
  (put 'dired-find-alternate-file 'disabled nil)
  :bind
  (:map dired-mode-map
        ("<mouse-2>" . dired-find-alternate-file))
  :custom
  (dired-kill-when-opening-new-dired-buffer t)
  :hook
  (dired-mode . dired-hide-details-mode))

(use-package winner
  :demand t
  :config
  (winner-mode 1))

(use-package eglot
  :bind
  (:map eglot-mode-map
	("C-c C-r" . eglot-rename))
  :custom
  (eglot-connect-timeout 3000)
  :config
  ;; NB. https://www.reddit.com/r/emacs/comments/1c898xg/comment/l1331u8
  ;; (setq-default eglot-workspace-configuration
  ;;             '(:completions
  ;;               (:completeFunctionCalls t)))
  (defun eglot-code-actions-temporary-map (&rest arg)
    (set-temporary-overlay-map
     (let ((map (make-sparse-keymap)))
       (define-key map (kbd "RET") 'eglot-code-actions)
       map)
     nil))
  ;; TODO: try remapping this instead
  (setq eglot-diagnostics-map
	(let ((map (make-sparse-keymap)))
	  (define-key map [mouse-1] #'eglot-code-actions-at-mouse)
	  map))
  (cl-loop for i from 1
           for type in '(eglot-note eglot-warning eglot-error)
           do (put type 'flymake-overlay-control
                   `((mouse-face . highlight)
                     (priority . ,(+ 50 i))
                     (keymap . ,eglot-diagnostics-map)))))

(use-package eglot-hierarchy
  ;; Awesome package.
  ;; Maybe not needed after 1.19 https://github.com/joaotavora/eglot/issues/614
  )

(use-package jarchive
  ;; Needed for Eglot https://github.com/joaotavora/eglot/issues/661#issuecomment-1362204524
  :config
  (jarchive-setup))

(use-package flymake
  ;; TODO: flymake-eslint ?? https://www.rahuljuliato.com/posts/eslint-on-emacs
  :config
  (advice-add 'flymake-goto-next-error :before #'eglot-code-actions-temporary-map)
  (advice-add 'eglot-code-actions :after #'eglot-code-actions-temporary-map)
  :bind
  (:map flymake-mode-map
	;; TODO: I think my real itch here is to have C-; work a bit like
	;; hippie-expand for positions i.e. cycle through the most likely buffer
	;; positions of which the positions of flymake errors are very likely
	;; candidates
        ("C-;" . flymake-goto-next-error)
        ("C-M-!" . flymake-show-buffer-diagnostics)))

;; (with-eval-after-load 'treemacs
;;   (define-key treemacs-mode-map [mouse-1] #'treemacs-single-click-expand-action))

(use-package ledger-mode
  :bind
  (:map ledger-mode-map
	("C-c C-c" . ledger-report)
	("M-a" . ledger-navigate-prev-xact-or-directive)
	("M-e" . ledger-navigate-next-xact-or-directive)
	("M-RET" . ledger-start-entry))
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-copy-env "LEDGER_FILE"))
  (defun ledger ()
    (interactive)
    (find-file (getenv "LEDGER_FILE"))
    (ledger-mode))
  (defun ledger-start-entry (&optional _arg)
    (interactive "p")
    (goto-char (point-max))
    (while (and (not (bobp))
		(progn (previous-line)
		       (looking-at-p "^\s*$"))))
    (forward-line)
    (delete-region (point) (point-max))
    (insert ?\n)
    (insert ?\n)
    (insert (format-time-string "%Y/%m/%d "))))

(use-package eat
  :bind
  ("M-o" . consult-buffer-other-window))

(use-package ghostel
  :commands ghostel)

(use-package agent-shell
  :custom
  (agent-shell-anthropic-authentication
   (agent-shell-anthropic-make-authentication :login t))
  (agent-shell-agent-configs
   '(agent-shell-anthropic-make-claude-code-config
     agent-shell-openai-make-codex-config
     agent-shell-google-make-gemini-config)))

(use-package move-dup
  :bind
  (:map move-dup-mode-map
	("C-M-<up>")))

(use-package window
  :custom
  (display-buffer-alist
   '(((and (derived-mode . magit-status-mode)
           (this-command . (magit-status
                            magit-project-status
                            project-switch-project)))
      (display-buffer-full-frame))
     ((and (derived-mode . org-agenda-mode)
           (this-command . org-agenda))
      (display-buffer-full-frame)))))

(use-package magit
  :demand t
  :custom
  (magit-bury-buffer-function #'magit-restore-window-configuration)
  :bind
  ((:map magit-blob-mode-map
         ("<return>" . magit-blob-visit-file))))

(use-package cider
  :custom
  (cider-xref-fn-depth 20)
  :bind
  (:map cider-mode-map
	("M-.") ;; Just use lsp xref
	("M-<RET>" . cider-pprint-eval-last-sexp)))

(use-package browse-kill-ring
  :bind
  ("M-Y" . browse-kill-ring))

(use-package slime
  :custom
  (inferior-lisp-program "sbcl")
  :bind
  (:map slime-mode-map
	(("M-." . slime-edit-definition))))

;; TODO: investigate puni-mode https://github.com/AmaiKinono/puni

(use-package paredit
  :demand t
  :bind
  (:map paredit-mode-map
	("C-k" . paredit-kill-tidy)
	("C-M-<up>" . paredit-splice-sexp-killing-backward))
  ;; :vc (:url "https://paredit.org/paredit.git"
  ;; 	    :rev :v26)
  :config
  (defun paredit-kill-tidy ()
    (interactive)
    (save-excursion
      (while (and (not (eobp))
		  (save-excursion
		    (beginning-of-line)
		    (looking-at "[\s\t]*\)")))
	(delete-indentation)))
    (paredit-kill))
  (dolist (binding '("RET" "M-s" "M-?"))
    (define-key paredit-mode-map (read-kbd-macro binding) nil))
  (define-key paredit-mode-map (kbd "C-M-<up>") 'paredit-splice-sexp-killing-backward))

(use-package clojure-mode
  :config
  (add-hook 'clojure-mode-hook #'paredit-mode)
  :demand t)

(use-package ocaml-ts-mode
  :after reformatter
  :config
  (defcustom ocp-indent-args nil
    "Arguments for \"ocp-indent\" invocation.")

  (reformatter-define ocp-indent
    :program "ocp-indent"
    :args ocp-indent-args
    :lighter " OCP")

  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 '(ocaml-ts-mode . ("ocamllsp")))))

(use-package tuareg)

(use-package nix-ts-mode
  :after reformatter
  :config
  (reformatter-define nixfmt
    :program "nixfmt"
    :lighter " nixfmt")
  (add-hook 'nix-ts-mode-hook #'nixfmt-on-save-mode))

(use-package j-mode
  :demand t
  :config
  (add-hook 'inferior-j-mode-hook (lambda () (electric-pair-mode -1)))
  :bind
  (:map j-mode-map
	("M-RET" . j-console-execute-line)))

(defcustom prettier-executable (executable-find "prettier")
  "Prettier executable."
  :type 'string
  :group 'prettier)

(use-package jtsx
  ;; NB. try using repeat-modes for modal-like editing with jsx
  :ensure t
  :mode (("\\.jsx?\\'" . jtsx-jsx-mode)
         ("\\.tsx\\'" . jtsx-tsx-mode)
         ("\\.ts\\'" . jtsx-typescript-mode))
  :commands jtsx-install-treesit-language
  :hook ((jtsx-jsx-mode . hs-minor-mode)
         (jtsx-tsx-mode . hs-minor-mode)
         (jtsx-typescript-mode . hs-minor-mode)))

;; (use-package typescript-ts-mode
;;   :demand t
;;   :config
;;   ;; TODO: capf snippets esp. to enable quick entry of jsx tags ??
;;   (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
;;   (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
;;   (reformatter-define prettier-ts
;;     :program prettier-executable
;;     :args '("--parser" "typescript"))
;;   :hook
;;   (typescript-ts-base-mode . prettier-ts-on-save-mode))

(use-package css-mode
  :hook
  (css-mode . prettier-css-on-save-mode)
  :config
  (reformatter-define prettier-css
    :program prettier-executable
    :args '("--parser" "css")))

(use-package justl
  :bind
  ("C-x j" . justl-exec-recipe-in-dir))

(use-package envrc
  :custom
  (envrc-async t)
  :config
  (envrc-global-mode))

(use-package marginalia
  :config
  (marginalia-mode))

(setq-default
 recentf-max-saved-items 1000
 recentf-exclude `("/tmp/" "/ssh:" ,(concat package-user-dir "/.*-autoloads\\.el\\'")))

(recentf-mode t)

(when (fboundp 'so-long-enable)
  (add-hook 'after-init-hook 'so-long-enable))

(setq-default history-length 1000)
(add-hook 'after-init-hook 'savehist-mode)

(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-ts-mode))

;; (use-package focus)

(use-package corfu
  :demand t
  :custom
  (corfu-auto t)
  (corfu-popupinfo-mode t)
  :bind
  (:map corfu-map
        ("<TAB>")
	("C-<return>" . corfu-quit)
	([escape] . corfu-quit)
	("M-." . corfu-move-to-minibuffer)
	("M-/" . hippie-expand))
  :config
  (global-corfu-mode)

  (defun corfu-move-to-minibuffer ()
    (interactive)
    (let ((completion-cycle-threshold completion-cycling))
      (apply #'consult-completion-in-region (cl-subseq completion-in-region--data 0 4)))))

(use-package cape)

(use-package tempel
  :demand t
  :custom
  (tempel-trigger-prefix "@")
  :bind
  (:map tempel-map
        ("<TAB>" . tempel-next))

  :config
  (defun tempel-setup-capf ()
    (setq-local completion-at-point-functions
                (cons #'tempel-complete
                      completion-at-point-functions)))

  (add-hook 'conf-mode-hook 'tempel-setup-capf)
  (add-hook 'prog-mode-hook 'tempel-setup-capf))

(use-package whole-line-or-region
  :demand t
  :config
  (whole-line-or-region-global-mode))

(use-package delsel
  :custom
  (delete-selection-mode t))

(use-package symbol-overlay
  :bind
  ("C-c C-r" . symbol-overlay-rename))

(use-package hippie-exp
  :config
  (defun try-complete-at-point (_old)
    ;; I want M-/ to run complete at point if there is no hippie
    ;; expansion. Useful on a blank line, before auto corfu has kicked
    ;; in to tell me about available properties.
    (completion-at-point))
  :bind
  (("M-/" . hippie-expand))
  :custom
  (hippie-expand-try-functions-list
   '(try-complete-file-name-partially
     try-complete-file-name
     try-expand-dabbrev
     try-expand-dabbrev-all-buffers
     try-expand-dabbrev-from-kill
     try-complete-at-point)))

(use-package simple
  :config
  (defun zap-to-char-basic (arg)
    "Same as zap-to-char except either zap forward or backward by the
first occurance (not ARGth occurance)."
    (interactive "p")
    (let ((current-prefix-arg (when (equal 4 arg) '(-1))))
      ;; TODO: temporary key map with 'z' bound to repeat zap in ARG direction
      (call-interactively 'zap-to-char)))
  :bind
  ("M-z" . zap-to-char-basic))

(use-package org
  :hook
  (org-mode . visual-line-mode)
  :bind
  ((:map org-mode-map
	 ("C-k" . org-archive-subtree))))

(use-package org-agenda
  ;; NB. since completion doesn't work within :custom macro, try using tempel templates
  :custom
  (org-agenda-files '("~/Documents/Pitch"))
  (org-agenda-restore-windows-after-quit t)
  :bind
  (("C-c a" . org-agenda)))

(use-package org-habit
  :custom
  (org-habit-show-habits t))

(use-package org-roam
  :bind
  ("M-m" . org-roam-node-find)
  :config

    (setq org-roam-capture-templates
        '(("d" "default" entry
           "* ${title}\n:PROPERTIES:\n:ID: %(org-id-new)\n:END:\n%?"
           :target (file "~/Documents/Pitch/todo.org")
           :unnarrowed t)))

  (setq org-roam-directory (expand-file-name "~/Documents/Pitch")))

(use-package prog-mode
  :hook
  (prog-mode . electric-pair-mode)
  :bind
  (:map prog-mode-map
        ("C-." . mark-sexp)))

(use-package minions
  :config
  (minions-mode))

(custom-set-variables
 '(use-package-enable-imenu-support t)
 '(use-short-answers t))

(setq custom-file (expand-file-name "~/.emacs"))
(load custom-file 'noerror 'nomessage)

;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
;;; init.el ends here
(put 'narrow-to-region 'disabled nil)
