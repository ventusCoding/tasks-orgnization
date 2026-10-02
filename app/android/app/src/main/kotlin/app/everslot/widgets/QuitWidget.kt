package app.everslot.widgets

import android.content.Context
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.clickable
import androidx.glance.appwidget.AndroidRemoteViews
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import app.everslot.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import java.time.Duration
import java.time.Instant

/**
 * Clean-time counter (T8.2.05): whole days as text, the running part of the day as a system
 * Chronometer — it ticks without the app; the 30-minute update rolls the day count over.
 */
class QuitWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      GlanceTheme { Content(context, Snapshot.read(currentState<HomeWidgetGlanceState>().preferences)) }
    }
  }

  @Composable
  private fun Content(context: Context, snapshot: Snapshot?) {
    val quit = snapshot?.quits?.firstOrNull()
    WidgetFrame(context, snapshot, title = quit?.name ?: snapshot?.s("quit").orEmpty(), link = quit?.link ?: "everslot://habits") {
      if (quit == null) {
        EmptyLine(snapshot?.s("noQuit").orEmpty())
      } else {
        val elapsed = Duration.between(quit.since, Instant.now()).coerceAtLeast(Duration.ZERO)
        val days = elapsed.toDays()
        val withinDay = elapsed.minusDays(days).toMillis()
        val views =
            RemoteViews(context.packageName, R.layout.widget_quit_chronometer).apply {
              setChronometer(R.id.quit_chronometer, SystemClock.elapsedRealtime() - withinDay, null, true)
            }
        Column(modifier = GlanceModifier.fillMaxWidth().padding(top = 4.dp).clickable(openLink(context, quit.link))) {
          Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                context.resources.getQuantityString(R.plurals.widget_days, days.toInt(), days.toInt()),
                style = TextStyle(color = GlanceTheme.colors.primary, fontSize = 26.sp, fontWeight = FontWeight.Bold),
            )
          }
          AndroidRemoteViews(views)
          quit.saved?.let {
            Text(it, maxLines = 1, style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp))
          }
          quit.next?.let {
            Text(it, maxLines = 1, style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp))
          }
        }
      }
    }
  }
}

class QuitWidgetReceiver : HomeWidgetGlanceWidgetReceiver<QuitWidget>() {
  override val glanceAppWidget = QuitWidget()
}
