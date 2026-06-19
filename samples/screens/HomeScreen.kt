package screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

/**
 * Sample screen. Replace with your own (or point the launcher at your project).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen() {
    var count by remember { mutableStateOf(0) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("My App") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { count++ }) {
                Icon(Icons.Filled.Add, contentDescription = "Add")
            }
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("Welcome \uD83D\uDC4B")
            Card(modifier = Modifier.fillMaxWidth()) {
                Text(
                    text = "You tapped $count times",
                    modifier = Modifier.padding(16.dp),
                )
            }
            Button(onClick = { count = 0 }) {
                Text("Reset")
            }
        }
    }
}
