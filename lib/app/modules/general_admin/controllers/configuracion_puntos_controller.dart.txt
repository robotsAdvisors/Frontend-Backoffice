import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfiguracionPuntosController extends GetxController {
  // Campos configurables (reactivos)
  var limitePorPedido = 300.obs;
  var caducidadMeses = 12.obs;
  var maximoPorCampania = 1000.obs;

  var puntosRegistro = 50.obs;
  var puntosCompra = 1.obs; // por cada EUR
  var puntosReferido = 150.obs;

  // Flags antifraude
  var validarDuplicados = true.obs;
  var validarReferidos = true.obs;

  // Métodos para actualizar valores
  void setLimitePorPedido(int valor) => limitePorPedido.value = valor;
  void setCaducidadMeses(int valor) => caducidadMeses.value = valor;
  void setMaximoPorCampania(int valor) => maximoPorCampania.value = valor;

  void setPuntosRegistro(int valor) => puntosRegistro.value = valor;
  void setPuntosCompra(int valor) => puntosCompra.value = valor;
  void setPuntosReferido(int valor) => puntosReferido.value = valor;

  void toggleValidarDuplicados(bool valor) => validarDuplicados.value = valor;
  void toggleValidarReferidos(bool valor) => validarReferidos.value = valor;

  // Guardar configuración (stub, se conecta al backend)
  Future<void> guardarConfiguracion() async {
    debugPrint("Guardando configuración...");
    debugPrint("Límite por pedido: ${limitePorPedido.value}");
    debugPrint("Caducidad: ${caducidadMeses.value} meses");
    debugPrint("Máximo por campaña: ${maximoPorCampania.value}");
    debugPrint("Puntos registro: ${puntosRegistro.value}");
    debugPrint("Puntos compra: ${puntosCompra.value}");
    debugPrint("Puntos referido: ${puntosReferido.value}");
    debugPrint("Antifraude duplicados: ${validarDuplicados.value}");
    debugPrint("Antifraude referidos: ${validarReferidos.value}");
  }
}
