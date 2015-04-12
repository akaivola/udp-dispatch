(ns udp-dispatch.core
  (:require [dgram]
            [Baconjs :as Bacon]
            [udp-dispatch.serial :refer [attitude]]
            [udp-dispatch.midi :as midi]
            [udp-dispatch.util :refer [first second]]
            [ramda :refer [partial zip-obj]]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(defn- ypr->buf [ypr]
  (let [b (Buffer. (* 6 8))
        _ (b.writeDoubleLE 0 0)
        _ (b.writeDoubleLE 0 8)
        _ (b.writeDoubleLE 0 16)
        _ (b.writeDoubleLE (:yaw ypr) 24)
        _ (b.writeDoubleLE (:pitch ypr) 32)
        _ (b.writeDoubleLE (:roll ypr) 40)]
    b))

(def client (let [c (dgram.createSocket :udp4)
                  _ (c.bind 4243)]
              c))

(defn- send-datagram! [buffer]
  (client.send
    buffer
    0
    buffer.length
    4242
    :localhost))

(def arr->ypr (partial zip-obj [:yaw :pitch :roll]))

(defn- log [v] (console.log v))

(-> attitude ;test-stream
    (.map ypr->buf)
    (.onValue send-datagram!))

(midi.start!)
