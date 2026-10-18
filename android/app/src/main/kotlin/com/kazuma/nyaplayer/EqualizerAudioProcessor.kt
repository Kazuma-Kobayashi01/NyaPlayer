package com.kazuma.nyaplayer

import android.util.Log
import androidx.media3.common.C
import androidx.media3.common.audio.AudioProcessor.AudioFormat
import androidx.media3.common.audio.BaseAudioProcessor
import androidx.media3.common.util.UnstableApi
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * ExoPlayer audio processor that runs [EqCore] on 16-bit and float PCM
 * (TECH_SPEC §4.7, M10-4). Higher integer depths arrive as float because the
 * audio sink is built with float output enabled (see `EqRenderersFactory`),
 * so FLAC 24-bit goes through without losing precision.
 *
 * Always active so toggling the EQ never reconfigures the audio sink; when the
 * EQ is off or flat the input is copied through unchanged.
 */
@UnstableApi
class EqualizerAudioProcessor : BaseAudioProcessor() {
    val core = EqCore()

    private var scratch = FloatArray(0)

    // Diagnostics (logcat tag NyaEq): once a second of audio, what went in and
    // how much of it clipped on the way out.
    private var diagFrames = 0L
    private var diagPeakIn = 0f
    private var diagClipped = 0L
    private var diagBuffers = 0

    override fun onConfigure(inputAudioFormat: AudioFormat): AudioFormat {
        Log.i(TAG, "onConfigure $inputAudioFormat")
        val supported = inputAudioFormat.encoding == C.ENCODING_PCM_16BIT ||
            inputAudioFormat.encoding == C.ENCODING_PCM_FLOAT
        if (!supported || inputAudioFormat.channelCount < 1) return AudioFormat.NOT_SET
        core.configure(inputAudioFormat.sampleRate, inputAudioFormat.channelCount)
        Log.i(TAG, "configure $inputAudioFormat")
        return inputAudioFormat
    }

    override fun onFlush() {
        // A seek or new item: stale filter tails would click.
        if (inputAudioFormat != AudioFormat.NOT_SET) {
            core.configure(inputAudioFormat.sampleRate, inputAudioFormat.channelCount)
        }
    }

    override fun queueInput(inputBuffer: ByteBuffer) {
        val size = inputBuffer.remaining()
        if (size == 0) return
        val output = replaceOutputBuffer(size)
        if (core.isIdle()) {
            output.put(inputBuffer)
            output.flip()
            return
        }
        // PCM is in native byte order, but a buffer straight from the decoder
        // may still carry ByteBuffer's default big-endian flag, which would
        // turn every 16-bit sample into noise.
        inputBuffer.order(ByteOrder.nativeOrder())
        val is16 = inputAudioFormat.encoding == C.ENCODING_PCM_16BIT
        val samples = size / (if (is16) 2 else 4)
        val frames = samples / inputAudioFormat.channelCount
        if (scratch.size < samples) scratch = FloatArray(samples)
        if (is16) {
            for (i in 0 until samples) scratch[i] = inputBuffer.getShort() / 32768f
        } else {
            for (i in 0 until samples) scratch[i] = inputBuffer.getFloat()
        }
        var peakIn = 0f
        for (i in 0 until samples) peakIn = maxOf(peakIn, Math.abs(scratch[i]))
        core.process(scratch, frames)
        var clipped = 0
        for (i in 0 until samples) if (Math.abs(scratch[i]) >= 1f) clipped++
        diagBuffers++
        diagFrames += frames
        diagPeakIn = maxOf(diagPeakIn, peakIn)
        diagClipped += clipped
        if (diagFrames >= inputAudioFormat.sampleRate) {
            Log.i(
                TAG,
                "processed ${diagFrames} frames in $diagBuffers buffers " +
                    "(${if (is16) "16-bit" else "float"}), peak in $diagPeakIn, " +
                    "clipped samples $diagClipped",
            )
            diagFrames = 0
            diagPeakIn = 0f
            diagClipped = 0
            diagBuffers = 0
        }
        if (is16) {
            for (i in 0 until samples) {
                val v = Math.round(scratch[i] * 32768f).coerceIn(-32768, 32767)
                output.putShort(v.toShort())
            }
        } else {
            for (i in 0 until samples) output.putFloat(scratch[i])
        }
        output.flip()
    }

    private companion object {
        const val TAG = "NyaEq"
    }
}
