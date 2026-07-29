package com.dartsistemas.foodtabletapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Modo quiosque: fixa o app na tela via Screen Pinning nativo do Android
// (startLockTask), pra impedir que o cliente saia do app de autoatendimento
// e mexa livremente no tablet. exitKiosk() so e' chamado do lado Flutter
// depois que o usuario confirma o PIN das configuracoes.
class MainActivity : FlutterActivity() {
    private val CHANNEL = "br.com.dartsoft.dartchef/kiosk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterKiosk" -> {
                    try {
                        startLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "exitKiosk" -> {
                    try {
                        stopLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        try {
            startLockTask()
        } catch (e: Exception) {
            // Screen Pinning pode nao estar disponivel em todo aparelho/versao.
        }
    }
}
