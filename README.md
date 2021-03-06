# Deploy k8s Cluster via Ansible & Terraform
Esse reposítório contém um exemplo de um projeto onde foi construído um cluster Kubernetes através do Ansible e Terraform.

## Topologia

![plot](./projetok8s.pdf)


## Workflow de construção do Projeto
As etapas de desenvolvimento do projeto são:
- Construção da Infraestrutura: deploy das Vms que compõe o cluster
- Instalação dos pacotes e componentes K8s
- Construção do cluster através do Join dos Workers
- Deploy via helm dos componenentes de Observability: Prometheus & Grafana
- Deploy de uma aplicação versionada (App de exemplo)

## Falando um Pouco da infra
O deploy da infraestrutura doi realizado via terraform na Azure. Abaixo o detalhe de como instanciar o modulo e as respectivias variaveis:

```bash
module "az_virtual_machines" {
    source             = "git@github.com:igoritos22/terraformlabs//modules/az_virtual_machine"
    tag_projeto        = "iac_expert"
    az_group           = "iac_expert"
    vm_name            = ["iacnode1", "iacnode2", "iacnode3"]
    ip_allocation      = "Dynamic"
    nic_name           = "niciacexpert"
    allocation_method  = "Static"
    vm_size            = "Standard_B2ms"
    storage_name       = "stgiacexpertlab"
    account_tier       = "Standard"
    replication_type   = "LRS"
    publisher          = "Canonical"
    offer              = "UbuntuServer"
    sku                = "18.04-LTS"
    version_image      = "latest"
    admin_password     = "defina_sua_senha"

    #Retorna o valor dos IPs
    output "ip_instances" {
      value = module.az_virtual_machines.ips_internos
    }
}
```
## Inventário Dinâmico
Caso deseje gerar o inventário (hosts) de maneira automática instancie o resource "local_file" :
```bash
resource "local_file" "inventory" {
    filename = "./hosts"
    content     = <<_EOF
    [k8s-master]
    ${module.az_virtual_machines.ips_internos[0]}

    [k8s-workers]
    ${module.az_virtual_machines.ips_internos[1]}
    ${module.az_virtual_machines.ips_internos[2]}

    [k8s-workers:vars]
    K8S_MASTER_NODE_IP=${module.az_virtual_machines.ips_internos[0]}
    K8S_API_SECURE_PORT=6443
    _EOF
}
```
para mais detalhes consulte a documentação oficial [Hashicorp](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)

Uma vez instanciado, basta substituir passar o path do arquivo de hosts quando for rodar a playbook. 

## Enviado as chaves para os nodes gerenciados do Ansible
Uma vez que as Vms estejam no ar, utilize o comando [ssh-copy-id](https://www.ssh.com/ssh/copy-id) para enviar a chave do nó master do Ansible para os nós gerenciados.
```bash
ssh-copy-id -i ~/.ssh/mykey user@host
```

## Estamos quase lá meu Jovem!!

Para garantir a vitória, é interessante testar a conectividade entre o Ansible e os nós gerenciados. Para isso você pode usar o módulo ping (um comando Ad-hoc). Consulte o módulo [Ping](https://docs.ansible.com/ansible/2.3/ping_module.html) na doc oficial do Ansible.

```bash
ansible all -m ping
```
Se o resultado for positivo, partiu rodar a playbook.

## Rodando a Playbook!!
Finalmente vamos rodar a playbook. Navegue até o diretório install_k8s/. Na sequencia execute a playbook.
```bash
[k8s-projeto]# cd install_k8s/
[install_k8s]# ls
hosts  main.yml  roles
[install_k8s]# ansible-playbook -i hosts main.yml
```
Deixe a magia rolar a partir daqui.

## Validando o Cluster
Para validar se todas as playbooks executaram corretamente acesse o seu node master do k8s e digite o seguinte comando:
```bash
root@iacnode1-labanisble:/# kubectl get nodes
NAME                  STATUS   ROLES                  AGE   VERSION
iacnode1-labanisble   Ready    control-plane,master   54m   v1.20.4
iacnode2-labanisble   Ready    <none>                 53m   v1.20.4
iacnode3-labanisble   Ready    <none>                 54m   v1.20.4
```
## Deploy da Aplicação Giropops

Muito bem, agora que sabemos que o nosso cluster esta funcionando, você pode fazer o deploy de uma aplicação de exemplo. Dentro do diretório deploy-aap-v1 execute o seguinte:
```bash
 deploy-app-v1]# ansible-playbook -i hosts main.yml
```
Através do comando kubectl get svc ou kubectl get pods você poderá validar se o seu deploy ocorreu corretamente via a playbook.

```bash
root@iacnode1-labanisble:/# kubectl get svc
NAME                                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                        AGE
alertmanager-operated                     ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP     66m
giropops                                  NodePort    10.103.10.134   <none>        80:32222/TCP,32111:32111/TCP   60m
kubernetes                                ClusterIP   10.96.0.1       <none>        443/TCP                        67m
```
## Atualizando a aplicação Giropops para a Versão 2
A ideia da playbook do deploy da versão dois da aplicação giropops é mostrar o Ansible tratando o scale out e oscae down dos pods de acordo com a demanda.

Para atualizar a aplicação apra a versão dois basta navegar até o diretorio deploy-app-v2 e rodar o seguinte comando:
deploy-app-v2]# ansible-playbook -i hosts main.yml
```bash
root@iacnode1-labanisble:/# kubectl get pods
NAME                                                    READY   STATUS        RESTARTS   AGE
alertmanager-meu-prometheus-prometheus-alertmanager-0   2/2     Running       0          72m
giropops-v1-65df785568-48sk4                            1/1     Terminating   0          6m10s
giropops-v1-65df785568-j5sr2                            1/1     Terminating   0          6m10s
giropops-v1-65df785568-k5ff8                            1/1     Terminating   0          6m10s
giropops-v1-65df785568-rkj88                            1/1     Running       0          6m10s
giropops-v1-65df785568-tfv8b                            1/1     Terminating   0          6m10s
giropops-v2-57674bdf77-2gkq8                            1/1     Running       0          60m
```
Note que as instancias da versão 1 estão send encerradas enquanto instancias da versão 2 começam a subir.

## Contribuidores:
Esse projeto trata-se de um desafio do curso ministrado pelo Jefferson Fernando,  [@badtuxx](https://github.com/badtuxx). Aproveito para deixar meu agradecimento ao professor pelo desafio e curso.
