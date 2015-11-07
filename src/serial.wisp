(ns udp-dispatch.serial
  (:require [bluetooth-serial-port]
            [Baconjs :refer [Bus Error]]
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
         (let [begin-of-frame? (and (= 0xAA (aget buffer 0))
                                    (= 0xAA (aget buffer 1)))]
           (if begin-of-frame?
             (console.log "Beginning frame found: " buffer)
             (console.log "Seeking beginning of frame, got: " buffer))
           ; skips elements until falsy returned once
           (not begin-of-frame?))))
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

(def ^:private port (new bluetooth-serial-port.BluetoothSerialPort))

(port.on
 :found
 (fn [address name]
   (console.log "Found bluetooth device" name "[" address "]")
   (port.find-serial-port-channel
    address
    (fn [channel]
      (console.log "Connecting to" address)
      (port.connect
       address channel
       (fn []
         (console.log "Connected to" address)
         (port.on :data (fn [buffer] (accumulator.push buffer))))))
    (fn []
      (console.log "Error connecting to " address)))))

(defn- on-open [error]
  (if error
    (do
      (console.log (str "error: " error))
      (port.open on-open))
    (do
      (console.log (str "Serial port opened"))
      )))

(defn re-open []
  (port.close)
  (port.inquire)
  true)

(port.inquire)
