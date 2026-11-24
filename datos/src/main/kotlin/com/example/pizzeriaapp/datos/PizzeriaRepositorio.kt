package com.example.pizzeriaapp.datos

import com.example.pizzeriaapp.modelo.Cliente
import com.example.pizzeriaapp.modelo.Pedido
import com.example.pizzeriaapp.modelo.Producto

data class ResumenPizzeria(
    val totalClientes: Int,
    val totalPedidos: Int,
    val ultimoCliente: String,
    val pedidosRecientes: List<Pedido>
)

class PizzeriaRepositorio {
    private val clientes = mutableListOf<Cliente>()
    private val pedidos = mutableListOf<Pedido>()
    private val pizza = Producto(
        nombre = "Pepperoni",
        precio = 12000.0,
        ingredientes = mapOf("Masa" to 1, "Queso" to 2, "Pepperoni" to 3)
    )

    init {
        registrarCliente("MarÃ­a GonzÃ¡lez", "999999999")
        registrarPedido(4)
    }

    fun registrarCliente(nombre: String, telefono: String) {
        clientes.add(Cliente(nombre.trim(), telefono.trim()))
    }

    fun registrarPedido(cantidad: Int) {
        require(clientes.isNotEmpty()) { "Primero debes registrar un cliente." }
        pedidos.add(Pedido(id = pedidos.size + 1, producto = pizza, cantidad = cantidad))
    }

    fun resumen(): ResumenPizzeria = ResumenPizzeria(
        totalClientes = clientes.size,
        totalPedidos = pedidos.size,
        ultimoCliente = clientes.lastOrNull()?.nombre ?: "Sin clientes",
        pedidosRecientes = pedidos.takeLast(5).reversed()
    )
}
