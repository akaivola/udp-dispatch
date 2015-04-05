(ns udp-dispatch.test
  (:require [udp-dispatch.core :as u]
            [Baconjs :as Bacon]
            [ramda :refer [partial zip]]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def test-stream
  (-> (Bacon.repeat u.rand)
      (.slidingWindow 3 3)
      (.toEventStream)
      (.map u.arr->ypr)
      (.debounce 1000)
      (.onValue (fn [v] (console.log v)))))
