(in-package :texatl.cl)

(defclass texatl-spritesheet ()
  ((metrics :initform (make-hash-table :test 'equal) :initarg :metrics)))

(defmethod conspack:encode-object ((object texatl-spritesheet)
                                   &key &allow-other-keys)
  (with-slots (metrics) object
    (alist :metrics metrics)))

(defmethod conspack:decode-object ((class (eql 'texatl-spritesheet))
                                   alist &key &allow-other-keys)
  (alist-bind (metrics) alist
    (make-instance 'texatl-spritesheet :metrics metrics)))

(defun sprite (spritesheet name frame)
  "Return a float-vector in the form #(X0 Y0 X1 Y1) for a sprite given
`NAME` and `FRAME`."
  (with-slots (metrics) spritesheet
    (aref (gethash name metrics) frame)))

(defmacro with-sprite ((x0 y0 x1 y1) name frame sprite-sheet &body body)
  (with-gensyms (metrics)
    (once-only (name frame sprite-sheet)
      `(let ((,metrics (sprite ,sprite-sheet ,name ,frame)))
         (if (null ,metrics)
             (error "Sprite ~A frame ~A not found in ~A"
                    ,name ,frame ,sprite-sheet)
             (let ((,x0 (aref ,metrics 0))
                   (,y0 (aref ,metrics 1))
                   (,x1 (aref ,metrics 2))
                   (,y1 (aref ,metrics 3)))
               ,@body))))))

(defun frame-count (spritesheet name)
  "Return the number of frames for sprite named `NAME` in spritesheet."
  (with-slots (metrics) spritesheet
    (length (gethash name metrics))))

(defmacro mapsheet (function-designator spritesheet)
  "Iterate over `SPRITESHEET` and pass `NAME`, `FRAME`, and a vector
of coordinates to `FUNCTION-DESIGNATOR`.  That is, iterate over every
frame in every sprite, passing its metrics."
  (once-only (function-designator)
    (with-gensyms (metrics k v vec i)
      `(with-slots ((,metrics metrics)) ,spritesheet
         (maphash
          (lambda (,k ,v)
            (loop for ,vec across ,v
                  for ,i from 0
                  do (funcall ,function-designator ,k ,i ,vec)))
          ,metrics)))))
