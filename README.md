# NodeExporter / Prometheus
**BEFORE YOU BEGIN**
**Make sure you have nginx installed**
**Run the script only once. If you run it more than once you will have to clear the last lines in /etc/ngingx/sites-enables/<yourWebsite>**


*Installation:* 
1. Clone the repo
2. cd Node-Exporter-for-Prometheus
3. chmod +x script-grafana.sh
4. ./script-grafana.sh
5. you will be asked two times to select yes
6. Enjoy

P.S Don't forget to add the IP in Prometheus instance (nano /etc/prometheus/prometheus.yml)
