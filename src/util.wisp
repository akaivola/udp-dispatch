(ns udp-dispatch.util
  (:require [ramda :refer [nth partial]]))

(def first (partial nth 0))
(def second (partial nth 1))

(defn ypr->buf [ypr]
  (let [b (Buffer. (* 6 8))
        _ (b.writeDoubleLE 0 0)
        _ (b.writeDoubleLE 0 8)
        _ (b.writeDoubleLE 0 16)
        _ (b.writeDoubleLE (:yaw ypr) 24)
        _ (b.writeDoubleLE (:pitch ypr) 32)
        _ (b.writeDoubleLE (:roll ypr) 40)]
    b))

(defn buf->ypr [buf]
  {:yaw   (buf.readDoubleLE 24)
   :pitch (buf.readDoubleLE 32)
   :roll  (buf.readDoubleLE 40)})
