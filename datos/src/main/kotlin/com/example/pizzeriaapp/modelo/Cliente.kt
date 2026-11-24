package com.example.pizzeriaapp.modelo

import com.example.pizzeriaapp.utilidades.validarNombre
import com.example.pizzeriaapp.utilidades.validarTelefono

data class Cliente(val nombre: String, val telefono: String) {
    init {
        validarNombre(nombre)
        validarTelefono(telefono)
    }
}
