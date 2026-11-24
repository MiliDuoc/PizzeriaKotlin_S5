# Semana 5 - PizzeriaApp: modularizacion y resumen dinamico
# Colocar este archivo en la raiz de PizzeriaApp_S5 y ejecutar desde PowerShell.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Escribir([string]$ruta, [string]$contenido) {
    $destino = Join-Path $PSScriptRoot $ruta
    $carpeta = Split-Path $destino -Parent
    if (!(Test-Path $carpeta)) { New-Item -ItemType Directory -Path $carpeta -Force | Out-Null }
    [System.IO.File]::WriteAllText($destino, $contenido.TrimStart("`r", "`n") + "`n", $utf8)
    Write-Host "Creado/actualizado: $ruta"
}
if (!(Test-Path '.\app\build.gradle.kts') -or !(Test-Path '.\gradle\libs.versions.toml')) {
    throw 'Ejecuta este script dentro de la carpeta PizzeriaApp_S5, que debe contener app y gradle/libs.versions.toml.'
}
$catalogo = Get-Content '.\gradle\libs.versions.toml' -Raw
$m = [regex]::Match($catalogo, '(?m)^\s*kotlin\s*=\s*"([0-9][^\"]*)"')
if (!$m.Success) { throw 'No se encontro la version kotlin en gradle/libs.versions.toml. No se modifico el proyecto.' }
$kotlin = $m.Groups[1].Value
Write-Host "Version Kotlin existente: $kotlin"

# Conservar y trasladar clases de Semana 4 sin reescribir su logica.
$modelosOrigen = 'app\src\main\java\com\example\pizzeriaapp\modelo'
$modelosDestino = 'datos\src\main\kotlin\com\example\pizzeriaapp\modelo'
foreach ($nombre in @('Usuario.kt','Producto.kt','Pedido.kt')) {
    $origen = Join-Path $modelosOrigen $nombre
    if (!(Test-Path $origen)) { throw "Falta $origen. Verifica que copiaste el proyecto de Semana 4." }
}

$settings = Get-Content '.\settings.gradle.kts' -Raw
$settings = $settings -replace 'rootProject\.name\s*=\s*"[^"]+"', 'rootProject.name = "PizzeriaApp_S5"'
if ($settings -notmatch 'include\(":datos"\)') { $settings += "`ninclude(`":datos`")`n" }
if ($settings -notmatch 'include\(":utilidades"\)') { $settings += "include(`":utilidades`")`n" }
Escribir 'settings.gradle.kts' $settings

$rootGradle = Get-Content '.\build.gradle.kts' -Raw
if ($rootGradle -notmatch 'org\.jetbrains\.kotlin\.jvm') {
    $rootGradle = $rootGradle -replace 'plugins\s*\{', "plugins {`n    id(`"org.jetbrains.kotlin.jvm`") version `"$kotlin`" apply false"
}
Escribir 'build.gradle.kts' $rootGradle

Escribir 'utilidades/build.gradle.kts' @'
plugins {
    id("org.jetbrains.kotlin.jvm")
}
kotlin {
    jvmToolchain(17)
}
'@
Escribir 'datos/build.gradle.kts' @'
plugins {
    id("org.jetbrains.kotlin.jvm")
}
kotlin {
    jvmToolchain(17)
}
dependencies {
    implementation(project(":utilidades"))
}
'@

foreach ($nombre in @('Usuario.kt','Producto.kt','Pedido.kt')) {
    $contenido = Get-Content (Join-Path $modelosOrigen $nombre) -Raw
    $contenido = $contenido -replace 'package\s+com\.example\.pizzeriaapp\.modelo', 'package com.example.pizzeriaapp.modelo'
    Escribir (Join-Path $modelosDestino $nombre) $contenido
}
# Retirar los originales para que no existan clases duplicadas entre modulos.
foreach ($nombre in @('Usuario.kt','Producto.kt','Pedido.kt')) {
    Remove-Item -Path (Join-Path $modelosOrigen $nombre) -Force
}

Escribir 'utilidades/src/main/kotlin/com/example/pizzeriaapp/utilidades/Validaciones.kt' @'
package com.example.pizzeriaapp.utilidades

fun validarNombre(nombre: String) {
    require(nombre.trim().length >= 2) { "El nombre debe tener al menos 2 caracteres." }
}

fun validarTelefono(telefono: String) {
    require(Regex("^\\d{9}$").matches(telefono.trim())) {
        "El teléfono debe contener exactamente 9 dígitos."
    }
}

fun formatoCLP(monto: Double): String =
    "$" + java.text.NumberFormat.getIntegerInstance(java.util.Locale("es", "CL"))
        .format(kotlin.math.round(monto).toLong())
'@

Escribir 'datos/src/main/kotlin/com/example/pizzeriaapp/modelo/Cliente.kt' @'
package com.example.pizzeriaapp.modelo

import com.example.pizzeriaapp.utilidades.validarNombre
import com.example.pizzeriaapp.utilidades.validarTelefono

data class Cliente(val nombre: String, val telefono: String) {
    init {
        validarNombre(nombre)
        validarTelefono(telefono)
    }
}
'@

Escribir 'datos/src/main/kotlin/com/example/pizzeriaapp/datos/PizzeriaRepositorio.kt' @'
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
        registrarCliente("María González", "999999999")
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
'@

$gradleApp = Get-Content '.\app\build.gradle.kts' -Raw
if ($gradleApp -notmatch 'project\(":datos"\)') {
    $dependencias = @'
    implementation(project(":datos"))
    implementation(project(":utilidades"))
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.9.4")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.9.4")
    implementation("androidx.compose.runtime:runtime-livedata")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
'@
    $gradleApp = $gradleApp -replace 'dependencies\s*\{', ("dependencies {`n" + $dependencias)
}
Escribir 'app/build.gradle.kts' $gradleApp

Escribir 'app/src/main/java/com/example/pizzeriaapp/PizzeriaViewModel.kt' @'
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
                    ?: throw IllegalArgumentException("Ingresa una cantidad válida.")
                repositorio.registrarPedido(cantidad)
            }.onSuccess { _mensaje.value = "Pedido registrado correctamente." }
                .onFailure { _mensaje.value = it.message ?: "No se pudo registrar el pedido." }
            _resumen.value = repositorio.resumen()
        }
    }
}
'@

Escribir 'app/src/main/java/com/example/pizzeriaapp/MainActivity.kt' @'
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
            Text("Bienvenidos a la mejor pizzería de la ciudad", style = MaterialTheme.typography.headlineSmall)
            Text("Semana 5 · PizzeriaApp", style = MaterialTheme.typography.titleMedium)
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
                label = { Text("Teléfono (9 dígitos)") },
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
                Text("Últimos pedidos", style = MaterialTheme.typography.titleMedium)
                datos.pedidosRecientes.forEach { pedido ->
                    Card(modifier = Modifier.fillMaxWidth()) {
                        Text(
                            "Pedido #${pedido.id} · ${pedido.cantidad} pizza(s) · ${formatoCLP(pedido.calcularTotal())}",
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
            Text("Último cliente: ${datos.ultimoCliente}")
        }
    }
}
'@

Write-Host "`nProyecto de Semana 5 preparado. Sincroniza Gradle y ejecuta la app." -ForegroundColor Green
Write-Host 'Los 3 modulos son app (UI), datos (negocio) y utilidades (funciones).'
