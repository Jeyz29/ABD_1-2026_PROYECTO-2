import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether, HRFlowable, Image
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_decorations(self, page_count):
        self.saveState()
        self.setFont('Helvetica', 8)
        self.setFillColor(colors.HexColor('#4A5568'))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 750, 'CompuComisiones, C.A. — Informe Técnico de Implementación de Base de Datos')
            self.setStrokeColor(colors.HexColor('#CBD5E1'))
            self.setLineWidth(0.5)
            self.line(54, 742, 558, 742)
            
        # Footer
        self.setStrokeColor(colors.HexColor('#CBD5E1'))
        self.setLineWidth(0.5)
        self.line(54, 45, 558, 45)
        self.drawString(54, 32, 'Universidad Central de Venezuela | Administración de Bases de Datos (Semestre 1-2026)')
        page_text = f'Página {self._pageNumber} de {page_count}'
        self.drawRightString(558, 32, page_text)
        self.restoreState()

os.makedirs('docs', exist_ok=True)
pdf_path = os.path.join('docs', 'Informe_Tecnico_Proyecto_CompuComisiones.pdf')

doc = SimpleDocTemplate(
    pdf_path,
    pagesize=letter,
    leftMargin=54,
    rightMargin=54,
    topMargin=54,
    bottomMargin=54
)

styles = getSampleStyleSheet()

primary_color = colors.HexColor('#0F294A')
secondary_color = colors.HexColor('#1E5B96')
accent_color = colors.HexColor('#D97706')
text_dark = colors.HexColor('#1E293B')

title_style = ParagraphStyle(
    'DocTitle',
    parent=styles['Normal'],
    fontName='Helvetica-Bold',
    fontSize=20,
    leading=24,
    textColor=primary_color,
    alignment=1,
    spaceAfter=10
)

subtitle_style = ParagraphStyle(
    'DocSubTitle',
    parent=styles['Normal'],
    fontName='Helvetica',
    fontSize=11,
    leading=15,
    textColor=secondary_color,
    alignment=1,
    spaceAfter=20
)

h1_style = ParagraphStyle(
    'Heading1_Custom',
    parent=styles['Heading1'],
    fontName='Helvetica-Bold',
    fontSize=13,
    leading=17,
    textColor=primary_color,
    spaceBefore=14,
    spaceAfter=6,
    keepWithNext=True
)

h2_style = ParagraphStyle(
    'Heading2_Custom',
    parent=styles['Heading2'],
    fontName='Helvetica-Bold',
    fontSize=10.5,
    leading=14,
    textColor=secondary_color,
    spaceBefore=10,
    spaceAfter=4,
    keepWithNext=True
)

body_style = ParagraphStyle(
    'Body_Custom',
    parent=styles['Normal'],
    fontName='Helvetica',
    fontSize=9,
    leading=13,
    textColor=text_dark,
    spaceAfter=5,
    alignment=4
)

bullet_style = ParagraphStyle(
    'Bullet_Custom',
    parent=body_style,
    leftIndent=15,
    firstLineIndent=-10,
    spaceAfter=3
)

story = []

# Encabezado Institucional
story.append(Paragraph('UNIVERSIDAD CENTRAL DE VENEZUELA', ParagraphStyle('Univ', fontName='Helvetica-Bold', fontSize=10, leading=12, alignment=1, textColor=primary_color)))
story.append(Paragraph('FACULTAD DE CIENCIAS — ESCUELA DE COMPUTACIÓN<br/>ADMINISTRACIÓN DE BASES DE DATOS (SEMESTRE 1-2026)', ParagraphStyle('Fac', fontName='Helvetica', fontSize=9, leading=11, alignment=1, textColor=secondary_color)))
story.append(Spacer(1, 15))

story.append(Paragraph('INFORME TÉCNICO DE DISEÑO, IMPLEMENTACIÓN Y ARQUITECTURA', title_style))
story.append(Paragraph('Proyecto II — Plataforma Integral de Cálculo de Comisiones de Ventas<br/><b>CompuComisiones, C.A.</b>', subtitle_style))
story.append(HRFlowable(width='100%', thickness=1.5, color=accent_color, spaceBefore=0, spaceAfter=12))

# 1. Resumen Ejecutivo
story.append(Paragraph('1. Resumen Ejecutivo y Alcance', h1_style))
story.append(Paragraph(
    'El presente documento detalla la arquitectura, modelo relacional, políticas de almacenamiento físico, seguridad, programación en T-SQL y estrategia de respaldo continuo de la base de datos para la empresa <b>CompuComisiones, C.A.</b> El motor seleccionado para el despliegue es <b>Microsoft SQL Server</b>.',
    body_style
))
story.append(Paragraph(
    'El sistema automatiza el ciclo completo de liquidación de incentivos comerciales para fuerzas de ventas corporativas, gestionando la jerarquía de supervisión acíclica, roles en facturas, esquemas dinámicos de planes y filtros de incentivos, cálculos consolidados por periodo y pagos independientes ejecutados por la gerencia de finanzas.',
    body_style
))

# 2. Modelo Relacional y Diccionario de Datos
story.append(Paragraph('2. Diseño del Modelo Relacional y Diccionario de Datos', h1_style))
story.append(Paragraph(
    'El modelo se encuentra normalizado en <b>Tercera Forma Normal (3NF)</b>. A continuación se resume la estructura de entidades principales implementadas:',
    body_style
))

table_dict_data = [
    [Paragraph('<b>Tabla</b>', body_style), Paragraph('<b>Atributos Clave y Restricciones</b>', body_style), Paragraph('<b>Filegroup</b>', body_style)],
    [Paragraph('<b>Persona</b>', body_style), Paragraph('id_persona (PK), nombre, apellidos, correo (UK), fecha_incorporacion, tipo_persona (CHECK), estatus (CHECK)', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>Vendedor</b>', body_style), Paragraph('id_vendedor (PK, FK Persona), cuota_ventas (CHECK >= 0)', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>Supervisor</b>', body_style), Paragraph('id_supervisor (PK, FK Persona), zona, id_supervisor_jefe (FK Supervisor, acíclico)', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>PersonalFinanzas</b>', body_style), Paragraph('id_personal (PK, FK Persona), cargo', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>SupervisorVendedor</b>', body_style), Paragraph('id_asignacion_sup (PK), id_supervisor (FK), id_vendedor (FK), porcentaje_reconocimiento (0-100), vigencia', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>Cliente</b>', body_style), Paragraph('id_cliente (PK), codigo_cliente (UK), nombre, segmento_mercado', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>Producto</b>', body_style), Paragraph('id_producto (PK), codigo_producto (UK), nombre, categoria, <b>precio (CHECK >= 0)</b>, costo_unitario (CHECK >= 0)', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>Factura</b>', body_style), Paragraph('id_factura (PK), numero_factura (UK), id_cliente (FK), fecha_emision, situacion (CHECK), fecha_cobro', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>FacturaDetalle</b>', body_style), Paragraph('(id_factura, id_producto) [PK], cantidad (> 0), monto (>= 0), motivo', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>RolVenta</b>', body_style), Paragraph('id_rol (PK), nombre_rol (UK), descripcion', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>FacturaParticipacion</b>', body_style), Paragraph('id_participacion (PK), (id_factura, id_vendedor, id_rol) [UK], porcentaje_participacion (0-100)', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>PlanComision</b>', body_style), Paragraph('id_plan (PK), codigo_plan (UK), nombre, tasa_comision (0-100), base_aplicacion (Ingreso/Margen/Cantidad), admite_descuento', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>AsignacionPlan</b>', body_style), Paragraph('id_asignacion_plan (PK), id_vendedor (FK), id_rol (FK), id_plan (FK), fecha_inicio_vigor, fecha_fin_vigor', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>PlanFiltro</b>', body_style), Paragraph('(id_plan, numero_orden) [PK], tipo_filtro (PRODUCTO/CATEGORIA/MOTIVO), valor_filtro. Entidad Débil.', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>Periodo</b>', body_style), Paragraph('id_periodo (PK), codigo_periodo (UK), descripcion, tipo_periodo (Semanal/Mensual/Trimestral/Anual), fechas', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>CalculoComision</b>', body_style), Paragraph('id_calculo (PK), (id_periodo, id_persona) [UK], monto_propio_ventas, monto_supervision, monto_total, estado', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>CalculoDetalle</b>', body_style), Paragraph('id_calculo_detalle (PK), id_calculo (FK), id_factura (FK), base_comisionable, comision_generada, tipo_origen', body_style), Paragraph('FG_COMPU_DATA', body_style)],
    [Paragraph('<b>PagoComision</b>', body_style), Paragraph('id_pago (PK), id_periodo_pago (FK), id_persona (FK), fecha_pago, monto, estado_pago, id_personal_finanzas (FK)', body_style), Paragraph('FG_COMPU_DATA', body_style)]
]

t_dict = Table(table_dict_data, colWidths=[95, 310, 99])
t_dict.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#E2E8F0')),
    ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor('#94A3B8')),
    ('INNERGRID', (0,0), (-1,-1), 0.5, colors.HexColor('#CBD5E1')),
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ('TOPPADDING', (0,0), (-1,-1), 3),
]))
story.append(t_dict)
story.append(Spacer(1, 10))

# Nota sobre el campo Precio
story.append(Paragraph('<b>Consideración de Diseño sobre los Campos Precio y Monto:</b>', h2_style))
story.append(Paragraph(
    'En cumplimiento de los requerimientos corporativos, la tabla <b>Producto</b> incorpora de manera explícita el campo <b>precio</b> (precio base de catálogo) y el campo <b>costo_unitario</b> (requerido para determinar el Margen comercial en planes de incentivos). En la tabla <b>FacturaDetalle</b>, se preserva el campo <b>monto</b>, el cual representa el valor monetario real facturado por la línea (permitiendo reflejar descuentos de negociación o condiciones comerciales particulares aplicadas a esa venta).',
    body_style
))

# 3. Arquitectura Física y Filegroups
story.append(Paragraph('3. Arquitectura de Almacenamiento Físico (Filegroups)', h1_style))
story.append(Paragraph(
    'Por política institucional, <b>ningún objeto de usuario se aloja en el filegroup PRIMARY</b>. Se estructuraron dos Filegroups secundarios dedicados:',
    body_style
))
story.append(Paragraph('• <b>FG_COMPU_DATA:</b> Almacena exclusivamente los datos (páginas de datos y montículos clustered) de las 18 tablas de la solución.', bullet_style))
story.append(Paragraph('• <b>FG_COMPU_INDEX:</b> Aloja todas las claves primarias (PK) e índices no agrupados sobre los atributos «nombre».', bullet_style))
story.append(Paragraph('• <b>Nomenclatura de Índices:</b> Todos los índices cumplen rígidamente con el formato corporativo <code>&lt;nombreAtributo&gt;_&lt;nombreTabla&gt;_indx</code> (ej. <i>nombre_Persona_indx</i>, <i>nombre_Producto_indx</i>, <i>id_producto_Producto_indx</i>).', bullet_style))

# 4. Seguridad y Roles
story.append(Paragraph('4. Esquema de Seguridad y Roles de Base de Datos', h1_style))
story.append(Paragraph(
    'La base de datos implementa el esquema <b>comisiones</b>, cuyo propietario es el usuario <b>usr_schema_owner</b> creado <i>WITHOUT LOGIN</i> (impidiendo cualquier conexión o inicio de sesión interactivo con dicha cuenta). El acceso se otorga exclusivamente mediante roles bajo el principio de mínimo privilegio:',
    body_style
))
story.append(Paragraph('• <b>registrador:</b> Permisos de INSERT y UPDATE sobre personas, facturas y participaciones comerciales.', bullet_style))
story.append(Paragraph('• <b>moderador:</b> Permiso exclusivo de solo lectura (SELECT) sobre todas las tablas del esquema.', bullet_style))
story.append(Paragraph('• <b>administrador:</b> Control DML total (SELECT, INSERT, UPDATE, DELETE, EXECUTE) sobre los objetos del esquema.', bullet_style))

# 5. Programabilidad T-SQL
story.append(Paragraph('5. Lógica de Negocio y Objetos Programables', h1_style))
story.append(Paragraph('• <b>Trigger 1 (Control de Participación):</b> Garantiza que la suma de porcentajes de participación por factura nunca sobrepase el 100.00%, abortando la transacción si se intenta registrar un valor superior.', bullet_style))
story.append(Paragraph('• <b>Trigger 2 (Integridad de Supervisión):</b> Bloquea la auto-supervisión y analiza mediante un <b>CTE Recursivo</b> toda la línea de mando ascendente, rechazando dependencias cíclicas directas o indirectas.', bullet_style))
story.append(Paragraph('• <b>Trigger 3 (Recupero por Devolución):</b> Al pasar una factura a estado <i>Anulada</i>, detecta si el plan bajo el cual se comisionó admite descuentos y revierte inmediatamente las comisiones devengadas en <code>CalculoComision</code> y <code>CalculoDetalle</code>.', bullet_style))
story.append(Paragraph('• <b>Función fn_CalcularBaseComisionable:</b> Evalúa dinámicamente los filtros de inclusión del plan (por Producto, Categoría o Motivo) y retorna la base acumulada según sea Ingreso, Margen o Cantidad.', bullet_style))
story.append(Paragraph('• <b>Procedimiento sp_CorrerCalculoComisiones:</b> Ejecuta la liquidación de comisiones para un periodo dado sobre facturas cobradas, reconociendo tanto ventas propias como porcentajes a supervisores.', bullet_style))
story.append(Paragraph('• <b>Procedimiento sp_RegistrarPagosPeriodo:</b> Procesa y registra los desembolsos reales en <code>PagoComision</code> para un periodo de pago independiente, liquidando los cálculos aprobados.', bullet_style))
story.append(Paragraph('• <b>Vista vw_ReportePagosFinanzas:</b> Reporte multi-periodo (semanal, mensual, trimestral y anual) para auditoría financiera.', bullet_style))

# 6. Estrategia de Respaldo 24/7
story.append(Paragraph('6. Estrategia de Respaldo y Continuidad Operativa (24/7)', h1_style))
story.append(Paragraph(
    'Para dar cumplimiento estricto a la directriz de mantener la base de datos <b>siempre operativa</b>, se definió un modelo de recuperación <b>FULL</b> con un esquema de respaldo en 3 niveles:',
    body_style
))
story.append(Paragraph('• <b>SLA de Negocio:</b> RPO ≤ 15 minutos (máxima pérdida admisible) y RTO ≤ 30 minutos (tiempo de restauración).', bullet_style))
story.append(Paragraph('• <b>Respaldo Completo (Full):</b> Semanal (Domingos 01:00 AM) en ventana de bajo tráfico.', bullet_style))
story.append(Paragraph('• <b>Respaldo Diferencial:</b> Diario (Lunes a Sábado 01:00 AM), optimizando radicalmente el RTO.', bullet_style))
story.append(Paragraph('• <b>Respaldo de Log de Transacciones:</b> Cada 15 minutos (24x7), posibilitando Point-in-Time Recovery y truncando el archivo LDF.', bullet_style))
story.append(Paragraph('• <b>Respaldo de Cola de Log (Tail-Log):</b> Procedimiento de contingencia para alcanzar RPO = 0 ante fallas físicas.', bullet_style))

# 7. Conclusión
story.append(Paragraph('7. Conclusión de la Entrega', h1_style))
story.append(Paragraph(
    'La solución diseñada para <b>CompuComisiones, C.A.</b> responde a los más altos estándares de ingeniería de bases de datos relacionales en Microsoft SQL Server. Cumple cabalmente con la totalidad de requerimientos conceptuales, restricciones de integridad, partición física en filegroups, seguridad y resiliencia ante desastres, garantizando la escalabilidad y exactitud financiera de la plataforma.',
    body_style
))

doc.build(story, canvasmaker=NumberedCanvas)
print('Informe Técnico en PDF generado exitosamente en:', pdf_path)
