;;; init.el --- Emacs init.el file
;;; Commentary:
;;; Code:

(setq inhibit-startup-message t ; Don't show the splash screen
      visible-bell t)           ; Flash when the bell rings

(menu-bar-mode -1)              ; no menu bar
(tool-bar-mode -1)              ; no toolbar
(scroll-bar-mode -1)            ; no scrollbar

(require 'package)

(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archive-priorities '("melpa-stable" . 50) t)
(add-to-list 'package-archive-priorities '("melpa" . 10) t)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package-ensure)
(eval-and-compile
  (setq use-package-always-ensure t
        use-package-expand-minimally t))

(use-package auto-package-update
  :config
  (setq auto-package-update-delete-old-versions t
	auto-package-update-hide-results t)
  (auto-package-update-maybe))

;; set firacode font
(set-face-attribute 'default nil :font "FiraCode Nerd Font")
(add-to-list 'default-frame-alist
             '(font . "FiraCode Nerd Font-10"))

;; Display line numbers in all buffers
(global-display-line-numbers-mode 1)

;; indent guides
(use-package highlight-indent-guides
  :init
  (setq highlight-indent-guides-method 'character)
  :hook
  (prog-mode . highlight-indent-guides-mode))

;; fix shell path
;;(use-package exec-path-from-shell
;;  :config
;;  (when (or (memq window-system '(mac ns x)) (daemonp))
;;    (exec-path-from-shell-initialize)))

;; search tools
(use-package ag)
(use-package rg)

;; navigate faster with avy
(use-package avy
  :config
  (avy-setup-default))

;;treemacs
(use-package treemacs
  :defer t)

;; make emacs write custom configuration to separate file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(use-package all-the-icons)
(use-package nerd-icons)
;; doom themes
(use-package doom-themes
  :after (all-the-icons nerd-icons)
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; modeline
(use-package doom-modeline
  :after (doom-themes)
  :init (doom-modeline-mode 1))

;; vertico
(use-package vertico
  :bind
  (:map vertico-map
	("C-j" . vertico-next)
	("C-k" . vertico-previous)
	("C-f" . vertico-exit)
	:map minibuffer-local-map
	("M-h" . backward-kill-word))
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode))

;; extensions for vertico
(use-package orderless
  :after vertico
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :after vertico
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode))

;; Do not allow the cursor in the minibuffer prompt
(setq minibuffer-prompt-properties
      '(read-only t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;; remember last edited file
(recentf-mode 1)

;; Save what you enter into minibuffer prompts
(setq history-length 25)
(use-package savehist
  :init
  (savehist-mode 1))

;; Remember and restore the last cursor location of opened files
(save-place-mode 1)

;; Don't pop up UI dialogs when prompting
(setq use-dialog-box nil)

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;; Revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

;; start maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; disable backups
(setq make-backup-files nil)
(setq auto-save-default nil)

;; highlight current line in buffer
(global-hl-line-mode 1)

(setq user-full-name "Sahir Maredia"
      user-mail-address "sahirzm@gmail.com")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; fill-column
(setq-default fill-column 120)
(setq-default display-fill-column-indicator t)
(setq-default display-fill-column-indicator-character 9474)

;; sync both clipboards
(setq select-enable-clipboard t)

;; Projectile
(use-package projectile
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
	      ("C-c p" . projectile-command-map))
  :config
  (setq projectile-project-search-path '("~/workspace/")))

(use-package which-key
  :init
  (which-key-mode))

;; completions
(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
	 ("C-c r" . consult-recent-file)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;; By default `consult-project-function' uses `project-root' from project.el.
  ;; Optionally configure a different project root function.
  ;;;; 1. project.el (the default)
  ;; (setq consult-project-function #'consult--default-project--function)
  ;;;; 2. vc.el (vc-root-dir)
  ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
  ;;;; 3. locate-dominating-file
  ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
  ;;;; 4. projectile.el (projectile-project-root)
  ;; (autoload 'projectile-project-root "projectile")
  ;; (setq consult-project-function (lambda (_) (projectile-project-root)))
  ;;;; 5. No project support
  ;; (setq consult-project-function nil)
  )

(use-package consult-flycheck
  :after consult
  :bind (
	 ("M-g f" . consult-flycheck)               ;; Alternative: consult-flycheck
	 ))

;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

(use-package corfu
  ;; Optional customizations
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)                 ;; Enable auto completion
  ;; (corfu-separator ?\s)          ;; Orderless field separator
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect 'prompt)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin

  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.
  ;; This is recommended since Dabbrev can be used globally (M-/).
  ;; See also `corfu-exclude-modes'.
  :init
  (global-corfu-mode))

(use-package cape)

(use-package orderless
  :init
  ;; Tune the global completion style settings to your liking!
  ;; This affects the minibuffer and non-lsp completion at point.
  (setq completion-styles '(orderless partial-completion basic)
        completion-category-defaults nil
        completion-category-overrides nil))

;; Dependencies for LSP
(use-package flycheck
  :init (global-flycheck-mode))
(use-package yasnippet :config (yas-global-mode))
(use-package lsp-mode
  :custom
  (lsp-completion-provider :none) ;; we use Corfu!
  :commands
  (lsp lsp-deferred)
  :init
  (setenv "LSP_USE_PLISTS" "1")
  (defun my/orderless-dispatch-flex-first (_pattern index _total)
    (and (eq index 0) 'orderless-flex))

  (defun my/lsp-mode-setup-completion ()
    (setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
	  '(orderless)))

  ;; Optionally configure the first word as flex filtered.
  (add-hook 'orderless-style-dispatchers #' my/orderless-dispatch-flex-first nil 'local)

  ;; Optionally configure the cape-capf-buster.
  (setq-local completion-at-point-functions (list (cape-capf-buster #'lsp-completion-at-point)))
  (setq lsp-keymap-prefix "C-c l")

  :hook
  (lsp-completion-mode . my/lsp-mode-setup-completion)
  :config
  (lsp-enable-which-key-integration t)
  (setq read-process-output-max (* 1024 1024 3)
	gc-cons-threshold 100000000
	lsp-idle-delay 0.500
	lsp-file-watch-threshold 3000
	lsp-enable-on-type-formatting nil)
  :bind (:map lsp-mode-map
	      ("C-c d" . lsp-describe-thing-at-point)
	      ("C-c a" . lsp-execute-code-action)))

(use-package hydra)

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode))

(use-package lsp-treemacs
  :after lsp)

;; Java LSP
(setq lombok-path
      (concat
       "-javaagent:"
       (expand-file-name
	(concat
	 (file-name-directory (or load-file-name (buffer-file-name)))
	 "libs/lombok/lombok-1.18.28.jar"))))

(setq lsp-java-vmargs
      (cons
       lombok-path
       '("-XX:+UseParallelGC"
	 "-XX:GCTimeRatio=4"
	 "-XX:AdaptiveSizePolicyWeight=90"
	 "-Dsun.zip.disableMemoryMapping=true"
	 "-Xmx4G"
	 "-Xms100m")))

(use-package lsp-java
  :config
  (add-hook 'java-mode-hook 'lsp)
  (setq lsp-java-format-on-type-enabled nil))

(use-package dap-mode
  :after lsp-mode
  :config
  (dap-auto-configure-mode))

(use-package dap-java
  :ensure nil)

;; Kotlin LSP
(use-package kotlin-mode
  :hook (kotlin-mode . lsp-deferred)
  :config
  (setq lsp-kotlin-debug-adapter-enabled t))

(use-package flycheck-kotlin
  :hook
  (kotlin-mode . flycheck-mode))

;; Typescript LSP
(use-package typescript-ts-mode
  :mode (("\\.ts\\'" . typescript-ts-mode)
	 ("\\.tsx\\'" . tsx-ts-mode))
  :hook ((typescript-ts-mode . lsp-deferred)
	 (tsx-ts-mode . lsp-deferred))
  :config
  (setq typescript-indent-level 2
	lsp-javascript-format-enable nil))

(use-package rjsx-mode
  :hook
  (rjsx-mode . lsp-deferred))

;; nix LSP
(use-package lsp-mode)

(use-package lsp-nix
  :ensure lsp-mode
  :after (lsp-mode)
  :demand t
  :custom
  (lsp-nix-nil-formatter ["nixpkgs-fmt"]))

(use-package nix-mode
  :hook (nix-mode . lsp-deferred))

;; format code
(use-package format-all
  :hook
  (prog-mode . format-all-mode))    ;; format on save

(use-package editorconfig
  :config
  (editorconfig-mode 1))

;; colorful parens
(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

;; org mode

;; magit
(use-package magit
  :bind (("C-x g" . magit-status))
  :config
  (setq magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1))

;; yaml-mode
(use-package yaml-mode
  :mode "\\.ya?ml\\'")

;; auto switch to tree-sitter modes
(use-package treesit-auto
  :config
  (global-treesit-auto-mode 1)
  (setq treesit-auto-install t))

(provide 'init)
;;; init.el ends here
