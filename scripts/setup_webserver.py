import os
import subprocess

def ejecutar(comando):
    print(f"Ejecutando comando: {comando}")
    subprocess.run(comando, shell=True, check=True)

def configurar_http():
    if os.path.exists("/etc/debian_version"):
        print("Sistema operativo Debian detectado")
        ejecutar("sudo apt update")
        ejecutar("sudo apt install -y apache2")
        ejecutar("sudo systemctl enable apache2")
        ejecutar("sudo systemctl start apache2")
    elif os.path.exists("/etc/redhat-release") or os.path.exists("/etc/system-release"):
        print("Sistema operativo RedHat o Amazon Linux detectado")
        ejecutar("sudo yum install -y httpd")
        ejecutar("sudo systemctl enable httpd")
        ejecutar("sudo systemctl start httpd")
    else:
        print("Sistema operativo no compatible con este script.")
        exit(1)

def generar_index_html(nombre_host="WebNode-1"):
    contenido_html = f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <title>{nombre_host}</title>
    </head>
    <body>
        <h1>Bienvenido desde {nombre_host}</h1>
    </body>
    </html>
    """
    ruta_temporal = "/tmp/index_custom.html"
    with open(ruta_temporal, "w", encoding="utf-8") as archivo:
        archivo.write(contenido_html)

    destino_final = "/var/www/html/index.html"
    ejecutar(f"sudo mv {ruta_temporal} {destino_final}")

if __name__ == "__main__":
    configurar_http()
    generar_index_html("WebNode-3")

