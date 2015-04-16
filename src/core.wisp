(ns udp-dispatch.core
  (:require [dgram]
            [Baconjs :as Bacon]
            [udp-dispatch.serial :refer [attitude]]
            [udp-dispatch.midi :as midi]
            [udp-dispatch.util :refer [first second ypr->buf]]
            [ramda :refer [partial zip-obj]]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

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
