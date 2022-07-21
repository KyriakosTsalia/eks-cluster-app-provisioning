package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/gorilla/mux"
	"html/template"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

type Server struct {
	*mux.Router
}

func (s *Server) routes() {
	s.HandleFunc("/", s.get_pods()).Methods("GET")
	s.HandleFunc("/api/ready", s.ready()).Methods("GET")
	s.HandleFunc("/api/healthy", s.healthy()).Methods("GET")
	s.Handle("/metrics", promhttp.Handler())

}

func NewServer() *Server {
	s := &Server{
		Router: mux.NewRouter(),
	}
	s.routes()
	return s
}

func (s *Server) ready() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write(nil)
	}
}

func (s *Server) healthy() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write(nil)
	}
}

func isFlagPassed(name string) bool {
	found := false
	flag.Visit(func(f *flag.Flag) {
		if f.Name == name {
			found = true
		}
	})
	return found
}

func (s *Server) get_pods() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		namespace, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")
		if err != nil {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}

		url := "https://kubernetes.default.svc/api/v1/namespaces/" + string(namespace) + "/pods"

		token, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/token")
		if err != nil {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}

		var bearer = "Bearer " + string(token)

		req, err := http.NewRequest("GET", url, nil)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		req.Header.Add("Authorization", bearer)

		caCert, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
		if err != nil {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}

		caCertPool := x509.NewCertPool()
		caCertPool.AppendCertsFromPEM(caCert)
		client := &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					RootCAs: caCertPool,
				},
			},
		}

		res, err := client.Do(req)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		defer res.Body.Close()

		data, err := ioutil.ReadAll(res.Body)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// to return a json, uncomment these lines and delete everything under them
		// w.Header().Set("Content-Type", "application/json")
		// w.WriteHeader(http.StatusOK)
		// w.Write(data)

		var dd map[string]interface{}

		if err := json.Unmarshal(data, &dd); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		t, err := template.ParseFiles("/app/main.html")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		h, err := os.Hostname()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		data_struct := struct {
			Items    interface{}
			Hostname string
		}{dd["items"], h}

		w.WriteHeader(http.StatusOK)
		t.Execute(w, data_struct)
	}
}

func main() {
	srv := NewServer()

	delayPtr := flag.String("delay", "0", "app start delay")

	flag.Parse()
	if isFlagPassed("delay") && *delayPtr != "" && *delayPtr != "0" {
		fmt.Printf("Sleeping for %v seconds\n", *delayPtr)
		sec, err := strconv.Atoi(*delayPtr)
		if err != nil {
			fmt.Fprintf(os.Stderr, "error: %v\n", err)
			os.Exit(1)
		}
		time.Sleep(time.Duration(sec) * time.Second)
		fmt.Println("Server started on port 8080")
		http.ListenAndServe(":8080", srv)
	} else {
		fmt.Println("Server started on port 8080")
		http.ListenAndServe(":8080", srv)
	}
}
