package com.dartsistemas.foodtabletapp

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// Modo quiosque: fixa o app na tela via Screen Pinning nativo do Android
// (startLockTask), pra impedir que o cliente saia do app de autoatendimento
// e mexa livremente no tablet. exitKiosk() so e' chamado do lado Flutter
// depois que o usuario confirma o PIN das configuracoes.
class MainActivity : FlutterActivity() {
    private val CHANNEL = "br.com.dartsoft.dartchef/kiosk"

    // Quando o Flutter pede pra sair do quiosque (instalar atualizacao, ou
    // "Sair do app"), o onResume NAO pode re-fixar a tela - senao o Android
    // joga o instalador pra tras assim que ele abre.
    private var kioskEnabled = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterKiosk" -> {
                    kioskEnabled = true
                    try {
                        startLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "exitKiosk" -> {
                    kioskEnabled = false
                    try {
                        stopLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "canInstallApks" -> {
                    result.success(canInstallApks())
                }
                "requestInstallPermission" -> {
                    kioskEnabled = false
                    try {
                        stopLockTask()
                    } catch (_: Exception) {
                    }
                    requestInstallPermission()
                    result.success(true)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("bad_path", "Caminho do APK vazio.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        kioskEnabled = false
                        try {
                            stopLockTask()
                        } catch (_: Exception) {
                        }
                        installApk(path)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("install_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun canInstallApks(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists() || file.length() < 1024) {
            throw IllegalStateException("APK baixado está vazio ou incompleto.")
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(intent)
    }

    override fun onResume() {
        super.onResume()
        if (!kioskEnabled) return
        try {
            startLockTask()
        } catch (e: Exception) {
            // Screen Pinning pode nao estar disponivel em todo aparelho/versao.
        }
    }
}
