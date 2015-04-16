(ns udp-dispatch.midi
  (:require [midi]
            [dgram]
            [wisp.runtime :refer [>=]]
            [udp-dispatch.util :refer [buf->ypr]]
            [Baconjs :as Bacon]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def yaw-neg 208)
(def yaw-pos 209)
(def pitch-neg 210)
(def pitch-pos 211)

(def output (let [o (new midi.output)
                  _ (o.openVirtualPort "udp-dispatch")]
              o))

(defn send [channel value]
  (output.sendMessage [channel value 0]))

(def server (let [c (dgram.createSocket :udp4)
                  _ (c.bind 4222)]
              c))

(defn ypr->midi! [m]
  (do
    (let [yaw (:yaw m)
          pitch (:pitch m)]
      (if (>= yaw 0)
        (do (send yaw-pos yaw) (send yaw-neg 0))
        (do (send yaw-neg (* -1 yaw)) (send yaw-pos 0)))

      (if (>= pitch 0)
        (do (send pitch-pos pitch) (send pitch-neg 0))
        (do (send pitch-neg (* -1 pitch)) (send pitch-pos 0))))))

(defn read-datagram [server]
  (-> (Bacon.fromEvent server :message)
      (.map buf->ypr)
      (.onValue ypr->midi!)))

(defn start! []
  (console.log "Starting udp->midi bridge")
  (read-datagram server))
