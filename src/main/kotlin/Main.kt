import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPosition
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import java.awt.MouseInfo
import java.awt.Window as AwtWindow
import ui.PreviewHost

/**
 * This is your "preview engine". It opens a borderless, phone-shaped window that
 * renders your Android screens (written in Jetpack Compose) live.
 *
 * Run it with:   ./gradlew hotRun --auto
 * Then every time you save a .kt file, the window updates instantly.
 *
 * Move the phone: drag the top (notch) area.
 * Close it:       press Esc (or Alt+F4).
 *
 * You mostly edit the screens inside src/main/kotlin/screens/.
 */
fun main() = application {
    val state = rememberWindowState(
        size = DpSize(400.dp, 820.dp),
        position = WindowPosition(Alignment.Center),
    )
    Window(
        onCloseRequest = ::exitApplication,
        state = state,
        undecorated = true,
        transparent = true,
        resizable = false,
        title = "Android Live Preview",
        onKeyEvent = { event ->
            if (event.key == Key.Escape) {
                exitApplication()
                true
            } else {
                false
            }
        },
    ) {
        MaterialTheme {
            PhoneFrame(awtWindow = window) {
                PreviewHost()
            }
        }
    }
}

@Composable
private fun PhoneFrame(
    awtWindow: AwtWindow,
    content: @Composable () -> Unit,
) {
    // The device fills the whole window. Outside the rounded corners is
    // transparent, so you only ever see the phone.
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0E0E10), RoundedCornerShape(40.dp))
            .padding(12.dp),
        contentAlignment = Alignment.TopCenter,
    ) {
        // The screen itself. Content starts below the status bar / notch.
        Surface(
            modifier = Modifier
                .fillMaxSize()
                .clip(RoundedCornerShape(34.dp)),
        ) {
            Box(modifier = Modifier.fillMaxSize().padding(top = 40.dp)) {
                content()
            }
        }
        // Drag handle: the status-bar strip with the camera notch.
        // Dragging here moves the whole window. We track the mouse position on
        // screen so the window follows the cursor exactly (no jitter).
        var grabX by remember { mutableStateOf(0) }
        var grabY by remember { mutableStateOf(0) }
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(40.dp)
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragStart = {
                            val mouse = MouseInfo.getPointerInfo().location
                            grabX = mouse.x - awtWindow.x
                            grabY = mouse.y - awtWindow.y
                        },
                        onDrag = { change, _ ->
                            change.consume()
                            val mouse = MouseInfo.getPointerInfo().location
                            awtWindow.setLocation(mouse.x - grabX, mouse.y - grabY)
                        },
                    )
                },
            contentAlignment = Alignment.TopCenter,
        ) {
            Box(
                modifier = Modifier
                    .padding(top = 8.dp)
                    .width(110.dp)
                    .height(24.dp)
                    .background(Color(0xFF0E0E10), RoundedCornerShape(50)),
            )
        }
    }
}
