(defun power (a b)
  (let ((y b))
  (let ((x a))
    (loop while (> y 0) do
      (setf x (* x a))
      (setf y (- y 1)))
      (print x))))
