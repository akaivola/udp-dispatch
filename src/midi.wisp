(ns udp-dispatch.midi
  (:require [midi]
            [dgram]
            [wisp.runtime :refer [>=]]
            [udp-dispatch.util :refer [first second buf->ypr]]
            [Baconjs :as Bacon]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def yaw-a 208)
(def yaw-b 209)
(def yaw [yaw-a yaw-b])

(def pitch-a 210)
(def pitch-b 211)
(def pitch [pitch-a pitch-b])

(def output (let [o (new midi.output)
                  _ (o.openVirtualPort "udp-dispatch")]
              o))

(defn value->chans [value]
  (if (> value 0)
    (let [remainder (% value 255)]
      [(Math.floor (/ value 255)) remainder])
    [0 value]))

(defn scale [raw-value]
  (Math.round
   (* 100
      (+ 180 raw-value))))

(defn send [yaw-or-pitch raw-value]
  (let [scaled      (scale raw-value)
        chan-values (value->chans scaled)]
    (output.sendMessage [(first yaw-or-pitch) (first chan-values) 0])
    (output.sendMessage [(second yaw-or-pitch) (second chan-values) 0])))

(def server
  (let [c (dgram.createSocket :udp4)
        _ (c.bind 4222)]
    c))

(defn ypr->midi! [m]
  (do
    (send yaw (:yaw m))
    (send pitch (:pitch m))))

(defn read-datagram [server]
  (-> (Bacon.fromEvent server :message)
      (.map buf->ypr)
      (.onValue ypr->midi!)))

(defn start! []
  (console.log "Starting udp->midi bridge")
  (read-datagram server))
