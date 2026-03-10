package monitor

import (
	"fmt"
	"log"
	"os/exec"
	"strings"
	"time"

	"github.com/agentyk/agentyk/internal/notify"
)

var expectedContainers = []string{
	"agentyk",
	"agentyk-db",
	"ash-nginx",
	"ash-btcpay",
	"ash-bitcoind",
	"ash-stalwart",
	"ash-nbxplorer",
}

var lastAlertTime = make(map[string]time.Time)

func WatchServices(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	log.Printf("[MONITOR] Service watcher started (interval: %v)", interval)

	for range ticker.C {
		checkServices()
	}
}

func checkServices() {
	cmd := exec.Command("docker", "ps", "--format", "{{.Names}}")
	out, err := cmd.Output()
	if err != nil {
		log.Printf("[MONITOR] Failed to check docker containers: %v", err)
		return
	}

	running := make(map[string]bool)
	for _, name := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		if name != "" {
			running[name] = true
		}
	}

	now := time.Now()
	for _, container := range expectedContainers {
		if !running[container] {
			// Throttle alerts: max one per container per hour
			if last, exists := lastAlertTime[container]; !exists || now.Sub(last) > time.Hour {
				_ = notify.TelegramAdmin(fmt.Sprintf("⚠️ Container down: %s", container))
				lastAlertTime[container] = now
				log.Printf("[MONITOR] Alert sent: container %s is down", container)
			}
		} else {
			// Container is up - clear alert throttle
			delete(lastAlertTime, container)
		}
	}
}
