;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
(setq shell-file-name (executable-find "bash"))

;;(setq doom-font (font-spec :family "Spleen" :size 24))
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-theme 'doom-dracula)

;;(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 14))
(setq doom-font (font-spec :family "Berkeley Mono" :size 14))

;; Emacs pgtk rasterises into a buffer at the scale in effect when a frame was
;; created, and never re-renders when that frame moves to a differently-scaled
;; Wayland output -- sway upscales the stale buffer and text goes blurry.
;; Recreating the frame is the only way to get a correctly-scaled one.  kanshi
;; sends SIGUSR1 on every profile switch (see rescaleEmacsFrames in
;; hosts/anoa/default.nix), so docking and undocking fix themselves.
(defun sifr/emacs-rescale-frames ()
  "Rebuild graphical frames so they re-render at their output's current scale.
Buffers, window layout, selected window and point are preserved."
  (interactive)
  (dolist (old (frame-list))
    (when (and (display-graphic-p old)
               (not (frame-parameter old 'parent-frame)))
      (let* ((state (window-state-get (frame-root-window old) t))
             (focused (eq old (selected-frame)))
             (new (make-frame
                   (delq nil
                         (list (cons 'window-system (frame-parameter old 'window-system))
                               (when-let ((d (frame-parameter old 'display)))
                                 (cons 'display d))
                               (cons 'fullscreen (frame-parameter old 'fullscreen)))))))
        (with-selected-frame new
          (window-state-put state (frame-root-window new) 'safe))
        (delete-frame old)
        (when focused (select-frame-set-input-focus new))))))

(define-key special-event-map [sigusr1] #'sifr/emacs-rescale-frames)

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

;; Doom defers org, org-roam's database init (`+org-roam-try-init-db-a' waits
;; for the first `org-roam-db-query') and the whole `doom-first-file-hook'
;; cascade -- flycheck, diff-hl, yasnippet -- until each is first needed.  That
;; puts ~3s in front of the first `SPC n r f' and the first note opened in a
;; session; warm afterwards it's under 150ms.  In a daemon nobody is waiting at
;; startup, so pay it there.  Deferred to an idle timer so the daemon still
;; signals readiness promptly.
(when (daemonp)
  (defun sifr/warm-org-roam ()
    "Force-load the org/org-roam path so the first use of it isn't slow."
    (require 'org)
    (require 'org-roam)
    ;; Also triggers Doom's deferred `org-roam-db-sync'.
    (org-roam-node-read--completions)
    ;; Visiting a real org file is what fires `doom-first-file-hook'.
    (let ((file (expand-file-name "todo.org" org-directory)))
      (when (file-exists-p file)
        (let ((visiting (get-file-buffer file))
              (buf (find-file-noselect file)))
          (with-current-buffer buf (font-lock-ensure))
          (unless visiting (kill-buffer buf))))))
  (run-with-idle-timer 2 nil #'sifr/warm-org-roam))

;; :tools biblio derives org-cite-global-bibliography from this.
(setq citar-bibliography '("~/docs/Zotero/Library.bib"))

;; Title new bibliographic notes "Title, Luo et al." instead of
;; citar-org-roam's default "${author editor}, ${title}", which spells out
;; every author family-name-first before the title.  citar's built-in %etal
;; transform truncates at three names, so define a first-author-only one.
(after! citar
  (setf (alist-get 'etal1 citar-display-transform-functions)
        '(citar--shorten-names 1)))

(after! citar-org-roam
  (setq citar-org-roam-note-title-template "${title}, ${author editor:%etal1}")

  ;; citar-org-roam hardcodes its capture template (title only) unless
  ;; `citar-org-roam-capture-template-key' names one in
  ;; `org-roam-capture-templates', so register a copy of it that also stamps
  ;; #+date:.  The filename sexp is verbatim from
  ;; `citar-org-roam--create-capture-note'.
  (add-to-list
   'org-roam-capture-templates
   '("r" "reference" plain "%?"
     :target (file+head
              "%(concat (when citar-org-roam-subdir (concat citar-org-roam-subdir \"/\")) \"${citar-citekey}.org\")"
              "#+title: ${note-title}\n#+date: %t\n")
     :immediate-finish t
     :unnarrowed t))
  (setq citar-org-roam-capture-template-key "r"))

(use-package! ox-typst
  :after org)

;; gptel talks to ChatGPT over the subscription's OAuth token (the Codex
;; endpoint), not an API key.  Run `gptel-openai-oauth-login' once to log in.
(after! gptel
  (setq gptel-model 'gpt-5.6-sol
        gptel-backend (gptel-make-openai-oauth "OpenAI-sub")))

;; The Codex endpoint answers non-streamed requests with 400 "Stream must be
;; set to true", and `gptel-quick' never passes :stream (gptel-request defaults
;; it to nil).  Force it on for that one caller.
(defadvice! +gptel-quick-force-stream-a (fn &optional prompt &rest args)
  :around #'gptel-request
  (when (eq (plist-get args :callback) #'gptel-quick--callback-posframe)
    (setq args (plist-put args :stream t)))
  (apply fn prompt args))

;; Leader keys are pressed in evil normal state, where the block cursor sits
;; *on* the character at point -- so a command that plainly `insert's lands its
;; text one character behind where the cursor looks.  Step over that character
;; first, as `evil-append' does, unless we're already at end of line.
(defun my/insert-at-cursor (fn)
  "Call FN interactively, inserting at the cursor rather than before it."
  (when (and (bound-and-true-p evil-local-mode)
             (evil-normal-state-p)
             (not (eolp)))
    (forward-char))
  (call-interactively fn))

;; Citar under SPC n z
(after! org
  (defun my/org-insert-print-bibliography ()
    (interactive)
    (insert "#+print_bibliography:\n"))

  (defun my/citar-insert-citation ()
    (interactive)
    (my/insert-at-cursor #'citar-insert-citation))

  (defun my/citar-insert-reference ()
    (interactive)
    (my/insert-at-cursor #'citar-insert-reference))

  (map! :leader
        (:prefix ("n z" . "Zotero / Citar")
                 "a" #'citar-org-roam-ref-add
                 "c" #'my/citar-insert-citation
                 "r" #'my/citar-insert-reference
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
