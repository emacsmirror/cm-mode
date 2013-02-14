;;; cm-mode.el --- Minor mode for CriticMarkup

;; Copyright (c) 2013 Joost Kremers

;; Author: Joost Kremers <joostkremers@fastmail.fm>
;; Maintainer: Joost Kremers <joostkremers@fastmail.fm>
;; Created: 14 Feb 2013
;; Version: 0.1
;; Keywords: text

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. The name of the author may not be used to endorse or promote products
;;    derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
;; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
;; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
;; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;; NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES ; LOSS OF USE,
;; DATA, OR PROFITS ; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
;; THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; `cm-mode` provides (rudimentary) support for [CriticMarkup](http://criticmarkup.com/)
;;
;; CriticMarkup defines the following patterns for marking changes to a text:
;; 
;; Addition {++ ++}
;; Deletion {-- --}
;; Substitution {~~ ~> ~~}
;; Comment {>> <<}
;; Highlight {{ }}{>> <<}
;; 
;; Note: additions are called insertions here, because it allows us to use
;; mnemonic key bindings.
;;
;; Activating `cm-mode` adds the patterns above to font-lock-keywords and
;; provides key bindings to insert the patterns above and thus mark one's
;; changes to the text. The provided key bindings are:
;;
;; C-c * i: insert text
;; C-c * d: delete text
;; C-c * s: substitute text
;; C-c * c: insert a comment
;; C-c * h: highlight text and insert a comment
;;
;; The commands to delete, substitute and highlight text all operate on the
;; region. The commands for inserting and substituting text and for
;; inserting a comment (which includes the command to highlight text) all
;; put the cursor at the correct position, so you can start typing right away.
;;
;; TODO:
;;
;; - Commands to accept or reject the change at point (C-c * a and C-c * r)
;; - Command to accept or reject all changes interactively (C-c * A)
;; - Mouse support

;;; Code:

(defvar cm-insertion-regexp "\\(?:{\\+\\+.*?\\+\\+}\\)"
  "CriticMarkup insertion regexp.")

(defvar cm-deletion-regexp "\\(?:{--.*?--}\\)"
  "CriticMarkup deletion regexp.")

(defvar cm-substitution-regexp "\\(?:{~~.*?->.*?~~}\\)"
  "CriticMarkup substitution regexp.")

(defvar cm-comment-regexp "\\(?:{>>.*?<<}\\)"
  "CriticMarkup comment regexp.")

(defvar cm-highlight-regexp "\\(?:{{.*?}}\\)"
  "CriticMarkup highlight regexp.")

(defgroup criticmarkup nil "Minor mode for CriticMarkup." :group 'wp)

(defface cm-insertion-face '((t (:foreground "green")))
  "*Face for CriticMarkup insertions."
  :group 'criticmarkup)

(defface cm-deletion-face '((t (:foreground "red")))
  "*Face for CriticMarkup deletions."
  :group 'criticmarkup)

(defface cm-substitution-face '((t (:foreground "orange")))
  "*Face for CriticMarkup substitutions."
  :group 'criticmarkup)

(defface cm-comment-face '((t (:foreground "blue")))
  "*Face for CriticMarkup comments."
  :group 'criticmarkup)

(defface cm-highlight-face '((t (:foreground "magenta")))
  "*Face for CriticMarkup highlights."
  :group 'criticmarkup)

(defface ebib-crossref-face '((t (:foreground "red")))
  "*Face used to indicate values inherited from crossreferenced entries."
  :group 'ebib-faces)

(defvar cm-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c*i" 'cm-insertion)
    (define-key map "\C-c*d" 'cm-deletion)
    (define-key map "\C-c*s" 'cm-substitution)
    (define-key map "\C-c*c" 'cm-comment)
    (define-key map "\C-c*h" 'cm-highlight)
    (define-key map "\C-c*a" 'cm-accept-change)
    (define-key map "\C-c*r" 'cm-reject-change)
    (define-key map "-C-c*A" 'cm-accept/reject-all)
    map)
  "Keymap for cm-mode.")

;;;###autoload
(define-minor-mode cm-mode
  "Minor mode for CriticMarkup."
  :init-value nil :lighter " cm" :global nil
  (cond
   (cm-mode                             ; cm-mode is turned on
    (font-lock-add-keywords nil `((,cm-insertion-regexp . 'cm-insertion-face)
                                  (,cm-deletion-regexp . 'cm-deletion-face)
                                  (,cm-substitution-regexp . 'cm-substitution-face)
                                  (,cm-comment-regexp . 'cm-comment-face)
                                  (,cm-highlight-regexp . 'cm-highlight-face)) t))
   ((not cm-mode)                       ; cm-mode is turned off
    (font-lock-remove-keywords nil `((,cm-insertion-regexp . 'cm-insertion-face)
                                     (,cm-deletion-regexp . 'cm-deletion-face)
                                     (,cm-substitution-regexp . 'cm-substitution-face)
                                     (,cm-comment-regexp . 'cm-comment-face)
                                     (,cm-highlight-regexp . 'cm-highlight-face))))))

;;;###autoload
(defun turn-on-cm ()
  "Unconditionally turn on cm-mode."
  (interactive)
  (cm-mode 1))

(defun turn-off-cm ()
  "Unconditionally turn off cm-mode"
  (interactive)
  (cm-mode -1))

(defun cm-insertion ()
  "Make an insertion."
  (interactive)
  (insert "{++++}")
  (backward-char 3))

(defun cm-deletion (beg end)
  "Mark text for deletion."
  (interactive "r")
  (let ((text (delete-and-extract-region beg end)))
    (insert (concat "{--" text "--}"))))

(defun cm-substitution (beg end)
  "Mark a substitution."
  (interactive "r")
  (let ((text (delete-and-extract-region beg end)))
    (insert (concat "{~~" text "->~~}"))
    (backward-char 3)))

(defun cm-comment ()
  "Add a comment."
  (interactive)
  (insert "{>><<}")
  (backward-char 3))

(defun cm-highlight (beg end)
  "Highlight a stretch of text and add a comment."
  (interactive "r")
  (let ((text (delete-and-extract-region beg end)))
    (insert (concat "{{" text "}}{>><<}"))
    (backward-char 3)))

(provide 'cm-mode)

;;; cm-mode ends here
