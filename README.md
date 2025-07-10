# :top:Virtualizacion de infraestructura de redes virtual con KVM y Libvirt.

![GitHub repo size](https://img.shields.io/github/repo-size/JohanV711/Virtualizacion-de-redes-con-QEMU-KVM-Pyhton)

Proyecto de creación automática de una infraestructura de red virtual en ![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange?logo=ubuntu) usando **KVM** y **libvirt** .Para los scripts se ha usado el lenguaje de programación **Python** y **bash** para automatizar el despliegue y configuración de toda la infraestructura y sus componentes.
La infraestructura incluye:
- 4 PCs en redes independientes.
- 4 routers interconectados mediante enlaces punto a punto.
- 1 servidor accesible desde todas las redes.
<br>
La topología general es la siguiente:
<br><img src="Capturas/image9.png" alt="Esquema red" style="width: 50%; border: 1px solid #ccc;" /><br>
En este repositorio NO se incluye la imagen de disco maestro con extensión .qcow2 pero se pueden descargar a través de sitios oficiales de Debian o Ubuntu y después transformarse a formato qcow2 con el comando:

```bash
qemu-img convert -O qcow2 [imagen base].img [imagen final].qcow2
```
Leer la memoria antes de nada para comprobar las configuraciones necesarias antes de empezar.

## :rocket:Instalación.

-Para clonar el repositorio:
```bash
git clone https://github.com/JohanV711/Virtualizacion-de-redes-con-QEMU-KVM-Pyhton.git
```

## :hammer:Tecnologías y herramientas usadas.

- ![KVM](https://img.shields.io/badge/KVM-EE0000?logo=kvm&logoColor=white): Kernel-based Virtual Machine.
- ![Libvirt](https://img.shields.io/badge/Libvirt-1D99F3?logo=libvirt&logoColor=white): API para gestionar máquinas virtuales.
- ![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white): lenguaje elegido para trabajar con ficheros XML.
- ![Bash](https://img.shields.io/badge/Bash-4EAA25?logo=gnubash&logoColor=white): para scripting de automatización.
- ![Netplan](https://img.shields.io/badge/Netplan-0066CC?logoColor=white): configuración de red en Ubuntu.
- ![FRRouting](https://img.shields.io/badge/FRRouting-FFCC00?logoColor=black): para el enrutamiento (OSPF).

## :file_folder: Estructura del proyecto.

- `plantilla_kvm.xml`: plantilla de configuración xml de las máquinas virtuales.
- `agr-vm-base.qcow2`: imagen de disco que se va a usar de base para crear las máquinas virtuales, ocupan poco y son muy eficientes para el proyecto.
- `scriptPrincipal.sh`: Despliega toda la infraestructura.
- `script1.py`: Genera ficheros .xml con las redes virtuales para libvirt/KVM.
- `script2.py`: Genera y automatiza la creación de la estructura de archivos y la configuración XML para máquinas virtuales en KVM/libvirt a partir de la plantilla "plantilla_kvm.xml" y la imagen base "agr-vm-base.qcow2".
- `limpieza.sh`: limpia el entorno creado con scriptPrincipal.sh, todas las máquinas virtuales, carpetas, redes, etc.

El contenido está explicado más detalladamente en el archivo [`Memoria-virtualización.md`](Memoria-virtualización.md) cuyo índice e el siguiente:

1. [Introducción](Memoria-virtualización.md#Introducción)
2. [Hipervisores, KVM y Libvirt](Memoria-virtualización.md#hipervisores-kvm-y-libvirt)
3. [Requisitos, sistema operativo](Memoria-virtualización.md#requisitos-sistema-operativo)
4. [Plan](Memoria-virtualización.md#Plan)
5. [Script limpieza.sh](Memoria-virtualización.md#script-limpiezash)
6. [script1.py](Memoria-virtualización.md#script1py)
7. [script2.py](Memoria-virtualización.md#script2py)
8. [scriptPrincipal.sh](Memoria-virtualización.md#scriptprincipalsh)
9. [Resultado final](Memoria-virtualización.md#resultado-final)
10. [Referencias y bibliografía](Memoria-virtualización.md#referencias-y-bibliografía)

## :people_hugging: Contribuciones.
Se agradecen ideas, sugerencias o correcciones. Puedes abrir un *issue* o enviar un *pull request*.

Proyecto académico de virtualización de redes por Johan Vargas.
