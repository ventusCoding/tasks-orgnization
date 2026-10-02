package app.everslot.widgets

import android.content.SharedPreferences
import java.time.Duration
import java.time.Instant
import org.json.JSONArray
import org.json.JSONObject

/**
 * The snapshot the app writes (Dart `WidgetSnapshot`, T8.2.02): read-only for rendering, patched in
 * place for optimistic taps (the background Dart callback writes the authoritative copy right after).
 */
class Snapshot(private val json: JSONObject) {
  val generatedAt: Instant? = json.optString("generatedAt").takeIf { it.isNotEmpty() }?.let { runCatching { Instant.parse(it) }.getOrNull() }
  val rtl: Boolean = json.optBoolean("rtl")
  val dayLabel: String = json.optString("dayLabel")
  val progress: String = json.optString("progress")
  private val strings: JSONObject = json.optJSONObject("strings") ?: JSONObject()

  fun s(key: String, fallback: String = ""): String = strings.optString(key, fallback)

  fun isStale(now: Instant = Instant.now()): Boolean =
      generatedAt == null || Duration.between(generatedAt, now) > Duration.ofHours(24)

  val agenda: List<AgendaRow> = json.optJSONArray("agenda").objects().map {
    AgendaRow(
        key = it.optString("key"),
        title = it.optString("title"),
        time = it.optString("time"),
        link = it.optString("link"),
        start = it.instant("start"),
        end = it.instant("end"),
        allDay = it.optBoolean("allDay"),
        color = if (it.has("color")) it.optLong("color").toInt() else null,
        done = it.optBoolean("done"),
    )
  }

  val habits: List<HabitRow> = json.optJSONArray("habits").objects().map {
    HabitRow(
        id = it.optString("id"),
        name = it.optString("name"),
        progress = it.optDouble("progress", 0.0).toFloat(),
        label = it.optString("label"),
        done = it.optBoolean("done"),
        counter = it.optBoolean("counter"),
        link = it.optString("link"),
        action = it.optString("action"),
        color = if (it.has("color")) it.optLong("color").toInt() else null,
    )
  }

  val quits: List<QuitRow> = json.optJSONArray("quits").objects().map {
    QuitRow(
        id = it.optString("id"),
        name = it.optString("name"),
        since = it.instant("since") ?: Instant.now(),
        link = it.optString("link"),
        saved = it.optString("saved").takeIf { s -> s.isNotEmpty() },
        next = it.optString("next").takeIf { s -> s.isNotEmpty() },
    )
  }

  val checklist: ChecklistBlock? = json.optJSONObject("checklist")?.let { c ->
    ChecklistBlock(
        id = c.optString("id"),
        title = c.optString("title"),
        done = c.optInt("done"),
        total = c.optInt("total"),
        link = c.optString("link"),
        items = c.optJSONArray("items").objects().map {
          ChecklistRow(it.optString("id"), it.optString("text"), it.optInt("depth"), it.optString("action"))
        },
    )
  }

  /** Optimistic habit tap: done for yes/no habits, one more for counters. */
  fun withHabitTapped(id: String): Snapshot {
    val copy = JSONObject(json.toString())
    copy.optJSONArray("habits").objects().firstOrNull { it.optString("id") == id }?.let { h ->
      if (h.optBoolean("counter")) {
        val parts = h.optString("label").split("/")
        val achieved = parts.getOrNull(0)?.toDoubleOrNull()
        val target = parts.getOrNull(1)?.toDoubleOrNull()
        if (achieved != null && target != null && target > 0) {
          val next = achieved + 1
          h.put("label", "${trim(next)}/${parts[1]}")
          h.put("progress", (next / target).coerceAtMost(1.0))
          h.put("done", next >= target)
        }
      } else {
        h.put("done", true)
        h.put("progress", 1.0)
        h.put("label", "✓")
      }
    }
    return Snapshot(copy)
  }

  /** Optimistic item tap: the item leaves the open list. */
  fun withItemCompleted(id: String): Snapshot {
    val copy = JSONObject(json.toString())
    copy.optJSONObject("checklist")?.let { c ->
      val items = c.optJSONArray("items") ?: JSONArray()
      val kept = JSONArray()
      for (i in 0 until items.length()) {
        val item = items.getJSONObject(i)
        if (item.optString("id") != id) kept.put(item)
      }
      c.put("items", kept)
      c.put("done", c.optInt("done") + 1)
    }
    return Snapshot(copy)
  }

  fun encode(): String = json.toString()

  companion object {
    const val KEY = "everslot_snapshot"

    fun read(prefs: SharedPreferences): Snapshot? =
        prefs.getString(KEY, null)?.let { runCatching { Snapshot(JSONObject(it)) }.getOrNull() }

    fun write(prefs: SharedPreferences, snapshot: Snapshot) {
      prefs.edit().putString(KEY, snapshot.encode()).apply()
    }

    private fun trim(v: Double): String = if (v == Math.floor(v)) v.toLong().toString() else "%.1f".format(v)
  }
}

data class AgendaRow(
    val key: String,
    val title: String,
    val time: String,
    val link: String,
    val start: Instant?,
    val end: Instant?,
    val allDay: Boolean,
    val color: Int?,
    val done: Boolean,
) {
  fun isNow(now: Instant): Boolean = start != null && end != null && !now.isBefore(start) && now.isBefore(end)

  fun isOver(now: Instant): Boolean = end != null && !now.isBefore(end)
}

data class HabitRow(
    val id: String,
    val name: String,
    val progress: Float,
    val label: String,
    val done: Boolean,
    val counter: Boolean,
    val link: String,
    val action: String,
    val color: Int?,
)

data class QuitRow(val id: String, val name: String, val since: Instant, val link: String, val saved: String?, val next: String?)

data class ChecklistRow(val id: String, val text: String, val depth: Int, val action: String)

data class ChecklistBlock(
    val id: String,
    val title: String,
    val done: Int,
    val total: Int,
    val link: String,
    val items: List<ChecklistRow>,
)

private fun JSONArray?.objects(): List<JSONObject> {
  if (this == null) return emptyList()
  return (0 until length()).mapNotNull { optJSONObject(it) }
}

private fun JSONObject.instant(key: String): Instant? =
    optString(key).takeIf { it.isNotEmpty() }?.let { runCatching { Instant.parse(it) }.getOrNull() }
