package app.everslot.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextDecoration
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import java.time.Instant

/** Today agenda (T8.2.03): next tasks with a "now" marker; rows open the occurrence. */
class TodayWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()
  override val sizeMode = SizeMode.Exact

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      GlanceTheme { Content(context, Snapshot.read(currentState<HomeWidgetGlanceState>().preferences)) }
    }
  }

  @Composable
  private fun Content(context: Context, snapshot: Snapshot?) {
    val now = Instant.now()
    val rows = snapshot?.agenda.orEmpty().filter { !it.isOver(now) || it.allDay }
    val compact = LocalSize.current.height < 140.dp
    WidgetFrame(
        context,
        snapshot,
        title = snapshot?.dayLabel?.ifEmpty { null } ?: snapshot?.s("today") ?: "",
        link = "everslot://today",
        trailing = if (compact) null else snapshot?.progress,
    ) {
      if (rows.isEmpty()) {
        EmptyLine(snapshot?.s(if (snapshot.agenda.isEmpty()) "empty" else "allDone").orEmpty())
      } else {
        LazyColumn(modifier = GlanceModifier.padding(top = 6.dp)) {
          items(rows.take(if (compact) 2 else 12), itemId = { it.key.hashCode().toLong() }) { row ->
            AgendaLine(context, row, row.isNow(now), snapshot!!.s("now"))
          }
        }
      }
    }
  }

  @Composable
  private fun AgendaLine(context: Context, row: AgendaRow, isNow: Boolean, nowLabel: String) {
    Row(
        modifier =
            GlanceModifier.fillMaxWidth()
                .padding(vertical = 3.dp)
                .cornerRadius(10.dp)
                .background(if (isNow) GlanceTheme.colors.primaryContainer else GlanceTheme.colors.widgetBackground)
                .clickable(openLink(context, row.link)),
        verticalAlignment = Alignment.CenterVertically,
    ) {
      Box(
          modifier =
              GlanceModifier.width(4.dp)
                  .height(28.dp)
                  .cornerRadius(2.dp)
                  .background(argb(row.color) ?: GlanceTheme.colors.primary)
      ) {}
      Spacer(GlanceModifier.width(8.dp))
      Column(modifier = GlanceModifier.defaultWeight()) {
        Text(
            row.title,
            maxLines = 1,
            style =
                TextStyle(
                    color = GlanceTheme.colors.onSurface,
                    fontSize = 13.sp,
                    fontWeight = if (isNow) FontWeight.Bold else FontWeight.Normal,
                    textDecoration = if (row.done) TextDecoration.LineThrough else null,
                ),
        )
        Text(
            if (isNow) "$nowLabel · ${row.time}" else row.time,
            maxLines = 1,
            style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 11.sp),
        )
      }
    }
  }
}

class TodayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
  override val glanceAppWidget = TodayWidget()
}
