import json
from pathlib import Path
import subprocess

TF_DIR = Path(__file__).resolve().parents[1] / 'envs' / 'staging'
INV_PATH = Path(__file__).resolve().parent / 'inventories' / 'staging.ini'

# terraform output -json
proc = subprocess.run(['terraform', 'output', '-json'], cwd=str(TF_DIR), capture_output=True, text=True)
if proc.returncode != 0:
    raise SystemExit('terraform output failed; run from Terraform-AWS/envs/staging after apply')

outputs = json.loads(proc.stdout)
public_ip = outputs.get('kafka_public_ip', {}).get('value', '')
private_ip = outputs.get('kafka_private_ip', {}).get('value', '')

content = f"""[kafka]
"           f"kafka-staging ansible_host={private_ip or public_ip} ansible_user=${{KAFKA_USER}} ansible_ssh_private_key_file=${{KAFKA_SSH_KEY}}

"           f"[kafka:vars]
ansible_python_interpreter=/usr/bin/python3
kafka_advertised_host={private_ip or public_ip}
"

INV_PATH.write_text(content)
print(f"Inventory written to {INV_PATH}")
