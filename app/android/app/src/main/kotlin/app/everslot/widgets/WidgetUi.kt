package app.everslot.widgets

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import app.everslot.MainActivity

/** Opens an `everslot://…` link in the app (handled by the external links service, T8.2.01). */
fun openLink(context: Context, link: String): Action =
    actionStartActivity(
        Intent(Intent.ACTION_VIEW, Uri.parse(link.ifEmpty { "everslot://today" }), context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    )

fun argb(color: Int?): ColorProvider? = color?.let { ColorProvider(Color(it)) }

/** Shared frame: rounded surface, title row, and the "open the app" state for missing/stale data. */
@Composable
fun WidgetFrame(
    context: Context,
    snapshot: Snapshot?,
    title: String,
    link: String,
    trailing: String? = null,
    content: @Composable () -> Unit,
) {
  Box(
      modifier =
          GlanceModifier.fillMaxSize()
              .background(GlanceTheme.colors.widgetBackground)
              .cornerRadius(20.dp)
              .padding(12.dp)
  ) {
    Column(modifier = GlanceModifier.fillMaxSize()) {
      Column(modifier = GlanceModifier.fillMaxWidth().clickable(openLink(context, link))) {
        Text(
            title,
            maxLines = 1,
            style = TextStyle(color = GlanceTheme.colors.onSurface, fontSize = 15.sp, fontWeight = FontWeight.Bold),
        )
        if (trailing != null && trailing.isNotEmpty()) {
          Text(trailing, maxLines = 1, style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 12.sp))
        }
      }
      if (snapshot == null || snapshot.isStale()) {
        Box(
            modifier = GlanceModifier.fillMaxSize().clickable(openLink(context, "everslot://today")),
            contentAlignment = Alignment.Center,
        ) {
          Text(
              snapshot?.s("stale") ?: context.getString(app.everslot.R.string.widget_open_app),
              style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 13.sp),
          )
        }
      } else {
        content()
      }
    }
  }
}

@Composable
fun EmptyLine(text: String) {
  Text(
      text,
      modifier = GlanceModifier.padding(top = 8.dp),
      style = TextStyle(color = GlanceTheme.colors.onSurfaceVariant, fontSize = 13.sp),
  )
}
