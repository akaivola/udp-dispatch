(ns udp-dispatch.core
  (:require [dgram]
            [Baconjs :as Bacon]
            [udp-dispatch.serial :refer [attitude re-open]]
            [udp-dispatch.midi :as midi]
            [udp-dispatch.util :refer [first second third ypr->buf]]
            [wisp.runtime :refer [= > <]]
            [keypress]
            [ramda :refer [nth partial zip-obj mapObj]]))


(def center (new Bacon.Bus))
(center.push {:yaw 0 :pitch 0 :roll 0})
(keypress process.stdin)

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def arr->ypr (partial zip-obj [:yaw :pitch :roll]))

(defn- log [v] (console.log v))

(def alpha 0.5)

(defn normalize [degree]
  (if (> degree 180)
    (- degree 360)
    degree))

(def normalized-attitude
  (let [sample-size   2
        minimum-delta 0.17
        delta (fn [k samples]
                (- (aget (second samples) k)
                   (aget (first samples) k)))]
    (-> attitude
        (.map (fn [ypr]
                {:yaw  (normalize (:yaw ypr))
                 :pitch (normalize (:pitch ypr))
                 :roll (normalize (:roll ypr))}))
        (.sliding-window sample-size sample-size)
        (.scan {:yaw 0 :pitch 0 :roll 0}
               (fn [acc samples]
                 (let [d1 (Math.abs (delta :yaw samples))
                       d2 (Math.abs (delta :pitch samples))]
                   (if (or (> d1 minimum-delta)
                           (> d2 minimum-delta))
                     (second samples)
                     {:yaw   (+ (:yaw acc)   (/ (delta :yaw samples) 4))
                      :pitch (+ (:pitch acc) (/ (delta :pitch samples) 4))
                      :roll  (+ (:roll acc)  (/ (delta :roll samples) 4))}))))
        (.to-event-stream))))

(defn- pos? [x] (and x (> x 0)))

(process.stdin.on :keypress
  (fn [chunk, key]
    (let [key? (fn [k] (= key.name k))]
      (cond (key? :c)
            (-> normalized-attitude
              (.take 1)
              (.onValue (fn [v] (center.push v))))

            (key? :q)
            (if (pos? (- alpha 0.1 alpha))
              (do (set! alpha (- alpha 0.1)) (console.log "Alpha set to" alpha)))
            (key? :a)
            (if (not= 1 (+ alpha 0.1))
              (do (set! alpha (+ alpha 0.1)) (console.log "Alpha set to" alpha)))

            (key? :r)
            (re-open)

            (key? :x)
              (process.exit)))))

(process.stdin.setRawMode true)
(process.stdin.resume)
(center.onValue (fn [v] (console.log "Zeroed to" v)))

(def notes (-> (midi.midi-input.filter (fn [values] (= 144 (aget values 0))))
               (.map second)))


; center on channel zero
(-> (notes.filter (fn [channel] (= 0 channel)))
    (.doAction (fn [v] (console.log "Centering")))
    (.onValue (fn [_] (-> (normalized-attitude.take 1)
                         (.onValue (fn [v] (center.push v)))))))

(defn offset [number to-offset] (+ number (* -1 to-offset)))
(defn zero [ypr center]
  {:yaw (offset (:yaw ypr) (:yaw center))
   :pitch (offset (:pitch ypr) (:pitch center))
   :roll (offset (:roll ypr) (:roll center))})

(-> (Bacon.combineWith zero normalized-attitude center)
    (.onValue midi.ypr->midi!))

(console.log "Press x to quit. c to center. Press c to start after Serial port is opened.")
