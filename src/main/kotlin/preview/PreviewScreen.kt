package preview

import androidx.compose.runtime.Composable

/**
 * One previewable screen. Give it a title (shown as a tab) and the composable
 * to render. You list these in your project's PreviewRegistry.kt.
 */
class PreviewScreen(
    val title: String,
    val content: @Composable () -> Unit,
)
