package com.example.pizzeriaapp.modelo

data class Pedido(
    val id: Int,
    val producto: Producto,
    val cantidad: Int,
    var estado: String = "Pendiente"
) {
    init {
        require(id > 0) {
            "El identificador debe ser positivo."
        }
        require(cantidad in 1..100) {
            "La cantidad debe estar entre 1 y 100."
        }
    }

    fun calcularSubtotal(): Double {
        return producto.precio * cantidad
    }

    fun calcularDescuento(): Double {
        return if (cantidad > 3) {
            calcularSubtotal() * 0.10
        } else {
            0.0
        }
    }

    fun calcularTotal(): Double {
        val neto = calcularSubtotal() - calcularDescuento()
        return neto * 1.19
    }

    fun mostrarResumen(): String {
        return """
            PEDIDO NÂ° $id
            Producto: ${producto.nombre}
            Cantidad: $cantidad
            Subtotal: $${calcularSubtotal().toInt()}
            Descuento: $${calcularDescuento().toInt()}
            Total con IVA: $${calcularTotal().toInt()}
            Estado: $estado
        """.trimIndent()
    }
}

