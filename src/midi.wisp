(ns udp-dispatch.midi
  (:require [midi]
            [dgram]
            [wisp.runtime :refer [>=]]
            [udp-dispatch.util :refer [first second third buf->ypr]]
            [Baconjs :as Bacon]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def yaw-a 208)
(def yaw-b 209)
(def yaw-c 210)
(def yaw [yaw-a yaw-b yaw-c])

(def pitch-a 211)
(def pitch-b 212)
(def pitch-c 213)
(def pitch [pitch-a pitch-b pitch-c])

(def output (let [o (new midi.output)
                  _ (o.openVirtualPort "udp-dispatch")]
              o))

(def input (let [i (new midi.input)
                 _ (i.openPort 0)]
             i))

(def midi-input (-> (Bacon.fromBinder (fn [sink]
                                          (input.on :message (fn [deltaTime message]
                                                           (sink message)))
                                          (fn [])))))

(midi-input.onValue (fn [val] (console.log val)))

(defn value->chans [value]
  (let [a (bit-and (bit-shift-right value 16) 255)
        b (bit-and (bit-shift-right value 8) 255)
        c (bit-and value 255)]
    [a b c]))

(def max (Math.pow 2 24))
(defn scale
  "Scale number to a positive 0-90 degree arc using 3 bytes"
  [raw-value]
  (-> max
      (/ 90)
      (* (+ 45 raw-value))
      (Math.round)
      (- 1)
      (Math.min max)
      (Math.max 0)))

(defn send [yaw-or-pitch raw-value]
  (let [scaled      (scale raw-value)
        chan-values (value->chans scaled)]
    (output.sendMessage [(first yaw-or-pitch) (first chan-values) 0])
    (output.sendMessage [(second yaw-or-pitch) (second chan-values) 0])
    (output.sendMessage [(third yaw-or-pitch) (third chan-values) 0])))

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
