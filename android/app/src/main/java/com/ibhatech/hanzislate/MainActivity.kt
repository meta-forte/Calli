package com.ibhatech.hanzislate

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Modifier
import com.ibhatech.hanzislate.models.AssetResourceLoader
import com.ibhatech.hanzislate.models.CharacterStore
import com.ibhatech.hanzislate.models.SharedPreferencesStore
import com.ibhatech.hanzislate.services.AppUpdateService
import com.ibhatech.hanzislate.services.AudioPlayerService
import com.ibhatech.hanzislate.services.PracticeStorageService
import com.ibhatech.hanzislate.ui.AppColors
import com.ibhatech.hanzislate.ui.CharacterGridScreen

class MainActivity : ComponentActivity() {
    private lateinit var prefs: SharedPreferencesStore
    private lateinit var store: CharacterStore
    private lateinit var updateService: AppUpdateService
    private lateinit var audioService: AudioPlayerService
    private lateinit var practiceStorage: PracticeStorageService

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val resourceLoader = AssetResourceLoader(applicationContext)
        prefs = SharedPreferencesStore(applicationContext)
        store = CharacterStore(
            prefs = prefs,
            resourceLoader = resourceLoader,
            loadBundledData = true
        )
        updateService = AppUpdateService(
            currentVersionString = BuildConfig.VERSION_NAME,
            resourceLoader = resourceLoader,
            urlOpener = { url ->
                runCatching {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                }
            }
        )
        audioService = AudioPlayerService(applicationContext)
        practiceStorage = PracticeStorageService.create(applicationContext)

        setContent {
            MaterialTheme(
                colorScheme = lightColorScheme(
                    primary = AppColors.AccentBlue,
                    background = AppColors.AppBackground,
                    surface = AppColors.AppBackground
                )
            ) {
                LaunchedEffect(Unit) {
                    updateService.checkForUpdates()
                }
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .statusBarsPadding()
                ) {
                    CharacterGridScreen(
                        store = store,
                        prefs = prefs,
                        updateService = updateService,
                        audioService = audioService,
                        practiceStorage = practiceStorage
                    )
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        audioService.shutdown()
        practiceStorage.close()
    }
}
