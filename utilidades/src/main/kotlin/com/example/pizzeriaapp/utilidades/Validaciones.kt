package com.example.pizzeriaapp.utilidades

fun validarNombre(nombre: String) {
    require(nombre.trim().length >= 2) { "El nombre debe tener al menos 2 caracteres." }
}

fun validarTelefono(telefono: String) {
    require(Regex("^\\d{9}$").matches(telefono.trim())) {
        "El telÃ©fono debe contener exactamente 9 dÃ­gitos."
    }
}

fun formatoCLP(monto: Double): String =
    "$" + java.text.NumberFormat.getIntegerInstance(java.util.Locale("es", "CL"))
        .format(kotlin.math.round(monto).toLong())
