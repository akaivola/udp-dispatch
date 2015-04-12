(ns udp-dispatch.midi
  (:require [midi]
            [dgram]
            [Baconjs :as Bacon]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def yaw 208)
(def pitch 209)
(def roll 210)

(def output (let [o (new midi.output)
                  (o.openVirtualPort "udp-dispatch")]
              o))

(defn send [channel value]
  (output.sendMessage [channel value 0]))

(def server (let [c (dgram.createSocket :udp4)
                  _ (c.bind 4222)]
              c))

(defn ypr->midi! [m]
  (do
    (send yawch (:yaw m))
    (send yawch (:pitch m))
    (send yawch (:roll m))))

(defn read-datagram [server]
  (-> (Bacon.fromEvent server :message)
      (.onValue (fn [msg] (console.log "got message" msg)))))

(defn start! []
  (console.log "Starting udp->midi bridge")
  (read-datagram server))
