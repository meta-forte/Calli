package com.ibhatech.hanzislate.services

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import com.ibhatech.hanzislate.models.CharacterItem
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale
import java.util.UUID

class AudioPlayerService(context: Context) {
    private val _isPlaying = MutableStateFlow(false)
    val isPlayingFlow: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private var tts: TextToSpeech? = null
    private var isReady: Boolean = false

    init {
        tts = TextToSpeech(context.applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = tts?.setLanguage(Locale.SIMPLIFIED_CHINESE)
                if (result != TextToSpeech.LANG_MISSING_DATA && result != TextToSpeech.LANG_NOT_SUPPORTED) {
                    isReady = true
                } else {
                    tts?.setLanguage(Locale.CHINESE)
                    isReady = true
                }
                tts?.setSpeechRate(0.84f)
                tts?.setPitch(1.0f)
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {
                        _isPlaying.value = true
                    }

                    override fun onDone(utteranceId: String?) {
                        _isPlaying.value = false
                    }

                    @Deprecated("Deprecated in Java")
                    override fun onError(utteranceId: String?) {
                        _isPlaying.value = false
                    }

                    override fun onStop(utteranceId: String?, interrupted: Boolean) {
                        _isPlaying.value = false
                    }
                })
            }
        }
    }

    fun playPronunciation(character: CharacterItem) {
        val engine = tts ?: return
        if (!isReady) return
        if (engine.isSpeaking) {
            engine.stop()
        }
        _isPlaying.value = true
        val utteranceId = UUID.randomUUID().toString()
        engine.speak(character.hanzi, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
    }

    fun stop() {
        val engine = tts ?: return
        if (engine.isSpeaking) {
            engine.stop()
        }
        _isPlaying.value = false
    }

    fun shutdown() {
        tts?.stop()
        tts?.shutdown()
        tts = null
        _isPlaying.value = false
    }
}
