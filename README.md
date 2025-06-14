# 🗳️ Elección con Delegación - Contrato en Solidity

Este proyecto implementa un sistema electoral descentralizado usando Solidity. Está diseñado para simular un proceso democrático completo con fases, votantes autorizados, candidatos, votación única y delegación de voto.

## 📜 Descripción del Contrato

### 👑 Rol de Administrador

La cuenta que despliega el contrato es el `admin`. Solo el admin puede:

* Agregar candidatos
* Autorizar votantes
* Iniciar y finalizar la votación

### 🚦 Fases de la Elección (`enum Fase`)

1. `Preparacion`: Se agregan candidatos y se autorizan votantes.
2. `Votacion`: Se habilita la votación.
3. `Finalizada`: Se bloquea la votación y se pueden consultar los resultados.

### 📊 Funcionalidades

| Función                            | Descripción                                            |
| ---------------------------------- | ------------------------------------------------------ |
| `agregarCandidato(string nombre)`  | Agrega un nuevo candidato                              |
| `autorizarVotante(address cuenta)` | Habilita a una dirección para votar                    |
| `iniciarVotacion()`                | Cambia la fase a Votación                              |
| `finalizarVotacion()`              | Cambia la fase a Finalizada                            |
| `votar(uint indiceCandidato)`      | Emite un voto por un candidato                         |
| `delegarVoto(address aQuien)`      | Delegar el voto a otra persona                         |
| `verGanador()`                     | Devuelve el nombre y votos del candidato con más votos |
| `obtenerCandidato(uint indice)`    | Visualiza nombre y votos de un candidato               |


---

## 🛡️ Seguridad Considerada

* Solo votantes autorizados pueden votar
* Cada dirección vota una sola vez
* Delegaciones no pueden ser circulares
* Solo el admin controla la configuración
* Validación de índice de candidatos

---

## ✍️ Ejemplo de Uso

```solidity
// Fase de preparación
contrato.agregarCandidato("Luz");
contrato.autorizarVotante(0x123...);

// Fase de votación
contrato.iniciarVotacion();
contrato.votar(0); // Vota por Luz

// Delegar voto
contrato.delegarVoto(0x456...);

// Finalizar elección
contrato.finalizarVotacion();
contrato.verGanador();
```

---

## 👨‍💻 Autora

Creado por Lupe(https://github.com/luucamay)
Contribuciones y sugerencias son bienvenidas. 🤝
