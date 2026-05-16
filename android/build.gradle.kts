allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Fix 1: Auto-inject namespace for plugins missing it (e.g. on_audio_query_android)
// Fix 2: Align Java + Kotlin JVM targets to prevent "Inconsistent JVM-target" build error
subprojects {
    plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android")

        // Namespace injection via reflection
        val getNamespace = android::class.java.methods
            .firstOrNull { it.name == "getNamespace" }
        val currentNamespace = getNamespace?.invoke(android) as? String
        if (currentNamespace.isNullOrEmpty()) {
            val groupId = project.group.toString()
            if (groupId.isNotEmpty()) {
                try {
                    android::class.java.getMethod("setNamespace", String::class.java)
                        .invoke(android, groupId)
                } catch (_: Exception) {}
            }
        }

        // Force Java compile options to match Kotlin JVM target
        project.tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }

        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "11"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
