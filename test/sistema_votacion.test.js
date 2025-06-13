const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Eleccion", function () {
  let contrato;
  let admin, votante1, votante2, votante3;

  beforeEach(async () => {
    const Eleccion = await ethers.getContractFactory("Eleccion");
    [admin, votante1, votante2, votante3] = await ethers.getSigners();
    contrato = await Eleccion.connect(admin).deploy().then(()=>{console.log({admin, votante1, votante2, votante3})})
    

    await contrato.agregarCandidato("Ame");
    await contrato.agregarCandidato("Max");
    await contrato.autorizarVotante(votante1.address);
    await contrato.autorizarVotante(votante2.address);
    await contrato.autorizarVotante(votante3.address);
    await contrato.iniciarVotacion();
  });

  it("votante autorizado puede votar", async function () {
    await contrato.connect(votante1).votar(0); // Ame
    const [nombre, votos] = await contrato.obtenerCandidato(0);
    expect(votos).to.equal(1);
  });

  it("no autorizado no puede votar", async function () {
    await expect(
      contrato.connect(ethers.Wallet.createRandom()).votar(0)
    ).to.be.revertedWith("No estas autorizado para votar.");
  });

  it("no se puede votar dos veces", async function () {
    await contrato.connect(votante1).votar(0);
    await expect(contrato.connect(votante1).votar(1)).to.be.revertedWith("Ya has votado.");
  });

  it("delegar voto transfiere el peso correctamente si el delegado no ha votado", async function () {
    await contrato.connect(votante1).delegarVoto(votante2.address);
    await contrato.connect(votante2).votar(1); // Vota por Max

    const [nombre, votos] = await contrato.obtenerCandidato(1);
    expect(votos).to.equal(2); // 1 de votante2 + 1 delegado
  });

  it("delegar voto transfiere directamente si el delegado ya ha votado", async function () {
    await contrato.connect(votante2).votar(0); // Vota por Ame
    await contrato.connect(votante1).delegarVoto(votante2.address);

    const [nombre, votos] = await contrato.obtenerCandidato(0);
    expect(votos).to.equal(2);
  });

  it("no se puede delegar a uno mismo", async function () {
    await expect(
      contrato.connect(votante1).delegarVoto(votante1.address)
    ).to.be.revertedWith("No puedes delegarte a ti mismo.");
  });

  it("detecta bucles de delegación", async function () {
    await contrato.connect(votante1).delegarVoto(votante2.address);
    await expect(
      contrato.connect(votante2).delegarVoto(votante1.address)
    ).to.be.revertedWith("Delegacion circular detectada.");
  });

  it("solo admin puede finalizar la votación", async function () {
    await expect(
      contrato.connect(votante1).finalizarVotacion()
    ).to.be.revertedWith("Solo el admin puede realizar esta accion.");
  });

  it("gana el candidato con más votos", async function () {
    await contrato.connect(votante1).votar(0);
    await contrato.connect(votante2).votar(1);
    await contrato.connect(votante3).votar(1);
    await contrato.finalizarVotacion();

    const [nombreGanador, votos] = await contrato.verGanador();
    expect(nombreGanador).to.equal("Max");
    expect(votos).to.equal(2);
  });
});
