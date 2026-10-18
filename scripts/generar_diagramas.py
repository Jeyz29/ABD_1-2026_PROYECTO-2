import base64
import json
import requests
import os

mermaid_code = """erDiagram
    PERSONA ||--o| VENDEDOR : "es un"
    PERSONA ||--o| SUPERVISOR : "es un"
    PERSONA ||--o| PERSONAL_FINANZAS : "es un"

    SUPERVISOR ||--o{ SUPERVISOR : "reporta a"
    SUPERVISOR ||--o{ SUPERVISOR_VENDEDOR : "supervisa con reconocimiento"
    VENDEDOR ||--o{ SUPERVISOR_VENDEDOR : "es supervisado por"

    CLIENTE ||--o{ FACTURA : "recibe"
    FACTURA ||--|{ FACTURA_DETALLE : "contiene"
    PRODUCTO ||--|{ FACTURA_DETALLE : "se vende en"

    FACTURA ||--|{ FACTURA_PARTICIPACION : "registra participacion"
    VENDEDOR ||--|{ FACTURA_PARTICIPACION : "participa en"
    ROL_VENTA ||--|{ FACTURA_PARTICIPACION : "ejerce rol en"

    VENDEDOR ||--o{ ASIGNACION_PLAN : "tiene asignado"
    ROL_VENTA ||--o{ ASIGNACION_PLAN : "asociado a rol"
    PLAN_COMISION ||--o{ ASIGNACION_PLAN : "define reglas"

    PLAN_COMISION ||--|{ PLAN_FILTRO : "contiene filtros ordenados"

    PERIODO ||--o{ CALCULO_COMISION : "periodo de calculo"
    PERSONA ||--o{ CALCULO_COMISION : "devenga comision"
    FACTURA ||--o{ CALCULO_DETALLE : "origen de liquidacion"
    CALCULO_COMISION ||--|{ CALCULO_DETALLE : "desglosa comision"

    PERIODO ||--o{ PAGO_COMISION : "periodo de pago"
    PERSONA ||--o{ PAGO_COMISION : "percibe pago"
    PERSONAL_FINANZAS ||--o{ PAGO_COMISION : "registrado por"

    PERSONA {
        INT id_persona PK
        VARCHAR nombre
        VARCHAR apellidos
        VARCHAR correo UK
        DATE fecha_incorporacion
        VARCHAR tipo_persona
        VARCHAR estatus
    }

    VENDEDOR {
        INT id_vendedor PK,FK
        DECIMAL cuota_ventas
    }

    SUPERVISOR {
        INT id_supervisor PK,FK
        VARCHAR zona
        INT id_supervisor_jefe FK
    }

    PERSONAL_FINANZAS {
        INT id_personal PK,FK
        VARCHAR cargo
    }

    SUPERVISOR_VENDEDOR {
        INT id_asignacion_sup PK
        INT id_supervisor FK
        INT id_vendedor FK
        DECIMAL porcentaje_reconocimiento
        DATE fecha_inicio
        DATE fecha_fin
    }

    CLIENTE {
        INT id_cliente PK
        VARCHAR codigo_cliente UK
        VARCHAR nombre
        VARCHAR segmento_mercado
    }

    PRODUCTO {
        INT id_producto PK
        VARCHAR codigo_producto UK
        VARCHAR nombre
        VARCHAR categoria
        DECIMAL precio
        DECIMAL costo_unitario
    }

    FACTURA {
        INT id_factura PK
        VARCHAR numero_factura UK
        INT id_cliente FK
        DATE fecha_emision
        VARCHAR situacion
        DATE fecha_cobro
    }

    FACTURA_DETALLE {
        INT id_factura PK,FK
        INT id_producto PK,FK
        DECIMAL cantidad
        DECIMAL monto
        VARCHAR motivo
    }

    ROL_VENTA {
        INT id_rol PK
        VARCHAR nombre_rol UK
        VARCHAR descripcion
    }

    FACTURA_PARTICIPACION {
        INT id_participacion PK
        INT id_factura FK
        INT id_vendedor FK
        INT id_rol FK
        DECIMAL porcentaje_participacion
    }

    PLAN_COMISION {
        INT id_plan PK
        VARCHAR codigo_plan UK
        VARCHAR nombre
        DECIMAL tasa_comision
        VARCHAR base_aplicacion
        BIT admite_descuento
    }

    ASIGNACION_PLAN {
        INT id_asignacion_plan PK
        INT id_vendedor FK
        INT id_rol FK
        INT id_plan FK
        DATE fecha_inicio_vigor
        DATE fecha_fin_vigor
    }

    PLAN_FILTRO {
        INT id_plan PK,FK
        INT numero_orden PK
        VARCHAR tipo_filtro
        VARCHAR valor_filtro
    }

    PERIODO {
        INT id_periodo PK
        VARCHAR codigo_periodo UK
        VARCHAR descripcion
        VARCHAR tipo_periodo
        DATE fecha_inicio
        DATE fecha_fin
    }

    CALCULO_COMISION {
        INT id_calculo PK
        INT id_periodo FK
        INT id_persona FK
        DECIMAL monto_propio_ventas
        DECIMAL monto_supervision
        DECIMAL monto_total_reconocido
        VARCHAR estado_reconocimiento
    }

    CALCULO_DETALLE {
        INT id_calculo_detalle PK
        INT id_calculo FK
        INT id_factura FK
        INT id_rol FK
        DECIMAL base_comisionable
        DECIMAL tasa_aplicada
        DECIMAL comision_generada
        VARCHAR tipo_origen
    }

    PAGO_COMISION {
        INT id_pago PK
        INT id_periodo_pago FK
        INT id_persona FK
        DATE fecha_pago
        DECIMAL monto
        VARCHAR estado_pago
        INT id_personal_finanzas FK
    }
"""

os.makedirs('docs/diagramas', exist_ok=True)

# Guardar también el archivo .mmd fuente
with open('docs/diagramas/diagrama_modelo_relacional.mmd', 'w', encoding='utf-8') as f:
    f.write(mermaid_code)
print("Archivo .mmd guardado en docs/diagramas/diagrama_modelo_relacional.mmd")

# Codificar a Base64 url-safe para mermaid.ink
graphbytes = mermaid_code.encode('utf8')
base64_bytes = base64.urlsafe_b64encode(graphbytes)
base64_string = base64_bytes.decode('ascii')

url_png = f"https://mermaid.ink/img/{base64_string}?bgColor=white"
url_svg = f"https://mermaid.ink/svg/{base64_string}?bgColor=white"

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
}

print("Descargando imagen PNG desde mermaid.ink...")
try:
    r_png = requests.get(url_png, headers=headers, timeout=45)
    if r_png.status_code == 200:
        with open('docs/diagramas/diagrama_modelo_relacional.png', 'wb') as f:
            f.write(r_png.content)
        print(f"PNG generado con éxito en docs/diagramas/diagrama_modelo_relacional.png ({len(r_png.content)} bytes)")
    else:
        print(f"Error al descargar PNG: código {r_png.status_code}")
except Exception as e:
    print(f"Excepción en PNG: {e}")

print("Descargando imagen SVG desde mermaid.ink...")
try:
    r_svg = requests.get(url_svg, headers=headers, timeout=45)
    if r_svg.status_code == 200:
        with open('docs/diagramas/diagrama_modelo_relacional.svg', 'wb') as f:
            f.write(r_svg.content)
        print(f"SVG generado con éxito en docs/diagramas/diagrama_modelo_relacional.svg ({len(r_svg.content)} bytes)")
    else:
        print(f"Error al descargar SVG: código {r_svg.status_code}")
except Exception as e:
    print(f"Excepción en SVG: {e}")

# Crear también un visor HTML interactivo con zoom y botón de descarga directa
html_content = f"""<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Diagrama Modelo Relacional - CompuComisiones, C.A.</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.6.1/dist/svg-pan-zoom.min.js"></script>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f8fafc;
            color: #0f172a;
        }}
        .header {{
            max-width: 1200px;
            margin: 0 auto 20px auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 15px;
        }}
        h1 {{
            margin: 0;
            font-size: 24px;
            color: #0f294a;
        }}
        p {{
            margin: 5px 0 0 0;
            color: #64748b;
            font-size: 14px;
        }}
        .btn-group {{
            display: flex;
            gap: 10px;
        }}
        .btn {{
            background-color: #1e5b96;
            color: white;
            padding: 8px 16px;
            border-radius: 6px;
            text-decoration: none;
            font-size: 13px;
            font-weight: 500;
            transition: background-color 0.2s;
            cursor: pointer;
            border: none;
        }}
        .btn:hover {{
            background-color: #0f294a;
        }}
        .btn-secondary {{
            background-color: #475569;
        }}
        .btn-secondary:hover {{
            background-color: #334155;
        }}
        #diagram-container {{
            width: 100%;
            height: 80vh;
            background-color: white;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            display: flex;
            justify-content: center;
            align-items: center;
        }}
        .mermaid {{
            width: 100%;
            height: 100%;
        }}
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>Diagrama del Modelo Relacional</h1>
            <p>CompuComisiones, C.A. — Administración de Bases de Datos (UCV)</p>
        </div>
        <div class="btn-group">
            <a href="diagrama_modelo_relacional.png" download="diagrama_modelo_relacional.png" class="btn">📥 Descargar PNG</a>
            <a href="diagrama_modelo_relacional.svg" download="diagrama_modelo_relacional.svg" class="btn btn-secondary">📥 Descargar SVG</a>
            <button onclick="downloadSvgDirect()" class="btn btn-secondary">Exportar SVG Actual</button>
        </div>
    </div>
    
    <div id="diagram-container">
        <div class="mermaid" id="mermaid-graph">
{mermaid_code}
        </div>
    </div>

    <script>
        mermaid.initialize({{
            startOnLoad: true,
            theme: 'default',
            securityLevel: 'loose',
            er: {{
                useMaxWidth: false
            }}
        }});

        window.addEventListener('load', function() {{
            setTimeout(function() {{
                var svg = document.querySelector('#mermaid-graph svg');
                if (svg) {{
                    svg.style.width = '100%';
                    svg.style.height = '100%';
                    svgPanZoom(svg, {{
                        zoomEnabled: true,
                        controlIconsEnabled: true,
                        fit: true,
                        center: true
                    }});
                }}
            }}, 500);
        }});

        function downloadSvgDirect() {{
            var svg = document.querySelector('#mermaid-graph svg');
            if (!svg) return;
            var serializer = new XMLSerializer();
            var source = serializer.serializeToString(svg);
            var blob = new Blob([source], {{type: "image/svg+xml;charset=utf-8"}});
            var url = URL.createObjectURL(blob);
            var a = document.createElement("a");
            a.href = url;
            a.download = "diagrama_modelo_relacional.svg";
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
        }}
    </script>
</body>
</html>
"""

with open('docs/diagramas/visor_diagrama.html', 'w', encoding='utf-8') as f:
    f.write(html_content)
print("Visor HTML interactivo generado en docs/diagramas/visor_diagrama.html")
