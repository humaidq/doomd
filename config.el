;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
(setq shell-file-name (executable-find "bash"))

;;(setq doom-font (font-spec :family "Spleen" :size 24))
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-theme 'doom-dracula)

;;(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 14))
(setq doom-font (font-spec :family "Berkeley Mono" :size 14))

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

(setq! copilot-indent-offset-warning-disable t)

(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word)))

;; Enable SSH signing in Magit
(after! magit
  ;; Show signatures in commit logs
  (setq magit-commit-show-gpg-signature t)
  ;; Magit respects git's commit.gpgsign config automatically
  )

(setq org-cite-global-bibliography '("~/docs/Zotero/Library.bib"))
(setq citar-bibliography org-cite-global-bibliography)
(use-package! ox-typst
  :after org
  :config
  (require 'ox-typst))

;; Citar under SPC n z in Org buffers
(after! org
  (defun my/org-insert-print-bibliography ()
    (interactive)
    (insert "#+print_bibliography:\n"))

  (map! :leader
        :map org-mode-map
        (:prefix ("n z" . "Zotero / Citar")
                 "a" #'citar-org-roam-ref-add
                 "c" #'citar-insert-citation
                 "r" #'citar-insert-reference
                 "b" #'my/org-insert-print-bibliography
                 "o" #'citar-open
                 )))
(defun humaid/pdf-to-text-layout ()
  (interactive)
  (let* ((file (cond
                ((derived-mode-p 'pdf-view-mode)
                 (or (ignore-errors (pdf-view-buffer-file-name))
                     (buffer-file-name)))
                (t (buffer-file-name))))
         (exe  (executable-find "pdftotext"))
         (buf  (and file
                    (get-buffer-create
                     (format "*pdftotext -layout: %s*"
                             (file-name-nondirectory file))))))
    (unless exe
      (user-error "pdftotext not found in PATH"))
    (unless (and file (string-match-p "\\.pdf\\'" (downcase file)))
      (user-error "This buffer is not visiting a PDF file"))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer))
    ;; Synchronous call: pdftotext -layout <file> -
    (let ((exit (call-process exe nil buf nil "-layout" file "-")))
      (unless (eq exit 0)
        (pop-to-buffer buf)
        (user-error "pdftotext failed with exit code %s (see buffer for details)" exit)))
    (with-current-buffer buf
      (setq buffer-file-coding-system 'utf-8-unix)
      (text-mode)
      (visual-line-mode 1)
      (view-mode 1)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(after! pdf-tools
  (map! :map pdf-view-mode-map
        :localleader

        "D" #'pdf-annot-delete
        "a" #'pdf-annot-attachment-dired
        "h" #'pdf-annot-add-highlight-markup-annotation
        "l" #'pdf-annot-list-annotations
        "m" #'pdf-annot-add-markup-annotation
        "o" #'pdf-annot-add-strikeout-markup-annotation
        "s" #'pdf-annot-add-squiggly-markup-annotation
        "t" #'pdf-annot-add-text-annotation
        "u" #'pdf-annot-add-underline-markup-annotation
        "e" #'humaid/pdf-to-text-layout

        ;; Midnight mode
        "i" #'pdf-view-midnight-minor-mode
        ))
