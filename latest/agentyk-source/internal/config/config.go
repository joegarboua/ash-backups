package config

import "os"

// Domain returns the configured mail domain, defaulting to agentyk.ru.
func Domain() string {
	if d := os.Getenv("AGENTYK_DOMAIN"); d != "" {
		return d
	}
	return "agentyk.ru"
}
