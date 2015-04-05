(ns udp-dispatch
  (:require [dgram]
            [serial :refer [attitude]]
            [wisp.runtime :refer [= and not or]]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))


(defn- buf [n]
  (Buffer. n))

(defn- test-buf []
  (let [b (buf (* 6 8))
        _ (b.writeDoubleLE 1.0 0)
        _ (b.writeDoubleLE 2.0 8)
        _ (b.writeDoubleLE 3.0 16)
        _ (b.writeDoubleLE 4.0 24)
        _ (b.writeDoubleLE 5.0 32)
        _ (b.writeDoubleLE 6.0 40)]
    b))

(defn ypr->buf [ypr]
  (let [b (buf (* 6 8))
        _ (b.writeDoubleLE (:yaw ypr) 0)
        _ (b.writeDoubleLE (:pitch ypr) 8)
        _ (b.writeDoubleLE (:roll ypr) 16)
        _ (b.writeDoubleLE 0.0 24)
        _ (b.writeDoubleLE 0.0 32)
        _ (b.writeDoubleLE 0.0 40)]
    b))

(defn send-datagram! [buffer]
  (let [client (dgram.createSocket :udp4)
        _ (client.bind 4243)
        closef (fn [err bytes] (client.close))]
    (client.send
     buffer
     0
     buffer.length
     4242
     :localhost closef)
    nil))

(-> attitude
    (.map ypr->buf)
    (.onValue send-datagram!))
