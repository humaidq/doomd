;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;(setq doom-font (font-spec :family "Spleen" :size 24))
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-theme 'doom-dracula)

(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 24))

(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))

(setq display-line-numbers-type t)

(setq org-directory "~/docs/org/")
(setq org-roam-directory (file-truename (concat org-directory "roam/")))
(setq org-agenda-files (list "~/docs/org/todo.org"))

;;;###autoload
;; (defun user/api-key-from-auth-source (&optional host user)
;;   "Lookup api key in the auth source.
;; By default, the LLM host for the active backend is used as HOST,
;; and \"apikey\" as USER."
;;   (if-let ((secret
;;             (plist-get
;;              (car (auth-source-search
;;                    :host (or host)
;;                    :user (or user "apikey")
;;                    :require '(:secret)))
;;              :secret)))
;;       (if (functionp secret)
;;           (encode-coding-string (funcall secret) 'utf-8)
;;         secret)
;;     (user-error "No `api-key' found in the auth source")))

(after! evil
  (define-key evil-visual-state-map "s" 'evil-surround-delete))

;; Restore 's' behaviour from vim, and other sensible stuff
(remove-hook 'doom-first-input-hook #'evil-snipe-mode)

;;(setq! evil-want-Y-yank-to-eol nil)

(use-package! websocket
  :after org-roam)

(use-package! org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

(use-package! astro-ts-mode
  :after treesit-auto)

(setq! copilot-indent-offset-warning-disable t)


(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

;; (after! gptel
;;  ;; Set copilot as the default llm interface and claude as the talker
;;  (setq! gptel-model 'claude-3.7-sonnet
;;         gptel-backend (gptel-make-gh-copilot "Copilot"))
;;  (setq! gptel-default-mode 'org-mode))


;; TODO monitor this for when it is released on melpa or similar
;;(use-package! mcp
;;  :config
;;  (require 'mcp-hub)
;;  (require 'gptel-integrations)
;;  (setq! mcp-hub-servers
;;         `(("nixos" :command "mcp-nixos")
;;           ("github" :command "github-mcp-server" :args ("stdio") :env (:GITHUB_PERSONAL_ACCESS_TOKEN ,(user/api-key-from-auth-source "api.github.com" "humaid^mcp")))
;;           ("filesystem" . (:command "npx" :args ("-y" "@modelcontextprotocol/server-filesystem" "~/projects")))
;;           ("sequential" . (:command "npx" :args ("-y" "@modelcontextprotocol/server-sequential-thinking")))
;;           ("context7" . (:command "npx" :args ("-y" "@upstash/context7-mcp"))))))

;; (use-package! aidermacs
;;   :commands aidermacs-transient-menu
;;   :init
;;   (setenv "OPENAI_API_KEY" (user/api-key-from-auth-source "github.com" "humaidq"))
;;   (setenv "OPENAI_API_BASE" "https://api.githubcopilot.com")
;;   ;;(require 'vterm nil t)
;;   :config
;;   ;; Use vterm backend (default is comint)
;;   (setq! aidermacs-backend 'vterm
;;          ;; Enable file watching only works with vterm
;;          setq aidermacs-watch-files t
;;          ;; TODO see https://aider.chat/2024/09/26/architect.html
;;          ;; Optional: Set specific model for architect reasoning
;;          setq aidermacs-architect-model  "openai/claude-3.5-sonnet"
;;          ;; Optional: Set specific model for code generation
;;          setq aidermacs-editor-model  "openai/claude-3.5-sonnet")
;;   :custom
;;   (aidermacs-use-architect-mode t)
;;   (aidermacs-default-model "openai/claude-3.5-sonnet"))
