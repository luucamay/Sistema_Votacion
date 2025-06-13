// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Eleccion {
    
    // -------------------------
    // ESTRUCTURAS Y ENUMS
    // -------------------------

    enum EstadoEleccion { Preparacion, Votacion, Finalizada }
    EstadoEleccion public estadoActual;

    struct Candidato {
        string nombre;
        uint votos;
    }

    struct Votante {
        bool autorizado;
        bool haVotado;
        address delegado;
        uint peso; // número de votos que representa
        uint indiceCandidatoVotado;
    }

    // -------------------------
    // VARIABLES DE ESTADO
    // -------------------------

    address public admin;
    Candidato[] public candidatos;
    mapping(address => Votante) public votantes;

    // -------------------------
    // EVENTOS
    // -------------------------

    event VotoEmitido(address votante, uint indiceCandidato);
    event Delegacion(address delegador, address delegado);
    event EleccionFinalizada(uint indiceGanador, string nombreGanador, uint votos);
    event CandidatoAgregado(string nombre);
    event VotanteAutorizado(address votante);

    // -------------------------
    // CONSTRUCTOR
    // -------------------------

    constructor() {
        admin = msg.sender;
        estadoActual = EstadoEleccion.Preparacion;
    }

    // -------------------------
    // MODIFICADORES
    // -------------------------

    modifier soloAdmin() {
        require(msg.sender == admin, "Solo el admin puede realizar esta accion.");
        _;
    }

    modifier enEstado(EstadoEleccion _estado) {
        require(estadoActual == _estado, "Operacion no permitida en esta fase.");
        _;
    }

    // -------------------------
    // FUNCIONES DE GESTION
    // -------------------------

    function agregarCandidato(string memory _nombre)
        public
        soloAdmin
        enEstado(EstadoEleccion.Preparacion)
    {
        candidatos.push(Candidato(_nombre, 0));
        emit CandidatoAgregado(_nombre);
    }

    function autorizarVotante(address _votante)
        public
        soloAdmin
        enEstado(EstadoEleccion.Preparacion)
    {
        votantes[_votante].autorizado = true;
        votantes[_votante].peso = 1;
        emit VotanteAutorizado(_votante);
    }

    function iniciarVotacion()
        public
        soloAdmin
        enEstado(EstadoEleccion.Preparacion)
    {
        require(candidatos.length > 0, "Debe haber al menos un candidato.");
        estadoActual = EstadoEleccion.Votacion;
    }

    function finalizarVotacion()
        public
        soloAdmin
        enEstado(EstadoEleccion.Votacion)
    {
        estadoActual = EstadoEleccion.Finalizada;

        uint indiceGanador = obtenerIndiceGanador();
        emit EleccionFinalizada(
            indiceGanador,
            candidatos[indiceGanador].nombre,
            candidatos[indiceGanador].votos
        );
    }

    // -------------------------
    // FUNCION DE VOTO
    // -------------------------

    function delegarVoto(address _aQuien)
        public
        enEstado(EstadoEleccion.Votacion)
    {
        Votante storage delegador = votantes[msg.sender];
        require(delegador.autorizado, "No estas autorizado para votar.");
        require(!delegador.haVotado, "Ya has votado.");
        require(_aQuien != msg.sender, "No puedes delegarte a ti mismo.");

        // Sigue la cadena de delegación para evitar bucles
        address delegadoFinal = _aQuien;
        while (votantes[delegadoFinal].delegado != address(0)) {
            delegadoFinal = votantes[delegadoFinal].delegado;
            require(delegadoFinal != msg.sender, "Delegacion circular detectada.");
        }

        delegador.haVotado = true;
        delegador.delegado = delegadoFinal;

        Votante storage receptor = votantes[delegadoFinal];
        require(receptor.autorizado, "El delegado no esta autorizado.");

        if (receptor.haVotado) {
            // Si ya votó, sumamos el peso directamente al candidato elegido
           candidatos[receptor.indiceCandidatoVotado].votos += delegador.peso;
        } else {
            // Si aún no votó, sumamos el peso a su cuenta
            receptor.peso += delegador.peso;
        }

        emit Delegacion(msg.sender, delegadoFinal);
    }

    function votar(uint _indiceCandidato)
        public
        enEstado(EstadoEleccion.Votacion)
    {        
        Votante storage votante = votantes[msg.sender];
        require(votantes[msg.sender].autorizado, "No estas autorizado para votar.");
        require(!votantes[msg.sender].haVotado, "Ya has votado.");
        require(_indiceCandidato < candidatos.length, "Candidato invalido.");

        votante.haVotado = true;
        candidatos[_indiceCandidato].votos += votante.peso;

        emit VotoEmitido(msg.sender, _indiceCandidato);
    }

    // -------------------------
    // FUNCIONES DE CONSULTA
    // -------------------------

    function obtenerCantidadCandidatos() public view returns (uint) {
        return candidatos.length;
    }

    function obtenerCandidato(uint _indice) public view returns (string memory nombre, uint votos) {
        require(_indice < candidatos.length, "Indice fuera de rango.");
        Candidato storage c = candidatos[_indice];
        return (c.nombre, c.votos);
    }

    function obtenerIndiceGanador()
        internal
        view
        returns (uint indiceGanador)
    {
        uint maxVotos = 0;
        for (uint i = 0; i < candidatos.length; i++) {
            if (candidatos[i].votos > maxVotos) {
                maxVotos = candidatos[i].votos;
                indiceGanador = i;
            }
        }
    }

    function verGanador()
        public
        view
        enEstado(EstadoEleccion.Finalizada)
        returns (string memory nombreGanador, uint votos)
    {
        uint indice = obtenerIndiceGanador();
        Candidato memory ganador = candidatos[indice];
        return (ganador.nombre, ganador.votos);
    }
}
