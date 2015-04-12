(ns udp-dispatch.util
  (:require [ramda :refer [nth partial]))

(def first (partial nth 0))
(def second (partial nth 1))
