(defclass stateable-object ()
  ((state-stack :initarg :state :initform '(())
                :documentation "A stack of states - always at least of length 1."))
  (:documentation "A mixin that provides the slot that holds state state."))

(defgeneric state (obj)
  (:documentation "Get the top value of the state-stack of an object."))
(defmethod state ((obj stateable-object))
  (first (slot-value obj 'state-stack)))

(defgeneric (setf state) (new-state obj)
  (:documentation "Change the top value of the state-stack of an object."))
(defmethod (setf state) (new-state (obj stateable-object))
  (setf (slot-value obj 'state-stack) 
        (cons new-state (cdr (slot-value obj 'state-stack)))))

(defgeneric push-state (obj)
  (:documentation "Push an item on the state-stack of an object."))
(defmethod push-state (new-state (obj stateable-object))
  (setf (slot-value obj 'state-stack)
        (cons new-state (slot-value obj 'state-stack))))

(defgeneric pop-state (obj)
  (:documentaiton "Push an item off the state-stack of an object."))
(defmethod pop-state ((obj stateable-object))
  (setf (slot-value obj 'state-stack)
        (cdr (slot-value obj 'state-stack))))


(defmacro defstatemethod (name state stated-arg args &rest body)
  "Hides away the extra method used to return the state we dispatch on."
  `(progn (defmethod ,name ,state ,args ,@body)
            (defmethod ,name :state-returner ,args (values (state ,stated-arg) ,stated-arg))))

(defun maphash->list (fn hashtable)
  "Maps an fn over a hashtable into a list."
  (let ((results '()))
    (flet ((list-fn (key val)
             (push (funcall fn key val) results)))
      (maphash #'list-fn hashtable)
      (nreverse results))))

(defun query-for (stream query-string)
  "Print query-string into stream, read value back. A query!"
  (format stream query-string)
  (read stream))

;This version of the method combination does the sorting statically.
(define-condition no-method-for-state ()
  ((object :reader nmfs-object :initarg :object)
   (object-state :reader nmfs-object-state :initarg :object-state)
   (generic-function :reader nmfs-generic-function :initarg :generic-function)
   (methods :reader nmfs-methods :initarg :methods))
  (:report (lambda (condition stream)
             (format stream "The generic function ~W~%Using the :state method combination~%Has been unable to dispatch with object:~W at state:~W~%From methods:~W"
                     (nmfs-generic-function condition) 
                     (nmfs-object condition)
                     (nmfs-object-state condition)
                     (nmfs-methods condition))))
  (:documentation "Signaled if no method for state is found."))

(defun sort-methods->hashtable (methods)
  "Sort the method objects in /methods/ into a hashtable keyed by state."
  (let ((return (make-hash-table)))
    (dolist (method methods)
      (let ((state (first (method-qualifiers method))))
        (setf (gethash state return)
              (reverse (cons method (gethash state return))))))
    return))

(define-method-combination :state ()
  ((get-state (:state-returner) :order :most-specific-first)
   (methods * :order :most-specific-first))
  (:generic-function generic-function)
  "Dispatch methods based on the state of one argument - first seperate methods into groups according to method, and then conditionally return by testing each one."
  (let ((block-name (gensym))
        ;sort the methods into a list
        (states-and-methods (sort-methods->hashtable methods)))
    `(block ,block-name 
       (tagbody restart-dispatch
          (multiple-value-bind (state stated-obj args) (call-method ,(first get-state))
            (restart-case
                (progn
                  ,@(maphash->list (lambda (state methodlist)
                                     `(when (equal state ,state)
                                        (return-from ,block-name
                                          (call-method ,(first methodlist) ,(rest methodlist)))))
                                   states-and-methods)
                  (error 'no-method-for-state 
                         :object stated-obj 
                         :object-state state
                         :generic-function ,generic-function
                         :methods (list ,@methods)))
              (return-value (value)
                :report "Refuse computation and return a value."
                :interactive (lambda () (list (query-for *query-io* "Value to return: ")))
                (return-from ,block-name value))
              (change-object-state (new-state)
                :report "Change the state of the object and retry."
                :interactive (lambda () (list (query-for *query-io* "State to change to: ")))
                (progn (setf (state stated-obj) new-state)
                       (go restart-dispatch)))))))))



(defclass bob (stateable-object) ())
(defclass joe (bob) ())
(defmethod initialize-instance :after ((instance joe) &rest initargs)
  (setf (state instance) :stdate))

(defgeneric do-bob (bob-instance)
  (:method-combination :state))
(defstatemethod do-bob :state bob-instance ((bob-instance bob))
     (print "bob-instance is at state :state"))
(defstatemethod do-bob :state joe-instance ((joe-instance joe))
     (print "joe-instance is at state :state")
     (call-next-method))


