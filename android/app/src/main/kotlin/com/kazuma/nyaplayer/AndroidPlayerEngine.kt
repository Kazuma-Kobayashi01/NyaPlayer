package com.kazuma.nyaplayer

import android.content.Context
import android.net.Uri
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Timeline
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Android playback core on Media3 ExoPlayer (TECH_SPEC §4.7, M10-2). Dart
 * talks to it through [PlayerEngine] in `AndroidPlayerEngine`; behaviour
 * mirrors the Rust engine (`rust/src/player/engine.rs`): the same queue
 * commands, loop modes and "skip broken files, stop after five in a row".
 *
 * The 10-band EQ (M10-4) is an ExoPlayer audio processor, see
 * [EqualizerAudioProcessor]. Not yet here (M10-5): audio focus and
 * becoming-noisy handling, still done by AudioFocusCoordinator, so ExoPlayer
 * is built with both of those disabled.
 *
 * Runs on the main thread (ExoPlayer requirement); Flutter method and event
 * channel callbacks are already delivered there.
 */
@OptIn(UnstableApi::class)
class AndroidPlayerEngine private constructor(context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val equalizer = EqualizerAudioProcessor()

    private val player: ExoPlayer = ExoPlayer.Builder(context, EqRenderersFactory(context, equalizer))
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(C.USAGE_MEDIA)
                .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
                .build(),
            /* handleAudioFocus = */ false,
        )
        .setHandleAudioBecomingNoisy(false)
        .build()

    // Channels of the Flutter engine currently attached (null while detached).
    private var method: MethodChannel? = null
    private var events: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var consecutiveFailures = 0

    private val listener = object : Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            emit(mapOf("kind" to "playing", "playing" to isPlaying))
        }

        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            emitIndex()
        }

        override fun onTimelineChanged(timeline: Timeline, reason: Int) {
            emitIndex()
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            when (playbackState) {
                Player.STATE_READY -> consecutiveFailures = 0
                Player.STATE_ENDED -> emit(mapOf("kind" to "completed"))
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            val path = player.currentMediaItem?.localConfiguration?.uri?.path ?: "?"
            emit(mapOf("kind" to "error", "message" to "$path: ${error.errorCodeName}"))
            consecutiveFailures++
            val current = player.currentMediaItemIndex
            // Repeat-one would spin on a broken file; move on to the next one.
            val next = if (player.repeatMode == Player.REPEAT_MODE_ONE) current + 1
            else player.nextMediaItemIndex
            if (consecutiveFailures < MAX_CONSECUTIVE_FAILURES && next != C.INDEX_UNSET &&
                next < player.mediaItemCount
            ) {
                player.seekTo(next, 0)
                player.prepare()
            } else {
                player.stop()
                emit(mapOf("kind" to "playing", "playing" to false))
            }
        }
    }

    init {
        player.addListener(listener)
    }

    private fun bind(messenger: BinaryMessenger) {
        method = MethodChannel(messenger, "nyaplayer/player").also { it.setMethodCallHandler(this) }
        events = EventChannel(messenger, "nyaplayer/player/events").also { it.setStreamHandler(this) }
    }

    private fun unbind() {
        method?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        method = null
        events = null
        sink = null
    }

    // MethodChannel ----------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openQueue" -> {
                val paths = call.argument<List<String>>("paths").orEmpty()
                val start = call.argument<Number>("startIndex")?.toInt() ?: 0
                val autoplay = call.argument<Boolean>("autoplay") ?: true
                consecutiveFailures = 0
                player.setMediaItems(paths.map(::mediaItem), start.coerceIn(0, maxOf(0, paths.size - 1)), 0)
                player.prepare()
                player.playWhenReady = autoplay
            }
            "play" -> player.play()
            "pause" -> player.pause()
            "seek" -> player.seekTo(call.argument<Number>("positionMs")?.toLong() ?: 0L)
            "jumpTo" -> {
                val index = call.argument<Number>("index")?.toInt() ?: -1
                if (index in 0 until player.mediaItemCount) player.seekTo(index, 0)
            }
            "add" -> call.argument<String>("path")?.let { player.addMediaItem(mediaItem(it)) }
            "insert" -> {
                val index = call.argument<Number>("index")?.toInt() ?: 0
                val path = call.argument<String>("path")
                if (path != null) {
                    player.addMediaItem(index.coerceIn(0, player.mediaItemCount), mediaItem(path))
                }
            }
            "remove" -> {
                val index = call.argument<Number>("index")?.toInt() ?: -1
                if (index in 0 until player.mediaItemCount) player.removeMediaItem(index)
            }
            "move" -> {
                val from = call.argument<Number>("from")?.toInt() ?: -1
                val to = call.argument<Number>("to")?.toInt() ?: -1
                val count = player.mediaItemCount
                if (from in 0 until count && to in 0 until count) player.moveMediaItem(from, to)
            }
            "reorder" -> reorder(call.argument<List<Number>>("order").orEmpty().map { it.toInt() })
            "setLoopMode" -> player.repeatMode = when (call.argument<String>("mode")) {
                "one" -> Player.REPEAT_MODE_ONE
                "all" -> Player.REPEAT_MODE_ALL
                else -> Player.REPEAT_MODE_OFF
            }
            "setEqualizer" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val gains = call.argument<List<Number>>("gainsDb").orEmpty().map { it.toDouble() }
                val preamp = call.argument<Number>("preampDb")?.toDouble() ?: 0.0
                android.util.Log.i("NyaEq", "setEqualizer enabled=$enabled preamp=$preamp gains=$gains")
                equalizer.core.set(enabled, gains, preamp)
            }
            "setVolume" -> player.volume = (call.argument<Number>("volume")?.toFloat() ?: 1f)
                .coerceIn(0f, 1f)
            "position" -> {
                result.success(player.currentPosition.coerceAtLeast(0L))
                return
            }
            else -> {
                result.notImplemented()
                return
            }
        }
        result.success(null)
    }

    /**
     * [order] lists original indexes in their new order (TECH_SPEC §4.2).
     * ExoPlayer has no bulk reorder, so move items one by one; playback of
     * the current item continues.
     */
    private fun reorder(order: List<Int>) {
        if (order.size != player.mediaItemCount) return
        val current = (0 until order.size).toMutableList()
        order.forEachIndexed { target, wanted ->
            val from = current.indexOf(wanted)
            if (from in 0 until order.size && from != target) {
                player.moveMediaItem(from, target)
                current.add(target, current.removeAt(from))
            }
        }
    }

    // EventChannel -----------------------------------------------------------

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) {
        sink = eventSink
        // Catch the new subscriber up: events sent before it listened are gone.
        emitIndex()
        emit(mapOf("kind" to "playing", "playing" to player.isPlaying))
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun emit(event: Map<String, Any?>) {
        sink?.success(event)
    }

    private fun emitIndex() {
        val index = if (player.mediaItemCount == 0) null else player.currentMediaItemIndex
        emit(mapOf("kind" to "currentIndex", "index" to index))
    }

    // Lifecycle --------------------------------------------------------------

    /**
     * Called when a Flutter engine attaches (MainActivity). The player is a
     * process-wide singleton: it outlives activities, so background playback
     * continues across activity recreation. Dart is asked to subscribe again
     * because its event subscription belonged to the previous engine.
     */
    companion object {
        @Volatile
        private var instance: AndroidPlayerEngine? = null

        /** Consecutive files that fail before playback stops (FMT-07). */
        private const val MAX_CONSECUTIVE_FAILURES = 5

        fun attach(context: Context, messenger: BinaryMessenger) {
            val engine = instance ?: AndroidPlayerEngine(context.applicationContext)
                .also { instance = it }
            engine.bind(messenger)
            engine.method?.invokeMethod("resubscribe", null)
        }

        fun detach() {
            instance?.unbind()
        }
    }

    private fun mediaItem(path: String): MediaItem =
        MediaItem.fromUri(Uri.fromFile(File(path)))

}

/**
 * Builds the audio sink with the EQ in its processor chain. Float output is
 * on so 24/32-bit PCM reaches the EQ as float instead of being cut to 16 bit.
 */
@OptIn(UnstableApi::class)
private class EqRenderersFactory(
    context: Context,
    private val equalizer: EqualizerAudioProcessor,
) : DefaultRenderersFactory(context) {
    override fun buildAudioSink(
        context: Context,
        enableFloatOutput: Boolean,
        enableAudioTrackPlaybackParams: Boolean,
    ): AudioSink = DefaultAudioSink.Builder(context)
        .setAudioProcessors(arrayOf(equalizer))
        .setEnableFloatOutput(enableFloatOutput)
        .setEnableAudioTrackPlaybackParams(enableAudioTrackPlaybackParams)
        .build()
}
