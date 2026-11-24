package com.example.pizzeriaapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModelProvider
import androidx.compose.runtime.livedata.observeAsState
import com.example.pizzeriaapp.datos.ResumenPizzeria
import com.example.pizzeriaapp.ui.theme.PizzeriaAppTheme
import com.example.pizzeriaapp.utilidades.formatoCLP

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val vm = ViewModelProvider(this)[PizzeriaViewModel::class.java]
        setContent {
            PizzeriaAppTheme {
                PantallaPizzeria(vm)
            }
        }
    }
}

@Composable
fun PantallaPizzeria(vm: PizzeriaViewModel) {
    val resumen by vm.resumen.observeAsState()
    val mensaje by vm.mensaje.observeAsState("")
    var nombre by remember { mutableStateOf("") }
    var telefono by remember { mutableStateOf("") }
    var cantidad by remember { mutableStateOf("1") }

    Scaffold(modifier = Modifier.fillMaxSize()) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(18.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text("Bienvenidos a la mejor pizzerÃ­a de la ciudad", style = MaterialTheme.typography.headlineSmall)
            Text("Semana 5 Â· PizzeriaApp", style = MaterialTheme.typography.titleMedium)
            resumen?.let { PanelResumen(it) }
            HorizontalDivider()
            Text("Registrar cliente", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(
                value = nombre,
                onValueChange = { nombre = it },
                label = { Text("Nombre del cliente") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            OutlinedTextField(
                value = telefono,
                onValueChange = { telefono = it },
                label = { Text("TelÃ©fono (9 dÃ­gitos)") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            Button(onClick = {
                vm.registrarCliente(nombre, telefono)
            }) { Text("Agregar cliente") }
            HorizontalDivider()
            Text("Registrar pedido de Pepperoni", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(
                value = cantidad,
                onValueChange = { cantidad = it },
                label = { Text("Cantidad de pizzas (1 a 100)") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            Button(onClick = { vm.registrarPedido(cantidad) }) {
                Text("Agregar pedido")
            }
            if (mensaje.isNotBlank()) {
                Text(mensaje, color = MaterialTheme.colorScheme.primary)
            }
            resumen?.let { datos ->
                HorizontalDivider()
                Text("Ãšltimos pedidos", style = MaterialTheme.typography.titleMedium)
                datos.pedidosRecientes.forEach { pedido ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            "Pedido #${pedido.id} Â· ${pedido.cantidad} pizza(s) Â· ${formatoCLP(pedido.calcularTotal())}",
                            modifier = Modifier.padding(12.dp)
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PanelResumen(datos: ResumenPizzeria) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text("Resumen actualizado", style = MaterialTheme.typography.titleLarge)
            Text("Total de clientes: ${datos.totalClientes}")
            Text("Total de pedidos: ${datos.totalPedidos}")
            Text("Ãšltimo cliente: ${datos.ultimoCliente}")
        }
    }
}
