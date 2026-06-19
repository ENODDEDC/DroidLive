package ui

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import preview.registerScreens

/**
 * Shows a tab per screen returned by registerScreens() (which lives in YOUR
 * project's PreviewRegistry.kt). You normally never edit this file.
 */
@Composable
fun PreviewHost() {
    val screens = remember { registerScreens() }
    var selected by remember { mutableStateOf(0) }

    if (screens.isEmpty()) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(
                text = "No screens yet.\nAdd them in PreviewRegistry.kt",
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(24.dp),
            )
        }
        return
    }

    val current = selected.coerceIn(0, screens.lastIndex)

    Column(modifier = Modifier.fillMaxSize()) {
        if (screens.size > 1) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                screens.forEachIndexed { index, screen ->
                    FilterChip(
                        selected = current == index,
                        onClick = { selected = index },
                        label = { Text(screen.title) },
                    )
                }
            }
        }
        screens[current].content()
    }
}
