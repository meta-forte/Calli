package com.ibhatech.hanzislate.services

import com.ibhatech.hanzislate.models.FileResourceLoader
import com.ibhatech.hanzislate.models.ResourceLoader
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import java.net.HttpURLConnection
import java.net.URI
import kotlin.math.max

object PropertyConfig {
    fun loadProperties(named: String, resourceLoader: ResourceLoader = FileResourceLoader()): Map<String, String> {
        val content = resourceLoader.loadText("$named.properties") ?: return emptyMap()
        return parse(content)
    }

    fun parse(content: String): Map<String, String> {
        val result = mutableMapOf<String, String>()
        for (line in content.lines()) {
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("#") || trimmed.startsWith("!")) {
                continue
            }
            val separatorIndex = trimmed.indexOf('=')
            if (separatorIndex >= 0) {
                val key = trimmed.substring(0, separatorIndex).trim()
                val value = trimmed.substring(separatorIndex + 1).trim()
                result[key] = value
            }
        }
        return result
    }
}

class AppVersion(versionString: String) : Comparable<AppVersion> {
    val components: List<Int> = versionString.trim()
        .split('.')
        .mapNotNull { it.toIntOrNull() }

    override fun compareTo(other: AppVersion): Int {
        val maxCount = max(components.size, other.components.size)
        for (i in 0 until maxCount) {
            val left = if (i < components.size) components[i] else 0
            val right = if (i < other.components.size) other.components[i] else 0
            if (left != right) {
                return left.compareTo(right)
            }
        }
        return 0
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is AppVersion) return false
        return compareTo(other) == 0
    }

    override fun hashCode(): Int {
        val trimmed = components.dropLastWhile { it == 0 }
        return trimmed.hashCode()
    }
}

data class AppUpdateInfo(
    val latestVersion: String,
    val minSupportedVersion: String? = null,
    val releaseNotes: String? = null,
    val appStoreUrl: String? = null,
    val forceUpdate: Boolean? = null
) {
    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        fun decodeFromJson(rawJson: String): AppUpdateInfo {
            val obj = json.decodeFromString<JsonObject>(rawJson)
            fun str(vararg keys: String): String? {
                for (k in keys) {
                    val v = obj[k]?.jsonPrimitive?.contentOrNull
                    if (!v.isNullOrEmpty()) return v
                }
                return null
            }
            fun bool(vararg keys: String): Boolean? {
                for (k in keys) {
                    val v = obj[k]?.jsonPrimitive?.booleanOrNull
                    if (v != null) return v
                }
                return null
            }

            return AppUpdateInfo(
                latestVersion = str("latest_version", "latestVersion") ?: "1.0.0",
                minSupportedVersion = str("min_supported_version", "minSupportedVersion", "minimum_version"),
                releaseNotes = str("release_notes", "releaseNotes", "message"),
                appStoreUrl = str("app_store_url", "appStoreUrl", "store_url"),
                forceUpdate = bool("force_update", "forceUpdate")
            )
        }
    }
}

class AppUpdateService(
    val currentVersionString: String = "1.0.0",
    private val resourceLoader: ResourceLoader = FileResourceLoader(),
    var urlOpener: ((String) -> Unit)? = null
) {
    private val _updateInfo = MutableStateFlow<AppUpdateInfo?>(null)
    val updateInfoFlow: StateFlow<AppUpdateInfo?> = _updateInfo.asStateFlow()
    val updateInfo: AppUpdateInfo?
        get() = _updateInfo.value

    private val _isChecking = MutableStateFlow(false)
    val isCheckingFlow: StateFlow<Boolean> = _isChecking.asStateFlow()
    val isChecking: Boolean
        get() = _isChecking.value

    private val _isForcedUpdate = MutableStateFlow(false)
    val isForcedUpdateFlow: StateFlow<Boolean> = _isForcedUpdate.asStateFlow()
    val isForcedUpdate: Boolean
        get() = _isForcedUpdate.value

    private val _isOptionalUpdate = MutableStateFlow(false)
    val isOptionalUpdateFlow: StateFlow<Boolean> = _isOptionalUpdate.asStateFlow()
    val isOptionalUpdate: Boolean
        get() = _isOptionalUpdate.value

    private val _showUpdateSheet = MutableStateFlow(false)
    val showUpdateSheetFlow: StateFlow<Boolean> = _showUpdateSheet.asStateFlow()
    var showUpdateSheet: Boolean
        get() = _showUpdateSheet.value
        set(value) { _showUpdateSheet.value = value }

    private val _hasUnreadUpdate = MutableStateFlow(false)
    val hasUnreadUpdateFlow: StateFlow<Boolean> = _hasUnreadUpdate.asStateFlow()
    val hasUnreadUpdate: Boolean
        get() = _hasUnreadUpdate.value

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessageFlow: StateFlow<String?> = _errorMessage.asStateFlow()
    val errorMessage: String?
        get() = _errorMessage.value

    val configuredUpdateURL: String?
        get() {
            val appConfig = PropertyConfig.loadProperties("AppConfig", resourceLoader)
            val metadata = PropertyConfig.loadProperties("AppStoreMetadata", resourceLoader)
            val rawURL = appConfig["update_check_url"]
                ?: appConfig["app.update_check_url"]
                ?: metadata["app.update_check_url"]
                ?: metadata["update_check_url"]
                ?: "http://localhost:8000"

            return try {
                val uri = URI(rawURL)
                val path = uri.path ?: ""
                if (path.isEmpty() || path == "/") {
                    rawURL.trimEnd('/') + "/version.json"
                } else {
                    rawURL
                }
            } catch (_: Exception) {
                null
            }
        }

    val appStoreURL: String
        get() {
            val customUrl = _updateInfo.value?.appStoreUrl
            if (!customUrl.isNullOrEmpty()) {
                return customUrl
            }
            val appConfig = PropertyConfig.loadProperties("AppConfig", resourceLoader)
            val metadata = PropertyConfig.loadProperties("AppStoreMetadata", resourceLoader)
            return appConfig["app_store_url"]
                ?: metadata["app.store_url"]
                ?: "https://play.google.com/store"
        }

    suspend fun checkForUpdates(customURL: String? = null) {
        val urlString = customURL ?: configuredUpdateURL ?: return
        _isChecking.value = true
        _errorMessage.value = null

        try {
            val responseBody = withContext(Dispatchers.IO) {
                val conn = URI(urlString).toURL().openConnection() as HttpURLConnection
                conn.connectTimeout = 5000
                conn.readTimeout = 5000
                conn.useCaches = false
                conn.requestMethod = "GET"
                val code = conn.responseCode
                if (code != 200) {
                    throw IllegalStateException("Server returned status $code")
                }
                conn.inputStream.bufferedReader(Charsets.UTF_8).use { it.readText() }
            }
            val info = AppUpdateInfo.decodeFromJson(responseBody)
            evaluateUpdate(info)
        } catch (e: Exception) {
            _errorMessage.value = e.message ?: "Unable to check for updates"
        } finally {
            _isChecking.value = false
        }
    }

    fun evaluateUpdate(info: AppUpdateInfo) {
        _updateInfo.value = info
        val current = AppVersion(currentVersionString)
        val latest = AppVersion(info.latestVersion)

        val minVersionString = info.minSupportedVersion
        if (!minVersionString.isNullOrEmpty()) {
            val minVersion = AppVersion(minVersionString)
            if (current < minVersion) {
                _isForcedUpdate.value = true
                _isOptionalUpdate.value = false
                _hasUnreadUpdate.value = true
                return
            }
        }

        if (info.forceUpdate == true && current < latest) {
            _isForcedUpdate.value = true
            _isOptionalUpdate.value = false
            _hasUnreadUpdate.value = true
            return
        }

        if (current < latest) {
            _isForcedUpdate.value = false
            _isOptionalUpdate.value = true
            _hasUnreadUpdate.value = true
        } else {
            _isForcedUpdate.value = false
            _isOptionalUpdate.value = false
            _hasUnreadUpdate.value = false
        }
    }

    fun dismissOptionalNotice() {
        _showUpdateSheet.value = false
        _hasUnreadUpdate.value = false
    }

    fun openAppStore() {
        urlOpener?.invoke(appStoreURL)
    }
}
