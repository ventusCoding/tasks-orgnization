package app.everslot.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.LocalSize
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
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
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** Today's habits with tap-to-check / +1 (T8.2.04). */
class HabitsWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()
  override val sizeMode = SizeMode.Exact

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      GlanceTheme { Content(context, Snapshot.read(currentState<HomeWidgetGlanceState>().preferences)) }
    }
  }

  @Composable
  private fun Content(context: Context, snapshot: Snapshot?) {
    val habits = snapshot?.habits.orEmpty()
    val compact = LocalSize.current.height < 140.dp
    WidgetFrame(
        context,
        snapshot,
        title = snapshot?.s("habits").orEmpty(),
        link = "everslot://habits",
        trailing = if (compact) null else snapshot?.s("habitsProgress"),
    ) {
      if (habits.isEmpty()) {
        EmptyLine(snapshot?.s("noHabits").orEmpty())
      } else {
        LazyColumn(modifier = GlanceModifier.padding(top = 6.dp)) {
          items(habits.take(if (compact) 2 else 12), itemId = { it.id.hashCode().toLong() }) { habit ->
            HabitLine(context, habit)
          }
        }
      }
    }
  }

  @Composable
  private fun HabitLine(context: Context, habit: HabitRow) {
    Row(
        modifier = GlanceModifier.fillMaxWidth().padding(vertical = 3.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
      Column(modifier = GlanceModifier.defaultWeight().clickable(openLink(context, habit.link))) {
        Text(
            habit.name,
            maxLines = 1,
            style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 13.sp, fontWeight = FontWeight.Medium),
        )
        LinearProgressIndicator(
            progress = habit.progress,
            modifier = GlanceModifier.fillMaxWidth().padding(top = 3.dp),
            color = argb(habit.color) ?: GlanceTheme.colors.primary,
            backgroundColor = GlanceTheme.colors.secondaryContainer,
        )
      }
      Spacer(GlanceModifier.width(8.dp))
      // 48 dp touch target; the label shows "✓" or "3/8".
      Box(
          modifier =
              GlanceModifier.size(44.dp)
                  .cornerRadius(22.dp)
                  .background(if (habit.done) GlanceTheme.colors.primary else GlanceTheme.colors.secondaryContainer)
                  .semantics { contentDescription = habit.name }
                  .clickable(
                      actionRunCallback<HabitTapAction>(
                          actionParametersOf(RowIdKey to habit.id, ActionUriKey to habit.action)
                      )
                  ),
          contentAlignment = Alignment.Center,
      ) {
        Text(
            if (habit.counter) habit.label.ifEmpty { "+1" } else if (habit.done) "✓" else "○",
            maxLines = 1,
            style =
                TextStyle(
                    color = if (habit.done) GlanceTheme.colors.onPrimary else GlanceTheme.colors.onSecondaryContainer,
                    fontSize = if (habit.counter) 11.sp else 18.sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                ),
        )
      }
    }
  }
}

class HabitsWidgetReceiver : HomeWidgetGlanceWidgetReceiver<HabitsWidget>() {
  override val glanceAppWidget = HabitsWidget()
}
