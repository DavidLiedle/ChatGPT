(ns chat-cli.core
  (:require [clj-http.client :as http]
            [cheshire.core :as json]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:gen-class))

(def history-file "history.json")

(defn load-history []
  (let [f (io/file history-file)]
    (if (.exists f)
      (let [txt (slurp f)]
        (if (str/blank? txt)
          []
          (json/parse-string txt true)))
      [])))

(defn save-history [msgs]
  (spit history-file (json/generate-string msgs {:pretty true})))

(defn call-openai [msgs api-key]
  (let [resp (http/post "https://api.openai.com/v1/chat/completions"
                        {:headers {"Authorization" (str "Bearer " api-key)
                                   "Content-Type" "application/json"}
                         :body (json/generate-string {:model "gpt-4o"
                                                      :messages msgs})
                         :as :json})]
    (if (= 200 (:status resp))
      (-> resp :body :choices first :message :content)
      (throw (ex-info "API error" {:status (:status resp) :body (:body resp)}))))

(defn chat [api-key]
  (let [history (atom (load-history))]
    (println "Enter 'exit' to quit.")
    (loop []
      (print "> ")
      (flush)
      (when-let [line (read-line)]
        (let [text (str/trim line)]
          (if (#{"exit" "quit"} text)
            nil
            (do
              (swap! history conj {:role "user" :content text})
              (let [reply (call-openai @history api-key)]
                (println reply)
                (swap! history conj {:role "assistant" :content reply})
                (save-history @history))
              (recur))))))))

(defn print-history []
  (doseq [m (load-history)]
    (println (str (:role m) ": " (:content m)))))

(defn clear-history []
  (let [f (io/file history-file)]
    (when (.exists f)
      (.delete f))))

(defn -main [& args]
  (if (empty? args)
    (println "Usage: [chat|history|clear]")
    (let [api-key (System/getenv "OPENAI_API_KEY")]
      (if (str/blank? api-key)
        (println "OPENAI_API_KEY not set")
        (case (first args)
          "chat" (chat api-key)
          "history" (print-history)
          "clear" (clear-history)
          (println "Unknown command"))))))
