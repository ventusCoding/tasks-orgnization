package app.everslot.widgets

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.updateAll
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

val RowIdKey = ActionParameters.Key<String>("everslot.id")
val ActionUriKey = ActionParameters.Key<String>("everslot.action")

/**
 * Habit tap (T8.2.04): patch the snapshot optimistically, redraw, then let the Dart background
 * callback write the `habit_logs` row (source = widget) and the authoritative snapshot.
 */
class HabitTapAction : ActionCallback {
  override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
    val id = parameters[RowIdKey] ?: return
    val action = parameters[ActionUriKey] ?: return
    val prefs = HomeWidgetPlugin.getData(context)
    Snapshot.read(prefs)?.let { Snapshot.write(prefs, it.withHabitTapped(id)) }
    HabitsWidget().updateAll(context)
    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(action)).send()
  }
}

/** Checklist item tap (T8.2.08): same flow, the item leaves the open list at once. */
class ItemTapAction : ActionCallback {
  override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
    val id = parameters[RowIdKey] ?: return
    val action = parameters[ActionUriKey] ?: return
    val prefs = HomeWidgetPlugin.getData(context)
    Snapshot.read(prefs)?.let { Snapshot.write(prefs, it.withItemCompleted(id)) }
    ChecklistWidget().updateAll(context)
    HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(action)).send()
  }
}
