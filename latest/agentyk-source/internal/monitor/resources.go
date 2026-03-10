package monitor

import (
	"fmt"
	"log"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/agentyk/agentyk/internal/notify"
)

var lastResourceAlert time.Time

func WatchResources(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	log.Printf("[MONITOR] Resource watcher started (interval: %v)", interval)

	for range ticker.C {
		checkResources()
	}
}

func checkResources() {
	diskUsage := checkDiskSpace()
	ramUsage := checkRAMUsage()

	var alerts []string

	if diskUsage >= 90.0 {
		alerts = append(alerts, fmt.Sprintf("💾 Disk usage critical: %.1f%%", diskUsage))
	} else if diskUsage >= 80.0 {
		alerts = append(alerts, fmt.Sprintf("💾 Disk usage high: %.1f%%", diskUsage))
	}

	if ramUsage >= 95.0 {
		alerts = append(alerts, fmt.Sprintf("🧠 RAM usage critical: %.1f%%", ramUsage))
	} else if ramUsage >= 85.0 {
		alerts = append(alerts, fmt.Sprintf("🧠 RAM usage high: %.1f%%", ramUsage))
	}

	if len(alerts) > 0 {
		now := time.Now()
		// Throttle resource alerts to once per hour
		if now.Sub(lastResourceAlert) > time.Hour {
			msg := "⚠️ Resource Alert:\n" + strings.Join(alerts, "\n")
			_ = notify.TelegramAdmin(msg)
			lastResourceAlert = now
			log.Printf("[MONITOR] Resource alert sent: %v", alerts)
		}
	}
}

func checkDiskSpace() float64 {
	cmd := exec.Command("df", "/")
	out, err := cmd.Output()
	if err != nil {
		log.Printf("[MONITOR] Failed to check disk space: %v", err)
		return 0
	}

	// Parse df output: Filesystem Size Used Avail Use% Mounted
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) < 2 {
		return 0
	}

	fields := strings.Fields(lines[1])
	if len(fields) < 5 {
		return 0
	}

	// Use% field (e.g., "45%")
	useStr := strings.TrimSuffix(fields[4], "%")
	usage, err := strconv.ParseFloat(useStr, 64)
	if err != nil {
		log.Printf("[MONITOR] Failed to parse disk usage: %v", err)
		return 0
	}

	return usage
}

func checkRAMUsage() float64 {
	cmd := exec.Command("free")
	out, err := cmd.Output()
	if err != nil {
		log.Printf("[MONITOR] Failed to check RAM usage: %v", err)
		return 0
	}

	// Parse free output
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) < 2 {
		return 0
	}

	// Mem: total used free shared buff/cache available
	fields := strings.Fields(lines[1])
	if len(fields) < 3 {
		return 0
	}

	total, err1 := strconv.ParseFloat(fields[1], 64)
	used, err2 := strconv.ParseFloat(fields[2], 64)
	if err1 != nil || err2 != nil {
		log.Printf("[MONITOR] Failed to parse RAM values")
		return 0
	}

	if total == 0 {
		return 0
	}

	return (used / total) * 100
}
