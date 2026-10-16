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

subprojects {
    // device_apps pins compileSdk 30. androidx resources need android:attr/lStar
    // (API 31+). finalizeDsl runs after that pin and before AGP locks the DSL.
    plugins.withId("com.android.library") {
        val components = extensions.findByName("androidComponents") ?: return@withId
        val finalize = components.javaClass.methods.firstOrNull { method ->
            method.name == "finalizeDsl" &&
                method.parameterCount == 1 &&
                method.parameterTypes[0].name == "org.gradle.api.Action"
        } ?: return@withId
        val action = object : Action<Any> {
            override fun execute(ext: Any) {
                val current = ext.javaClass.methods.firstOrNull { method ->
                    method.name == "getCompileSdk" && method.parameterCount == 0
                }?.invoke(ext) as? Int
                if (current != null && current >= 36) return
                val setter = ext.javaClass.methods.firstOrNull { method ->
                    method.name == "setCompileSdk" && method.parameterCount == 1
                } ?: return
                setter.invoke(ext, 36)
            }
        }
        finalize.invoke(components, action)
    }
}

subprojects {
    // Lazy config so Flutter plugin modules inherit warning-tolerant Kotlin flags.
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            allWarningsAsErrors.set(false)
            freeCompilerArgs.addAll(
                listOf(
                    "-nowarn",
                    "-Xsuppress-version-warnings",
                ),
            )
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
