package com.kazuma.nyaplayer

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sin

/**
 * 15-band peaking equalizer (TECH_SPEC §5.1), a port of `rust/src/dsp/eq.rs`
 * and of the macOS parametric bands so all platforms sound the same:
 *
 * * RBJ cookbook peaking biquads, 2/3 octave bandwidth (Q = 2.145), f32,
 *   Direct Form 2 Transposed, independent state per channel.
 * * Linear preamp applied before the filters.
 * * Untouched samples while disabled / flat.
 * * Settings changes are ramped over ~20 ms (coefficients recomputed per
 *   32-frame block, preamp interpolated per frame) to avoid clicks.
 *
 * Pure Kotlin on purpose (no Media3, no Android) so it can be unit-tested on
 * the JVM; [EqualizerAudioProcessor] wraps it for ExoPlayer.
 *
 * [set] may be called from any thread; [process] and [configure] belong to
 * the audio thread.
 */
class EqCore {
    /** Target values: disabled already folded into "all zero". */
    private class Target(val gainsDb: FloatArray, val preampDb: Float)

    @Volatile
    private var latest = Target(FloatArray(NUM_BANDS), 0f)
    private var seen = latest

    private var sampleRate = 44100
    private var channels = 2
    private var framesInBlock = 0

    // Filter state per channel and band: z1, z2.
    private val state = FloatArray(MAX_CHANNELS * NUM_BANDS * 2)
    private val b0 = FloatArray(NUM_BANDS)
    private val b1 = FloatArray(NUM_BANDS)
    private val b2 = FloatArray(NUM_BANDS)
    private val a1 = FloatArray(NUM_BANDS)
    private val a2 = FloatArray(NUM_BANDS)
    private val bandActive = BooleanArray(NUM_BANDS)
    private var anyBandActive = false

    // What is currently applied, and the ramp towards the target.
    private val curGains = FloatArray(NUM_BANDS)
    private var curPreampDb = 0f
    private val rampFromGains = FloatArray(NUM_BANDS)
    private var rampFromPreamp = 0f
    private var targetGains = FloatArray(NUM_BANDS)
    private var targetPreamp = 0f
    private var rampBlock = 0
    private var rampBlocks = 0

    private var preampLin = 1f
    private var preampStep = 0f
    private var preampBlockEnd = 1f

    private var bypass = true

    /** New settings; disabled behaves like flat. Short gain lists are padded. */
    fun set(enabled: Boolean, gainsDb: List<Double>, preampDb: Double) {
        val gains = FloatArray(NUM_BANDS)
        val preamp: Float
        if (enabled) {
            for (i in 0 until NUM_BANDS) {
                val g = gainsDb.getOrNull(i)?.toFloat() ?: 0f
                gains[i] = if (g.isFinite()) g else 0f
            }
            preamp = preampDb.toFloat().takeIf { it.isFinite() } ?: 0f
        } else {
            preamp = 0f
        }
        latest = Target(gains, preamp)
    }

    /** Stream format changed (or playback was flushed): restart the filters. */
    fun configure(sampleRate: Int, channels: Int) {
        this.sampleRate = sampleRate
        this.channels = channels
        if (isRamping()) {
            // Keep the ramp duration ~constant in time at the new rate.
            val t = rampBlock.toFloat() / rampBlocks
            rampBlocks = rampBlocksFor(sampleRate)
            rampBlock = min((t * rampBlocks).toInt(), rampBlocks - 1)
        }
        state.fill(0f)
        updateCoefficients(resetAll = true)
        framesInBlock = 0
        updateBypass()
    }

    /** True when [process] would leave every sample unchanged. */
    fun isIdle(): Boolean =
        latest === seen && !isRamping() && !anyBandActive &&
            abs(curPreampDb) < GAIN_EPSILON_DB && preampStep == 0f

    /** Filters [frames] interleaved frames of [buf] in place (floats in -1..1). */
    fun process(buf: FloatArray, frames: Int) {
        var pos = 0
        while (pos < frames) {
            if (framesInBlock == 0) controlBlock()
            val n = min(BLOCK_FRAMES - framesInBlock, frames - pos)
            if (!bypass) filterFrames(buf, pos, n)
            framesInBlock += n
            if (framesInBlock >= BLOCK_FRAMES) framesInBlock = 0
            pos += n
        }
    }

    private fun filterFrames(buf: FloatArray, from: Int, count: Int) {
        for (frame in from until from + count) {
            val base = frame * channels
            for (ch in 0 until channels) {
                var x = buf[base + ch] * preampLin
                if (ch < MAX_CHANNELS && anyBandActive) {
                    for (band in 0 until NUM_BANDS) {
                        if (!bandActive[band]) continue
                        val s = (ch * NUM_BANDS + band) * 2
                        val y = b0[band] * x + state[s]
                        state[s] = b1[band] * x - a1[band] * y + state[s + 1]
                        state[s + 1] = b2[band] * x - a2[band] * y
                        x = y
                    }
                    if (!x.isFinite()) {
                        for (band in 0 until NUM_BANDS) {
                            val s = (ch * NUM_BANDS + band) * 2
                            state[s] = 0f
                            state[s + 1] = 0f
                        }
                        x = 0f
                    }
                }
                buf[base + ch] = max(-1f, min(1f, x))
            }
            preampLin += preampStep
        }
    }

    private fun isRamping() = rampBlock < rampBlocks

    private fun rampBlocksFor(sampleRate: Int): Int {
        val rampFrames = max(RAMP_SECONDS * sampleRate, 1f)
        return max(ceil(rampFrames / BLOCK_FRAMES).toInt(), 1)
    }

    private fun updateBypass() {
        bypass = !isRamping() && !anyBandActive &&
            abs(curPreampDb) < GAIN_EPSILON_DB && preampStep == 0f
    }

    /**
     * Recomputes coefficients for [curGains]. Bands becoming active get their
     * state reset (a 0 dB peaking filter is an identity with zero state, so
     * this is continuous).
     */
    private fun updateCoefficients(resetAll: Boolean) {
        val fs = sampleRate.toDouble()
        var any = false
        for (band in 0 until NUM_BANDS) {
            val f0 = BAND_FREQUENCIES[band].toDouble()
            val gain = curGains[band]
            if (f0 < MAX_FREQ_RATIO * fs && abs(gain) >= GAIN_EPSILON_DB) {
                // RBJ cookbook peakingEQ.
                val a = 10.0.pow(gain / 40.0)
                val w0 = 2.0 * PI * f0 / fs
                val alpha = sin(w0) / (2.0 * BAND_Q)
                val cosW = cos(w0)
                val a0 = 1.0 + alpha / a
                b0[band] = ((1.0 + alpha * a) / a0).toFloat()
                b1[band] = (-2.0 * cosW / a0).toFloat()
                b2[band] = ((1.0 - alpha * a) / a0).toFloat()
                a1[band] = (-2.0 * cosW / a0).toFloat()
                a2[band] = ((1.0 - alpha / a) / a0).toFloat()
                if (resetAll || !bandActive[band]) {
                    for (ch in 0 until MAX_CHANNELS) {
                        val s = (ch * NUM_BANDS + band) * 2
                        state[s] = 0f
                        state[s + 1] = 0f
                    }
                }
                bandActive[band] = true
                any = true
            } else {
                bandActive[band] = false
            }
        }
        anyBandActive = any
    }

    /** Runs at the start of every control block (frame-aligned). */
    private fun controlBlock() {
        // Finish the previous block's preamp interpolation exactly.
        preampLin = preampBlockEnd
        preampStep = 0f

        val next = latest
        if (next !== seen) {
            seen = next
            if (!next.gainsDb.contentEquals(targetGains) || next.preampDb != targetPreamp) {
                curGains.copyInto(rampFromGains)
                rampFromPreamp = curPreampDb
                targetGains = next.gainsDb
                targetPreamp = next.preampDb
                rampBlocks = rampBlocksFor(sampleRate)
                rampBlock = 0
            }
        }

        if (isRamping()) {
            rampBlock += 1
            val t = rampBlock.toFloat() / rampBlocks
            if (rampBlock >= rampBlocks) {
                targetGains.copyInto(curGains)
                curPreampDb = targetPreamp
            } else {
                for (b in 0 until NUM_BANDS) {
                    curGains[b] = rampFromGains[b] + (targetGains[b] - rampFromGains[b]) * t
                }
                curPreampDb = rampFromPreamp + (targetPreamp - rampFromPreamp) * t
            }
            updateCoefficients(resetAll = false)
            preampBlockEnd = dbToLin(curPreampDb)
            preampStep = (preampBlockEnd - preampLin) / BLOCK_FRAMES
        }

        updateBypass()
    }

    companion object {
        /** Center frequencies of the 15 bands, in Hz (2/3 octave apart). */
        val BAND_FREQUENCIES = floatArrayOf(
            25f, 40f, 63f, 100f, 160f, 250f, 400f, 630f, 1000f, 1600f, 2500f, 4000f,
            6300f, 10000f, 16000f,
        )
        const val NUM_BANDS = 15

        /** Two-thirds of an octave bandwidth: 1 / (2 sinh(ln 2 / 2 * 2/3)). */
        private const val BAND_Q = 2.145

        /** Bands at or above this fraction of the sample rate are skipped. */
        private const val MAX_FREQ_RATIO = 0.45

        /** Frames between control updates (settings polling, ramp steps). */
        private const val BLOCK_FRAMES = 32

        /** Ramp duration for settings changes. */
        private const val RAMP_SECONDS = 0.020f

        /** Channels beyond this count get the preamp but no filtering. */
        private const val MAX_CHANNELS = 8

        /** Gains with a smaller magnitude than this (dB) are treated as 0. */
        private const val GAIN_EPSILON_DB = 1e-4f

        private fun dbToLin(db: Float): Float = 10f.pow(db / 20f)
    }
}
