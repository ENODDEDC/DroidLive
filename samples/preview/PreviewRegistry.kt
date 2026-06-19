package preview

import screens.HomeScreen
import screens.LoginScreen

/**
 * List the screens you want to preview here. This is the ONLY file the preview
 * tool needs in your project. Add a line per screen.
 */
fun registerScreens(): List<PreviewScreen> = listOf(
    PreviewScreen("Home") { HomeScreen() },
    PreviewScreen("Login") { LoginScreen() },
)
