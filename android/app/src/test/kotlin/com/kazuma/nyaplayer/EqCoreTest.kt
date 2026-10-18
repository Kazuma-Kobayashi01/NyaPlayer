package com.kazuma.nyaplayer

import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.pow
import kotlin.math.sin
import kotlin.math.sqrt
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Same cases as the `tests` module of `rust/src/dsp/eq.rs`, so the Kotlin EQ
 * is held to the Rust one (M10-4).
 */
class EqCoreTest {
    private fun sine(freq: Float, sr: Int, secs: Float, amp: Float): FloatArray =
        FloatArray((sr * secs).toInt()) { i ->
            amp * sin(2.0 * PI * freq * i / sr).toFloat()
        }

    private fun rms(x: FloatArray, from: Int = 0, to: Int = x.size): Double {
        var sum = 0.0
        for (i in from until to) sum += x[i].toDouble().pow(2)
        return sqrt(sum / (to - from))
    }

    private fun db(ratio: Double) = 20.0 * log10(ratio)

    private fun gains(vararg pairs: Pair<Int, Double>): List<Double> {
        val g = MutableList(15) { 0.0 }
        for ((i, v) in pairs) g[i] = v
        return g
    }

    private fun core(sr: Int, channels: Int, enabled: Boolean, g: List<Double>, preamp: Double) =
        EqCore().apply {
            configure(sr, channels)
            set(enabled, g, preamp)
        }

    /** Gain in dB of a mono sine through the given settings (steady state). */
    private fun sineGainDb(freq: Float, sr: Int, g: List<Double>, preamp: Double = 0.0): Double {
        val input = sine(freq, sr, 1.0f, 0.25f)
        val out = input.copyOf()
        core(sr, 1, true, g, preamp).process(out, out.size)
        val skip = sr / 5
        return db(rms(out, skip) / rms(input, skip))
    }

    @Test
    fun bypassIsBitIdentical() {
        val input = sine(440f, 48_000, 0.1f, 0.8f) + floatArrayOf(1.5f, -2.0f, 0.0f, -0.0f)
        val frames = input.size / 2

        for (c in listOf(
            core(48_000, 2, true, gains(), 0.0),
            core(48_000, 2, false, List(15) { 6.0 }, -3.0),
        )) {
            val out = input.copyOf()
            c.process(out, frames)
            assertArrayEquals(
                input.map { it.toRawBits() }.toIntArray(),
                out.map { it.toRawBits() }.toIntArray(),
            )
        }

        // The only band is above 0.45 x fs, so it is skipped.
        val out = input.copyOf()
        core(22_050, 1, true, gains(14 to 12.0), 0.0).process(out, out.size)
        assertArrayEquals(
            input.map { it.toRawBits() }.toIntArray(),
            out.map { it.toRawBits() }.toIntArray(),
        )
    }

    @Test
    fun bandGainAtCenterAndFarAway() {
        val g = sineGainDb(1000f, 48_000, gains(8 to 6.0))
        assertEquals("1 kHz band gain $g dB", 6.0, g, 0.3)
        val far = sineGainDb(1000f, 48_000, gains(0 to 6.0))
        assertTrue("31 Hz band affected 1 kHz by $far dB", abs(far) < 0.5)
    }

    @Test
    fun preampMinus6Db() {
        val g = sineGainDb(1000f, 48_000, gains(), -6.0)
        assertEquals("preamp gain $g dB", -6.0, g, 0.1)
    }

    @Test
    fun midStreamChangeIsRampedAndFast() {
        val sr = 48_000
        val changeAt = 10_000
        // DC input makes any preamp jump obvious. Process in two chunks.
        val c = core(sr, 1, true, gains(), 0.0)
        val out = FloatArray(sr) { 0.5f }
        c.process(out, changeAt)
        c.set(true, gains(), -6.0)
        val tail = out.copyOfRange(changeAt, sr)
        c.process(tail, tail.size)
        tail.copyInto(out, changeAt)

        var maxJump = 0f
        for (i in 1 until out.size) maxJump = maxOf(maxJump, abs(out[i] - out[i - 1]))
        assertTrue("preamp jump $maxJump", maxJump < 0.005f)
        val expected = 0.5f * 10f.pow(-6f / 20f)
        for (i in changeAt + (0.025 * sr).toInt() until sr) {
            assertEquals(expected, out[i], 1e-5f)
        }
        assertEquals(0.5f, out[changeAt - 1], 1e-7f)

        // Band gain change on a sine: no jump beyond the boosted sine itself.
        val input = sine(1000f, sr, 1.0f, 0.1f)
        var inMaxDiff = 0f
        for (i in 1 until input.size) inMaxDiff = maxOf(inMaxDiff, abs(input[i] - input[i - 1]))
        val c2 = core(sr, 1, true, gains(), 0.0)
        val out2 = input.copyOf()
        c2.process(out2, changeAt)
        c2.set(true, gains(8 to 12.0), 0.0)
        val tail2 = out2.copyOfRange(changeAt, out2.size)
        c2.process(tail2, tail2.size)
        tail2.copyInto(out2, changeAt)
        var jump2 = 0f
        for (i in 1 until out2.size) jump2 = maxOf(jump2, abs(out2[i] - out2[i - 1]))
        val bound = inMaxDiff * 10f.pow(12f / 20f) * 1.1f
        assertTrue("jump $jump2 > $bound", jump2 <= bound)
        val from = changeAt + (0.025 * sr).toInt() + 480
        val g = db(rms(out2, from, from + 480 * 4) / rms(input, from, from + 480 * 4))
        assertEquals("gain after change $g", 12.0, g, 0.3)
    }

    @Test
    fun stereoIndependentStateAnd44k1() {
        val sr = 44_100
        val left = sine(1000f, sr, 1.0f, 0.25f)
        val interleaved = FloatArray(left.size * 2) { if (it % 2 == 0) left[it / 2] else 0f }
        val g6 = gains(8 to 6.0)
        core(sr, 2, true, g6, 0.0).process(interleaved, left.size)
        val outL = FloatArray(left.size) { interleaved[it * 2] }
        assertTrue("right channel leaked", (0 until left.size).all { interleaved[it * 2 + 1] == 0f })

        val mono = left.copyOf()
        core(sr, 1, true, g6, 0.0).process(mono, mono.size)
        assertArrayEquals(mono, outL, 0f)

        val skip = sr / 5
        val g = db(rms(outL, skip) / rms(left, skip))
        assertEquals("44.1k gain $g", 6.0, g, 0.3)
    }

    @Test
    fun outputIsClamped() {
        val input = sine(1000f, 48_000, 0.5f, 0.95f)
        val stereo = FloatArray(input.size * 2) { input[it / 2] }
        core(48_000, 2, true, List(15) { 12.0 }, 6.0).process(stereo, input.size)
        assertTrue(stereo.all { it in -1f..1f })
        assertTrue(stereo.any { abs(it) == 1f })
    }

    @Test
    fun flushRestartsFiltersWithoutNaN() {
        val c = core(48_000, 2, true, gains(8 to 12.0), 0.0)
        val buf = FloatArray(4096) { 0.5f }
        c.process(buf, buf.size / 2)
        c.configure(48_000, 2)
        c.process(buf, buf.size / 2)
        assertFalse(buf.any { !it.isFinite() })
    }
}
