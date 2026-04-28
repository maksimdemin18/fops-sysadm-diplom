[all:vars]
ansible_user=${vm_user}
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=${private_key_path}
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -o ProxyCommand="ssh -i ${private_key_path} -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ${vm_user}@${bastion_public_ip}"

[web]
web-1 ansible_host=${web1_private_ip} private_ip=${web1_private_ip} role=web
web-2 ansible_host=${web2_private_ip} private_ip=${web2_private_ip} role=web

[prometheus_nodes]
prometheus ansible_host=${prometheus_private_ip} private_ip=${prometheus_private_ip} role=prometheus

[elasticsearch_nodes]
elasticsearch ansible_host=${elastic_private_ip} private_ip=${elastic_private_ip} role=elasticsearch

[grafana_nodes]
grafana ansible_host=${grafana_private_ip} private_ip=${grafana_private_ip} public_ip=${grafana_public_ip} role=grafana

[kibana_nodes]
kibana ansible_host=${kibana_private_ip} private_ip=${kibana_private_ip} public_ip=${kibana_public_ip} role=kibana
