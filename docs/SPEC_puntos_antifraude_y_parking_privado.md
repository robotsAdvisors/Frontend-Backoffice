# SPEC — Ajuste antifraude de puntos y Publicaciones de parking privado

| | |
|---|---|
| **Estado** | Borrador para revisión |
| **Fecha** | 2026-07-24 |
| **Ámbito backend** | Django, app `points_admin` (`/api/v1/admin/…`) |
| **Ámbito frontend** | Backoffice del Super Admin (repo `Frontend-Backoffice`) |
| **Pantallas afectadas** | Wallet de puntos, Historial de movimientos, Publicaciones de aparcamiento, Detalle de publicación |

---

## 0. Resumen ejecutivo

Se especifican dos capacidades del Super Admin que hoy existen como maqueta en el frontend y **no tienen backend**:

- **Módulo A — Puntos y antifraude.** Ver el saldo y el historial de movimientos de puntos de un usuario concreto, y **retirar o corregir puntos obtenidos de forma fraudulenta**, con trazabilidad completa.
- **Módulo B — Parking privado de cobro.** Publicar y supervisar plazas de aparcamiento privadas de pago, con doble ciclo de vida (funcional y económico) y liquidación vía Stripe.

Principio rector del Módulo A: **el saldo de puntos es un libro mayor de solo-adición (*append-only*)**. Nunca se actualiza un contador ni se borra un movimiento; toda corrección es un asiento nuevo. Esto da auditoría, reversibilidad y defensa jurídica por construcción.

---

## 1. Contexto y motivación

El Super Admin necesita responder a fraude en la obtención de puntos: usuarios que suben contribuciones duplicadas, falsas o automatizadas para acumular saldo. Hoy el backoffice puede *moderar la contribución* (BG-06) pero **no puede actuar sobre los puntos ya acreditados** ni auditar el saldo de un usuario.

Además, la plataforma quiere ofrecer plazas de aparcamiento **privadas y de pago**, publicadas por la propia plataforma, distintas de las contribuciones colaborativas gratuitas que ya existen.

---

## 2. Alcance

### 2.1 Dentro de alcance
- Consulta de saldo de puntos **por usuario** desde el backoffice.
- Consulta paginada y filtrable del **historial de movimientos** de puntos de un usuario.
- **Ajuste manual** (positivo o negativo) de puntos con motivo obligatorio y auditoría.
- **Reversión** de un ajuste previo.
- Retirada automática de puntos al **rechazar** una contribución fraudulenta.
- CRUD y supervisión de **publicaciones de parking privado de cobro**, con acciones Validar / Revisar / Cancelar / Reembolsar.

### 2.2 Fuera de alcance
- Wallet de dinero y retiradas (`credits/`), que ya existe y es un libro distinto.
- Reparto de ingresos entre plataforma e informador (Stripe Connect) — ver §8, decisión abierta D5.
- Cambios en la app de cliente.

---

## 3. Lo que ya existe (reutilizar, no duplicar)

| Pieza existente | Ruta / modelo | Cómo se aprovecha |
|---|---|---|
| Cola de moderación antifraude (BG-06) | `GET /admin/moderation/contributions/` | Origen de la evidencia de fraude; se enlaza desde el ajuste |
| Decisión de moderación | `POST /admin/moderation/contributions/{kind}/{id}/` | Se **extiende** con `revoke_points` (§4.3.5) |
| Umbrales antifraude (BG-07) | `GET/POST/PATCH /admin/antifraud-rules/` | Sin cambios |
| Registro de auditoría de usuario | `GET /admin/users/{id}/audit-log/` | Todo ajuste debe aparecer aquí |
| Acciones de cumplimiento | `POST /admin/users/{id}/kyc/action/` + `/compliance/history/` | Patrón a imitar para sanciones |
| Ciclo de canje | `redemption-codes/validation/` → `/delivery/` | Ya bloquea y consume puntos: define los buckets `bloqueado` y `consumido` |

> ⚠️ **No reutilizar** `GET /admin/users/{id}/transactions/`: es el libro de **dinero** (`amount`, `payment_method`). Puntos y dinero son libros separados.

### 3.1 Convenciones del proyecto (obligatorias)

- Base: `https://api.letdem.net/api/v1`. Todas las rutas con barra final.
- Paginación DRF: `{count, next, previous, results:[…]}`.
- Contrato de error único: `{error_code, message, details}` con el HTTP status correspondiente.
- Permiso por defecto de este spec: `IsSuperAdmin` → `403` en cualquier otro caso.

---

## 4. Módulo A — Puntos y ajuste antifraude

### 4.1 Modelo de datos

```python
class PointsMovement(models.Model):
    """Libro mayor de puntos. APPEND-ONLY: nunca se hace UPDATE ni DELETE."""

    KIND = [("EARN","Ganado"), ("VALIDATE","Validado"), ("REJECT","Rechazado"),
            ("BLOCK","Bloqueado"), ("CONSUME","Consumido"), ("RELEASE","Liberado"),
            ("EXPIRE","Expirado"), ("ADJUST","Ajustado")]

    REASON = [("CONTRIBUTION","Contribución"), ("REDEMPTION","Canje"),
              ("CAMPAIGN","Campaña"), ("FRAUD","Fraude"), ("ERROR","Error operativo"),
              ("CHARGEBACK","Contracargo"), ("MANUAL","Corrección manual"),
              ("EXPIRY","Caducidad")]

    user            = FK(User, related_name="points_movements", db_index=True)
    amount          = IntegerField()            # con signo: +50 / -100
    kind            = CharField(choices=KIND)
    reason_code     = CharField(choices=REASON)
    reason_text     = TextField(blank=True)     # obligatorio si kind=ADJUST

    source_type     = CharField(null=True)      # "contribution" | "redemption" | "campaign" | "adjustment"
    source_id       = CharField(null=True)      # id del origen (uuid o entero)

    actor           = FK(User, null=True)       # null = sistema; informado = Super Admin
    idempotency_key = CharField(unique=True, null=True)
    reverses        = FK("self", null=True, related_name="reversals")

    created_at      = DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        indexes = [Index(fields=["user", "-created_at"])]
```

```python
class PointsWallet(models.Model):
    """Caché de saldos. Se actualiza SIEMPRE en la misma transacción que el movimiento."""
    user       = OneToOne(User, related_name="points_wallet")
    disponible = IntegerField(default=0)
    pendiente  = IntegerField(default=0)
    bloqueado  = IntegerField(default=0)
    expirado   = IntegerField(default=0)
    updated_at = DateTimeField(auto_now=True)
```

**Migración de datos:** al desplegar, generar un `PointsMovement` histórico por cada acreditación existente para que el saldo derivado cuadre con el actual. Un saldo que no se pueda reconstruir desde el libro es un bug.

### 4.2 Máquina de estados y buckets

Cada `kind` mueve puntos entre buckets. Esta tabla es la fuente de verdad:

| `kind` | Origen | Destino | Cuándo ocurre |
|---|---|---|---|
| `EARN` | — | `pendiente` | El usuario sube una contribución |
| `VALIDATE` | `pendiente` | `disponible` | Moderación valida (BG-06) |
| `REJECT` | `pendiente` | — (se descarta) | Moderación rechaza |
| `BLOCK` | `disponible` | `bloqueado` | Se genera un código de canje |
| `CONSUME` | `bloqueado` | — (gastado) | Se entrega el canje |
| `RELEASE` | `bloqueado` | `disponible` | El canje se cancela o caduca |
| `EXPIRE` | `disponible` | `expirado` | Job de caducidad |
| `ADJUST` | cualquiera | cualquiera | Intervención del Super Admin |

> **Nota de diseño:** el prototipo del frontend usa un único campo `estado` que mezcla *tipo de movimiento* con *estado*. Aquí se separan: `kind` (qué pasó) es lo que se filtra y se pinta. El frontend debe adaptarse a `kind`.

### 4.3 Endpoints

#### 4.3.1 Saldo de un usuario

```http
GET /api/v1/admin/users/{user_id}/points/
```
**200**
```json
{
  "user_id": 42,
  "disponible": 1200,
  "pendiente": 150,
  "bloqueado": 300,
  "expirado": 80,
  "total_historico": 4820,
  "actualizado_en": "2026-07-24T10:12:00Z"
}
```

#### 4.3.2 Movimientos de un usuario

```http
GET /api/v1/admin/users/{user_id}/points/movements/
      ?kind=ADJUST&reason_code=FRAUD&from=2026-01-01&to=2026-07-24&page=1&page_size=20
```
**200** — paginación DRF
```json
{
  "count": 137,
  "next": "…?page=2",
  "previous": null,
  "results": [
    {
      "id": "9f3a…",
      "created_at": "2026-07-22T14:03:11Z",
      "amount": -500,
      "kind": "ADJUST",
      "reason_code": "FRAUD",
      "reason_text": "5 contribuciones duplicadas en zona ezjm1",
      "source": {"type": "adjustment", "id": null},
      "actor": {"id": 7, "email": "super@letdem.net"},
      "reverses": null
    }
  ]
}
```

#### 4.3.3 Ajuste manual de puntos ← **endpoint crítico**

```http
POST /api/v1/admin/users/{user_id}/points/adjustments/
Idempotency-Key: 3f1c8b7e-…        ← obligatorio
```
```json
{
  "amount": -500,
  "reason_code": "FRAUD",
  "reason_text": "5 contribuciones duplicadas en zona ezjm1",
  "bucket": "disponible",
  "evidence_ref": "moderation:space:abc-123"
}
```
**201**
```json
{
  "movement_id": "9f3a…",
  "saldos": {"disponible": 700, "pendiente": 150, "bloqueado": 300, "expirado": 80}
}
```

Reglas:
- `amount ≠ 0`; `reason_text` obligatorio y no vacío.
- `Idempotency-Key` obligatorio: si se repite, devuelve **200** con el movimiento ya creado (no duplica).
- Bloqueo de fila: `PointsWallet.objects.select_for_update()` dentro de `transaction.atomic()`.
- Escribe una entrada en el `audit-log` del usuario (actor, IP, motivo).

#### 4.3.4 Reversión de un ajuste

```http
POST /api/v1/admin/points/adjustments/{movement_id}/reverse/
{ "reason_text": "Ajuste aplicado al usuario equivocado" }
```
**201** — crea un movimiento con `amount` invertido y `reverses = movement_id`.

> No existe `DELETE`. Borrar un movimiento rompe la auditoría antifraude y el rastro exigible por RGPD.

#### 4.3.5 Retirada de puntos desde moderación (extensión)

Se **amplía** el endpoint existente en lugar de crear un flujo paralelo:

```http
POST /api/v1/admin/moderation/contributions/{kind}/{id}/
{ "decision": "reject", "reason": "Duplicada", "revoke_points": true }
```
Con `revoke_points: true`, el rechazo genera automáticamente el `PointsMovement` de retirada (`kind=ADJUST`, `reason_code=FRAUD`, `source_type="contribution"`). Cubre el caso mayoritario sin intervención manual.

### 4.4 Errores

| HTTP | `error_code` | Cuándo |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `amount` = 0, `reason_text` vacío, bucket inválido |
| 401 | `NOT_AUTHENTICATED` | Sin token |
| 403 | `PERMISSION_DENIED` | No es Super Admin |
| 404 | `USER_NOT_FOUND` / `MOVEMENT_NOT_FOUND` | — |
| 409 | `INSUFFICIENT_POINTS` | Si D1 se resuelve como "no permitir negativo" |
| 409 | `ALREADY_REVERSED` | El ajuste ya tiene reversión |
| 428 | `IDEMPOTENCY_KEY_REQUIRED` | Falta la cabecera |

### 4.5 Seguridad y auditoría

- `IsSuperAdmin` en todos los endpoints de §4.
- Toda escritura genera entrada de auditoría inmutable: actor, IP, user-agent, motivo, importe, saldo antes/después.
- **Cuatro ojos** (recomendado): ajustes cuyo valor absoluto supere un umbral configurable quedan en estado `PENDING_APPROVAL` y requieren un segundo Super Admin. Reutilizable desde `antifraud-rules`.
- El `reason_text` puede contener datos personales: queda sujeto a las políticas RGPD ya implantadas.

---

## 5. Módulo B — Publicaciones de parking privado de cobro

### 5.1 Modelo de datos

```python
class ParkingPublication(models.Model):
    MODALIDAD = [("PA-01", …), ("PA-02", …), ("PA-03", …)]   # ← definir, decisión D4
    FUNCIONAL = [("ACTIVA",…), ("BLOQUEADA",…), ("LIBERADA",…), ("EXPIRADA",…)]
    ECONOMICO = [("PENDIENTE",…), ("PAGADO",…), ("VALIDADO",…),
                 ("DISPUTADO",…), ("REEMBOLSADO",…)]

    modalidad        = CharField(choices=MODALIDAD)
    informador       = FK(User, related_name="publicaciones")
    solicitante      = FK(User, null=True, related_name="publicaciones_compradas")

    is_private       = BooleanField(default=False)   # publicada por la plataforma
    published_by     = FK(User, null=True)           # Super Admin que la publicó

    precio           = DecimalField(max_digits=8, decimal_places=2)
    moneda           = CharField(default="EUR")

    estado_funcional = CharField(choices=FUNCIONAL, default="ACTIVA")
    estado_economico = CharField(choices=ECONOMICO, default="PENDIENTE")

    stripe_payment_intent_id = CharField(null=True)
    stripe_charge_id         = CharField(null=True)
    importe_reembolsado      = DecimalField(default=0)

    direccion, latitud, longitud
    ventana_inicio, ventana_fin
    created_at, updated_at


class PublicationEvent(models.Model):
    """Trazabilidad append-only. Alimenta la línea de tiempo del detalle."""
    publication = FK(ParkingPublication, related_name="events")
    estado      = CharField()
    tipo        = CharField(choices=[("FUNCIONAL",…), ("ECONOMICO",…)])
    actor       = FK(User, null=True)
    reason      = TextField(blank=True)
    created_at  = DateTimeField(auto_now_add=True)
```

### 5.2 Transiciones válidas

**Funcional:** `ACTIVA → BLOQUEADA → LIBERADA` · `ACTIVA → EXPIRADA` (por ventana temporal)
**Económico:** `PENDIENTE → PAGADO → VALIDADO` · `PAGADO → DISPUTADO → REEMBOLSADO`

Cualquier transición no listada devuelve `409 INVALID_TRANSITION`. Toda transición escribe un `PublicationEvent`.

### 5.3 Endpoints

```http
GET   /api/v1/admin/parking/publications/
        ?estado_funcional=&estado_economico=&modalidad=&search=&page=
POST  /api/v1/admin/parking/publications/          ← publicar parking privado
GET   /api/v1/admin/parking/publications/{id}/     → incluye events[]
PATCH /api/v1/admin/parking/publications/{id}/
POST  /api/v1/admin/parking/publications/{id}/actions/
```

**Listado — 200**
```json
{
  "count": 24,
  "results": [{
    "id": "b71e…",
    "modalidad": "PA-01",
    "estado_funcional": "ACTIVA",
    "estado_economico": "PAGADO",
    "informador":  {"id": 3, "nombre": "Juan Pérez"},
    "solicitante": {"id": 9, "nombre": "María Gómez"},
    "precio": "4.50", "moneda": "EUR",
    "created_at": "2026-07-23T14:30:00Z",
    "stripe_charge_id": "ch_1ABCDEF"
  }]
}
```

**Crear publicación privada — `POST`**
```json
{
  "modalidad": "PA-01",
  "precio": "4.50",
  "direccion": "Calle Mayor 88, Madrid",
  "latitud": 40.4168, "longitud": -3.7038,
  "ventana_inicio": "2026-07-25T08:00:00Z",
  "ventana_fin":    "2026-07-25T20:00:00Z",
  "is_private": true
}
```
→ **201** con la publicación creada, `published_by` = usuario autenticado.

**Acciones — `POST /{id}/actions/`**
```json
{ "action": "refund", "reason": "Plaza no disponible a la llegada", "amount": "4.50" }
```
`action` ∈ `validate` | `review` | `cancel` | `refund`. `amount` solo para `refund` (parcial, si D6 lo permite).

### 5.4 Stripe — webhooks obligatorios

El `POST /actions/` con `refund` **inicia** el reembolso; no lo concluye. Es obligatorio consumir webhooks para mantener `estado_economico` sincronizado:

| Evento Stripe | Efecto |
|---|---|
| `payment_intent.succeeded` | `PENDIENTE → PAGADO`, guarda `charge_id` |
| `charge.refunded` | `→ REEMBOLSADO`, actualiza `importe_reembolsado` |
| `charge.dispute.created` | `→ DISPUTADO` |
| `charge.dispute.closed` | `→ VALIDADO` o `REEMBOLSADO` según resultado |

Los webhooks deben ser **idempotentes** (Stripe reenvía) y verificar la firma.

---

## 6. Mapeo con las pantallas del frontend

| Pantalla | Endpoint | Cambio necesario en el frontend |
|---|---|---|
| Wallet de puntos | `GET /admin/users/{id}/points/` | Necesita **selector de usuario**; hoy no lo tiene |
| Historial de movimientos | `GET /admin/users/{id}/points/movements/` | Cambiar `estado` por `kind`; añadir paginación y filtros |
| — (nuevo) | `POST …/points/adjustments/` | **Falta la UI de ajuste**: importe, motivo obligatorio, confirmación |
| Publicaciones | `GET /admin/parking/publications/` | Sustituir lista quemada; los filtros ya están maquetados |
| Detalle de publicación | `GET …/{id}/` + `POST …/actions/` | Recibir `id` real por argumento (hoy es `'demo'`); cablear los 4 botones |

Todas las pantallas deben además incluir `BackofficeSidebar` (hoy no la usan) y respetar el requisito **GA-03** del PRD: *ninguna pantalla carga datos con IDs dummy*.

---

## 7. Criterios de aceptación

**Módulo A — Puntos**

| ID | Criterio |
|---|---|
| PF-01 | El saldo devuelto por `GET …/points/` coincide con la suma del libro de movimientos |
| PF-02 | Un ajuste crea exactamente un `PointsMovement` y actualiza los buckets en la misma transacción |
| PF-03 | Repetir la petición con el mismo `Idempotency-Key` **no** duplica el ajuste |
| PF-04 | Un ajuste sin `reason_text` es rechazado con `400 VALIDATION_ERROR` |
| PF-05 | Un usuario no Super Admin recibe `403` en todos los endpoints de §4 |
| PF-06 | Todo ajuste aparece en `GET /admin/users/{id}/audit-log/` con actor y motivo |
| PF-07 | La reversión genera un asiento con importe invertido; el original permanece intacto |
| PF-08 | Rechazar con `revoke_points:true` retira los puntos de esa contribución |
| PF-09 | Dos ajustes concurrentes sobre el mismo usuario no corrompen el saldo |
| PF-10 | No existe ninguna ruta que permita borrar un `PointsMovement` |

**Módulo B — Publicaciones**

| ID | Criterio |
|---|---|
| PP-01 | Solo el Super Admin puede crear publicaciones con `is_private: true` |
| PP-02 | Toda transición de estado genera un `PublicationEvent` visible en el detalle |
| PP-03 | Una transición no permitida devuelve `409 INVALID_TRANSITION` |
| PP-04 | Tras un reembolso confirmado por webhook, `estado_economico = REEMBOLSADO` |
| PP-05 | Los webhooks de Stripe son idempotentes ante reenvíos |
| PP-06 | Los filtros de listado combinan funcional + económico + búsqueda |

---

## 8. Decisiones abiertas (bloquean la implementación)

| ID | Decisión | Impacto |
|---|---|---|
| **D1** | ¿El saldo puede quedar **negativo** al retirar puntos ya gastados? | Recomendado: permitir negativo y bloquear canjes hasta regularizar. Alternativa: `409 INSUFFICIENT_POINTS` |
| **D2** | ¿Qué buckets admiten ajuste? ¿Solo `disponible` o también `pendiente`/`bloqueado`? | Define el parámetro `bucket` |
| **D3** | ¿Existe ya un job de **caducidad** de puntos? | Sin él, el bucket `expirado` siempre será 0 |
| **D4** | ¿Qué representan **PA-01 / PA-02 / PA-03**? | Bloquea el modelado de `modalidad` |
| **D5** | ¿Quién cobra el parking privado: plataforma o informador? | Si es el informador, hace falta **Stripe Connect** (esfuerzo alto) |
| **D6** | ¿Se admite **reembolso parcial**? | Determina si `importe_reembolsado` es decimal o booleano |
| **D7** | ¿Umbral de importe para aprobación de **cuatro ojos**? | Define si se implementa `PENDING_APPROVAL` en la v1 |

---

## 9. Riesgos

| Riesgo | Severidad | Mitigación |
|---|---|---|
| Doble descuento por reintento del cliente | Alta | `Idempotency-Key` obligatorio |
| Condición de carrera entre ajustes simultáneos | Alta | `select_for_update()` + `transaction.atomic()` |
| Pérdida de auditoría por borrado de movimientos | Alta | Prohibido `DELETE`; solo asientos compensatorios |
| Abuso de privilegios del Super Admin | Media | Auditoría obligatoria, motivo requerido, cuatro ojos |
| Estados económicos desincronizados con Stripe | Alta | Webhooks firmados e idempotentes |
| Saldo cacheado divergente del libro | Media | Job de conciliación periódico que compare `PointsWallet` con la suma del libro |

---

## 10. Plan de entrega sugerido

1. **Fase 1 — Lectura.** `PointsMovement` + `PointsWallet` + migración histórica + endpoints §4.3.1 y §4.3.2. Desbloquea las dos pantallas de puntos sin riesgo de escritura.
2. **Fase 2 — Escritura.** Ajustes (§4.3.3), reversión (§4.3.4) y auditoría. Requiere D1, D2, D7.
3. **Fase 3 — Automatización.** `revoke_points` en moderación (§4.3.5) y job de caducidad (D3).
4. **Fase 4 — Parking.** Módulo B completo. Requiere D4, D5, D6.

---

## 11. Nota de ubicación de este documento

Este spec describe el **backoffice**, no la app de cliente. Cuando se complete la separación de repositorios, debe moverse a `Frontend-Backoffice` junto con `PRD_panel_admin.md` y `docs/screens/06-general-admin-backoffice.md`, que hoy siguen residiendo en el repo de la app.
