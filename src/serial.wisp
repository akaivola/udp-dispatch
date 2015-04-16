(ns udp-dispatch.serial
  (:require [serialport :refer [SerialPort]]
            [Baconjs :refer [Bus]]
            [udp-dispatch.util :refer [first]]
            [ramda :refer [map reduce filter]]
            [wisp.runtime :refer [when + = < <= >= >]]))

(defmacro -> [& operations] (reduce (fn [form operation] (cons (first operation) (cons form (rest operation)))) (first operations) (rest operations)))

(def ^:private accumulator (Bus.))
(def ^:private hatire-offset 4)
(def ^:private hatire-read-length 12)
(def ^:private hatire-length 30)

(defn buf->ypr [buffer]
  (let [yaw   (buffer.readFloatLE hatire-offset)
        pitch (buffer.readFloatLE (+ hatire-offset 4))
        roll  (buffer.readFloatLE (+ hatire-offset 8))]
    {:yaw yaw
     :pitch pitch
     :roll roll}))

(defn- full? [buffer]
  (= hatire-length buffer.length))

(defn notf [pred]
  (fn [x] (not (pred x))))

(def attitude
  (-> accumulator
      (.skipWhile
       (fn [buffer]
         (and (>= 2 buffer.length)
              (not (= 0xAAAA (buffer.readUInt16LE 0))))))
      (.scan [(Buffer. 0) (Buffer. 0)]
       (fn [acc buffer]
         (let [buffers      (-> (filter (notf full?) acc)
                                (.concat buffer))
               total-length (reduce + 0 (map (fn [b] b.length) buffers))
               concatenated (Buffer.concat buffers total-length)
               fst (concatenated.slice 0 hatire-length)
               snd (concatenated.slice hatire-length concatenated.length)]
           [fst snd])))
      (.toEventStream)
      (.map first)
      (.filter full?)
      (.map buf->ypr)))

(def ^:private port (SerialPort. "/dev/tty.HC-06-DevB"
                       {:baudrate 115200
                        :buffersize 30}
                       false ; do not open immediately
                       ))

(defn- on-open [error]
  (console.log (str "Serial port opened" (if error (str ", error: " error) "")))
  (port.on :data
           (fn [buffer]
             (accumulator.push buffer))))

(port.open on-open)
