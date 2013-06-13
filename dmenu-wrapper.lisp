(in-package #:stumpwm)

;; I did not like the input window that was built in in Stumpwm and i do not know enough clx to "improve" it
;; so i just quickly wrote this wrapper code to easily (i hope) call and config dmenu from lisp code :) ...

(defvar *dmenu-position* :top)
(defvar *dmenu-fast-p* t)
(defvar *dmenu-case-sensitive-p* nil)
(defvar *dmenu-font* nil)
(defvar *dmenu-background-color* nil)
(defvar *dmenu-foreground-color* nil)
(defvar *dmenu-selected-background-color* nil)
(defvar *dmenu-max-vertical-lines* 10)

(defun dmenu-build-cmd-options ()
  (format nil "~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~] ~@[~A~]"
          (when (equal *dmenu-position* :bottom) "-b")
          (when *dmenu-fast-p* "-f")
          (when (not *dmenu-case-sensitive-p*) "-i")
          (when *dmenu-font* (format nil "-fn ~A" *dmenu-font*))
          (when *dmenu-background-color* (format nil "-nb ~A" *dmenu-background-color*))
          (when *dmenu-foreground-color* (format nil "-nf ~A" *dmenu-foreground-color*))
          (when *dmenu-selected-background-color* (format nil "-sb ~A" *dmenu-selected-background-color*))))

(defun dmenu-build-list (item-list)
  (if item-list (format nil "\"~{~A\\n~}\"" item-list) ""))

(defun dmenu (&key item-list prompt vertical-lines) 
  (let* ((cmd (format nil
                      "printf ~A | dmenu~A ~@[-p \"~A\"~] ~@[-l \"~A\"~]"
                      (dmenu-build-list item-list)
                      (dmenu-build-cmd-options)
                      prompt
                      vertical-lines))
         (selection (run-shell-command cmd t)))
    (when (not (equal selection ""))
      (string-trim '(#\Newline) selection))))

;; Examples of what can be done with (dmenu) ....

(defcommand dmenu-call-command () ()
  "Uses dmenu to call a Stumpwm command"
  (let ((selection (dmenu :item-list (all-commands) :prompt "Commands:")))
    (when selection (run-commands selection))))

(defcommand dmenu-windowlist () ()
  "Uses dmenu to change the visible window"
  (labels ((get-window (window-name)
             (first (remove-if #'null
                               (mapcar
                                #'(lambda (x) (when (equal window-name (window-title x)) x))
                                (all-windows))))))
    (let* ((open-windows (mapcar #'window-name (all-windows)))
           (num-of-windows (length open-windows))
           (win-name (dmenu
                     :item-list open-windows
                     :prompt "Choose a window:"
                     :vertical-lines (if (> num-of-windows *dmenu-max-vertical-lines*)
                                         *dmenu-max-vertical-lines*
                                         num-of-windows))))
      (when win-name (group-focus-window (current-group) (get-window win-name))))))

(defcommand dmenu-kill-proc () ()
  (run-shell-command (format nil "pkill \"$(pidof ~A)\"" (dmenu :prompt "pkill:"))))

(defcommand dmenu-run () ()
  "Just a simple wrapper to call dmenu_run from lisp"
  (run-shell-command (format nil "dmenu_run ~A" (dmenu-build-cmd-options))))
    
  

