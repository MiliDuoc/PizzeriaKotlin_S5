package com.example.pizzeriaapp

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.pizzeriaapp.datos.PizzeriaRepositorio
import com.example.pizzeriaapp.datos.ResumenPizzeria
import kotlinx.coroutines.launch

class PizzeriaViewModel : ViewModel() {
    private val repositorio = PizzeriaRepositorio()
    private val _resumen = MutableLiveData(repositorio.resumen())
    val resumen: LiveData<ResumenPizzeria> = _resumen
    private val _mensaje = MutableLiveData("")
    val mensaje: LiveData<String> = _mensaje

    fun registrarCliente(nombre: String, telefono: String) {
        viewModelScope.launch {
            runCatching { repositorio.registrarCliente(nombre, telefono) }
                .onSuccess { _mensaje.value = "Cliente registrado correctamente." }
                .onFailure { _mensaje.value = it.message ?: "No se pudo registrar el cliente." }
            _resumen.value = repositorio.resumen()
        }
    }

    fun registrarPedido(cantidadTexto: String) {
        viewModelScope.launch {
            runCatching {
                val cantidad = cantidadTexto.toIntOrNull()
                    ?: throw IllegalArgumentException("Ingresa una cantidad vÃ¡lida.")
                repositorio.registrarPedido(cantidad)
            }.onSuccess { _mensaje.value = "Pedido registrado correctamente." }
                .onFailure { _mensaje.value = it.message ?: "No se pudo registrar el pedido." }
            _resumen.value = repositorio.resumen()
        }
    }
}
