#!/usr/bin/env python3
"""ASH Dashboard + Brain Gateway - Merged Server"""

import asyncio
import json
import os
import re
import subprocess
import time
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional

try:
    from aiohttp import web
except ImportError:
    print("Install aiohttp: pip install aiohttp")
    exit(1)

# Configuration
PORT = 8080
ASH_DIR = Path('/home/ash/ASH')
TASK_QUEUE = ASH_DIR / 'task-queue.md'
BIBLE_PATH = ASH_DIR / 'bible.md'
MEMORY_PATH = ASH_DIR / 'memory' / 'MEMORY.md'

class BrainStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    DOWN = "down"

@dataclass
class Brain:
    name: str
    command: list
    timeout: int
    status: BrainStatus = BrainStatus.HEALTHY
    last_failure: Optional[float] = None
    failure_count: int = 0
    success_count: int = 0
    avg_response_time: float = 0.0

# Brain registry
BRAINS = {
    "claude": Brain(
        name="claude",
        command=[str(ASH_DIR / "daemon/claude-serialized.sh"), "--dangerously-skip-permissions", "-p", "{prompt}", "--output-format", "text"],
        timeout=180,
    ),
    "kimi": Brain(
        name="kimi",
        command=["/home/ash/.local/bin/kimi", "-p", "{prompt}", "--print", "--final-message-only", "--yolo"],
        timeout=120,
    ),
    "codex": Brain(
        name="codex",
        command=["/usr/local/bin/codex", "exec", "--skip-git-repo-check", "--full-auto", "--dangerously-skip-permissions", "{prompt}"],
        timeout=120,
    ),
}

RATE_LIMIT_PATTERNS = [
    "rate limit", "too many requests", "429", "quota exceeded",
    "you've hit your limit", "resets", "limit exceeded"
]

# Dashboard functions
def get_memory():
    try:
        out = subprocess.check_output(['free', '-m'], text=True)
        mem = out.strip().split('\n')[1].split()
        return {'total': int(mem[1]), 'used': int(mem[2]), 'free': int(mem[3])}
    except:
        return {'total': 0, 'used': 0, 'free': 0}

def get_services():
    """Check docker containers - try CLI first, fall back to host-generated file"""
    try:
        out = subprocess.check_output(['docker', 'ps', '-a', '--format', '{{.Names}}:{{.Status}}'], text=True)
        services = {}
        for line in out.strip().split('\n'):
            if ':' in line:
                name, status = line.split(':', 1)
                if name.startswith('ash-') or name in ['agentyk', 'agentyk-db']:
                    if status.startswith('Up'):
                        if 'unhealthy' in status:
                            services[name] = 'unhealthy'
                        elif 'healthy' in status:
                            services[name] = 'healthy'
                        else:
                            services[name] = 'active'
                    else:
                        services[name] = 'dead'
        return services
    except:
        pass
    # Fallback: read from host-generated file
    try:
        svc_file = Path('/home/ash/ASH/dashboard/.services.json')
        if svc_file.exists():
            import json as _json2
            return _json2.loads(svc_file.read_text())
    except:
        pass
    return {'error': 'unavailable'}

def get_tasks():
    pending, completed = [], []
    try:
        if TASK_QUEUE.exists():
            with open(TASK_QUEUE, 'r') as f:
                for line in f:
                    if line.startswith('- [ ]'):
                        m = re.search(r'(TASK-\d+):?\s*([^|]+)', line)
                        if m: pending.append({'id': m.group(1), 'desc': m.group(2).strip()})
                    elif line.startswith('- [x]'):
                        m = re.search(r'(TASK-\d+):?\s*([^|]+)', line)
                        if m: completed.append({'id': m.group(1), 'desc': m.group(2).strip()})
    except:
        pass
    return {'pending': pending, 'completed': completed[-15:]}

def get_brain_log():
    try:
        log_file = ASH_DIR / 'daemon/logs/telegram.log'
        if log_file.exists():
            return subprocess.check_output(['tail', '-12', str(log_file)], text=True)
        return 'No logs'
    except:
        return 'No logs'

def get_mail():
    try:
        mail_file = ASH_DIR / 'TRIBE-MAIL/mail.md'
        if mail_file.exists():
            return subprocess.check_output(['tail', '-20', str(mail_file)], text=True)
        return 'No mail'
    except:
        return 'No mail'


def get_resources():
    """Get CPU, RAM, Storage, Bandwidth stats for dashboard gauges"""
    res = {}
    
    # CPU
    try:
        cores = int(subprocess.check_output(["nproc"], text=True).strip())
        load = float(open("/proc/loadavg").read().split()[0])
        cpu_pct = min(100, round(load / cores * 100, 1))
        res["cpu"] = {"percent": cpu_pct, "cores": cores, "load": load}
    except:
        res["cpu"] = {"percent": 0, "cores": 0, "load": 0}
    
    # RAM
    try:
        out = subprocess.check_output(["free", "-m"], text=True)
        mem = out.strip().split("\n")[1].split()
        total_mb = int(mem[1])
        used_mb = int(mem[2])
        pct = round(used_mb / total_mb * 100, 1) if total_mb > 0 else 0
        res["ram"] = {"percent": pct, "used_mb": used_mb, "total_mb": total_mb}
    except:
        res["ram"] = {"percent": 0, "used_mb": 0, "total_mb": 0}
    
    # Storage
    try:
        out = subprocess.check_output(["df", "-BG", "/"], text=True)
        parts = out.strip().split("\n")[1].split()
        total_gb = int(parts[1].rstrip("G"))
        used_gb = int(parts[2].rstrip("G"))
        pct = round(used_gb / total_gb * 100, 1) if total_gb > 0 else 0
        res["storage"] = {"percent": pct, "used_gb": used_gb, "total_gb": total_gb}
    except:
        res["storage"] = {"percent": 0, "used_gb": 0, "total_gb": 0}
    
    # Bandwidth (from host-updated file)
    try:
        import json as _json
        bw_file = Path("/home/ash/ASH/dashboard/.bandwidth.json")
        if bw_file.exists():
            bw = _json.loads(bw_file.read_text())
            total_tb = round((bw["rx"] + bw["tx"]) / (1024**4), 2)
            cap_tb = 5
            pct = round(total_tb / cap_tb * 100, 1)
            res["bandwidth"] = {"percent": min(100, pct), "used_tb": total_tb, "total_tb": cap_tb}
        else:
            res["bandwidth"] = {"percent": 0, "used_tb": 0, "total_tb": 5}
    except:
        res["bandwidth"] = {"percent": 0, "used_tb": 0, "total_tb": 5}
    
    return res


def get_technical():
    """Get server technical information from host-generated file"""
    try:
        import json as _json3
        tech_file = Path('/home/ash/ASH/dashboard/.technical.json')
        if tech_file.exists():
            return _json3.loads(tech_file.read_text())
    except:
        pass
    return {"hostname": "unknown", "os": "unknown", "ipv4": "unknown", "ipv6": "Unassigned", "tailscale": "unknown", "cores": 0, "ram_gb": 0, "ssd_gb": 0, "bandwidth_tb": 5, "uptime": "unknown"}


def get_errors():
    """Read container error logs from host-generated file"""
    try:
        import json as _json4
        err_file = Path('/home/ash/ASH/dashboard/.errors.json')
        if err_file.exists():
            return _json4.loads(err_file.read_text())
    except:
        pass
    return {}


def get_usage():
    """Read per-process usage breakdown for pie charts"""
    try:
        import json as _json5
        f = Path('/home/ash/ASH/dashboard/.usage.json')
        if f.exists():
            return _json5.loads(f.read_text())
    except:
        pass
    return {"memory": [], "cpu": [], "disk": []}


def get_payment():
    """Read payment metrics from host-generated file"""
    try:
        import json as _json6
        f = Path('/home/ash/ASH/dashboard/.payment.json')
        if f.exists():
            return _json6.loads(f.read_text())
    except:
        pass
    return {}

# Brain Gateway
class BrainGateway:
    def __init__(self):
        self.sessions = {}
        self.default_brain = "claude"
        self.current_process = None
        self.current_brain = None
        
    def build_prompt(self, user_input: str, session_id: str) -> str:
        parts = []
        
        if BIBLE_PATH.exists():
            parts.append(BIBLE_PATH.read_text())
        
        if MEMORY_PATH.exists():
            mem = MEMORY_PATH.read_text()
            parts.append(f"\n\n## Current State\n{mem[:2000]}")
        
        if session_id in self.sessions:
            history = self.sessions[session_id].get("history", [])[-10:]
            if history:
                parts.append("\n\n## Recent Conversation")
                for msg in history:
                    parts.append(f"{msg['role']}: {msg['content'][:200]}")
        
        parts.append(f"\n\n## New Input\n{user_input}")
        return "\n\n".join(parts)
    
    def is_rate_limited(self, stderr: str) -> bool:
        err_lower = stderr.lower()
        return any(pat in err_lower for pat in RATE_LIMIT_PATTERNS)
    
    async def try_brain(self, brain_name: str, prompt: str) -> tuple[bool, str]:
        if brain_name not in BRAINS:
            return False, f"Unknown brain: {brain_name}"
        
        brain = BRAINS[brain_name]
        start_time = time.time()
        
        cmd = [str(arg).format(prompt=prompt) for arg in brain.command]
        env = dict(os.environ)
        env["PATH"] = "/home/ash/.local/bin:/usr/local/bin:" + env.get("PATH", "")
        env.pop("CLAUDECODE", None)
        
        try:
            proc = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(ASH_DIR),
                env=env,
            )
            
            self.current_process = proc
            self.current_brain = brain_name
            
            stdout, stderr = await asyncio.wait_for(
                proc.communicate(),
                timeout=brain.timeout,
            )
            
            elapsed = time.time() - start_time
            response = stdout.decode().strip()
            err_str = stderr.decode().strip()
            
            brain.avg_response_time = (brain.avg_response_time * brain.success_count + elapsed) / (brain.success_count + 1)
            
            if proc.returncode == 0 and response:
                brain.success_count += 1
                brain.status = BrainStatus.HEALTHY
                self.current_process = None
                self.current_brain = None
                return True, response
            
            if self.is_rate_limited(err_str):
                brain.status = BrainStatus.DEGRADED
                brain.last_failure = time.time()
                return False, f"[RATE_LIMITED: {brain_name}]"
            
            brain.failure_count += 1
            if brain.failure_count > 3:
                brain.status = BrainStatus.DEGRADED
            
            self.current_process = None
            self.current_brain = None
            return False, err_str[:500]
            
        except asyncio.TimeoutError:
            brain.status = BrainStatus.DEGRADED
            return False, f"[TIMEOUT: {brain_name}]"
        except Exception as e:
            brain.status = BrainStatus.DOWN
            return False, f"[ERROR: {brain_name} - {e}]"
    
    async def query(self, user_input: str, session_id: str = "default", 
                    preferred_brain: str = None, auto_fallback: bool = True) -> dict:
        prompt = self.build_prompt(user_input, session_id)
        
        if session_id not in self.sessions:
            self.sessions[session_id] = {
                "history": [],
                "preferred_brain": preferred_brain or self.default_brain,
                "auto_fallback": auto_fallback,
            }
        
        session = self.sessions[session_id]
        pref = preferred_brain or session.get("preferred_brain", self.default_brain)
        
        if pref not in BRAINS:
            pref = self.default_brain
        
        if auto_fallback and session.get("auto_fallback", True):
            brain_order = [pref] + [b for b in BRAINS.keys() if b != pref]
        else:
            brain_order = [pref]
        
        attempts = []
        for brain_name in brain_order:
            if brain_name not in BRAINS:
                continue
                
            success, response = await self.try_brain(brain_name, prompt)
            
            attempts.append({
                "brain": brain_name,
                "success": success,
                "error": None if success else response[:200],
            })
            
            if success:
                session["history"].append({
                    "role": "user",
                    "content": user_input,
                    "brain": brain_name,
                    "timestamp": time.time(),
                })
                session["history"].append({
                    "role": "assistant",
                    "content": response,
                    "brain": brain_name,
                    "timestamp": time.time(),
                })
                
                fallbacks_used = len(attempts) - 1
                
                return {
                    "success": True,
                    "response": response,
                    "brain": brain_name,
                    "attempts": attempts,
                    "fallbacks_used": fallbacks_used,
                    "session_id": session_id,
                }
        
        return {
            "success": False,
            "response": "[ALL_BRAINS_FAILED]",
            "brain": None,
            "attempts": attempts,
            "session_id": session_id,
        }
    
    def switch_brain(self, session_id: str, brain_name: str) -> bool:
        if brain_name not in BRAINS:
            return False
        
        if session_id not in self.sessions:
            self.sessions[session_id] = {"history": [], "preferred_brain": brain_name, "auto_fallback": True}
        else:
            self.sessions[session_id]["preferred_brain"] = brain_name
        
        return True
    
    def stop_current(self) -> dict:
        if self.current_process and self.current_process.returncode is None:
            try:
                self.current_process.kill()
                return {
                    "stopped": True,
                    "brain": self.current_brain,
                }
            except Exception as e:
                return {
                    "stopped": False,
                    "error": str(e),
                }
        return {
            "stopped": False,
            "reason": "no_process_running",
        }
    
    def get_health(self) -> dict:
        return {
            name: {
                "status": brain.status.value,
                "successes": brain.success_count,
                "failures": brain.failure_count,
                "avg_response_time": round(brain.avg_response_time, 2),
            }
            for name, brain in BRAINS.items()
        }

# Initialize gateway
gateway = BrainGateway()

# HTTP Handlers
async def handle_index(request):
    """GET / - Dashboard interface"""
    html_file = Path(__file__).parent / 'dashboard.html'
    if html_file.exists():
        return web.Response(text=html_file.read_text(), content_type='text/html')
    return web.Response(text='Dashboard not found', status=404)

async def handle_stats(request):
    """GET /api/stats - Dashboard statistics"""
    stats = {
        'memory': get_memory(),
        'services': get_services(),
        'tasks': get_tasks(),
        'brain_log': get_brain_log(),
        'mail': get_mail(),
        'resources': get_resources(),
        'technical': get_technical(),
        'errors': get_errors(),
        'usage': get_usage(),
        'payment': get_payment(),
    }
    return web.json_response(stats)

async def handle_query(request):
    """POST /api/query - Brain query"""
    try:
        data = await request.json()
        user_input = data.get("input", "")
        session_id = data.get("session_id", "default")
        preferred_brain = data.get("preferred_brain")
        auto_fallback = data.get("auto_fallback", True)
        
        if not user_input:
            return web.json_response({"error": "No input"}, status=400)
        
        result = await gateway.query(
            user_input, 
            session_id=session_id,
            preferred_brain=preferred_brain,
            auto_fallback=auto_fallback,
        )
        return web.json_response(result)
    
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)

async def handle_health(request):
    """GET /api/health - Brain health"""
    return web.json_response(gateway.get_health())

async def handle_switch(request):
    """POST /api/switch - Switch brain"""
    try:
        data = await request.json()
        session_id = data.get("session_id", "default")
        brain_name = data.get("brain")
        
        if not brain_name:
            return web.json_response({"error": "No brain specified"}, status=400)
        
        if gateway.switch_brain(session_id, brain_name):
            return web.json_response({
                "success": True,
                "brain": brain_name,
            })
        else:
            return web.json_response({
                "error": f"Unknown brain: {brain_name}",
                "available": list(BRAINS.keys()),
            }, status=400)
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)

async def handle_stop(request):
    """POST /api/stop - Stop current brain"""
    result = gateway.stop_current()
    return web.json_response(result)


async def handle_logo(request):
    """GET /logo.png - Logo image"""
    logo_file = Path(__file__).parent / 'logo.png'
    if logo_file.exists():
        return web.Response(body=logo_file.read_bytes(), content_type='image/png')
    return web.Response(text='Not found', status=404)


async def handle_clear_errors(request):
    """POST /api/clear-errors - Clear accumulated errors"""
    try:
        err_file = Path('/home/ash/ASH/dashboard/.errors.json')
        seen_file = Path('/home/ash/ASH/dashboard/.errors_seen.json')
        err_file.write_text('{}')
        if seen_file.exists():
            seen_file.unlink()
        return web.json_response({"cleared": True})
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)


async def handle_favicon(request):
    fav = Path(__file__).parent / 'favicon.ico'
    if fav.exists():
        return web.Response(body=fav.read_bytes(), content_type='image/x-icon')
    return web.Response(text='Not found', status=404)

# Application setup
app = web.Application()
app.router.add_get("/", handle_index)
app.router.add_get("/favicon.ico", handle_favicon)
app.router.add_get("/logo.png", handle_logo)
app.router.add_get("/api/stats", handle_stats)
app.router.add_post("/api/query", handle_query)
app.router.add_get("/api/health", handle_health)
app.router.add_post("/api/switch", handle_switch)
app.router.add_post("/api/stop", handle_stop)
app.router.add_post("/api/clear-errors", handle_clear_errors)

if __name__ == "__main__":
    print(f"🔥 ASH Dashboard + Brain Gateway starting on http://0.0.0.0:{PORT}")
    print(f"Brains: {list(BRAINS.keys())}")
    web.run_app(app, host="0.0.0.0", port=PORT)
