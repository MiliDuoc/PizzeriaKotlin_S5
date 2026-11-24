package com.example.pizzeriaapp.modelo

data class Producto(
    val nombre: String,
    val precio: Double,
    val ingredientes: Map<String, Int>
) {
    init {
        require(nombre.isNotBlank()) {
            "El nombre del producto es obligatorio."
        }
        require(precio.isFinite() && precio >= 0) {
            "El precio debe ser vÃ¡lido y no negativo."
        }
        require(ingredientes.isNotEmpty() &&
                ingredientes.values.all { it in 1..100 }) {
            "Los ingredientes deben tener cantidades entre 1 y 100."
        }
    }

    fun detallarProducto(): String {
        val detalle = ingredientes.entries.joinToString(", ") {
            "${it.key}: ${it.value}"
        }

        return "$nombre | Precio: $$precio | Ingredientes: $detalle"
    }
}

