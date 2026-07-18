# BankX — Documentación y Pruebas (Postman / Diagrams / OpenAPI)

Repositorio de **entregables de documentación** del sistema bancario BankX (Proyectos I, II y III).
El código fuente de cada microservicio vive en sus propios repositorios; aquí se centraliza:

- 📮 **Colecciones Postman** validadas end-to-end contra APIM + JWT (`docs/postman/`)
- 📐 **Diagramas UML / draw.io** (arquitectura, secuencia, despliegue, Kafka) (`docs/diagrams/`, `docs/uml/`)
- 📝 **Contratos OpenAPI** de cada microservicio (`docs/openapi/`)
- 🧪 **Plan de pruebas** (`docs/TEST-PLAN.md`)

## Arquitectura (entorno productivo / AKS)

- **7 microservicios funcionales**: `customer`, `account`, `credit`, `transaction`, `auth`, `yanki`, `fraud-detection`
- **Exposición vía Azure API Management** (`https://apim-bankx.azure-api.net`) + **JWT** (auth-service). No hay Spring Cloud Gateway ni Eureka ni Config Server en producción.
- **Comunicación inter-microservicio SOLO por Kafka** sobre **Azure Event Hubs** (`evhns-bankx`, SASL_SSL `:9093`)
- **Persistencia**: **Azure Cosmos DB (API de MongoDB)** `cosmos-bankx` / DB `bankx`, patrón database-per-service
- **Caché de catálogos**: Redis
- **Orquestación**: AKS `aks-bankx` (RG `rg-bankx`, región `centralus`, namespace `bankx`) con ingress-nginx

| Componente | Recurso Azure |
|------------|---------------|
| Cluster K8s | AKS `aks-bankx` (ns `bankx`) |
| API Gateway | APIM `apim-bankx` (Consumption) |
| Mensajería | Event Hubs `evhns-bankx` (Kafka) |
| Base de datos | Cosmos DB `cosmos-bankx` (MongoDB API) |
| Ingress | ingress-nginx |

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
| Arquitectura general (AKS/APIM) | `docs/uml/architecture-diagram.drawio` |
| Arquitectura de despliegue (AKS) | `docs/uml/deployment-architecture.drawio` |
| Interacción de microservicios | `docs/uml/microservices-interaction.drawio` |
| Arquitectura hexagonal | `docs/uml/hexagonal-architecture.drawio` |
| Tópicos Kafka (Event Hubs) | `docs/uml/kafka-topics.drawio` |
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

## Infraestructura como código

El despliegue en Azure (AKS, APIM, Cosmos, Event Hubs, ingress) se gestiona en `infra-azure-bankx/`
del repo principal del proyecto.
