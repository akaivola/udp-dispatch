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
        calculate-sma (fn [sma m-n m]
                        (- (+ sma (/ m-n sample-size)) (/ m sample-size)))]
    (-> attitude
        (.map (fn [ypr]
                {:yaw  (normalize (:yaw ypr))
                 :pitch (normalize (:pitch ypr))
                 :roll (normalize (:roll ypr))}))
        (.sliding-window sample-size sample-size)
        (.scan {:yaw 0 :pitch 0 :roll 0}
               (fn [sma samples]
                 {:yaw   (or (calculate-sma  (:yaw sma)
                                             (:yaw (first samples))
                                             (:yaw (nth (- sample-size 1) samples))) 0)
                  :pitch (or (calculate-sma  (:pitch sma)
                                             (:pitch (first samples))
                                             (:pitch (nth (- sample-size 1) samples))) 0)
                  :roll  (or (calculate-sma  (:roll sma)
                                             (:roll (first samples))
                                             (:roll (nth (- sample-size 1) samples))) 0)}))
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

(defn offset [number to-offset] (+ number (* -1 to-offset)))
(defn zero [ypr center]
  {:yaw (offset (:yaw ypr) (:yaw center))
   :pitch (offset (:pitch ypr) (:pitch center))
   :roll (offset (:roll ypr) (:roll center))})

(-> (Bacon.combineWith zero normalized-attitude center)
    (.onValue midi.ypr->midi!))

(console.log "Press x to quit. c to center. Press c to start after Serial port is opened.")
