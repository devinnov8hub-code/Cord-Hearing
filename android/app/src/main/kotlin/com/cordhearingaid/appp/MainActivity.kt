package com.cordhearingaid.app

import android.annotation.SuppressLint
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val otaChannelName = "com.cordhearingaid.app/ota_file_picker"
    private val audioChannelName = "com.cordhearingaid.app/bluetooth_audio"
    private val pickFirmwareRequestCode = 9401
    private var pendingResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        // BluetoothProfile constants for Hearing Aid (ASHA) and LE Audio
        private const val PROFILE_HEADSET = BluetoothProfile.HEADSET // 1
        private const val PROFILE_A2DP = BluetoothProfile.A2DP // 2
        private const val PROFILE_HEARING_AID = 21 // BluetoothProfile.HEARING_AID (API 29+)
        private const val PROFILE_LE_AUDIO = 22 // BluetoothProfile.LE_AUDIO (API 33+)
        private const val CONNECTION_POLICY_ALLOWED = 100
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, otaChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "pickFirmwareFile") {
                    if (pendingResult != null) {
                        result.error("BUSY", "File picker is already active", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    startActivityForResult(intent, pickFirmwareRequestCode)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureBondAndConnectAudio" -> {
                        val address = call.argument<String>("address")
                        if (address.isNullOrBlank()) {
                            result.error("INVALID_ARG", "Device MAC address is required", null)
                            return@setMethodCallHandler
                        }
                        val status = ensureBondAndConnectAudio(address)
                        result.success(status)
                    }
                    "routeAudioToHearingAid" -> {
                        val address = call.argument<String>("address")
                        val routed = routeAudioToHearingAid(address)
                        result.success(routed)
                    }
                    "isAudioRouted" -> {
                        val address = call.argument<String>("address")
                        result.success(isHearingAidAudioActive(address))
                    }
                    "getAudioConnectedDevices" -> {
                        result.success(getAudioConnectedDeviceAddresses())
                    }
                    "openBluetoothSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.localizedMessage, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @SuppressLint("MissingPermission")
    private fun ensureBondAndConnectAudio(address: String): Map<String, Any> {
        val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = btManager?.adapter
        if (adapter == null || !BluetoothAdapter.checkBluetoothAddress(address)) {
            return mapOf(
                "bonded" to false,
                "audioOutputConnected" to false
            )
        }

        val device: BluetoothDevice = try {
            adapter.getRemoteDevice(address)
        } catch (_: Exception) {
            return mapOf(
                "bonded" to false,
                "audioOutputConnected" to false
            )
        }

        var bondInitiated = false
        val currentBondState = try {
            device.bondState
        } catch (_: SecurityException) {
            BluetoothDevice.BOND_NONE
        }

        if (currentBondState == BluetoothDevice.BOND_NONE) {
            try {
                bondInitiated = device.createBond()
            } catch (_: Exception) {
            }
        }

        // Trigger OS-level audio profile connections (ASHA Hearing Aid, LE Audio, A2DP, HFP)
        connectSystemAudioProfiles(adapter, device)

        // Schedule follow-up audio routing passes once async profile connection completes
        mainHandler.postDelayed({
            connectSystemAudioProfiles(adapter, device)
            routeAudioToHearingAid(address)
        }, 1200L)

        mainHandler.postDelayed({
            routeAudioToHearingAid(address)
        }, 2500L)

        val audioActive = routeAudioToHearingAid(address)
        return mapOf(
            "bonded" to (currentBondState == BluetoothDevice.BOND_BONDED),
            "bondState" to currentBondState,
            "bondInitiated" to bondInitiated,
            "audioOutputConnected" to audioActive
        )
    }

    @SuppressLint("MissingPermission")
    private fun connectSystemAudioProfiles(adapter: BluetoothAdapter, device: BluetoothDevice) {
        val profilesToTry = mutableListOf(
            PROFILE_HEARING_AID,
            PROFILE_A2DP,
            PROFILE_HEADSET
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            profilesToTry.add(0, PROFILE_LE_AUDIO)
        }

        for (profileId in profilesToTry) {
            try {
                adapter.getProfileProxy(
                    applicationContext,
                    object : BluetoothProfile.ServiceListener {
                        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
                            try {
                                allowAndConnectProfileProxy(adapter, proxy, device)
                            } catch (_: Throwable) {
                            } finally {
                                mainHandler.postDelayed({
                                    try {
                                        adapter.closeProfileProxy(profile, proxy)
                                    } catch (_: Throwable) {
                                    }
                                }, 1500L)
                            }
                        }

                        override fun onServiceDisconnected(profile: Int) {}
                    },
                    profileId
                )
            } catch (_: Throwable) {
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun allowAndConnectProfileProxy(
        adapter: BluetoothAdapter,
        proxy: BluetoothProfile,
        device: BluetoothDevice
    ) {
        val proxyClass = proxy.javaClass

        // 1. Ensure connection policy / priority is allowed on the profile proxy
        try {
            val setPolicy = proxyClass.getMethod(
                "setConnectionPolicy",
                BluetoothDevice::class.java,
                Int::class.javaPrimitiveType
            )
            setPolicy.isAccessible = true
            setPolicy.invoke(proxy, device, CONNECTION_POLICY_ALLOWED)
        } catch (_: Throwable) {
            try {
                val setPriority = proxyClass.getMethod(
                    "setPriority",
                    BluetoothDevice::class.java,
                    Int::class.javaPrimitiveType
                )
                setPriority.isAccessible = true
                setPriority.invoke(proxy, device, CONNECTION_POLICY_ALLOWED)
            } catch (_: Throwable) {
            }
        }

        // 2. Connect the profile if not already connected
        val state = try {
            proxy.getConnectionState(device)
        } catch (_: Throwable) {
            BluetoothProfile.STATE_DISCONNECTED
        }

        if (state != BluetoothProfile.STATE_CONNECTED &&
            state != BluetoothProfile.STATE_CONNECTING
        ) {
            try {
                val connectMethod = proxyClass.getMethod("connect", BluetoothDevice::class.java)
                connectMethod.isAccessible = true
                connectMethod.invoke(proxy, device)
            } catch (_: Throwable) {
            }
        }

        // 3. Mark the device as the active audio device for media & calls
        try {
            val setActive = proxyClass.getMethod("setActiveDevice", BluetoothDevice::class.java)
            setActive.isAccessible = true
            setActive.invoke(proxy, device)
        } catch (_: Throwable) {
        }

        // Android 10+ BluetoothAdapter.setActiveDevice(device, ACTIVE_DEVICE_ALL = 2)
        try {
            val adapterSetActive = adapter.javaClass.getMethod(
                "setActiveDevice",
                BluetoothDevice::class.java,
                Int::class.javaPrimitiveType
            )
            adapterSetActive.isAccessible = true
            adapterSetActive.invoke(adapter, device, 2) // 2 = ACTIVE_DEVICE_ALL
        } catch (_: Throwable) {
        }
    }

    private fun routeAudioToHearingAid(address: String?): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false

        val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        val matchingDevice = outputs.firstOrNull { info ->
            isHearingAidOrBleAudioType(info.type) &&
                (address.isNullOrBlank() ||
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.P ||
                    info.address.isNullOrBlank() ||
                    info.address.equals(address, ignoreCase = true))
        } ?: outputs.firstOrNull { info ->
            isHearingAidOrBleAudioType(info.type)
        }

        if (matchingDevice != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                try {
                    val commDevices = audioManager.availableCommunicationDevices
                    val commTarget = commDevices.firstOrNull { d ->
                        d.id == matchingDevice.id || isHearingAidOrBleAudioType(d.type)
                    }
                    if (commTarget != null) {
                        audioManager.setCommunicationDevice(commTarget)
                    }
                } catch (_: Throwable) {
                }
            }
            return true
        }
        return false
    }

    private fun isHearingAidAudioActive(address: String?): Boolean {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false

        val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        return outputs.any { info ->
            isHearingAidOrBleAudioType(info.type) &&
                (address.isNullOrBlank() ||
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.P ||
                    info.address.isNullOrBlank() ||
                    info.address.equals(address, ignoreCase = true))
        }
    }

    private fun getAudioConnectedDeviceAddresses(): List<String> {
        val addresses = linkedSetOf<String>()
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        if (audioManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (info in outputs) {
                if (isHearingAidOrBleAudioType(info.type) && !info.address.isNullOrBlank()) {
                    addresses.add(info.address)
                }
            }
        }
        return addresses.toList()
    }

    private fun isHearingAidOrBleAudioType(type: Int): Boolean {
        if (type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
            type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO
        ) {
            return true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            type == AudioDeviceInfo.TYPE_HEARING_AID
        ) {
            return true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            (type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                type == AudioDeviceInfo.TYPE_BLE_SPEAKER)
        ) {
            return true
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            type == AudioDeviceInfo.TYPE_BLE_BROADCAST
        ) {
            return true
        }
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickFirmwareRequestCode) return

        val callback = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            callback.success(null)
            return
        }

        val uri: Uri = data.data!!
        try {
            val fileName = resolveDisplayName(uri) ?: uri.lastPathSegment ?: "firmware.bin"
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes == null) {
                callback.error("READ_ERROR", "Unable to read selected file", null)
                return
            }
            callback.success(
                mapOf(
                    "name" to fileName,
                    "bytes" to bytes
                )
            )
        } catch (e: Exception) {
            callback.error("READ_ERROR", e.localizedMessage ?: "Failed to read file", null)
        }
    }

    private fun resolveDisplayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) {
                        return cursor.getString(idx)
                    }
                }
            }
        return null
    }
}
