package app.everslot.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** Open items of the pinned checklist with tap-to-complete (T8.2.08). */
class ChecklistWidget : GlanceAppWidget() {
  override val stateDefinition = HomeWidgetGlanceStateDefinition()
  override val sizeMode = SizeMode.Exact

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      GlanceTheme { Content(context, Snapshot.read(currentState<HomeWidgetGlanceState>().preferences)) }
    }
  }

  @Composable
  private fun Content(context: Context, snapshot: Snapshot?) {
    val list = snapshot?.checklist
    WidgetFrame(
        context,
        snapshot,
        title = list?.title ?: snapshot?.s("list").orEmpty(),
        link = list?.link ?: "everslot://lists",
        trailing = list?.let { "${it.done}/${it.total}" },
    ) {
      when {
        list == null -> EmptyLine(snapshot?.s("noList").orEmpty())
        list.items.isEmpty() -> EmptyLine(snapshot.s("listDone"))
        else ->
            LazyColumn(modifier = GlanceModifier.padding(top = 6.dp)) {
              items(list.items.take(15), itemId = { it.id.hashCode().toLong() }) { item ->
                ItemLine(item)
              }
            }
      }
    }
  }

  @Composable
  private fun ItemLine(item: ChecklistRow) {
    Row(
        modifier = GlanceModifier.fillMaxWidth().padding(start = (item.depth * 14).dp, top = 2.dp, bottom = 2.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
      Box(
          modifier =
              GlanceModifier.size(40.dp)
                  .semantics { contentDescription = item.text }
                  .clickable(
                      actionRunCallback<ItemTapAction>(actionParametersOf(RowIdKey to item.id, ActionUriKey to item.action))
                  ),
          contentAlignment = Alignment.Center,
      ) {
        Text("☐", style = TextStyle(color = GlanceTheme.colors.primary, fontSize = 20.sp))
      }
      Spacer(GlanceModifier.width(4.dp))
      Text(item.text, maxLines = 2, style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 13.sp))
    }
  }
}

class ChecklistWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ChecklistWidget>() {
  override val glanceAppWidget = ChecklistWidget()
}
