;;; scpaste.el --- Paste to the web via scp.

;; Copyright (C) 2008 Phil Hagelberg

;; Author: Phil Hagelberg
;; URL: http://www.emacswiki.org/cgi-bin/wiki/SCPaste
;; Version: 0.6
;; Created: 2008-04-02
;; Keywords: convenience hypermedia
;; EmacsWiki: SCPaste
;; Package-Requires: ((htmlize "1.39"))

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; This will place an HTML copy of a buffer on the web on a server
;; that the user has shell access on.

;; It's similar in purpose to services such as http://paste.lisp.org
;; or http://rafb.net, but it's much simpler since it assumes the user
;; has an account on a publicly-accessible HTTP server. It uses `scp'
;; as its transport and uses Emacs' font-lock as its syntax
;; highlighter instead of relying on a third-party syntax highlighter
;; for which individual language support must be added one-by-one.

;;; Install

;; To install, copy this file into your Emacs source directory, set
;; `scpaste-http-destination' and `scpaste-scp-destination' to
;; appropriate values, and add this to your .emacs file:

;; (autoload 'scpaste "scpaste" "Paste the current buffer." t nil)
;; (setq scpaste-http-destination "http://p.hagelb.org"
;;       scpaste-scp-destination "p.hagelb.org:p.hagelb.org")

;;; Usage

;; M-x scpaste, enter a name, and press return. The name will be
;; incorporated into the URL by escaping it and adding it to the end
;; of `scpaste-http-destination'. The URL for the pasted file will be
;; pushed onto the kill ring.

;; You can autogenerate a splash page that gets uploaded as index.html
;; in `scpaste-http-destination' by invoking M-x scpaste-index. This
;; will upload an explanation as well as a listing of existing
;; pastes. If a paste's filename includes "private" it will be skipped.

;; You probably want to set up SSH keys for your destination to avoid
;; having to enter your password once for each paste. Also be sure the
;; key of the host referenced in `scpaste-scp-destination' is in your
;; known hosts file--scpaste will not prompt you to add it but will
;; simply hang.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'url)
(require 'htmlize)

(defvar scpaste-username
  (user-login-name))

(defvar scpaste-scp-port
  "22")

(defvar scpaste-http-destination
  "http://p.hagelb.org"
  "Publicly-accessible (via HTTP) location for pasted files.")

(defvar scpaste-scp-destination
  "p.hagelb.org:p.hagelb.org"
  "SSH-accessible directory corresponding to `scpaste-http-destination'.
You must have write-access to this directory via `scp'.")

(defvar scpaste-footer
  (concat "<p style='font-size: 8pt; font-family: monospace;'>Generated by "
          user-full-name
          " using <a href='http://p.hagelb.org'>scpaste</a> at %s. "
          (cadr (current-time-zone)) ". (<a href='%s'>original</a>)</p>")
  "HTML message to place at the bottom of each file.")

;; To set defvar while developing: (load-file (buffer-file-name))
(defvar scpaste-el-location load-file-name)

;;;###autoload
(defun scpaste (original-name)
  "Paste the current buffer via `scp' to `scpaste-http-destination'."
  (interactive "MName (defaults to buffer name): ")
  (let* ((b (htmlize-buffer))
         (name (url-hexify-string (if (equal "" original-name)
                                      (buffer-name)
                                    original-name)))
         (full-url (concat scpaste-http-destination "/" name ".html"))
         (scp-destination (concat scpaste-scp-destination "/" name ".html"))
         (scp-original-destination (concat scpaste-scp-destination "/" name))
         (tmp-file (concat temporary-file-directory "/" name)))

    ;; Save the file (while adding footer)
    (save-excursion
      (switch-to-buffer b)
      (goto-char (point-min))
      (search-forward "</body>\n</html>")
      (insert (format scpaste-footer
                      (current-time-string)
                      (substring full-url 0 -5)))
      (write-file tmp-file)
      (kill-buffer b))

    (shell-command (concat "scp -P " scpaste-scp-port
                           " " tmp-file
			   " " scpaste-username
                           "@" scp-destination))
    (shell-command (concat "scp -P " scpaste-scp-port
                           " " (buffer-file-name (current-buffer))
			   " " scpaste-username
                           "@" scp-original-destination))

    ;; Notify user and put the URL on the kill ring
    (let ((x-select-enable-primary t))
      (kill-new full-url))
    (message "Pasted to %s (on kill ring)" full-url)))

;;;###autoload
(defun scpaste-region (name)
  "Paste the current region via `scpaste'."
  (interactive "MName: ")
  (let ((region-contents (buffer-substring (mark) (point))))
    (with-temp-buffer
      (insert region-contents)
      (scpaste name))))

;;;###autoload
(defun scpaste-index ()
  "Generate an index of all existing pastes on server on the splash page."
  (interactive)
  (let* ((dest-parts (split-string scpaste-scp-destination ":"))
         (files (shell-command-to-string (concat "ssh " scpaste-username
						 "@" (car dest-parts)
                                                 " ls " (cadr dest-parts))))
         (file-list (split-string files "\n")))
    (save-excursion
      (with-temp-buffer
        (insert-file-contents scpaste-el-location)
        (goto-char (point-min))
        (search-forward ";;; Commentary")
        (forward-line -1)
        (insert "\n;;; Pasted Files\n\n")
        (dolist (file file-list)
          (when (and (string-match "\\.html$" file)
                     (not (string-match "private" file)))
            (insert (concat ";; * <" scpaste-http-destination "/" file ">\n"))))
        (emacs-lisp-mode) (font-lock-fontify-buffer) (rename-buffer "SCPaste")
        (write-file "/tmp/scpaste-index")
        (scpaste "index")))))

(provide 'scpaste)
;;; scpaste.el ends here
