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

(unless (package-installed-p 'vc-use-package)
  (package-vc-install "https://github.com/slotThe/vc-use-package"))
(require 'vc-use-package)

(eval-and-compile
  (setq use-package-always-ensure t
        use-package-expand-minimally t
        package-native-compile t
        native-comp-async-report-warnings-errors nil))

(use-package auto-package-update
  :custom
  (auto-package-update-delete-old-versions t)
  (auto-package-update-hide-results t)
  :config
  (auto-package-update-maybe))

;; set firacode font
(set-face-attribute 'default nil :font "FiraCode Nerd Font-11")
(add-to-list 'default-frame-alist
             '(font . "FiraCode Nerd Font-11"))
(setq line-spacing 0.1)

;; Display line numbers in all buffers
(global-display-line-numbers-mode 1)
(electric-pair-mode t)
(column-number-mode)
(line-number-mode)
(minibuffer-electric-default-mode 1)

;; prettify symbols
(global-prettify-symbols-mode t)
(setq-default
 prettify-symbols-alist `(("lambda" . "λ")))

;; indent configuration
;; use spaces for indent
(setq-default indent-tabs-mode nil)
(setq tab-width 2)
(defvaralias 'web-mode-markup-indent-offset 'tab-width)
(defvaralias 'web-mode-css-indent-offset 'tab-width)
(defvaralias 'web-mode-code-indent-offset 'tab-width)
(defvaralias 'c-basic-offset 'tab-width)
(defvaralias 'css-indent-offset 'tab-width)

;; indent guides
(use-package highlight-indent-guides
  :config
  (setq highlight-indent-guides-method 'character
        highlight-indent-guides-auto-character-face-perc 50
        highlight-indent-guides-responsive 'top)
  :hook
  (prog-mode . highlight-indent-guides-mode))

;; fix shell path
(use-package exec-path-from-shell
  :config
  (when (or (memq window-system '(mac ns x)) (daemonp))
    (exec-path-from-shell-initialize)))

;; file backups
(defvar backup-directory (concat user-emacs-directory "backups"))
(if (not (file-exists-p backup-directory))
    (make-directory backup-directory t))
(setq backup-directory-alist `((".*" . ,backup-directory)))
(setq make-backup-files t               ; backup of a file the first time it is saved.
      backup-by-copying t               ; don't clobber symlinks
      version-control t                 ; version numbers for backup files
      delete-old-versions t             ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 6               ; oldest versions to keep when a new numbered backup is made (default: 2)
      kept-new-versions 9               ; newest versions to keep when a new numbered backup is made (default: 2)
      auto-save-default t               ; auto-save every buffer that visits a file
      auto-save-timeout 20              ; number of seconds idle time before auto-save (default: 30)
      auto-save-interval 200            ; number of keystrokes between auto-saves (default: 300)
      )
;; lock files location
(defvar lock-file-directory (concat user-emacs-directory "lock-files"))
(if (not (file-exists-p lock-file-directory))
    (make-directory lock-file-directory t))
(setq lock-file-name-transforms
      `(("\\(?:[^/]*/\\)*\\(.*\\)" ,(concat lock-file-directory "\\1") t)))

;; search tools
(use-package ag)
(use-package rg)

;; navigate faster with avy
(use-package avy
  :bind
  (("C-'" . avy-goto-char-timer)
   ("M-g l" . avy-goto-line)
   ("M-g w" . avy-goto-word-1))
  :config
  (avy-setup-default))

;; expand-region
(use-package expand-region
  :bind
  ("C-@" . er/expand-region))
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
  (load-theme 'doom-tokyo-night t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (setq-default doom-themes-treemacs-theme "doom-colors") ; use "doom-colors" for less minimal icon theme
  (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;; modeline
(use-package doom-modeline
  :after (doom-themes)
  :init
  (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 30
        doom-modeline-project-detection 'auto
        doom-modeline-persp-name t))

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
  (completion-styles '(orderless partial-completion basic))
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

;; start maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; highlight current line in buffer
(global-hl-line-mode 1)

(setq user-full-name "Sahir Maredia"
      user-mail-address "sahirzm@gmail.com")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq-default display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq-default org-directory "~/org/")

;; fill-column
(setq-default fill-column 140)
(setq-default display-fill-column-indicator t)
(setq-default display-fill-column-indicator-character 9474)

;; sync both clipboards
(setq select-enable-clipboard t)

;; Dired
;; Revert Dired and other buffers
(setq-default global-auto-revert-non-file-buffers t)
(setf dired-kill-when-opening-new-dired-buffer t)

;; Show icons based on file types
(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))
;; font coloring based on file types
(use-package dired-rainbow
  :config
  (progn
    (dired-rainbow-define-chmod directory "#6cb2eb" "d.*")
    (dired-rainbow-define html "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
    (dired-rainbow-define xml "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
    (dired-rainbow-define document "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
    (dired-rainbow-define markdown "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
    (dired-rainbow-define database "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
    (dired-rainbow-define media "#de751f" ("mp3" "mp4" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
    (dired-rainbow-define image "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
    (dired-rainbow-define log "#c17d11" ("log"))
    (dired-rainbow-define shell "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
    (dired-rainbow-define interpreted "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
    (dired-rainbow-define compiled "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
    (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
    (dired-rainbow-define compressed "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
    (dired-rainbow-define packaged "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
    (dired-rainbow-define encrypted "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
    (dired-rainbow-define fonts "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
    (dired-rainbow-define partition "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
    (dired-rainbow-define vc "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
    (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*")
    ))

;; perspective for workspaces
(use-package perspective
  :custom
  (persp-mode-prefix-key (kbd "C-c M-p"))  ; pick your own prefix key here
  :init
  (persp-mode))

;; Projectile
(use-package projectile
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
	      ("C-c p" . projectile-command-map))
  :config
  (setq projectile-project-search-path '("~/workspace/")))

;; projectile flycheck
(use-package flycheck-projectile
  :after (projectile flycheck))

;; eglot
(use-package eglot
  :custom
  (fset #'jsonrpc--log-event #'ignore)
  (eglot-events-buffer-size 0)
  (eglot-sync-connect nil)
  (eglot-connect-timeout nil)
  (eglot-autoshutdown t)
  (eglot-send-changes-idle-time 3)
  (flymake-no-changes-timeout 5)
  (eldoc-echo-area-use-multiline-p nil)
  (setq eglot-ignored-server-capabilities '( :documentHighlightProvider)))

;; use native eglot booster
(use-package eglot-booster
  :ensure t
  :vc (:fetcher github :repo jdtsmith/eglot-booster)
  :after eglot
  :config
  (eglot-booster-mode))

;; flycheck-eglot
(use-package flycheck-eglot
  :ensure t
  :after (flycheck eglot)
  :custom (flycheck-eglot-exclusive t)
  :config
  (global-flycheck-eglot-mode 1))

(use-package consult-eglot
  :after (consult eglot))

(use-package consult-eglot-embark
  :after (embark consult-eglot)
  :config
  (consult-eglot-embark-mode))

(use-package which-key
  :init
  (which-key-mode))

;; multiple cursors
(use-package multiple-cursors
  :bind
  ("C->" . mc/mark-next-like-this)
  ("C-<" . mc/mark-previous-like-this)
  ("C-c C-<" . mc/mark-all-like-this))

;; completions
(use-package consult
  :after perspective
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
   ;; consult--source-buffer :hidden t :default nil
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;; use consult to display buffers based on perspective.el
  (add-to-list 'consult-buffer-sources 'persp-consult-source)

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
  (corfu-preselect 'directory)      ;; Preselect the prompt
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin

  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))

  ;; Recommended: Enable Corfu globally.
  ;; This is recommended since Dabbrev can be used globally (M-/).
  ;; See also `corfu-exclude-modes'.
  :bind
  (:map corfu-map
        ("TAB" . corfu-next)
        ([tab] . corfu-next)
        ("S-TAB" . corfu-previous)
        ([backtab] . corfu-previous))
  :init
  (global-corfu-mode)
  :config
  (setq tab-always-indent 'complete))

;; display icons for completion
(use-package kind-icon
  :ensure t
  :after corfu
  ;; :custom
  ;; (kind-icon-blend-background t)
  ;; (kind-icon-default-face 'corfu-default) ; only needed with blend-background
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-abbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-elisp-block)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-dict))

;; Treesitter
(setq-default treesit-auto-langs '(python
                                   rust
                                   go
                                   awk
                                   bash
                                   c
                                   cmake
                                   commonlisp
                                   cpp
                                   css
                                   dart
                                   dockerfile
                                   html
                                   javascript
                                   json
                                   kotlin
                                   lua
                                   make
                                   markdown
                                   ruby
                                   toml
                                   yaml
                                   java
                                   tsx
                                   typescript))

(use-package treesit-auto
  :config
  (setq treesit-auto-install t)
  (global-treesit-auto-mode))

(use-package flycheck
  :init (global-flycheck-mode))

(use-package yasnippet :config (yas-global-mode))

(use-package eglot-java
  :config
  (defvar lombok-path
    (concat
     "-javaagent:"
     (expand-file-name
      "~/.config/emacs/etc/lombok/lombok-1.18.32.jar")))
  (setq-default eglot-java-eclipse-jdt-args
                (cons
                 lombok-path
                 '("-XX:+UseParallelGC"
	           "-XX:GCTimeRatio=4"
	           "-XX:AdaptiveSizePolicyWeight=90"
	           "-Dsun.zip.disableMemoryMapping=true"
	           "-Xmx4G"
	           "-Xms1G")))
  (setq-default lsp-java-configuration-runtimes '[(:name "JavaSE-17"
                                                         :path "/home/sahir/.sdkman/candidates/java/17.0.10-amzn/"
                                                         :default t)])
  (setq eglot-java-user-init-opts-fn 'custom-eglot-java-init-opts)
  (defun custom-eglot-java-init-opts (server eglot-java-eclipse-jdt)
    ;;   "Custom options that will be merged with default settings."
    '(:settings
      (:java
       ;;(:jdt
       ;; (:ls
       ;;  (:lombokSupport
       ;;   (:enabled t))))
       (:format
        (:settings
         (:url "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-;;style.xml")
         :enabled t)))))
  :hook
  (java-mode . eglot-java-mode)
  (java-ts-mode  . eglot-java-mode))

(use-package editorconfig
  :config
  (editorconfig-mode 1))

;; Kotlin
(use-package kotlin-ts-mode
  :mode ("\\.kts?\\'" . kotlin-ts-mode)
  :hook
  (kotlin-ts-mode . eglot-ensure))

(use-package flycheck-kotlin
  :hook
  (kotlin-mode . flycheck-mode))

;; Typescript Eglot
(use-package typescript-ts-mode
  :mode (("\\.ts\\'" . typescript-ts-mode))
  :hook ((typescript-ts-mode . eglot-ensure)
	 (tsx-ts-mode . eglot-ensure))
  :config
  (setq-default typescript-indent-level 'tab-width)
  (setq typescript-ts-mode-indent-offset 'tab-width)
  (setq js-jsx-indent-level 'tab-width)
  (setq js-indent-level 'tab-width)
  (setq-default js2-basic-offset 'tab-width))

(use-package jtsx
  :ensure t
  :mode (("\\.jsx?\\'" . jtsx-jsx-mode)
         ("\\.tsx?\\'" . jtsx-tsx-mode))
  :commands jtsx-install-treesit-language
  :hook ((jtsx-jsx-mode . hs-minor-mode)
         (jtsx-tsx-mode . hs-minor-mode)
         (jtsx-tsx-mode . eglot-ensure)
         (jtsx-jsx-mode . eglot-ensure))
  :custom
  ;; Optional customizations
  (js-indent-level 'tab-width)
  (typescript-ts-mode-indent-offset 'tab-width)
  ;; (jtsx-switch-indent-offset 0)
  ;; (jtsx-indent-statement-block-regarding-standalone-parent nil)
  ;; (jtsx-jsx-element-move-allow-step-out t)
  (jtsx-enable-jsx-electric-closing-element t)
  (jtsx-enable-electric-open-newline-between-jsx-element-tags t)
  (jtsx-enable-all-syntax-highlighting-features t)
  :config
  (defun jtsx-bind-keys-to-mode-map (mode-map)
    "Bind keys to MODE-MAP."
    (define-key mode-map (kbd "C-c C-j") 'jtsx-jump-jsx-element-tag-dwim)
    (define-key mode-map (kbd "C-c j o") 'jtsx-jump-jsx-opening-tag)
    (define-key mode-map (kbd "C-c j c") 'jtsx-jump-jsx-closing-tag)
    (define-key mode-map (kbd "C-c j r") 'jtsx-rename-jsx-element)
    (define-key mode-map (kbd "C-c <down>") 'jtsx-move-jsx-element-tag-forward)
    (define-key mode-map (kbd "C-c <up>") 'jtsx-move-jsx-element-tag-backward)
    (define-key mode-map (kbd "C-c C-<down>") 'jtsx-move-jsx-element-forward)
    (define-key mode-map (kbd "C-c C-<up>") 'jtsx-move-jsx-element-backward)
    (define-key mode-map (kbd "C-c C-S-<down>") 'jtsx-move-jsx-element-step-in-forward)
    (define-key mode-map (kbd "C-c C-S-<up>") 'jtsx-move-jsx-element-step-in-backward)
    (define-key mode-map (kbd "C-c j w") 'jtsx-wrap-in-jsx-element)
    (define-key mode-map (kbd "C-c j u") 'jtsx-unwrap-jsx)
    (define-key mode-map (kbd "C-c j d") 'jtsx-delete-jsx-node))
  
  (defun jtsx-bind-keys-to-jtsx-jsx-mode-map ()
    (jtsx-bind-keys-to-mode-map jtsx-jsx-mode-map))

  (defun jtsx-bind-keys-to-jtsx-tsx-mode-map ()
    (jtsx-bind-keys-to-mode-map jtsx-tsx-mode-map))

  (add-hook 'jtsx-jsx-mode-hook 'jtsx-bind-keys-to-jtsx-jsx-mode-map)
  (add-hook 'jtsx-tsx-mode-hook 'jtsx-bind-keys-to-jtsx-tsx-mode-map))

;; yaml-mode
(use-package yaml-mode
  :mode
  ("\\.ya?ml\\'" . yaml-ts-mode)
  :hook
  (yaml-ts-mode . eglot-ensure))

;; json-mode
(use-package json-mode
  :mode
  ("\\.json\\'" . json-ts-mode)
  :hook
  (json-ts-mode . eglot-ensure))

;; docker
(use-package dockerfile-mode
  :hook (dockerfile-mode . eglot-ensure))

;; format code
(use-package format-all
  :commands
  format-all-mode
  :hook
  (prog-mode . format-all-mode))    ;; format on save

(use-package apheleia
  :config
  (apheleia-global-mode 1))

(use-package editorconfig
  :config
  (editorconfig-mode 1))

;; colorful parens
(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

;; magit
(use-package magit
  :bind (("C-x g" . magit-status))
  :config
  (setq magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1))

;; lib vterm
(use-package vterm
  :custom
  (vterm-always-compile-module t))
(use-package multi-vterm
  :after (vterm))

;; elfeed
(use-package elfeed
  :custom
  (elfeed-search-filter "@2-week-ago")
  (elfeed-show-entry-switch #'pop-to-buffer)
  (elfeed-show-entry-delete #'+rss/delete-pane)
  (shr-max-image-proportion 0.8)
  :bind
  (("C-x w" . elfeed)))
(use-package elfeed-org
  :after (elfeed)
  :config
  (setq rmh-elfeed-org-files (list "~/.config/emacs/etc/elfeed/file.org"))
  (elfeed-org))
(use-package elfeed-goodies
  :after (elfeed)
  :config
  (elfeed-goodies/setup))

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-vc-selected-packages
   '((vc-use-package :vc-backend Git :url "https://github.com/slotThe/vc-use-package"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
