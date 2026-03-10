package monitor

import (
	"encoding/json"
	"fmt"
	"log"
	"os/exec"
	"time"

	"github.com/agentyk/agentyk/internal/notify"
)

type BlockchainInfo struct {
	Blocks           int     `json:"blocks"`
	Headers          int     `json:"headers"`
	VerificationProgress float64 `json:"verificationprogress"`
	InitialBlockDownload bool    `json:"initialblockdownload"`
}

var (
	lastBitcoinAlert time.Time
	lastKnownBlock   int
	stuckCounter     int
)

func WatchBitcoinSync(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	log.Printf("[MONITOR] Bitcoin sync watcher started (interval: %v)", interval)

	for range ticker.C {
		checkBitcoinSync()
	}
}

func checkBitcoinSync() {
	cmd := exec.Command("docker", "exec", "ash-bitcoind", "bitcoin-cli", "getblockchaininfo")
	out, err := cmd.Output()
	if err != nil {
		log.Printf("[MONITOR] Failed to check bitcoin sync: %v", err)
		// Alert if bitcoin-cli is unreachable
		now := time.Now()
		if now.Sub(lastBitcoinAlert) > 6*time.Hour {
			_ = notify.TelegramAdmin("⚠️ Bitcoin node unreachable (bitcoin-cli failed)")
			lastBitcoinAlert = now
		}
		return
	}

	var info BlockchainInfo
	if err := json.Unmarshal(out, &info); err != nil {
		log.Printf("[MONITOR] Failed to parse blockchain info: %v", err)
		return
	}

	progress := info.VerificationProgress * 100

	// Check if sync is stalled (no progress in 3 checks = ~1.5 hours)
	if info.Blocks == lastKnownBlock {
		stuckCounter++
		if stuckCounter >= 3 {
			now := time.Now()
			if now.Sub(lastBitcoinAlert) > 6*time.Hour {
				_ = notify.TelegramAdmin(fmt.Sprintf(
					"⚠️ Bitcoin sync stalled at block %d (%.2f%% complete)",
					info.Blocks, progress,
				))
				lastBitcoinAlert = now
				log.Printf("[MONITOR] Bitcoin sync appears stalled at block %d", info.Blocks)
			}
			stuckCounter = 0 // Reset to avoid spam
		}
	} else {
		stuckCounter = 0
		lastKnownBlock = info.Blocks
	}

	// Log progress periodically
	if info.InitialBlockDownload {
		log.Printf("[MONITOR] Bitcoin sync: %.2f%% - Block %d/%d", progress, info.Blocks, info.Headers)
	}
}
