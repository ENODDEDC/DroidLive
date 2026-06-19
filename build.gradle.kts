import java.util.Properties

plugins {
    kotlin("jvm") version "2.1.21"
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.21"
    id("org.jetbrains.compose") version "1.8.2"
    id("org.jetbrains.compose.hot-reload") version "1.1.0"
}

group = "com.preview"
version = "1.0.0"

// Which folder holds the screens to preview. Set by the folder picker
// (preview.ps1), which writes screensDir into preview.properties. If nothing is
// chosen, we fall back to the bundled samples.
val screensDir: String = run {
    val props = file("preview.properties")
    val chosen = if (props.exists()) {
        Properties().apply { props.inputStream().use { load(it) } }.getProperty("screensDir")
    } else {
        null
    }
    if (!chosen.isNullOrBlank() && file(chosen).exists()) chosen else "samples"
}

kotlin {
    jvmToolchain(21)
    sourceSets["main"].kotlin.srcDir(screensDir)
}

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation(compose.materialIconsExtended)
}

compose.desktop {
    application {
        mainClass = "MainKt"
    }
}
