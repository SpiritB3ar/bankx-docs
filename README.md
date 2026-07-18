# BankX — Documentación y Pruebas (Postman / Diagrams / OpenAPI)

Repositorio de **entregables de documentación** del sistema bancario BankX (Proyectos I, II y III).
El código fuente de cada microservicio vive en sus propios repositorios; aquí se centraliza:

- 📮 **Colecciones Postman** validadas end-to-end contra APIM + JWT (`docs/postman/`)
- 📐 **Diagramas UML / draw.io** (arquitectura, secuencia, despliegue, Kafka) (`docs/diagrams/`, `docs/uml/`)
- 📝 **Contratos OpenAPI** de cada microservicio (`docs/openapi/`)
- 📄 **Planes y especificaciones** de las 3 fases (`docs/superpowers/`)
- 🧪 **Plan de pruebas** (`docs/TEST-PLAN.md`)

## Arquitectura

- 7 microservicios: `customer`, `account`, `credit`, `transaction`, `auth`, `yanki`, `fraud-detection`
- Comunicación **inter-microservicio SOLO por Kafka** (Event Hubs, SASL_SSL :9093)
- Exposición vía **APIM** (`https://apim-bankx.azure-api.net`) + **JWT** (auth-service)
- Base de datos **MongoDB** por microservicio (database-per-service) + **Redis** para catálogos

## Cómo probar las APIs

1. Registrar usuario en `auth-service` → `POST /api/v1/auth/register`
2. Login → `POST /api/v1/auth/login` → copiar `accessToken`
3. Usar el token como `Bearer` en el resto de llamadas (variable `token` en las colecciones)
4. Todas las colecciones usan `baseUrl = https://apim-bankx.azure-api.net`

> ⚠️ En PowerShell, enviar el body JSON desde un archivo (`--data-binary "@req.json"`),
> nunca inline, para evitar corrupción de comillas.

## Índice de diagramas

| Diagrama | Archivo |
|----------|---------|
| Arquitectura general | `docs/uml/architecture-diagram.drawio` |
| Arquitectura de despliegue | `docs/uml/deployment-architecture.drawio` |
| Interacción de microservicios | `docs/uml/microservices-interaction.drawio` |
| Arquitectura hexagonal | `docs/uml/hexagonal-architecture.drawio` |
| Tópicos Kafka | `docs/uml/kafka-topics.drawio` |
| Secuencia: auth JWT | `docs/diagrams/sequence-auth-jwt-flow.drawio` |
| Secuencia: account | `docs/diagrams/sequence-account-operations.drawio` |
| Secuencia: credit | `docs/diagrams/sequence-credit-operations.drawio` |
| Secuencia: transaction | `docs/diagrams/sequence-transaction-operations.drawio` |
| Secuencia: debt-check (Kafka) | `docs/diagrams/sequence-debt-check-kafka.drawio` |
| Secuencia: fraud detection | `docs/diagrams/sequence-fraud-detection.drawio` |
| Secuencia: third-party payment | `docs/diagrams/sequence-third-party-payment.drawio` |
| Secuencia: Yanki wallet | `docs/diagrams/sequence-yanki-wallet.drawio` |
| Secuencia: fraud (UML) | `docs/uml/fraud-detection-sequence.drawio` |

## Contratos OpenAPI

`account`, `auth`, `credit`, `customer`, `fraud-detection`, `transaction`, `yanki` → `docs/openapi/*.yaml`
