(ns udp-dispatch.test
  (:require [udp-dispatch.core :as u]
            [Baconjs :as Bacon]
            [ramda :refer [partial zip]]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def test-stream
  (-> (Bacon.interval 333 1)
      (.map u.rand)
      (.bufferWithCount 3)
      (.map u.arr->ypr)
      (.onValue (fn [v] (console.log v)))))
