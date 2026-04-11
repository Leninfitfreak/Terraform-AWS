# Ansible Kafka Baseline (staging)

## Purpose
Configure the Kafka EC2 instance created by Terraform-AWS phase 1.

## Inventory
You can either edit `inventories/staging.ini` manually or generate it from Terraform outputs:

```
python gen_inventory_from_tf.py
```

Then set:
- `KAFKA_USER` (e.g., ec2-user)
- `KAFKA_SSH_KEY` (path to SSH key)

## Run (manual)
```
cd ansible
ansible-playbook -i inventories/staging.ini playbooks/kafka.yml   -e KAFKA_ADVERTISED_HOST=<private-ip-or-nlb-dns>
```

## Notes
- This playbook is idempotent.
- Prefer private IP or NLB DNS for `KAFKA_ADVERTISED_HOST`.
