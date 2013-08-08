(in-package #:stumpwm)

(defvar *dmenu-position* :top)
(defvar *dmenu-fast-p* t)
(defvar *dmenu-case-sensitive-p* nil)
(defvar *dmenu-font* nil)
(defvar *dmenu-background-color* nil)
(defvar *dmenu-foreground-color* nil)
(defvar *dmenu-selected-background-color* nil)
(defvar *dmenu-max-vertical-lines* 10)

(defun dmenu-build-cmd-options ()
  (format nil " ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~]"
          (when (equal *dmenu-position* :bottom) "-b")
          (when *dmenu-fast-p* "-f")
          (when (not *dmenu-case-sensitive-p*) "-i")
          (when *dmenu-font* (format nil "-fn ~A" *dmenu-font*))
          (when *dmenu-background-color* (format nil "-nb ~A" *dmenu-background-color*))
          (when *dmenu-foreground-color* (format nil "-nf ~A" *dmenu-foreground-color*))

          
          (when *dmenu-selected-background-color* (format nil "-sb ~A" *dmenu-selected-background-color*))))

(defun dmenu (&key item-list prompt vertical-lines (cmd-options (dmenu-build-cmd-options)))
  (let* ((cmd (format nil
                      "printf ~A | dmenu~A ~@[-p \"~A\"~] ~@[-l \"~A\"~]"
                      (if item-list (format nil "\"~{~A\\n~}\"" item-list) "")
                      cmd-options
                      prompt
                      vertical-lines))
         (selection (run-shell-command cmd t)))
    (when (not (equal selection ""))
      (string-trim '(#\Newline) selection))))

(defun dmenu-calc-vertica-lines (menu-length)
  (if (> menu-length *dmenu-max-vertical-lines*)
      *dmenu-max-vertical-lines*
      menu-length))

;; https://gist.github.com/scottjad/5262930
(defun select-from-menu (screen table &optional prompt (initial-selection 0))
  (declare (ignore screen initial-selection))
  (let* ((menu-options (mapcar #'menu-element-name table))
         (menu-length (length menu-options))
         (selection-string (dmenu
                            :item-list menu-options
                            :prompt prompt
                            :vertical-lines (dmenu-calc-vertica-lines menu-length)))
         (selection (find selection-string menu-options
                          :test (lambda (selection-string item)
                                  (string-equal selection-string (format nil "~A" item))))))
    (if (listp (car table))
        (assoc selection table)
        selection)))

(defcommand dmenu-call-command () ()
  "Uses dmenu to call a Stumpwm command"
  (let ((selection (dmenu :item-list (all-commands) :prompt "Commands:")))
    (when selection (run-commands selection))))

(defcommand dmenu-eval-lisp () ()
  "Uses dmenu to eval a Lisp expression"
  (let ((selection (dmenu :prompt "Eval: ")))
    (when selection (eval (read-from-string selection)))))

(defcommand dmenu-windowlist () ()
  "Uses dmenu to change the visible window"
  (labels ((get-window (window-name)
             (loop for w in (all-windows) do
                  (when (equal (window-title w) window-name) (return w))))
           (open-windows () (mapcar #'window-name (all-windows)))
           (num-of-windows () (length (open-windows))))
    (let ((selection (dmenu
                      :item-list (open-windows)
                      :prompt "Choose a window:"
                      :vertical-lines (dmenu-calc-vertica-lines (num-of-windows)))))
      (when selection (focus-window (get-window selection))))))

(defcommand dmenu-run () ()
  "Just a simple wrapper to call dmenu_run from lisp"
  (run-shell-command (format nil "dmenu_run ~A -p Run: " (dmenu-build-cmd-options))))
