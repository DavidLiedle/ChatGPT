(ns chat-cli.core-test
  (:require [clojure.test :refer :all]
            [chat-cli.core :as core]
            [clojure.java.io :as io]))

(deftest save-load-history
  (let [dir (java.nio.file.Files/createTempDirectory "hist" (make-array java.nio.file.attribute.FileAttribute 0))
        prev (System/getProperty "user.dir")]
    (System/setProperty "user.dir" (.toString dir))
    (try
      (core/save-history [{:role "user" :content "hi"}])
      (is (= [{:role "user" :content "hi"}] (core/load-history)))
      (finally
        (System/setProperty "user.dir" prev)))))

(deftest clear-history
  (let [dir (java.nio.file.Files/createTempDirectory "hist2" (make-array java.nio.file.attribute.FileAttribute 0))
        prev (System/getProperty "user.dir")]
    (System/setProperty "user.dir" (.toString dir))
    (try
      (core/save-history [{:role "user" :content "bye"}])
      (core/clear-history)
      (is (not (.exists (io/file core/history-file))))
      (finally
        (System/setProperty "user.dir" prev)))))
