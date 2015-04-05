(ns serial
  (:require [serialport :as sp :refer [SerialPort]]
            [Bacon :as b]))

(def attitude (b/Bus.))

(def ^:private hatire-offset 4)

(def ^:private hatire-read-length 12)

(def ^:private port (SerialPort. "/dev/tty.HC-06-DevB"
                       {:baudrate 115200
                        :buffersize 30}
                       false ; do not open immediately
                       ))

(defn- on-open [error]
  (port.on :data
           (fn [buffer]
             (let [yaw   (buffer.readFloatLE hatire-offset)
                   pitch (buffer.readFloatLE (+ hatire-offset 4))
                   roll  (buffer.readFloatLE (+ hatire-offset 8))]
               (attitude.push {:yaw yaw
                               :pitch pitch
                               :roll roll})))))

(port.open on-open)
