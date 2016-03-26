#|
 This file is a part of Staple
 (c) 2014 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.tymoonnext.staple)

(defgeneric symb-package (symb-object)
  (:documentation "Returns the symbol-package of the symbol."))

(defclass symb-object ()
  ((symbol :initarg :symbol :initform (error "SYMBOL required") :accessor symb-symbol)
   (package :initarg :package :accessor symb-package))
  (:documentation "Base class for symbol representation."))

(defmethod initialize-instance :after ((symb symb-object) &key)
  (unless (slot-boundp symb 'package)
    (setf (symb-package symb) (symbol-package (symb-true-symbol symb)))))

(defclass symb-type (symb-object) ()
  (:documentation "Object representing a type."))
(defclass symb-variable (symb-object) ()
  (:documentation "Object representing a variable."))
(defclass symb-function (symb-object) ()
  (:documentation "Object representing a function."))
(defclass symb-accessor (symb-function) ()
  (:documentation "Object representing an accessor."))
(defclass symb-macro (symb-function) ()
  (:documentation "Object representing a macro."))
(defclass symb-generic (symb-function) ()
  (:documentation "Object representing a generic function."))
(defclass symb-method (symb-function)
  ((method :initarg :method :initform (error "METHOD required") :accessor symb-method))
  (:documentation "Object representing a generic function method."))
(defclass symb-condition (symb-type) ()
  (:documentation "Object representing a condition."))
(defclass symb-class (symb-type) ()
  (:documentation "Object representing a class."))
(defclass symb-structure (symb-class) ()
  (:documentation "Object representing a structure."))
(defclass symb-special (symb-variable) ()
  (:documentation "Object representing a special variable."))
(defclass symb-constant (symb-variable) ()
  (:documentation "Object representing a constant."))

(defmethod print-object ((symb symb-object) stream)
  (print-unreadable-object (symb stream :type T)
    (format stream "~a" (symb-symbol symb)))
  symb)

(defmethod print-object ((symb symb-method) stream)
  (print-unreadable-object (symb stream :type T)
    (format stream "~a ~{~s ~}~s"
            (symb-symbol symb)
            (method-qualifiers (symb-method symb))
            (symb-arguments symb)))
  symb)

(defgeneric symb-true-symbol (symb-object)
  (:documentation "Returns the the true symbol of the symbol.
Preferable over SYMB-SYMBOL as it takes SETF-function names into account.")
  (:method ((symb symb-object))
    (let ((symbol (symb-symbol symb)))
      (if (listp symbol)
          (second symbol)
          symbol))))

(defgeneric symb-name (symb-object)
  (:documentation "Returns the symbol-name of the symbol.")
  (:method ((symb symb-object))
    (symbol-name (symb-true-symbol symb))))

(defgeneric symb-function (symb-object)
  (:documentation "Returns the symbol-function of the symbol.")
  (:method ((symb symb-object))
    (fdefinition (symb-symbol symb))))

(defgeneric symb-type (symb-object)
  (:documentation "Returns the string-name of the kind of object it represents.")
  (:method ((symb symb-object))
    (subseq (string-upcase (class-name (class-of symb))) 5)))

(defgeneric symb-scope (symb-object)
  (:documentation "Returns whether the symbol is :INHERITED, :EXTERNAL or :INTERNAL.")
  (:method ((symb symb-object))
    (nth-value 1 (find-symbol (symb-name symb)
                              (symb-package symb)))))

(defgeneric symb-qualifiers (symb-object)
  (:documentation "Returns the qualifiers of the method or NIL.")
  (:method ((symb symb-method))
    (method-qualifiers (symb-method symb)))
  (:method ((symb symb-object))
    NIL))

(defgeneric symb-arguments (symb-object)
  (:documentation "Returns the arguments of the function or NIL.")
  (:method ((symb symb-object))
    NIL)
  (:method ((symb symb-function))
    (arg:arglist (symb-symbol symb)))
  (:method ((symb symb-generic))
    ;; Apparently f.e. SBCL reports things from methods too? (???)
    (let ((args (call-next-method)))
      (remove-if #'listp args)))
  (:method ((symb symb-method))
    (loop with args = (call-next-method)
          for specializer in (method-specializers (symb-method symb))
          for i from 0
          do (setf (nth i args)
                   (list (nth i args) (etypecase specializer
                                        (eql-specializer `(eql ,(eql-specializer-object specializer)))
                                        (class (class-name specializer)))))
          finally (return args))))

(defgeneric symb-documentation (symb-object)
  (:documentation "Returns the documentation-string.")
  (:method ((symb symb-function))
    (documentation (symb-symbol symb) 'function))
  (:method ((symb symb-method))
    (documentation (symb-method symb) T))
  (:method ((symb symb-variable))
    (documentation (symb-symbol symb) 'variable))
  (:method ((symb symb-type))
    (documentation (symb-symbol symb) 'type))
  (:method ((symb symb-structure))
    (documentation (symb-symbol symb) 'structure)))

(defgeneric symb-is (symb-object mask)
  (:documentation "Checks if the symbol matches the mask.
The mask should be a keyword of either :INHERITED, :INTERNAL, :EXTERNAL
or one of the symb-object types.")
  (:method (symb mask) NIL)
  (:method ((symb symb-object) (mask (eql :inherited)))
    (eql (symb-scope symb) :inherited))
  (:method ((symb symb-object) (mask (eql :internal)))
    (eql (symb-scope symb) :internal))
  (:method ((symb symb-object) (mask (eql :external)))
    (eql (symb-scope symb) :external))
  (:method ((symb symb-type) (mask (eql :type))) T)
  (:method ((symb symb-variable) (mask (eql :variable))) T)
  (:method ((symb symb-function) (mask (eql :function))) T)
  (:method ((symb symb-accessor) (mask (eql :accessor))) T)
  (:method ((symb symb-macro) (mask (eql :macro))) T)
  (:method ((symb symb-generic) (mask (eql :generic))) T)
  (:method ((symb symb-method) (mask (eql :method))) T)
  (:method ((symb symb-structure) (mask (eql :structure))) T)
  (:method ((symb symb-condition) (mask (eql :condition))) T)
  (:method ((symb symb-class) (mask (eql :class))) T)
  (:method ((symb symb-special) (mask (eql :special))) T)
  (:method ((symb symb-constant) (mask (eql :constant))) T))

(defgeneric symb< (a b)
  (:documentation "Used to sort symbols alphabetically.
Special treatment is done so that generic functions should
always appear before their methods.")
  (:method ((a symb-method) (b symb-generic))
    (if (eql (symb-symbol a) (symb-symbol b))
        T
        (call-next-method)))
  (:method ((a symb-generic) (b symb-method))
    (if (eql (symb-symbol a) (symb-symbol b))
        NIL
        (call-next-method)))
  (:method ((a symb-object) (b symb-object))
    (if (string= (symb-true-symbol a) (symb-true-symbol b))
        (listp (symb-symbol b))
        (string< (symb-true-symbol a) (symb-true-symbol b)))))

(defun symb-type< (a b)
  "Used to sort symbols alphabetically, grouped by their type."
  (if (string-equal (symb-type a) (symb-type b))
      (symb< a b)
      (flet ((type-order (symb)
               (loop for type in '(constant special variable
                                   class condition structure type
                                   accessor function generic method
                                   macro object)
                     for i from 0
                     do (when (string-equal (symb-type symb) type)
                          (return i)))))
        (< (type-order a) (type-order b)))))

(defun symbol-function-p (symbol)
  "Returns T if the symbol is a pure function."
  (and (fboundp symbol)
       (or (listp symbol)
           (not (macro-function symbol)))
       (not (typep (fdefinition symbol) 'standard-generic-function))))

(defun symbol-setf-function-p (symbol)
  "Returns T if the symbol is a setf function."
  (and (fboundp `(setf ,symbol))))

(defun symbol-accessor-p (symbol)
  "Returns T if the symbol is a function and setter."
  (and (or (symbol-function-p symbol)
           (symbol-generic-p symbol))
       (symbol-setf-function-p symbol)))

(defun symbol-macro-p (symbol)
  "Returns T if the symbol is a macro."
  (and (fboundp symbol)
       (macro-function symbol)))

(defun symbol-generic-p (symbol)
  "Returns T if the symbol is a generic function."
  (and (fboundp symbol)
       (typep (fdefinition symbol) 'standard-generic-function)))

(defun symbol-constant-p (symbol)
  "Returns T if the symbol is a constant."
  #+:lispworks (sys:symbol-constant-p symbol)
  #-:lispworks (constantp symbol))

(defun symbol-special-p (symbol)
  "REturns T if the symbol is a special variable."
  (and (not (symbol-constant-p symbol))
       #+:ccl (ccl:proclaimed-special-p symbol)
       #+:lispworks (sys:declared-special-p symbol)
       #+:sbcl (eq (sb-cltl2:variable-information symbol) :special)
       #+:allegro (eq (sys:variable-information symbol) :special)
       ;; Welp.
       #-(or :ccl :lispworks :sbcl :allegro) NIL))

(defun symbol-structure-p (symbol)
  "Returns T if the symbol is a structure."
  (ignore-errors
   (subtypep symbol 'structure-class)))

(defun symbol-condition-p (symbol)
  "Returns T if the symbol is a condition."
  (ignore-errors
   (subtypep symbol 'condition)))

(defun symbol-class-p (symbol)
  "Returns T if the symbol is a class."
  (and (not (symbol-structure-p symbol))
       (not (symbol-condition-p symbol))
       (find-class symbol nil)))

(defvar *converters* (make-hash-table :test 'eql)
  "Hash table to contain the converter functions.")

(defun converter (name)
  "Accessor to the converter function associated with the name.
Each converter function takes two arguments, a symbol and a package,
and must return a list of symb-object instances."
  (gethash name *converters*))

(defun (setf converter) (function name)
  (setf (gethash name *converters*) function))

(defun remove-converter (name)
  "Remove the named converter.

See CONVERTER"
  (remhash name *converters*))

(defmacro define-converter (name args &body body)
  "Shorthand to easily define a converter function.

See CONVERTER"
  `(progn (setf (converter ',name)
                (lambda ,args
                  ,@body))
          ',name))

(defmacro define-simple-converter (object-class test)
  "Shorthand for the most common definitions.
If TEST function passes, a single symbol object constructed from OBJECT-CLASS
is returned as a list."
  `(define-converter ,object-class (symbol package)
     (when (,test symbol)
       (list (make-instance ',object-class :symbol symbol :package package)))))

(define-converter symb-accessor (symbol package)
  (when (symbol-accessor-p symbol)
    (list* (make-instance 'symb-accessor :symbol symbol :package package)
           (funcall (converter 'symb-method) `(setf ,symbol) package))))

(define-converter symb-method (symbol package)
  (when (symbol-generic-p symbol)
    (loop for method in (generic-function-methods (fdefinition symbol))
          collect (make-instance 'symb-method :symbol symbol
                                              :package package
                                              :method method))))

(define-converter symb-setf-function (symbol package)
  (when (and (symbol-setf-function-p symbol)
             (not (symbol-accessor-p symbol)))
    (let ((setfer `(setf ,symbol)))
      (if (symbol-generic-p setfer)
          (list* (make-instance 'symb-generic :symbol setfer :package package)
                 (funcall (converter 'symb-method) setfer package))
          (list (make-instance 'symb-function :symbol setfer :package package))))))

(define-simple-converter symb-function
    (lambda (symbol) (and (symbol-function-p symbol) (not (symbol-accessor-p symbol)))))
(define-simple-converter symb-generic
    (lambda (symbol) (and (symbol-generic-p symbol) (not (symbol-accessor-p symbol)))))
(define-simple-converter symb-macro symbol-macro-p)
(define-simple-converter symb-special symbol-special-p)
(define-simple-converter symb-constant symbol-constant-p)
(define-simple-converter symb-structure symbol-structure-p)
(define-simple-converter symb-condition symbol-condition-p)
(define-simple-converter symb-class symbol-class-p)

(defun package-symbols (package)
  "Gets all symbols within a package."
  (let ((lst ()))
    (do-symbols (s package lst)
      (push s lst))))

(defun symbol-objects (symbols &optional package)
  "Gathers all possible symbol-objects out of the list of passed symbols."
  (let ((objs ()))
    (dolist (symbol symbols objs)
      (loop for converter being the hash-values of *converters*
            do (dolist (obj (funcall converter symbol (or package (symbol-package symbol))))
                 (push obj objs))))))

(defun package-symbol-objects (package)
  "Gathers all possible symbol-objects of the given package."
  (symbol-objects (package-symbols package) package))
