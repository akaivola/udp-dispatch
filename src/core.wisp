(ns udp-dispatch.core
  (:require [dgram]
            [Baconjs :as Bacon]
            [udp-dispatch.serial :refer [attitude]]
            [udp-dispatch.midi :as midi]
            [udp-dispatch.util :refer [first second ypr->buf]]
            [wisp.runtime :refer [= > <]]
            [keypress]
            [ramda :refer [partial zip-obj]]))


(def center (new Bacon.Bus))
(center.push {:yaw 0 :pitch 0 :roll 0})
(keypress process.stdin)

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

(defn normalize [degree]
  (if (> degree 180)
    (- degree 360)
    degree))

(def normalized-attitude
  (-> attitude ;test-stream
      (.map (fn [ypr]
              {:yaw  (normalize (:yaw ypr))
               :pitch (normalize (:pitch ypr))
               :roll (normalize (:roll ypr))}))))

(process.stdin.on :keypress (fn [chunk, key]
                      (if (and key (= key.name "c"))
                        (-> normalized-attitude
                            (.take 1)
                            (.onValue (fn [v] (center.push v))))
                        (if (= key.name "q")
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

(console.log "Press q to quit. c to center")
