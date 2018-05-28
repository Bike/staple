#|
 This file is a part of Staple
 (c) 2014 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.staple)

(defmethod clip:clip ((component asdf:component) field)
  (case* string-equal field
    (name (asdf:component-name component))
    (parent (asdf:component-parent component))
    (system (asdf:component-system component))
    (version (asdf:component-version component))
    (children (asdf:component-children component))
    (encoding (asdf:component-encoding component))
    (loaded-p (asdf:component-loaded-p component))
    (pathname (asdf:component-pathname component))
    (relative-pathname(asdf:component-relative-pathname component))
    (find-path (asdf:component-find-path component))
    (external-format (asdf:component-external-format component))
    (children-by-name (asdf:component-children-by-name component))
    (load-dependencies (asdf:component-sideway-dependencies component))
    (sideway-dependencies (asdf:component-sideway-dependencies component))
    (T (call-next-method))))

(defmethod clip:clip ((system asdf:system) field)
  (case* string-equal field
    (author (asdf:system-author system))
    (mailto (asdf:system-mailto system))
    (licence (asdf:system-licence system))
    (license (asdf:system-licence system))
    (homepage (asdf:system-homepage system))
    (long-name (asdf:system-long-name system))
    (maintainer (asdf:system-maintainer system))
    (bug-tracker (asdf:system-bug-tracker system))
    (description (asdf:system-description system))
    (source-file (asdf:system-source-file system))
    (source-control (asdf:system-source-control system))
    (long-description (asdf:system-long-description system))
    (source-directory (asdf:system-source-directory system))
    (definition-pathname (asdf:system-source-file system))
    (license-link
     (let ((license (first (find-files (uiop:pathname-directory-pathname (output *page*))
                                       '("LICENCE" "LICENSE") :max-depth 1))))
       (if license
           (resolve-source-link (list :file license) *page*)
           (format NIL "https://tldrlegal.com/search?q=~a" (asdf:system-license system)))))
    (T (call-next-method))))

(defmethod clip:clip ((package package) field)
  (case* string-equal field
    (name (package-name package))
    (nicknames (package-nicknames package))
    (shadowing-symbols (package-shadowing-symbols package))
    (use-list (package-use-list package))
    (used-by-list (package-used-by-list package))
    (symbols
     (loop for symbol being the symbols of package
           collect symbol))
    (external-symbols
     (loop for symbol being the external-symbols of package
           collect symbol))
    (T (call-next-method))))

(defmethod clip:clip ((symbol symbol) field)
  (case* string-equal field
    (name (symbol-name symbol))
    (package (symbol-package symbol))
    (value (symbol-value symbol))
    (function (symbol-function symbol))
    (plist (symbol-plist symbol))
    (T (call-next-method))))

(defmethod clip:clip ((definition definitions:definition) field)
  (case* string-equal field
    (xref (xref definition))
    (id (definition-id definition))
    (designator (definitions:designator definition))
    (object (definitions:object definition))
    (symbol (definitions:symbol definition))
    (name (definitions:name definition))
    (full-name (format NIL "~a:~a"
                       (package-name (definitions:package definition))
                       (definitions:designator definition)))
    (package (definitions:package definition))
    (type (type-of definition))
    (kind (definitions:type definition))
    (visibility (definitions:visibility definition))
    (documentation (maybe-lang-docstring definition (language *page*)))
    (source-location (definitions:source-location definition))
    (arguments ())
    (qualifiers ())
    (source-link
     (let ((source (absolute-source-location (definitions:source-location definition))))
       (when source (resolve-source-link source *page*))))
    (formatted-documentation
     (or (format-documentation definition *page*)
         "<i>No documentation provided.</i>"))
    (T (call-next-method))))

(defmethod clip:clip ((definition definitions:callable) field)
  (case* string-equal field
    (arguments (definitions:arguments definition))
    (T (call-next-method))))

(defmethod clip:clip ((definition definitions:method) field)
  (case* string-equal field
    (qualifiers (definitions:qualifiers definition))
    (T (call-next-method))))

(defmethod clip:clip ((definition definitions:package) field)
  (case* string-equal field
    (nicknames (package-nicknames (definitions:object definition)))
    (definitions
     (definitions *page* (definitions:object definition)))
    (T (call-next-method))))
